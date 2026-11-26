import AppKit
@preconcurrency import AVFoundation
@preconcurrency import AudioToolbox
import CoreAudio
import CoreAudioKit
import CoreMIDI
import Foundation
import MachO
import Network
import OpenGL.GL
import OpenGL.CGLCurrent
@preconcurrency import ScreenCaptureKit

// MARK: - Off-screen Hit-Testing & Focus Isolation Swizzles

nonisolated(unsafe) var gActiveHostedWindowNumber: Int = 0
nonisolated(unsafe) var gActiveHitWindowNumber: Int = 0
nonisolated(unsafe) var gAllowAppActivation: Bool = false
nonisolated(unsafe) var gOrigCGWarpPtr: (@convention(c) (CGPoint) -> CGError)? = nil

func runOnMainCommonModes(_ block: @escaping @MainActor () -> Void) {
    let mainLoop = CFRunLoopGetMain()
    CFRunLoopPerformBlock(mainLoop, CFRunLoopMode.commonModes.rawValue) {
        MainActor.assumeIsolated {
            block()
        }
    }
    CFRunLoopWakeUp(mainLoop)
}

func runOnMainCommonModesAfter(_ delaySeconds: TimeInterval, _ block: @escaping @MainActor () -> Void) {
    DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + delaySeconds) {
        runOnMainCommonModes(block)
    }
}

extension NSWindow {
    @objc class func cadenza_windowNumber(at point: NSPoint, belowWindowWithWindowNumber windowNumber: Int) -> Int {
        if !gAllowAppActivation {
            if gActiveHitWindowNumber != 0 {
                return gActiveHitWindowNumber
            }
            if gActiveHostedWindowNumber != 0 {
                return gActiveHostedWindowNumber
            }
        }
        return cadenza_windowNumber(at: point, belowWindowWithWindowNumber: windowNumber)
    }

    @objc func cadenza_convertRectToScreen(_ rect: NSRect) -> NSRect {
        if !gAllowAppActivation && !NSStringFromClass(type(of: self)).hasPrefix("JUCEWindow") {
            return NSRect(x: 200.0 + rect.origin.x, y: 200.0 + rect.origin.y, width: rect.width, height: rect.height)
        }
        return cadenza_convertRectToScreen(rect)
    }

    @objc func cadenza_convertRectFromScreen(_ rect: NSRect) -> NSRect {
        if !gAllowAppActivation && !NSStringFromClass(type(of: self)).hasPrefix("JUCEWindow") {
            return NSRect(x: rect.origin.x - 200.0, y: rect.origin.y - 200.0, width: rect.width, height: rect.height)
        }
        return cadenza_convertRectFromScreen(rect)
    }

    @objc func cadenza_order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
        if !gAllowAppActivation && NSStringFromClass(type(of: self)).hasPrefix("JUCEWindow") && place == .above {
            self.alphaValue = 0.0
            self.ignoresMouseEvents = true
            self.collectionBehavior = [.stationary, .ignoresCycle]
            cadenza_order(.below, relativeTo: otherWin)
            return
        }
        cadenza_order(place, relativeTo: otherWin)
    }
}

extension NSApplication {
    @objc func cadenza_isActive() -> Bool {
        if !gAllowAppActivation {
            return true
        }
        return cadenza_isActive()
    }
}

func installOffscreenSwizzles() {
    if let orig = class_getClassMethod(NSWindow.self, #selector(NSWindow.windowNumber(at:belowWindowWithWindowNumber:))),
       let repl = class_getClassMethod(NSWindow.self, #selector(NSWindow.cadenza_windowNumber(at:belowWindowWithWindowNumber:))) {
        method_exchangeImplementations(orig, repl)
    }
    if let origTo = class_getInstanceMethod(NSWindow.self, #selector(NSWindow.convertToScreen(_:))),
       let replTo = class_getInstanceMethod(NSWindow.self, #selector(NSWindow.cadenza_convertRectToScreen(_:))) {
        method_exchangeImplementations(origTo, replTo)
    }
    if let origFrom = class_getInstanceMethod(NSWindow.self, #selector(NSWindow.convertFromScreen(_:))),
       let replFrom = class_getInstanceMethod(NSWindow.self, #selector(NSWindow.cadenza_convertRectFromScreen(_:))) {
        method_exchangeImplementations(origFrom, replFrom)
    }
    if let origOrd = class_getInstanceMethod(NSWindow.self, #selector(NSWindow.order(_:relativeTo:))),
       let replOrd = class_getInstanceMethod(NSWindow.self, #selector(NSWindow.cadenza_order(_:relativeTo:))) {
        method_exchangeImplementations(origOrd, replOrd)
    }
    if let origActive = class_getInstanceMethod(NSApplication.self, #selector(getter: NSApplication.isActive)),
       let replActive = class_getInstanceMethod(NSApplication.self, #selector(NSApplication.cadenza_isActive)) {
        method_exchangeImplementations(origActive, replActive)
    }
}

func neutralizeCGWarpInLoadedImages() {
    guard let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGWarpMouseCursorPosition") else {
        return
    }
    if gOrigCGWarpPtr == nil {
        gOrigCGWarpPtr = unsafeBitCast(sym, to: (@convention(c) (CGPoint) -> CGError).self)
    }
    let noop: @convention(c) (CGPoint) -> CGError = { pt in
        if gAllowAppActivation, let orig = gOrigCGWarpPtr {
            return orig(pt)
        }
        return .success
    }
    let noopPtr = unsafeBitCast(noop, to: UnsafeMutableRawPointer.self)
    let imgCount = _dyld_image_count()
    for i in 0..<imgCount {
        guard let namePtr = _dyld_get_image_name(i) else { continue }
        let name = String(cString: namePtr)
        guard name.contains("Arturia") || name.contains("Plug-Ins") else { continue }
        guard let header = _dyld_get_image_header(i) else { continue }
        var size: UInt = 0
        for seg in ["__DATA", "__DATA_CONST"] {
            for sect in ["__la_symbol_ptr", "__got"] {
                if let raw = getsectiondata(UnsafePointer<mach_header_64>(OpaquePointer(header)), seg, sect, &size) {
                    let count = Int(size) / MemoryLayout<UnsafeMutableRawPointer>.size
                    let ptrs = UnsafeMutableRawPointer(mutating: raw).assumingMemoryBound(to: UnsafeMutableRawPointer.self)
                    for j in 0..<count {
                        if ptrs[j] == sym {
                            var protErr = vm_protect(mach_task_self_, vm_address_t(bitPattern: ptrs + j), vm_size_t(8), 0, VM_PROT_READ | VM_PROT_WRITE)
                            if protErr != KERN_SUCCESS {
                                protErr = vm_protect(mach_task_self_, vm_address_t(bitPattern: ptrs + j), vm_size_t(8), 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY)
                            }
                            if protErr == KERN_SUCCESS {
                                ptrs[j] = noopPtr
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Helpers

func fourCC(_ s: String) -> OSType {
    var result: OSType = 0
    for byte in s.utf8.prefix(4) {
        result = (result << 8) | OSType(byte)
    }
    return result
}

func jsonString(_ dict: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
          let str = String(data: data, encoding: .utf8) else {
        return "{}"
    }
    return str
}

func normalizeSynthKey(_ s: String) -> String {
    return s.lowercased()
        .replacingOccurrences(of: "arturia:", with: "")
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: "_", with: "")
}

// MARK: - Hosted Synth Model

struct MidiCCMapping {
    let cc: UInt8
    let channel: UInt8
    let paramId: UInt64
    let minVal: Float
    let maxVal: Float
}

struct SynthLoadRequest {
    let uiName: String
    let appName: String
    let deviceName: String
    let bank: Int
    let program: Int
    let volume: Int
    let volumeCc: Int
    let cutoff: Int
    let resonance: Int
    let makeActive: Bool
}

@MainActor
final class HostedSynth {
    let key: String
    let displayName: String
    let appName: String
    let componentName: String
    let deviceName: String
    let avUnit: AVAudioUnit
    let viewController: NSViewController?
    let rootView: NSView
    let window: NSWindow
    var viewWidth: Int
    var viewHeight: Int
    var isPoppedOut: Bool = false
    var midiDest: MIDIEndpointRef = 0
    var paramToCC: [UInt64: MidiCCMapping] = [:]
    var paramObserverToken: AUParameterObserverToken?
    var suppressOutgoingUntil: TimeInterval = 0
    var recentOutgoingCC: [String: (val: UInt8, time: TimeInterval)] = [:]
    var lastSyncedBank: Int = -1
    var lastSyncedProgram: Int = -1
    var volumeSyncGen: Int = 0

    init(
        key: String,
        displayName: String,
        appName: String,
        componentName: String,
        deviceName: String,
        avUnit: AVAudioUnit,
        viewController: NSViewController?,
        rootView: NSView,
        window: NSWindow
    ) {
        self.key = key
        self.displayName = displayName
        self.appName = appName
        self.componentName = componentName
        self.deviceName = deviceName
        self.avUnit = avUnit
        self.viewController = viewController
        self.rootView = rootView
        self.window = window
        let sz = rootView.frame.size
        self.viewWidth = max(100, Int(sz.width.rounded()))
        self.viewHeight = max(100, Int(sz.height.rounded()))
    }
}

// MARK: - AU Host Controller

@MainActor
final class AUHostController {
    private let engine = AVAudioEngine()
    private var engineStarted = false
    private var outputDeviceConfigured = false
    private var midiEnabled = true
    private var midiClient = MIDIClientRef()
    private var midiInPort = MIDIPortRef()
    private var midiOutPort = MIDIPortRef()
    private var connectedSources: [String: MIDIEndpointRef] = [:]
    private var totalOutgoingCCSent = 0

    private var hostedByKey: [String: HostedSynth] = [:]
    private(set) var activeSynth: HostedSynth?
    private var isLoadingSynth = false
    private var loadQueue: [SynthLoadRequest] = []
    private var pendingCompletions: [String: [([String: Any]) -> Void]] = [:]

    private var latestJpegData: Data?
    private var captureTimer: Timer?
    private var isCapturing = false
    private var scWindowCache: [Int: SCWindow] = [:]
    private var lastCaptureMode: String = "none"
    private var mjpegClients: [NWConnection] = []
    private var eventCounter = 1
    private var lastDownPoint: NSPoint?

    init() {
        setupMIDI()
    }

    private func setupMIDI() {
        let status = MIDIClientCreateWithBlock("CadenzaAUHost" as CFString, &midiClient) { _ in }
        if status != noErr {
            fputs("[au-host] MIDIClientCreateWithBlock failed: \(status)\n", stderr)
            return
        }
        let portStatus = MIDIInputPortCreateWithBlock(midiClient, "CadenzaAUInput" as CFString, &midiInPort) { [weak self] pktListPtr, srcConnRefCon in
            guard let self = self else { return }
            let synthKey: String? = srcConnRefCon.map { Unmanaged<NSString>.fromOpaque($0).takeUnretainedValue() as String }
            let packets = pktListPtr.pointee
            var packet = packets.packet
            var events: [(String?, [UInt8])] = []
            for _ in 0..<packets.numPackets {
                let len = Int(packet.length)
                if len > 0 {
                    let bytes = withUnsafeBytes(of: packet.data) { raw -> [UInt8] in
                        Array(raw.prefix(min(len, raw.count)))
                    }
                    events.append((synthKey, bytes))
                }
                packet = MIDIPacketNext(&packet).pointee
            }
            if !events.isEmpty {
                DispatchQueue.main.async {
                    self.dispatchMIDIEvents(events)
                }
            }
        }
        if portStatus != noErr {
            fputs("[au-host] MIDIInputPortCreateWithBlock failed: \(portStatus)\n", stderr)
        }
        let outStatus = MIDIOutputPortCreate(midiClient, "CadenzaAUOutput" as CFString, &midiOutPort)
        if outStatus != noErr {
            fputs("[au-host] MIDIOutputPortCreate failed: \(outStatus)\n", stderr)
        }
    }

    private func endpointNames(_ endpoint: MIDIEndpointRef) -> (display: String, name: String) {
        var dispRef: Unmanaged<CFString>?
        var nameRef: Unmanaged<CFString>?
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &dispRef)
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &nameRef)
        let disp = (dispRef?.takeRetainedValue() as String?) ?? ""
        let name = (nameRef?.takeRetainedValue() as String?) ?? ""
        return (disp, name)
    }

    private func matchesIACBus(_ endpoint: MIDIEndpointRef, hosted: HostedSynth) -> Bool {
        let (disp, name) = endpointNames(endpoint)
        let devName = hosted.deviceName
        let shortBus = devName.replacingOccurrences(of: "IAC Driver ", with: "").trimmingCharacters(in: .whitespaces)
        let candidates = [devName, shortBus, hosted.appName, hosted.displayName].filter { !$0.isEmpty }
        for c in candidates {
            if disp.caseInsensitiveCompare(c) == .orderedSame || name.caseInsensitiveCompare(c) == .orderedSame {
                return true
            }
        }
        if !shortBus.isEmpty {
            if disp.localizedCaseInsensitiveContains(shortBus) || name.localizedCaseInsensitiveContains(shortBus) {
                return true
            }
        }
        return false
    }

    private func dispatchMIDIEvents(_ events: [(String?, [UInt8])]) {
        let now = CACurrentMediaTime()
        for (key, bytes) in events {
            guard let key = key, let hosted = hostedByKey[key] else { continue }
            guard let scheduleMIDI = hosted.avUnit.auAudioUnit.scheduleMIDIEventBlock else { continue }
            if bytes.count >= 3 && (bytes[0] & 0xF0) == 0xB0 {
                let ch = bytes[0] & 0x0F
                let cc = bytes[1]
                let val = bytes[2]
                let cacheKey = "\(ch):\(cc)"
                if let recent = hosted.recentOutgoingCC[cacheKey], recent.val == val, (now - recent.time) < 0.15 {
                    continue
                }
                hosted.suppressOutgoingUntil = now + 0.08
            } else if bytes.count >= 2 && (bytes[0] & 0xF0) == 0xC0 {
                hosted.suppressOutgoingUntil = now + 0.25
            }
            bytes.withUnsafeBufferPointer { buf in
                if let base = buf.baseAddress {
                    scheduleMIDI(AUEventSampleTimeImmediate, 0, bytes.count, base)
                }
            }
        }
    }

    private func syncMIDIConnections() {
        for (_, src) in connectedSources {
            MIDIPortDisconnectSource(midiInPort, src)
        }
        connectedSources.removeAll()

        let srcCount = MIDIGetNumberOfSources()
        for i in 0..<srcCount {
            let src = MIDIGetSource(i)
            for (key, hosted) in hostedByKey {
                if connectedSources[key] == nil && matchesIACBus(src, hosted: hosted) {
                    let ref = Unmanaged.passUnretained(hosted.key as NSString).toOpaque()
                    if MIDIPortConnectSource(midiInPort, src, ref) == noErr {
                        connectedSources[key] = src
                    }
                }
            }
        }

        let dstCount = MIDIGetNumberOfDestinations()
        for (_, hosted) in hostedByKey {
            hosted.midiDest = 0
            for i in 0..<dstCount {
                let dst = MIDIGetDestination(i)
                if matchesIACBus(dst, hosted: hosted) {
                    hosted.midiDest = dst
                    break
                }
            }
        }
    }

    private func sendCC(to hosted: HostedSynth, channel: UInt8, cc: UInt8, value: UInt8) {
        guard hosted.midiDest != 0, midiOutPort != 0 else { return }
        hosted.recentOutgoingCC["\(channel & 0x0F):\(cc)"] = (value, CACurrentMediaTime())
        var pktList = MIDIPacketList()
        let bytes: [UInt8] = [0xB0 | (channel & 0x0F), cc, value]
        withUnsafeMutablePointer(to: &pktList) { listPtr in
            let pkt = MIDIPacketListInit(listPtr)
            _ = bytes.withUnsafeBufferPointer { buf in
                MIDIPacketListAdd(listPtr, MemoryLayout<MIDIPacketList>.size, pkt, 0, bytes.count, buf.baseAddress!)
            }
            MIDISend(midiOutPort, hosted.midiDest, listPtr)
        }
        totalOutgoingCCSent += 1
    }

    private func loadDefaultMidiMap(appName: String) -> [UInt64: MidiCCMapping] {
        var result: [UInt64: MidiCCMapping] = [:]
        guard !appName.isEmpty else { return result }
        let xmlPath = "/Library/Arturia/\(appName)/resources/plugin.prefmidi.xml"
        guard let xml = try? String(contentsOfFile: xmlPath, encoding: .utf8) else { return result }
        guard let startRange = xml.range(of: "<midiconfig name=\"Default\">"),
              let endRange = xml.range(of: "</midiconfig>", range: startRange.upperBound..<xml.endIndex) else {
            return result
        }
        let section = String(xml[startRange.upperBound..<endRange.lowerBound])
        guard let lineRe = try? NSRegularExpression(pattern: "<assignment\\s+([^/>]+)/?>", options: []),
              let attrRe = try? NSRegularExpression(pattern: "(\\w+)=\"([^\"]*)\"", options: []) else {
            return result
        }
        let nsSection = section as NSString
        for match in lineRe.matches(in: section, range: NSRange(location: 0, length: nsSection.length)) {
            let attrsStr = nsSection.substring(with: match.range(at: 1))
            let nsAttrs = attrsStr as NSString
            var attrs: [String: String] = [:]
            for am in attrRe.matches(in: attrsStr, range: NSRange(location: 0, length: nsAttrs.length)) {
                attrs[nsAttrs.substring(with: am.range(at: 1))] = nsAttrs.substring(with: am.range(at: 2))
            }
            guard let ccInt = attrs["controller"].flatMap({ Int($0) }),
                  let paramInt = attrs["paramid"].flatMap({ UInt64($0) }) else {
                continue
            }
            let chInt = attrs["channel"].flatMap({ Int($0) }) ?? 0
            let isRel = attrs["isrelative"].flatMap({ Int($0) }) ?? 0
            guard isRel == 0, ccInt >= 0, ccInt <= 127 else { continue }
            let minV = attrs["min"].flatMap({ Float($0) }) ?? 0.0
            let maxV = attrs["max"].flatMap({ Float($0) }) ?? 1.0
            result[paramInt] = MidiCCMapping(
                cc: UInt8(ccInt),
                channel: UInt8(max(0, min(15, chInt))),
                paramId: paramInt,
                minVal: minV,
                maxVal: maxV
            )
        }
        return result
    }

    private func installParameterObserver(for hosted: HostedSynth) {
        guard hosted.paramObserverToken == nil,
              let tree = hosted.avUnit.auAudioUnit.parameterTree else {
            return
        }
        hosted.paramObserverToken = tree.token(byAddingParameterObserver: { [weak self, weak hosted] address, value in
            DispatchQueue.main.async {
                guard let self = self, let hosted = hosted else { return }
                // When AU Audio is enabled, au-host is the synth engine itself;
                // do not echo parameter changes back onto the IAC bus.
                guard !self.midiEnabled else { return }
                guard CACurrentMediaTime() > hosted.suppressOutgoingUntil else { return }
                guard let mapping = hosted.paramToCC[address] else { return }
                let span = mapping.maxVal - mapping.minVal
                let norm: Float = abs(span) > 0.0001 ? ((value - mapping.minVal) / span) : value
                let clamped = max(0.0, min(1.0, norm))
                let ccVal = UInt8(max(0, min(127, Int((clamped * 127.0).rounded()))))
                self.sendCC(to: hosted, channel: mapping.channel, cc: mapping.cc, value: ccVal)
            }
        })
    }

    private func stopStandaloneAppIfRunning(appName: String) {
        guard midiEnabled, !appName.isEmpty else { return }
        DispatchQueue.global(qos: .utility).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            proc.arguments = ["-x", appName]
            try? proc.run()
        }
    }

    private func configureOutputDeviceIfNeeded(appName: String) {
        guard !outputDeviceConfigured else { return }
        outputDeviceConfigured = true
        var preferredName = "USB Audio CODEC"
        if !appName.isEmpty {
            let prefPath = "/Library/Arturia/\(appName)/tmp/standalone.pref"
            if let xml = try? String(contentsOfFile: prefPath, encoding: .utf8),
               let re = try? NSRegularExpression(pattern: "name=\"AudioDeviceOutputName\"\\s+val=\"([^\"]+)\""),
               let m = re.firstMatch(in: xml, range: NSRange(location: 0, length: (xml as NSString).length)) {
                preferredName = (xml as NSString).substring(with: m.range(at: 1))
            }
        }
        var propAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &dataSize) == noErr else { return }
        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &dataSize, &devices) == noErr else { return }
        for devId in devices {
            var nameAddr = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var cfName: Unmanaged<CFString>?
            var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            if AudioObjectGetPropertyData(devId, &nameAddr, 0, nil, &nameSize, &cfName) == noErr,
               let name = cfName?.takeRetainedValue() as String?,
               name.caseInsensitiveCompare(preferredName) == .orderedSame {
                var outAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyStreamConfiguration,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: kAudioObjectPropertyElementMain
                )
                var bufSize: UInt32 = 0
                if AudioObjectGetPropertyDataSize(devId, &outAddr, 0, nil, &bufSize) == noErr,
                   bufSize >= UInt32(MemoryLayout<AudioBufferList>.size) {
                    let rawBuf = UnsafeMutableRawPointer.allocate(byteCount: Int(bufSize), alignment: MemoryLayout<AudioBufferList>.alignment)
                    defer { rawBuf.deallocate() }
                    if AudioObjectGetPropertyData(devId, &outAddr, 0, nil, &bufSize, rawBuf) == noErr {
                        let list = rawBuf.assumingMemoryBound(to: AudioBufferList.self).pointee
                        if list.mNumberBuffers > 0, let outUnit = engine.outputNode.audioUnit {
                            var target = devId
                            AudioUnitSetProperty(
                                outUnit,
                                kAudioOutputUnitProperty_CurrentDevice,
                                kAudioUnitScope_Global,
                                0,
                                &target,
                                UInt32(MemoryLayout<AudioDeviceID>.size)
                            )
                            return
                        }
                    }
                }
            }
        }
    }

    private func ensureEngineRunning(appName: String = "") {
        configureOutputDeviceIfNeeded(appName: appName)
        engine.mainMixerNode.outputVolume = midiEnabled ? 1.0 : 0.0
        guard !engineStarted else { return }
        do {
            try engine.start()
            engineStarted = true
        } catch {
            fputs("[au-host] AVAudioEngine start failed: \(error)\n", stderr)
        }
    }

    func setMIDIEnabled(_ enabled: Bool) {
        midiEnabled = enabled
        ensureEngineRunning()
        syncMIDIConnections()
        if enabled {
            for hosted in hostedByKey.values {
                stopStandaloneAppIfRunning(appName: hosted.appName)
            }
        }
    }

    func statusDict() -> [String: Any] {
        return [
            "ok": true,
            "activeSynth": activeSynth?.displayName as Any,
            "activeKey": activeSynth?.key as Any,
            "width": activeSynth?.viewWidth ?? 0,
            "height": activeSynth?.viewHeight ?? 0,
            "loadedSynths": Array(hostedByKey.keys).sorted(),
            "midiEnabled": midiEnabled,
            "connectedSources": Array(connectedSources.keys).sorted(),
            "hasActiveMidiDest": (activeSynth?.midiDest ?? 0) != 0,
            "midiMapCount": activeSynth?.paramToCC.count ?? 0,
            "outgoingCCSent": totalOutgoingCCSent,
            "openPopups": openPopupWindows().count,
            "poppedOut": activeSynth?.isPoppedOut ?? false,
            "captureMode": lastCaptureMode,
            "hasFrame": latestJpegData != nil
        ]
    }

    func listArturiaComponents() -> [AVAudioUnitComponent] {
        let desc = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice,
            componentSubType: 0,
            componentManufacturer: fourCC("Artu"),
            componentFlags: 0,
            componentFlagsMask: 0
        )
        return AVAudioUnitComponentManager.shared().components(matching: desc)
    }

    private func findComponent(uiName: String, appName: String) -> AVAudioUnitComponent? {
        let components = listArturiaComponents()
        let targets = [appName, uiName].filter { !$0.isEmpty }
        for target in targets {
            let normTarget = normalizeSynthKey(target)
            if let exact = components.first(where: { normalizeSynthKey($0.name) == normTarget }) {
                return exact
            }
        }
        for target in targets {
            let normTarget = normalizeSynthKey(target)
            if let partial = components.first(where: { normalizeSynthKey($0.name).contains(normTarget) }) {
                return partial
            }
        }
        return nil
    }

    private func syncDeviceState(
        to hosted: HostedSynth?,
        avUnit: AVAudioUnit,
        bank: Int,
        program: Int,
        volume: Int,
        volumeCc: Int,
        cutoff: Int,
        resonance: Int,
        includePreset: Bool = true
    ) {
        hosted?.suppressOutgoingUntil = CACurrentMediaTime() + 0.35
        guard let scheduleMIDI = avUnit.auAudioUnit.scheduleMIDIEventBlock else { return }
        var msgs: [[UInt8]] = []
        if includePreset && bank >= 0 && program >= 0 {
            hosted?.lastSyncedBank = bank
            hosted?.lastSyncedProgram = program
            msgs.append([0xB0, 0, 0])
            msgs.append([0xB0, 32, UInt8(bank & 0x7F)])
            msgs.append([0xC0, UInt8(program & 0x7F)])
        }
        if volume >= 0 && volumeCc >= 0 {
            let v = UInt8(max(0, min(127, volume)))
            let nudge = v > 0 ? v - 1 : min(127, v + 1)
            msgs.append([0xB0, UInt8(volumeCc & 0x7F), nudge])
            msgs.append([0xB0, UInt8(volumeCc & 0x7F), v])
        }
        if cutoff >= 0 {
            msgs.append([0xB0, 74, UInt8(max(0, min(127, cutoff)))])
        }
        if resonance >= 0 {
            msgs.append([0xB0, 71, UInt8(max(0, min(127, resonance)))])
        }
        for msg in msgs {
            msg.withUnsafeBufferPointer { buf in
                if let base = buf.baseAddress {
                    scheduleMIDI(AUEventSampleTimeImmediate, 0, msg.count, base)
                }
            }
        }
    }

    private func schedulePostPresetControllerSync(
        hosted: HostedSynth,
        volume: Int,
        volumeCc: Int,
        cutoff: Int,
        resonance: Int
    ) {
        hosted.volumeSyncGen += 1
        let gen = hosted.volumeSyncGen
        for delay in [0.45, 1.1, 2.2] {
            runOnMainCommonModesAfter(delay) { [weak self, weak hosted] in
                guard let self = self, let hosted = hosted, hosted.volumeSyncGen == gen else { return }
                self.syncDeviceState(
                    to: hosted,
                    avUnit: hosted.avUnit,
                    bank: -1,
                    program: -1,
                    volume: volume,
                    volumeCc: volumeCc,
                    cutoff: cutoff,
                    resonance: resonance,
                    includePreset: false
                )
            }
        }
    }

    private func dismissOpenPopups() {
        if let hosted = activeSynth {
            let targetView = findMouseTargetView(hosted.rootView)
            let dismissSel = NSSelectorFromString("dismissModals")
            if targetView.responds(to: dismissSel) {
                targetView.perform(dismissSel)
            }
        }
        for w in NSApp.windows where NSStringFromClass(type(of: w)).hasPrefix("JUCEWindow") {
            w.orderOut(nil)
        }
        if let hosted = activeSynth {
            gActiveHitWindowNumber = hosted.window.windowNumber
        }
    }

    private func unloadHostedSynth(key: String) {
        guard let hosted = hostedByKey.removeValue(forKey: key) else { return }
        hosted.volumeSyncGen += 1
        if let token = hosted.paramObserverToken,
           let tree = hosted.avUnit.auAudioUnit.parameterTree {
            tree.removeParameterObserver(token)
            hosted.paramObserverToken = nil
        }
        if let src = connectedSources.removeValue(forKey: key) {
            MIDIPortDisconnectSource(midiInPort, src)
        }
        engine.disconnectNodeOutput(hosted.avUnit)
        engine.detach(hosted.avUnit)
        hosted.window.orderOut(nil)
        if activeSynth === hosted {
            activeSynth = nil
        }
    }

    func syncActiveSynths(devices: [[String: Any]]) {
        var activeKeys: Set<String> = []
        var requests: [SynthLoadRequest] = []
        for (idx, dev) in devices.enumerated() {
            let uiName = (dev["uiName"] as? String) ?? ""
            let appName = (dev["appName"] as? String) ?? ""
            let deviceName = (dev["deviceName"] as? String) ?? ""
            let lookupName = !appName.isEmpty ? appName : uiName
            let key = normalizeSynthKey(lookupName)
            guard !key.isEmpty else { continue }
            guard !activeKeys.contains(key) else { continue }
            activeKeys.insert(key)
            requests.append(
                SynthLoadRequest(
                    uiName: uiName,
                    appName: appName,
                    deviceName: deviceName,
                    bank: (dev["bank"] as? Int) ?? -1,
                    program: (dev["program"] as? Int) ?? -1,
                    volume: (dev["volume"] as? Int) ?? -1,
                    volumeCc: (dev["volumeCc"] as? Int) ?? 7,
                    cutoff: (dev["cutoff"] as? Int) ?? -1,
                    resonance: (dev["resonance"] as? Int) ?? -1,
                    makeActive: activeSynth == nil && idx == 0
                )
            )
        }

        if !activeKeys.isEmpty {
            // Unload any previously hosted synths that are no longer in the song's device list
            for existingKey in Array(hostedByKey.keys) where !activeKeys.contains(existingKey) {
                if activeSynth?.key == existingKey { continue }
                unloadHostedSynth(key: existingKey)
            }
            loadQueue.removeAll { req in
                let k = normalizeSynthKey(!req.appName.isEmpty ? req.appName : req.uiName)
                return !activeKeys.contains(k)
            }
        }

        for req in requests {
            enqueueSynthLoad(req, completion: nil)
        }
    }

    func selectSynth(
        uiName: String,
        appName: String,
        deviceName: String,
        bank: Int = -1,
        program: Int = -1,
        volume: Int = -1,
        volumeCc: Int = 7,
        cutoff: Int = -1,
        resonance: Int = -1,
        completion: @escaping ([String: Any]) -> Void
    ) {
        dismissOpenPopups()
        let req = SynthLoadRequest(
            uiName: uiName,
            appName: appName,
            deviceName: deviceName,
            bank: bank,
            program: program,
            volume: volume,
            volumeCc: volumeCc,
            cutoff: cutoff,
            resonance: resonance,
            makeActive: true
        )
        enqueueSynthLoad(req, completion: completion)
    }

    private func enqueueSynthLoad(_ req: SynthLoadRequest, completion: (([String: Any]) -> Void)?) {
        let lookupName = !req.appName.isEmpty ? req.appName : req.uiName
        let key = normalizeSynthKey(lookupName)
        stopStandaloneAppIfRunning(appName: req.appName)

        if let existing = hostedByKey[key] {
            let presetChanged = (req.bank >= 0 && req.program >= 0)
                && (existing.lastSyncedBank != req.bank || existing.lastSyncedProgram != req.program)
            if presetChanged {
                syncDeviceState(
                    to: existing,
                    avUnit: existing.avUnit,
                    bank: req.bank,
                    program: req.program,
                    volume: req.volume,
                    volumeCc: req.volumeCc,
                    cutoff: req.cutoff,
                    resonance: req.resonance,
                    includePreset: true
                )
                schedulePostPresetControllerSync(
                    hosted: existing,
                    volume: req.volume,
                    volumeCc: req.volumeCc,
                    cutoff: req.cutoff,
                    resonance: req.resonance
                )
            }
            syncMIDIConnections()
            if req.makeActive || activeSynth == nil {
                activateHostedSynth(existing)
            }
            completion?([
                "ok": true,
                "synth": existing.displayName,
                "component": existing.componentName,
                "width": existing.viewWidth,
                "height": existing.viewHeight,
                "midiEnabled": midiEnabled,
                "poppedOut": existing.isPoppedOut,
                "cached": true
            ])
            return
        }

        if let completion = completion {
            pendingCompletions[key, default: []].append(completion)
        }

        if let existingIdx = loadQueue.firstIndex(where: {
            normalizeSynthKey(!$0.appName.isEmpty ? $0.appName : $0.uiName) == key
        }) {
            let prev = loadQueue.remove(at: existingIdx)
            let merged = SynthLoadRequest(
                uiName: req.uiName.isEmpty ? prev.uiName : req.uiName,
                appName: req.appName.isEmpty ? prev.appName : req.appName,
                deviceName: req.deviceName.isEmpty ? prev.deviceName : req.deviceName,
                bank: req.bank >= 0 ? req.bank : prev.bank,
                program: req.program >= 0 ? req.program : prev.program,
                volume: req.volume >= 0 ? req.volume : prev.volume,
                volumeCc: req.volumeCc,
                cutoff: req.cutoff >= 0 ? req.cutoff : prev.cutoff,
                resonance: req.resonance >= 0 ? req.resonance : prev.resonance,
                makeActive: req.makeActive || prev.makeActive
            )
            if merged.makeActive {
                loadQueue.insert(merged, at: 0)
            } else {
                loadQueue.append(merged)
            }
        } else {
            if req.makeActive {
                loadQueue.insert(req, at: 0)
            } else {
                loadQueue.append(req)
            }
        }

        processNextInLoadQueue()
    }

    private func finishPendingCompletions(for key: String, result: [String: Any]) {
        let callbacks = pendingCompletions.removeValue(forKey: key) ?? []
        for cb in callbacks {
            cb(result)
        }
    }

    private func processNextInLoadQueue() {
        guard !isLoadingSynth, !loadQueue.isEmpty else { return }
        let req = loadQueue.removeFirst()
        let lookupName = !req.appName.isEmpty ? req.appName : req.uiName
        let key = normalizeSynthKey(lookupName)

        if let existing = hostedByKey[key] {
            if req.makeActive || activeSynth == nil {
                activateHostedSynth(existing)
            }
            finishPendingCompletions(for: key, result: [
                "ok": true,
                "synth": existing.displayName,
                "component": existing.componentName,
                "width": existing.viewWidth,
                "height": existing.viewHeight,
                "midiEnabled": midiEnabled,
                "poppedOut": existing.isPoppedOut,
                "cached": true
            ])
            processNextInLoadQueue()
            return
        }

        guard let comp = findComponent(uiName: req.uiName, appName: req.appName) else {
            finishPendingCompletions(for: key, result: [
                "ok": false,
                "error": "No Arturia AudioUnit found matching '\(lookupName)'"
            ])
            processNextInLoadQueue()
            return
        }

        isLoadingSynth = true
        stopStandaloneAppIfRunning(appName: req.appName)

        AVAudioUnit.instantiate(with: comp.audioComponentDescription, options: [.loadInProcess]) { [weak self] avUnit, error in
            runOnMainCommonModes {
                guard let self = self else { return }
                if let error = error {
                    self.isLoadingSynth = false
                    self.finishPendingCompletions(for: key, result: ["ok": false, "error": "Instantiate failed: \(error.localizedDescription)"])
                    self.processNextInLoadQueue()
                    return
                }
                guard let avUnit = avUnit else {
                    self.isLoadingSynth = false
                    self.finishPendingCompletions(for: key, result: ["ok": false, "error": "Instantiate returned nil AVAudioUnit"])
                    self.processNextInLoadQueue()
                    return
                }

                let compName = comp.name
                neutralizeCGWarpInLoadedImages()
                self.engine.attach(avUnit)
                self.engine.connect(avUnit, to: self.engine.mainMixerNode, format: nil)
                self.ensureEngineRunning(appName: req.appName)
                self.syncDeviceState(
                    to: nil,
                    avUnit: avUnit,
                    bank: req.bank,
                    program: req.program,
                    volume: req.volume,
                    volumeCc: req.volumeCc,
                    cutoff: req.cutoff,
                    resonance: req.resonance,
                    includePreset: true
                )

                self.loadViewForAudioUnit(avUnit) { viewController, rootView in
                    runOnMainCommonModes {
                        neutralizeCGWarpInLoadedImages()
                        let finalView: NSView
                        if let rv = rootView {
                            finalView = rv
                        } else {
                            finalView = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 560))
                        }

                        var frame = finalView.frame
                        if frame.width < 100 || frame.height < 100 {
                            let fitting = finalView.fittingSize
                            let w = fitting.width >= 100 ? fitting.width : 1000
                            let h = fitting.height >= 100 ? fitting.height : 640
                            frame = NSRect(x: 0, y: 0, width: w, height: h)
                            finalView.frame = frame
                        }

                        let win = NSWindow(
                            contentRect: NSRect(origin: NSPoint(x: -16000, y: -16000), size: frame.size),
                            styleMask: [.titled],
                            backing: .buffered,
                            defer: false
                        )
                        win.isReleasedWhenClosed = false
                        win.hasShadow = false
                        win.collectionBehavior = [.stationary, .ignoresCycle]
                        let container = NSView(frame: NSRect(origin: .zero, size: frame.size))
                        win.contentView = container
                        container.addSubview(finalView)
                        self.positionWindowHiddenBehind(win)

                        let hosted = HostedSynth(
                            key: key,
                            displayName: req.uiName.isEmpty ? compName : req.uiName,
                            appName: req.appName,
                            componentName: compName,
                            deviceName: req.deviceName,
                            avUnit: avUnit,
                            viewController: viewController,
                            rootView: container,
                            window: win
                        )
                        hosted.lastSyncedBank = req.bank
                        hosted.lastSyncedProgram = req.program
                        hosted.paramToCC = self.loadDefaultMidiMap(appName: req.appName)
                        self.installParameterObserver(for: hosted)
                        self.hostedByKey[key] = hosted
                        self.syncMIDIConnections()
                        if req.makeActive || self.activeSynth == nil {
                            self.activateHostedSynth(hosted)
                        }
                        runOnMainCommonModesAfter(0.35) { [weak self, weak hosted] in
                            guard let self = self, let hosted = hosted else { return }
                            self.syncDeviceState(
                                to: hosted,
                                avUnit: avUnit,
                                bank: req.bank,
                                program: req.program,
                                volume: req.volume,
                                volumeCc: req.volumeCc,
                                cutoff: req.cutoff,
                                resonance: req.resonance,
                                includePreset: true
                            )
                            self.schedulePostPresetControllerSync(
                                hosted: hosted,
                                volume: req.volume,
                                volumeCc: req.volumeCc,
                                cutoff: req.cutoff,
                                resonance: req.resonance
                            )
                        }

                        self.isLoadingSynth = false
                        self.finishPendingCompletions(for: key, result: [
                            "ok": true,
                            "synth": hosted.displayName,
                            "component": hosted.componentName,
                            "width": hosted.viewWidth,
                            "height": hosted.viewHeight,
                            "midiEnabled": self.midiEnabled,
                            "poppedOut": hosted.isPoppedOut,
                            "cached": false
                        ])
                        self.processNextInLoadQueue()
                    }
                }
            }
        }
    }

    private func loadViewForAudioUnit(_ avUnit: AVAudioUnit, completion: @escaping (NSViewController?, NSView?) -> Void) {
        avUnit.auAudioUnit.requestViewController { vc in
            DispatchQueue.main.async {
                if let vc = vc {
                    completion(vc, vc.view)
                    return
                }
                // Fallback to AUv2 CocoaUI
                let au = avUnit.audioUnit
                var dataSize: UInt32 = 0
                var writable: DarwinBoolean = false
                let infoStatus = AudioUnitGetPropertyInfo(au, kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global, 0, &dataSize, &writable)
                guard infoStatus == noErr, dataSize > 0 else {
                    completion(nil, nil)
                    return
                }
                let rawPtr = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<AudioUnitCocoaViewInfo>.alignment)
                defer { rawPtr.deallocate() }
                let getStatus = AudioUnitGetProperty(au, kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global, 0, rawPtr, &dataSize)
                guard getStatus == noErr else {
                    completion(nil, nil)
                    return
                }
                let info = rawPtr.assumingMemoryBound(to: AudioUnitCocoaViewInfo.self).pointee
                let bundleURL = info.mCocoaAUViewBundleLocation.takeRetainedValue() as URL
                let className = info.mCocoaAUViewClass.takeRetainedValue() as String
                guard let bundle = Bundle(url: bundleURL),
                      bundle.load(),
                      let cls = bundle.classNamed(className) as? NSObject.Type else {
                    completion(nil, nil)
                    return
                }
                let factory = cls.init()
                let sel = NSSelectorFromString("uiViewForAudioUnit:withSize:")
                if factory.responds(to: sel) {
                    typealias Fn = @convention(c) (AnyObject, Selector, AudioUnit, NSSize) -> Unmanaged<NSView>?
                    let imp = factory.method(for: sel)
                    let fn = unsafeBitCast(imp, to: Fn.self)
                    let view = fn(factory, sel, au, NSSize(width: 1000, height: 640))?.takeUnretainedValue()
                    completion(nil, view)
                    return
                }
                completion(nil, nil)
            }
        }
    }

    private func positionWindowHiddenBehind(_ win: NSWindow) {
        if activeSynth == nil || activeSynth?.window === win {
            gAllowAppActivation = false
            gActiveHostedWindowNumber = win.windowNumber
            gActiveHitWindowNumber = win.windowNumber
        }
        win.styleMask = [.titled]
        win.collectionBehavior = [.stationary, .ignoresCycle]
        win.setFrameOrigin(NSPoint(x: -16000, y: -16000))
        win.level = .normal
        win.ignoresMouseEvents = true
        win.alphaValue = 0.0
        win.orderBack(nil)
    }

    private func syncHostedWindowAndViewSize(_ hosted: HostedSynth) {
        var targetSize = hosted.rootView.bounds.size
        if let firstChild = hosted.rootView.subviews.first {
            if firstChild.frame.origin != .zero {
                firstChild.setFrameOrigin(.zero)
            }
            if firstChild.frame.width >= 100 && firstChild.frame.height >= 100 {
                targetSize = firstChild.frame.size
            }
        }
        if let glView = findOpenGLView(hosted.rootView) {
            let glSize = glView.bounds.size
            if glSize.width >= 100 && glSize.height >= 100 {
                targetSize = glSize
            }
        }
        let w = Int(targetSize.width.rounded())
        let h = Int(targetSize.height.rounded())
        guard w >= 100, h >= 100 else { return }
        hosted.viewWidth = w
        hosted.viewHeight = h
        let curRootSize = hosted.rootView.frame.size
        if abs(curRootSize.width - targetSize.width) > 0.5 || abs(curRootSize.height - targetSize.height) > 0.5 {
            hosted.rootView.setFrameSize(targetSize)
            hosted.window.setContentSize(targetSize)
            if !hosted.isPoppedOut {
                hosted.window.setFrameOrigin(NSPoint(x: -16000, y: -16000))
            }
        }
    }

    private func positionWindowPoppedOut(_ win: NSWindow, title: String) {
        gAllowAppActivation = true
        gActiveHostedWindowNumber = win.windowNumber
        gActiveHitWindowNumber = win.windowNumber
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.collectionBehavior = [.moveToActiveSpace]
        win.title = "Cadenza AU — \(title)"
        win.level = .floating
        win.ignoresMouseEvents = false
        win.alphaValue = 1.0
        if let screenFrame = NSScreen.main?.visibleFrame {
            let w = win.frame.width
            let h = win.frame.height
            let cx = screenFrame.midX - w / 2.0
            let cy = screenFrame.midY - h / 2.0
            win.setFrameOrigin(NSPoint(x: cx, y: cy))
        }
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func activateHostedSynth(_ hosted: HostedSynth) {
        if let prev = activeSynth, prev !== hosted {
            if !prev.isPoppedOut {
                prev.window.orderOut(nil)
            }
        }
        activeSynth = hosted
        syncHostedWindowAndViewSize(hosted)
        gActiveHostedWindowNumber = hosted.window.windowNumber
        gActiveHitWindowNumber = hosted.window.windowNumber
        gAllowAppActivation = hosted.isPoppedOut
        scWindowCache.removeValue(forKey: hosted.window.windowNumber)
        if hosted.isPoppedOut {
            positionWindowPoppedOut(hosted.window, title: hosted.displayName)
        } else {
            positionWindowHiddenBehind(hosted.window)
        }
        startCaptureLoop()
        refreshFramesAfterInteraction()
    }

    func togglePopout() -> Bool {
        guard let hosted = activeSynth else { return false }
        hosted.isPoppedOut.toggle()
        if hosted.isPoppedOut {
            positionWindowPoppedOut(hosted.window, title: hosted.displayName)
        } else {
            positionWindowHiddenBehind(hosted.window)
        }
        return hosted.isPoppedOut
    }

    private func findOpenGLView(_ root: NSView) -> NSOpenGLView? {
        if let gl = root as? NSOpenGLView {
            return gl
        }
        for sv in root.subviews {
            if let found = findOpenGLView(sv) {
                return found
            }
        }
        return nil
    }

    private func findMouseTargetView(_ root: NSView) -> NSView {
        if let gl = findOpenGLView(root), let parent = gl.superview {
            return parent
        }
        func findJuceView(_ v: NSView) -> NSView? {
            let name = NSStringFromClass(type(of: v))
            if name.hasPrefix("JUCEView") {
                return v
            }
            for sv in v.subviews {
                if let found = findJuceView(sv) {
                    return found
                }
            }
            return nil
        }
        return findJuceView(root) ?? root
    }

    private var hadPopupsOnDown = false

    private func openPopupWindows() -> [NSWindow] {
        return NSApp.windows.filter {
            $0.isVisible
                && NSStringFromClass(type(of: $0)).hasPrefix("JUCEWindow")
                && $0.frame.width > 10
                && $0.frame.height > 10
        }
    }

    func handleMouse(type: String, normX: Double, normY: Double, deltaY: Double) {
        guard let hosted = activeSynth else { return }
        syncHostedWindowAndViewSize(hosted)
        let win = hosted.window
        var targetView = findMouseTargetView(hosted.rootView)
        let refView = findOpenGLView(hosted.rootView) ?? targetView
        let refBounds = refView.bounds
        let clampedX = max(0.0, min(1.0, normX))
        let clampedY = max(0.0, min(1.0, normY))
        let localX = clampedX * refBounds.width
        let localY = refView.isFlipped ? (clampedY * refBounds.height) : ((1.0 - clampedY) * refBounds.height)
        let mainWinPt = refView.convert(NSPoint(x: localX, y: localY), to: nil)
        let screenPt = NSPoint(x: 200.0 + mainWinPt.x, y: 200.0 + mainWinPt.y)

        let popups = openPopupWindows()
        var targetWin = win
        var winPt = mainWinPt
        var hitPopup = false

        for popWin in popups.reversed() {
            if popWin.frame.contains(screenPt), let popContent = popWin.contentView {
                targetWin = popWin
                winPt = NSPoint(x: screenPt.x - popWin.frame.origin.x, y: screenPt.y - popWin.frame.origin.y)
                targetView = findMouseTargetView(popContent)
                hitPopup = true
                break
            }
        }

        if !hosted.isPoppedOut {
            gAllowAppActivation = false
            gActiveHostedWindowNumber = win.windowNumber
            gActiveHitWindowNumber = targetWin.windowNumber
        }

        let ts = ProcessInfo.processInfo.systemUptime
        eventCounter += 1

        switch type {
        case "down":
            hadPopupsOnDown = !popups.isEmpty
            if !hitPopup && !popups.isEmpty {
                dismissOpenPopups()
            }
            lastDownPoint = mainWinPt
            if let moveEv = NSEvent.mouseEvent(
                with: .mouseMoved,
                location: winPt,
                modifierFlags: [],
                timestamp: ts,
                windowNumber: targetWin.windowNumber,
                context: nil,
                eventNumber: eventCounter,
                clickCount: 0,
                pressure: 0.0
            ) {
                targetView.mouseMoved(with: moveEv)
            }
            eventCounter += 1
            targetWin.makeFirstResponder(targetView)
            refreshFramesAfterInteraction()
            if let ev = NSEvent.mouseEvent(
                with: .leftMouseDown,
                location: winPt,
                modifierFlags: [],
                timestamp: ts,
                windowNumber: targetWin.windowNumber,
                context: nil,
                eventNumber: eventCounter,
                clickCount: 1,
                pressure: 1.0
            ) {
                let asyncSel = NSSelectorFromString("asyncMouseDown:")
                if targetView.responds(to: asyncSel) {
                    targetView.perform(asyncSel, with: ev)
                } else {
                    targetView.mouseDown(with: ev)
                }
            }
        case "drag":
            refreshFramesAfterInteraction()
            if let ev = NSEvent.mouseEvent(
                with: .leftMouseDragged,
                location: winPt,
                modifierFlags: [],
                timestamp: ts,
                windowNumber: targetWin.windowNumber,
                context: nil,
                eventNumber: eventCounter,
                clickCount: 1,
                pressure: 1.0
            ) {
                targetView.mouseDragged(with: ev)
            }
        case "up":
            let downPt = lastDownPoint
            lastDownPoint = nil
            refreshFramesAfterInteraction()
            if !hitPopup && !popups.isEmpty && !hadPopupsOnDown, let downPt = downPt {
                let dx = abs(mainWinPt.x - downPt.x)
                let dy = abs(mainWinPt.y - downPt.y)
                if dx < 8.0 && dy < 8.0 {
                    // Release of the click that just opened a popup menu: keep the menu open.
                    return
                }
            }
            if let ev = NSEvent.mouseEvent(
                with: .leftMouseUp,
                location: winPt,
                modifierFlags: [],
                timestamp: ts,
                windowNumber: targetWin.windowNumber,
                context: nil,
                eventNumber: eventCounter,
                clickCount: 1,
                pressure: 0.0
            ) {
                let asyncSel = NSSelectorFromString("asyncMouseUp:")
                if targetView.responds(to: asyncSel) {
                    targetView.perform(asyncSel, with: ev)
                } else {
                    targetView.mouseUp(with: ev)
                }
            }
        case "move":
            if let ev = NSEvent.mouseEvent(
                with: .mouseMoved,
                location: winPt,
                modifierFlags: [],
                timestamp: ts,
                windowNumber: targetWin.windowNumber,
                context: nil,
                eventNumber: eventCounter,
                clickCount: 0,
                pressure: 0.0
            ) {
                targetView.mouseMoved(with: ev)
            }
            if hitPopup {
                refreshFramesAfterInteraction()
            }
        case "wheel":
            if let cg = CGEvent(
                scrollWheelEvent2Source: nil,
                units: .pixel,
                wheelCount: 1,
                wheel1: Int32(-deltaY),
                wheel2: 0,
                wheel3: 0
            ) {
                if let ev = NSEvent(cgEvent: cg) {
                    targetView.scrollWheel(with: ev)
                }
            }
            refreshFramesAfterInteraction()
        default:
            break
        }
    }

    private func refreshFramesAfterInteraction() {
        captureCurrentWindow()
        for delay in [0.04, 0.12, 0.25] {
            runOnMainCommonModesAfter(delay) { [weak self] in
                self?.captureCurrentWindow()
            }
        }
    }

    private func startCaptureLoop() {
        if captureTimer != nil { return }
        let timer = Timer(timeInterval: 1.0 / 12.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self else { return }
                if self.mjpegClients.isEmpty && self.latestJpegData != nil {
                    return
                }
                self.captureCurrentWindow()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        captureTimer = timer
    }

    func captureCurrentWindow() {
        guard let hosted = activeSynth else { return }
        syncHostedWindowAndViewSize(hosted)
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        if let glView = findOpenGLView(hosted.rootView),
           captureWithOpenGL(glView: glView, hosted: hosted) {
            return
        }

        if CGPreflightScreenCaptureAccess() {
            let winNum = hosted.window.windowNumber
            if let scWin = scWindowCache[winNum] {
                isCapturing = true
                captureWithScreenCaptureKit(scWin: scWin, hosted: hosted)
                return
            }
        }

        captureWithAppKitFallback(hosted: hosted)
    }

    private func captureWithOpenGL(glView: NSOpenGLView, hosted: HostedSynth) -> Bool {
        guard let ctx = glView.openGLContext,
              let cgl = ctx.cglContextObj else {
            return false
        }
        CGLLockContext(cgl)
        defer {
            NSOpenGLContext.clearCurrentContext()
            CGLUnlockContext(cgl)
        }

        ctx.makeCurrentContext()
        var vp = [GLint](repeating: 0, count: 4)
        glGetIntegerv(GLenum(GL_VIEWPORT), &vp)
        let backingSize = glView.convertToBacking(glView.bounds).size
        let w = vp[2] > 0 ? Int(vp[2]) : Int(backingSize.width.rounded())
        let h = vp[3] > 0 ? Int(vp[3]) : Int(backingSize.height.rounded())
        guard w > 0, h > 0 else { return false }

        var rawPixels = [UInt8](repeating: 0, count: w * h * 4)
        glPixelStorei(GLenum(GL_PACK_ALIGNMENT), 1)
        glReadBuffer(GLenum(GL_FRONT))
        glReadPixels(0, 0, GLsizei(w), GLsizei(h), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &rawPixels)

        // Check if front buffer is unpopulated; fallback to back buffer if needed
        let sampleStride = max(1, (w * h) / 512)
        var hasContent = false
        var idx = 0
        while idx < rawPixels.count {
            if rawPixels[idx] != 0 || rawPixels[idx + 1] != 0 || rawPixels[idx + 2] != 0 {
                hasContent = true
                break
            }
            idx += sampleStride * 4
        }
        if !hasContent {
            glReadBuffer(GLenum(GL_BACK))
            glReadPixels(0, 0, GLsizei(w), GLsizei(h), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &rawPixels)
            var backIdx = 0
            while backIdx < rawPixels.count {
                if rawPixels[backIdx] != 0 || rawPixels[backIdx + 1] != 0 || rawPixels[backIdx + 2] != 0 {
                    hasContent = true
                    break
                }
                backIdx += sampleStride * 4
            }
        }
        guard hasContent else {
            return false
        }

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: w,
            pixelsHigh: h,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: w * 4,
            bitsPerPixel: 32
        ), let dstBase = rep.bitmapData else {
            return false
        }

        let rowBytes = w * 4
        rawPixels.withUnsafeBytes { srcRaw in
            guard let srcBase = srcRaw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for y in 0..<h {
                let srcRow = srcBase.advanced(by: (h - 1 - y) * rowBytes)
                let dstRow = dstBase.advanced(by: y * rowBytes)
                memcpy(dstRow, srcRow, rowBytes)
                var x = 3
                while x < rowBytes {
                    dstRow[x] = 255
                    x += 4
                }
            }
        }

        let popups = openPopupWindows()
        if !popups.isEmpty, let gfxCtx = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = gfxCtx
            let viewSize = hosted.rootView.bounds.size
            let scaleX = viewSize.width > 0 ? CGFloat(w) / viewSize.width : 1.0
            let scaleY = viewSize.height > 0 ? CGFloat(h) / viewSize.height : 1.0
            for popWin in popups {
                guard let popView = popWin.contentView,
                      let popRep = popView.bitmapImageRepForCachingDisplay(in: popView.bounds) else {
                    continue
                }
                popView.cacheDisplay(in: popView.bounds, to: popRep)
                let relX = (popWin.frame.origin.x - 200.0) * scaleX
                let relY = (popWin.frame.origin.y - 200.0) * scaleY
                let drawRect = NSRect(
                    x: relX,
                    y: relY,
                    width: popWin.frame.width * scaleX,
                    height: popWin.frame.height * scaleY
                )
                popRep.draw(in: drawRect)
                NSColor(white: 1.0, alpha: 0.18).setStroke()
                NSBezierPath(rect: drawRect).stroke()
            }
            NSGraphicsContext.restoreGraphicsState()
        }

        guard let jpg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) else {
            return false
        }
        lastCaptureMode = "OpenGLReadPixels"
        publishFrame(jpg)
        return true
    }

    private func captureWithScreenCaptureKit(scWin: SCWindow, hosted: HostedSynth) {
        let filter = SCContentFilter(desktopIndependentWindow: scWin)
        let config = SCStreamConfiguration()
        config.width = max(200, hosted.viewWidth)
        config.height = max(200, hosted.viewHeight)
        config.showsCursor = false
        config.capturesAudio = false

        SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { [weak self] cgImage, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                defer { self.isCapturing = false }
                if let error = error {
                    fputs("[au-host] SCScreenshotManager error: \(error)\n", stderr)
                }
                if let cgImage = cgImage {
                    let rep = NSBitmapImageRep(cgImage: cgImage)
                    if let jpg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) {
                        self.lastCaptureMode = "ScreenCaptureKit"
                        self.publishFrame(jpg)
                        return
                    }
                }
                self.captureWithAppKitFallback(hosted: hosted)
            }
        }
    }

    private func captureWithAppKitFallback(hosted: HostedSynth) {
        let view = hosted.rootView
        let bounds = view.bounds
        guard bounds.width > 0, bounds.height > 0,
              let rep = view.bitmapImageRepForCachingDisplay(in: bounds) else {
            return
        }
        view.cacheDisplay(in: bounds, to: rep)
        if let jpg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) {
            lastCaptureMode = "AppKitCacheDisplay"
            publishFrame(jpg)
        }
    }

    func currentFrameData() -> Data? {
        return latestJpegData
    }

    func addMJPEGClient(_ conn: NWConnection) {
        mjpegClients.append(conn)
        captureCurrentWindow()
        if let jpg = latestJpegData {
            sendMJPEGFrame(jpg, to: conn)
        }
    }

    func removeMJPEGClient(_ conn: NWConnection) {
        mjpegClients.removeAll { $0 === conn }
    }

    private func publishFrame(_ jpg: Data) {
        latestJpegData = jpg
        guard !mjpegClients.isEmpty else { return }
        for conn in mjpegClients {
            sendMJPEGFrame(jpg, to: conn)
        }
    }

    private func sendMJPEGFrame(_ jpg: Data, to conn: NWConnection) {
        let header = "--frame\r\nContent-Type: image/jpeg\r\nContent-Length: \(jpg.count)\r\n\r\n"
        var payload = Data(header.utf8)
        payload.append(jpg)
        payload.append(Data("\r\n".utf8))
        conn.send(content: payload, completion: .contentProcessed { [weak self] err in
            if err != nil {
                runOnMainCommonModes {
                    self?.removeMJPEGClient(conn)
                }
                conn.cancel()
            }
        })
    }
}

// MARK: - HTTP Server on 127.0.0.1:3099

final class LocalHTTPServer: @unchecked Sendable {
    private let port: UInt16
    private let controller: AUHostController
    private let netQueue = DispatchQueue(label: "cadenza.auhost.http", qos: .userInteractive)
    private var listener: NWListener?

    init(port: UInt16, controller: AUHostController) {
        self.port = port
        self.controller = controller
    }

    func start() throws {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        let nwPort = NWEndpoint.Port(rawValue: port)!
        let listener = try NWListener(using: params, on: nwPort)
        self.listener = listener

        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[au-host] Listening on http://127.0.0.1:\(self.port)")
                fflush(stdout)
            case .failed(let err):
                fputs("[au-host] Listener failed: \(err)\n", stderr)
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] conn in
            self?.handleConnection(conn)
        }
        listener.start(queue: netQueue)
    }

    private func handleConnection(_ conn: NWConnection) {
        conn.start(queue: netQueue)
        readHTTPRequest(conn: conn, buffer: Data())
    }

    private func readHTTPRequest(conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if error != nil {
                conn.cancel()
                return
            }
            var buf = buffer
            if let data = data {
                buf.append(data)
            }
            if let separatorRange = buf.range(of: Data("\r\n\r\n".utf8)) {
                let headerData = buf.subdata(in: 0..<separatorRange.lowerBound)
                let bodyStart = separatorRange.upperBound
                let headerStr = String(data: headerData, encoding: .utf8) ?? ""
                let lines = headerStr.components(separatedBy: "\r\n")
                let requestLine = lines.first ?? ""
                let parts = requestLine.split(separator: " ")
                let method = parts.count > 0 ? String(parts[0]) : "GET"
                let rawPath = parts.count > 1 ? String(parts[1]) : "/"
                let path = rawPath.components(separatedBy: "?").first ?? "/"

                var contentLength = 0
                for line in lines.dropFirst() {
                    let lower = line.lowercased()
                    if lower.hasPrefix("content-length:") {
                        let val = line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)
                        contentLength = Int(val) ?? 0
                    }
                }

                let availableBody = buf.count - bodyStart
                if availableBody >= contentLength {
                    let bodyData = buf.subdata(in: bodyStart..<(bodyStart + contentLength))
                    self.routeRequest(conn: conn, method: method, path: path, body: bodyData)
                    return
                }
            }
            if isComplete {
                conn.cancel()
                return
            }
            self.readHTTPRequest(conn: conn, buffer: buf)
        }
    }

    private func sendJSON(_ conn: NWConnection, status: Int = 200, dict: [String: Any]) {
        let body = Data(jsonString(dict).utf8)
        sendResponse(conn, status: status, contentType: "application/json; charset=utf-8", body: body)
    }

    private func sendResponse(_ conn: NWConnection, status: Int, contentType: String, body: Data, extraHeaders: [String: String] = [:]) {
        let statusText = status == 200 ? "OK" : (status == 204 ? "No Content" : "Error")
        var header = "HTTP/1.1 \(status) \(statusText)\r\n"
        header += "Access-Control-Allow-Origin: *\r\n"
        header += "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
        header += "Access-Control-Allow-Headers: Content-Type\r\n"
        header += "Content-Type: \(contentType)\r\n"
        header += "Content-Length: \(body.count)\r\n"
        header += "Cache-Control: no-store\r\n"
        for (k, v) in extraHeaders {
            header += "\(k): \(v)\r\n"
        }
        header += "Connection: close\r\n\r\n"

        var payload = Data(header.utf8)
        payload.append(body)
        conn.send(content: payload, completion: .contentProcessed { _ in
            conn.cancel()
        })
    }

    private func parseJSONBody(_ body: Data) -> [String: Any] {
        guard !body.isEmpty,
              let obj = try? JSONSerialization.jsonObject(with: body, options: []) as? [String: Any] else {
            return [:]
        }
        return obj
    }

    private func routeRequest(conn: NWConnection, method: String, path: String, body: Data) {
        if method == "OPTIONS" {
            sendResponse(conn, status: 204, contentType: "text/plain", body: Data())
            return
        }

        runOnMainCommonModes { [self] in
            switch (method, path) {
            case ("GET", "/status"):
                sendJSON(conn, dict: controller.statusDict())

            case ("GET", "/list"):
                let names = controller.listArturiaComponents().map { $0.name }.sorted()
                sendJSON(conn, dict: ["ok": true, "components": names])

            case ("POST", "/select"):
                let json = parseJSONBody(body)
                let uiName = (json["uiName"] as? String) ?? ""
                let appName = (json["appName"] as? String) ?? ""
                let deviceName = (json["deviceName"] as? String) ?? ""
                let bank = (json["bank"] as? Int) ?? -1
                let program = (json["program"] as? Int) ?? -1
                let volume = (json["volume"] as? Int) ?? -1
                let volumeCc = (json["volumeCc"] as? Int) ?? 7
                let cutoff = (json["cutoff"] as? Int) ?? -1
                let resonance = (json["resonance"] as? Int) ?? -1
                controller.selectSynth(
                    uiName: uiName,
                    appName: appName,
                    deviceName: deviceName,
                    bank: bank,
                    program: program,
                    volume: volume,
                    volumeCc: volumeCc,
                    cutoff: cutoff,
                    resonance: resonance
                ) { res in
                    self.sendJSON(conn, status: (res["ok"] as? Bool) == true ? 200 : 404, dict: res)
                }

            case ("POST", "/sync"):
                let json = parseJSONBody(body)
                let devices = (json["devices"] as? [[String: Any]]) ?? []
                controller.syncActiveSynths(devices: devices)
                sendJSON(conn, dict: ["ok": true, "queued": devices.count])

            case ("GET", "/frame.jpg"):
                controller.captureCurrentWindow()
                if let jpg = controller.currentFrameData() {
                    let extra = [
                        "X-View-Width": "\(controller.activeSynth?.viewWidth ?? 0)",
                        "X-View-Height": "\(controller.activeSynth?.viewHeight ?? 0)",
                    ]
                    sendResponse(conn, status: 200, contentType: "image/jpeg", body: jpg, extraHeaders: extra)
                } else {
                    sendJSON(conn, status: 404, dict: ["ok": false, "error": "No frame captured yet"])
                }

            case ("GET", "/stream.mjpeg"):
                let header = "HTTP/1.1 200 OK\r\n"
                    + "Access-Control-Allow-Origin: *\r\n"
                    + "Cache-Control: no-store, no-cache, must-revalidate\r\n"
                    + "Pragma: no-cache\r\n"
                    + "Connection: close\r\n"
                    + "Content-Type: multipart/x-mixed-replace; boundary=frame\r\n\r\n"
                conn.send(content: Data(header.utf8), completion: .contentProcessed { [weak self] err in
                    if err != nil {
                        conn.cancel()
                        return
                    }
                    runOnMainCommonModes {
                        self?.controller.addMJPEGClient(conn)
                    }
                })

            case ("POST", "/mouse"):
                let json = parseJSONBody(body)
                let type = (json["type"] as? String) ?? "move"
                let x = (json["x"] as? Double) ?? 0.5
                let y = (json["y"] as? Double) ?? 0.5
                let deltaY = (json["deltaY"] as? Double) ?? 0.0
                sendJSON(conn, dict: ["ok": true])
                controller.handleMouse(type: type, normX: x, normY: y, deltaY: deltaY)

            case ("POST", "/midi"):
                let json = parseJSONBody(body)
                let enabled = (json["enabled"] as? Bool) ?? false
                controller.setMIDIEnabled(enabled)
                sendJSON(conn, dict: ["ok": true, "midiEnabled": enabled])

            case ("POST", "/popout"):
                let popped = controller.togglePopout()
                sendJSON(conn, dict: ["ok": true, "poppedOut": popped])

            default:
                sendJSON(conn, status: 404, dict: ["ok": false, "error": "Not found"])
            }
        }
    }
}

// MARK: - App Entry

installOffscreenSwizzles()
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

signal(SIGTERM, SIG_IGN)
signal(SIGINT, SIG_IGN)
let termSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
termSource.setEventHandler { _exit(0) }
termSource.resume()
let intSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
intSource.setEventHandler { _exit(0) }
intSource.resume()

let controller = MainActor.assumeIsolated { AUHostController() }
let httpPort: UInt16 = UInt16(ProcessInfo.processInfo.environment["CADENZA_AU_HOST_PORT"] ?? "3099") ?? 3099
let server = LocalHTTPServer(port: httpPort, controller: controller)
try server.start()

app.run()
