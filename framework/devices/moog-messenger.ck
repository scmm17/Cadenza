// MoogMessenger
// Purpose: Moog Messenger MIDI patch implementation and bank/program preset stepping.
// Imports: framework/devices/patch.ck, framework/devices/presets/generated/moog-banks.ck
// Imported by: framework/devices/synth-registry.ck, framework/cadenza.ck

@import "patch.ck"
@import "presets/generated/moog-banks.ck"

public class MoogMessenger extends Patch
{
    fun MoogMessenger()
    {
        "Moog Messenger" => deviceName;
        "Moog" => uiName;
        0 => midiChannel;
        0 => bank;
        0 => program;
        formatPatchName(0, 0) => patchName;
    }

    fun MoogMessenger(int channel, int bank, int program, int v)
    {
        "Moog Messenger" => deviceName;
        "Moog" => uiName;
        channel - 1 => midiChannel;
        clampSlot(bank - 1) => this.bank;
        clampSlot(program - 1) => this.program;
        formatPatchName(this.bank, this.program) => patchName;
        Patch(v);
    }

    fun static int clampSlot(int val)
    {
        if (val < 0) return 0;
        if (val > 15) return 15;
        return val;
    }

    fun static string bankName(int b)
    {
        return MoogBanksData.BANK_NAMES[clampSlot(b)];
    }

    fun static string formatPatchName(int b, int p)
    {
        return bankName(b) + ": " + Std.itoa(clampSlot(p) + 1);
    }

    fun static int findBankByName(string name)
    {
        for (0 => int i; i < MoogBanksData.BANK_NAMES.cap(); i++) {
            if (MoogBanksData.BANK_NAMES[i] == name) return i;
        }
        return -1;
    }

    fun void programChangeMoogMessenger(int program, int bank)
    {
        clampSlot(bank) => int b;
        clampSlot(program) => int p;

        (b / 8) & 0x01 => int bankGroup;
        ((b % 8) * 16) + p => int pcNumber;

        // Bank Select MSB (CC 0 = 0) and LSB (CC 32: 0 = Banks 1-8, 1 = Banks 9-16)
        sendControllerChange(CadenzaConstants.CC_BANK_MSB(), 0);
        sendControllerChange(CadenzaConstants.CC_BANK_LSB(), bankGroup);

        // 2-byte MIDI Program Change (0-127 within the active 8-bank group)
        gma.programChange(midiChannel, pcNumber);
    }

    fun void setPreset()
    {
        programChangeMoogMessenger(program, bank);
    }

    fun void applyBankProgram(int b, int p, int vol)
    {
        clampSlot(b) => bank;
        clampSlot(p) => program;
        formatPatchName(bank, program) => patchName;
        setPreset();
        if (vol != -1) {
            sendControllerChange(CadenzaConstants.CC_VOLUME(), vol);
        }
        <<< "MoogMessenger(" + Std.itoa(midiChannel + 1) + ", " + Std.itoa(bank + 1) + ", " + Std.itoa(program + 1) + ", " + Std.itoa(vol) + ");", "" >>>;
    }

    fun void stepPreset(int delta, int vol)
    {
        bank => int curBank;
        program => int curProg;
        if (curBank < 0 || curBank > 15) { 0 => curBank; }
        if (curProg < 0 || curProg > 15) { 0 => curProg; }
        (curBank * 16 + curProg + delta + 256) % 256 => int idx;
        applyBankProgram(idx / 16, idx % 16, vol);
    }

    fun void stepPresetCategory(int delta, int vol)
    {
        bank => int curBank;
        if (curBank < 0 || curBank > 15) { 0 => curBank; }
        (curBank + delta + 16) % 16 => int nextBank;
        applyBankProgram(nextBank, program, vol);
    }

    fun int selectPresetByName(string presetName, int vol)
    {
        "" => string bankPart;
        -1 => int p;
        presetName.find("Program:") => int pPos;
        if (pPos > 0) {
            YamlNode.trimLeft(YamlNode.trimRight(presetName.substring(0, pPos))) => bankPart;
            Std.atoi(YamlNode.trimLeft(YamlNode.trimRight(presetName.substring(pPos + 8)))) - 1 => p;
        } else {
            presetName.find(":") => int cPos;
            if (cPos > 0) {
                YamlNode.trimLeft(YamlNode.trimRight(presetName.substring(0, cPos))) => bankPart;
                Std.atoi(YamlNode.trimLeft(YamlNode.trimRight(presetName.substring(cPos + 1)))) - 1 => p;
            }
        }
        if (bankPart != "" && p >= 0) {
            findBankByName(bankPart) => int b;
            if (b < 0 && bankPart.find("Bank:") == 0) {
                Std.atoi(YamlNode.trimLeft(YamlNode.trimRight(bankPart.substring(5)))) - 1 => b;
            }
            if (b >= 0) {
                applyBankProgram(b, p, vol);
                return 1;
            }
        }
        return 0;
    }

    fun void setCutoff(int val)
    {
        val => filterCutoff;
        if (filterCutoff != -1) {
            sendControllerChange(CadenzaConstants.CC_MOOG_CUTOFF(), filterCutoff);
        }
    }

    fun void setResonance(int val)
    {
        val => filterResonance;
        if (filterResonance != -1) {
            sendControllerChange(CadenzaConstants.CC_MOOG_RESONANCE(), filterResonance);
        }
    }

    fun void setPan(int val)
    {
        // CC 10 maps to OSC Tune on Moog Messenger; keep pan in state without sending CC 10.
        val => pan;
    }

    fun void updateControllers()
    {
        setPreset();

        if (filterCutoff != -1) {
            setCutoff(filterCutoff);
        }
        if (filterResonance != -1) {
            setResonance(filterResonance);
        }
        if (volume != -1) {
            sendControllerChange(CadenzaConstants.CC_VOLUME(), volume);
        }
    }

    fun void saveConfig(YamlNode @config)
    {
        saveCommonConfig(config);
        config.SetInt("program", program);
        config.SetInt("bank", bank);
    }

    fun void loadConfig(YamlNode @config)
    {
        loadCommonConfig(config);
        "Moog Messenger" => deviceName;
        "Moog" => uiName;
        openDevice();
        if (config.findChild("program") >= 0) {
            clampSlot(config.GetInt("program")) => program;
        } else {
            0 => program;
        }
        if (config.findChild("bank") >= 0) {
            clampSlot(config.GetInt("bank")) => bank;
        } else {
            0 => bank;
        }
        formatPatchName(bank, program) => patchName;
        updateControllers();
    }
}
