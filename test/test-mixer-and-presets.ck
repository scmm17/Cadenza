@import "test-helpers.ck"
@import "mock-patch.ck"
@import "../framework/cadenza.ck"

public class MixerAndPresetsTests {
    fun static void run() {
        <<< "--- Mixer & Presets Tests ---" >>>;
        testMuteAndSolo();
        testHydraPresetCollection();
        testSH4dPresetCollection();
        testV3PresetCollection();
        testMoogPresetParsingAndStepping();
        testStateBroadcasterJson();
        testArturiaSynths();
    }

    fun static void testMuteAndSolo() {
        MockSong song;
        MockPatch p1; "P1" => p1.deviceName;
        MockPatch p2; "P2" => p2.deviceName;
        MockPatch p3; "P3" => p3.deviceName;
        p1 @=> song.devices[0];
        p2 @=> song.devices[1];
        p3 @=> song.devices[2];

        // Initially unmuted
        Assert.isFalse("mute_init_p1", p1.muted);
        Assert.isFalse("mute_init_p2", p2.muted);

        // mutePatch / unMutePatch / toggleMute
        song.mutePatch(p1);
        Assert.isTrue("mutePatch_userMuted", p1.userMuted);
        Assert.isTrue("mutePatch_effectiveMuted", p1.muted);
        Assert.isFalse("mutePatch_p2_unaffected", p2.muted);
        Assert.equalInt("mutePatch_listSize", song.mutedPatchCount(), 1);

        song.toggleMute(p1);
        Assert.isFalse("toggleMute_off_userMuted", p1.userMuted);
        Assert.isFalse("toggleMute_off_effective", p1.muted);
        Assert.equalInt("toggleMute_off_listSize", song.mutedPatchCount(), 0);

        song.toggleMute(p2);
        Assert.isTrue("toggleMute_on_p2", p2.userMuted);
        song.unMutePatch(p2);
        Assert.isFalse("unMutePatch_p2", p2.muted);

        // Solo interacts with userMuted and clears cleanly
        song.mutePatch(p1);
        song.setSoloPatch(p2);
        Assert.isTrue("solo_p1_muted", p1.muted);
        Assert.isFalse("solo_p2_unmuted", p2.muted);
        Assert.isTrue("solo_p3_muted", p3.muted);

        // Soloing the already-muted p1 unmutes p1 while soloed
        song.setSoloPatch(p1);
        Assert.isFalse("solo_overrides_userMute", p1.muted);
        Assert.isTrue("solo_p1_mutes_p2", p2.muted);

        // Clearing solo restores p1's userMuted state
        song.unsetSoloPatch();
        Assert.isTrue("unsetSolo_restores_userMuted_p1", p1.muted);
        Assert.isFalse("unsetSolo_unmutes_p2", p2.muted);
        Assert.isFalse("unsetSolo_unmutes_p3", p3.muted);

        // toggleSoloPatch toggles on, switches target, toggles off
        song.toggleSoloPatch(p3);
        Assert.isTrue("toggleSolo_p3_active", song.isPatchSoloed(p3));
        Assert.isTrue("toggleSolo_p3_mutes_p2", p2.muted);
        song.toggleSoloPatch(p2);
        Assert.isTrue("toggleSolo_switches_to_p2", song.isPatchSoloed(p2));
        Assert.isTrue("toggleSolo_p2_mutes_p3", p3.muted);
        song.toggleSoloPatch(p2);
        Assert.isTrue("toggleSolo_clears", song.mixer.soloPatch == null);
        Assert.isFalse("toggleSolo_clears_unmutes_p3", p3.muted);

        // startMuteMode / endMuteMode clears all mutes
        song.startMuteMode();
        Assert.isTrue("startMuteMode", song.muteMode);
        song.endMuteMode();
        Assert.isFalse("endMuteMode_mode", song.muteMode);
        Assert.isFalse("endMuteMode_clears_userMuted", p1.userMuted);
        Assert.isFalse("endMuteMode_clears_effective", p1.muted);
        Assert.equalInt("endMuteMode_clears_list", song.mutedPatchCount(), 0);

        // startSoloMode / endSoloMode clears soloPatch
        song.startSoloMode();
        Assert.isTrue("startSoloMode", song.soloMode);
        song.setSoloPatch(p1);
        song.endSoloMode();
        Assert.isFalse("endSoloMode_mode", song.soloMode);
        Assert.isTrue("endSoloMode_clears_patch", song.mixer.soloPatch == null);
        Assert.isFalse("endSoloMode_unmutes_p2", p2.muted);
    }

    fun static void testHydraPresetCollection() {
        HydraPresetCollection h;
        Assert.isTrue("hydra_hasPreset_code", h.hasPreset("A001"));
        Assert.isTrue("hydra_hasPreset_name", h.hasPreset("Sawpressive GD"));
        Assert.isFalse("hydra_hasPreset_missing", h.hasPreset("NoSuchPreset"));
        Assert.equalString("hydra_normalizeQuotes", h.normalizePresetName("Foo \"Bar\""), "Foo 'Bar'");

        h.getPreset("A001") @=> Preset p0;
        Assert.equalString("hydra_getPreset_code", p0.name, "Sawpressive GD");

        h.setPresetState("A002");
        Assert.equalInt("hydra_setPresetState_idx", h.curPresetIndex, 1);
        Assert.equalString("hydra_setPresetState_cat", h.curPresetCategory, "A");

        h.getNextPreset() @=> Preset pNext;
        Assert.equalString("hydra_getNextPreset", pNext.code, "A003");
        h.getPreviousPreset() @=> Preset pPrev;
        Assert.equalString("hydra_getPreviousPreset", pPrev.code, "A002");

        // Wraparound backwards from index 0 and forwards from last
        h.setPresetState("A001");
        Assert.equalInt("hydra_setPresetState_first", h.curPresetIndex, 0);
        h.getPreviousPreset() @=> Preset pLast;
        Assert.equalString("hydra_wrap_prev_to_last", pLast.code, "E128");
        h.getNextPreset() @=> Preset pFirst;
        Assert.equalString("hydra_wrap_next_to_first", pFirst.code, "A001");

        // Category stepping
        h.getNextCategory() @=> Preset pCatB;
        Assert.equalString("hydra_nextCategory_B", pCatB.category, "B");
        h.getPreviousCategory() @=> Preset pCatA;
        Assert.equalString("hydra_prevCategory_A", pCatA.category, "A");
    }

    fun static void testSH4dPresetCollection() {
        SH4dPresetCollection s;
        Assert.isTrue("sh4d_hasPreset", s.hasPreset("Brilliant"));
        Assert.isTrue("sh4d_matchesPreset_true", s.matchesPreset("Brilliant", 64, 0));
        Assert.isFalse("sh4d_matchesPreset_wrongBank", s.matchesPreset("Brilliant", 99, 0));

        s.getPreset(64, 0) @=> Preset byBP;
        Assert.isTrue("sh4d_getByBP_nonNull", byBP != null);
        Assert.equalString("sh4d_getByBP_name", byBP.name, "Brilliant");

        s.setPresetState("Brilliant", 64, 0);
        Assert.equalInt("sh4d_setPresetState_bp_idx", s.curPresetIndex, 0);
        Assert.equalString("sh4d_setPresetState_bp_cat", s.curPresetCategory, "SH-4d OSC model");

        s.getNextPreset() @=> Preset nextS;
        Assert.equalInt("sh4d_nextPreset_idx", s.curPresetIndex, 1);
        s.getPreviousPreset() @=> Preset prevS;
        Assert.equalInt("sh4d_prevPreset_idx", s.curPresetIndex, 0);
        Assert.equalString("sh4d_prevPreset_name", prevS.name, "Brilliant");

        s.getNextCategory() @=> Preset nextCat;
        Assert.isTrue("sh4d_nextCat_changed", nextCat.category != "SH-4d OSC model");
        s.getPreviousCategory() @=> Preset prevCat;
        Assert.equalString("sh4d_prevCat_back", prevCat.category, "SH-4d OSC model");
    }

    fun static void testV3PresetCollection() {
        V3PresetCollection v;
        v.getPreset("Grand Piano Vienna") @=> Preset p0;
        Assert.equalString("v3_getPreset_name", p0.name, "Grand Piano Vienna");
        v.setPresetState("Grand Piano Vienna");
        Assert.equalInt("v3_setPresetState_idx", v.curPresetIndex, 0);
        Assert.equalString("v3_setPresetState_cat", v.curPresetCategory, "Grand Piano");

        v.getNextPreset() @=> Preset p1;
        Assert.equalInt("v3_nextPreset_idx", v.curPresetIndex, 1);
        v.getPreviousPreset() @=> Preset p0Again;
        Assert.equalInt("v3_prevPreset_idx", v.curPresetIndex, 0);
        Assert.equalString("v3_prevPreset_name", p0Again.name, "Grand Piano Vienna");

        v.getNextCategory() @=> Preset nextCat;
        Assert.isTrue("v3_nextCat_changed", nextCat.category != "Grand Piano");
        v.getPreviousCategory() @=> Preset prevCat;
        Assert.equalString("v3_prevCat_back", prevCat.category, "Grand Piano");
    }

    fun static void testMoogPresetParsingAndStepping() {
        MockSong song;
        MoogMessenger moog;
        moog @=> song.devices[0];
        moog @=> song.currentDevice;

        song.setPresetByName("Hard Lead: 12", -1);
        Assert.equalInt("moog_parse_bank", moog.bank, 4);
        Assert.equalInt("moog_parse_prog", moog.program, 11);
        Assert.equalString("moog_parse_name", moog.patchName, "Hard Lead: 12");

        song.setPresetByName("Soft Lead Program: 3", -1);
        Assert.equalInt("moog_legacyProgram_bank", moog.bank, 5);
        Assert.equalInt("moog_legacyProgram_prog", moog.program, 2);
        Assert.equalString("moog_legacyProgram_name", moog.patchName, "Soft Lead: 3");

        song.setPresetByName("Bank: 5 Program: 12", -1);
        Assert.equalInt("moog_legacyBankProgram_bank", moog.bank, 4);
        Assert.equalInt("moog_legacyBankProgram_prog", moog.program, 11);

        // Stepping across program and bank boundaries
        song.applyMoogPreset(0, 0, -1);
        song.setPreviousPreset(-1);
        Assert.equalInt("moog_wrap_prev_bank", moog.bank, 15);
        Assert.equalInt("moog_wrap_prev_prog", moog.program, 15);
        song.setNextPreset(-1);
        Assert.equalInt("moog_wrap_next_bank", moog.bank, 0);
        Assert.equalInt("moog_wrap_next_prog", moog.program, 0);

        song.setPreviousPresetCategory(-1);
        Assert.equalInt("moog_wrap_prevCat_bank", moog.bank, 15);
        song.setNextPresetCategory(-1);
        Assert.equalInt("moog_wrap_nextCat_bank", moog.bank, 0);

        // Polymorphic Patch preset stepping & stateBank/stateProgram
        Hydrasynth h;
        h @=> song.devices[1];
        song.selectDevice(1);
        song.setNextPreset(-1);
        Assert.equalString("hydra_poly_stepNext", h.presetName, "A002");
        song.setNextPresetCategory(-1);
        Assert.equalString("hydra_poly_nextCat", h.presetName.substring(0, 1), "B");
        song.setPresetByName("A001", -1);
        Assert.equalString("hydra_poly_selectByName", h.patchName, "Sawpressive GD");

        RolandSH4d sh;
        sh @=> song.devices[2];
        Assert.equalInt("sh4d_stateBank_channelMode", sh.stateBank(), -1);
        song.selectDevice(2);
        song.setPresetByName("Brilliant", -1);
        Assert.equalInt("sh4d_stateBank_toneMode", sh.stateBank(), 64);
        Assert.equalInt("sh4d_stateProgram_toneMode", sh.stateProgram(), 0);
    }

    fun static void testStateBroadcasterJson() {
        MockSong song;
        "test-song" => song.name;
        "Default" => song.currentPatchSet;
        "Default" => song.defaultPatchSet;
        125.0 => song.BPM;

        MockPatch p0;
        "Hydrasynth" => p0.uiName;
        "Sawpressive GD" => p0.patchName;
        0 => p0.midiChannel;
        100 => p0.volume;
        p0 @=> song.devices[0];
        p0 @=> song.currentDevice;

        Part emptyParts[0];
        Fragment frag("Verse 1", 2, emptyParts);
        1 => frag.currentRepeat;
        frag @=> song.startFragment;
        frag @=> song.currentFragment;

        StateBroadcaster sb;
        sb.buildStateJson(song) => string json;
        Assert.isTrue("stateJson_songName", json.find("\"songName\":\"test-song\"") >= 0);
        Assert.isTrue("stateJson_fragmentName", json.find("\"fragmentName\":\"Verse 1\"") >= 0);
        Assert.isTrue("stateJson_patchName", json.find("\"patchName\":\"Sawpressive GD\"") >= 0);
        Assert.isTrue("stateJson_repeatIndex", json.find("\"repeatIndex\":1") >= 0);
        Assert.isTrue("stateJson_repeatCount", json.find("\"repeatCount\":2") >= 0);
        Assert.isTrue("stateJson_escapeQuotes", sb.escJson("A\"B\\C") == "A\\\"B\\\\C");
    }

    fun static void testArturiaSynths() {
        // AcidVPresetCollection
        AcidVPresetCollection avCol;
        Assert.isTrue("acidv_hasPreset_fastTravel", avCol.hasPreset("Fast Travel"));
        Assert.isTrue("acidv_hasPreset_acidMouth", avCol.hasPreset("Acid Mouth"));
        Assert.isFalse("acidv_hasPreset_missing", avCol.hasPreset("NoSuchAcidPreset"));

        avCol.setPresetState("Fast Travel");
        Assert.equalString("acidv_init_cat", avCol.curPresetCategory, "Bass Line");
        avCol.getNextCategory() @=> Preset avNextCat;
        Assert.equalString("acidv_nextCat_pad", avNextCat.category, "Classic Synth Pad");
        avCol.setPresetState("Acid Mouth");
        Assert.equalString("acidv_acidMouth_cat", avCol.curPresetCategory, "Arpeggio");

        // AugmentedMalletsPresetCollection
        AugmentedMalletsPresetCollection amCol;
        Assert.isTrue("augmallets_hasPreset_royal", amCol.hasPreset("A Royal Mallet"));
        Assert.isTrue("augmallets_hasPreset_deep", amCol.hasPreset("Deep Hybridation"));

        amCol.setPresetState("Deep Hybridation");
        Assert.equalString("augmallets_init_cat", amCol.curPresetCategory, "Bass");
        amCol.getNextCategory() @=> Preset amBellsCat;
        Assert.equalString("augmallets_nextCat_bells", amBellsCat.category, "Bells");
        amCol.getNextCategory() @=> Preset amClassicCat;
        Assert.equalString("augmallets_nextCat_classic", amClassicCat.category, "Classic Synth Keys");

        // SynthRegistry channel resolution & empty factory
        MockSong song;
        Assert.equalInt("registry_acidv_ch", SynthRegistry.resolveMidiChannel(song.devices, 0, "Acid V"), 0);
        Assert.equalInt("registry_augmallets_ch", SynthRegistry.resolveMidiChannel(song.devices, 1, "Augmented Mallets"), 1);

        SynthRegistry.createEmpty("Acid V") @=> Patch @ emptyAv;
        Assert.isTrue("registry_createEmpty_acidv", emptyAv != null);
        Assert.equalString("registry_empty_acidv_ui", emptyAv.uiName, "Acid V");
        Assert.equalString("registry_empty_acidv_dev", emptyAv.deviceName, "IAC Driver Acid V");

        SynthRegistry.createEmpty("Augmented Mallets") @=> Patch @ emptyAm;
        Assert.isTrue("registry_createEmpty_augmallets", emptyAm != null);
        Assert.equalString("registry_empty_augmallets_ui", emptyAm.uiName, "Augmented Mallets");
        Assert.equalString("registry_empty_augmallets_dev", emptyAm.deviceName, "IAC Driver Augmented Mallets");
        Assert.equalInt("constants_cc_all_sound_off", CadenzaConstants.CC_ALL_SOUND_OFF(), 120);

        // Polymorphic Patch preset selection and stepping via MockSong
        AcidV acid;
        AugmentedMallets mallets;
        acid @=> song.devices[0];
        mallets @=> song.devices[1];

        song.selectDevice(0);
        song.setPresetByName("Acid Mouth", -1);
        Assert.equalString("acidv_poly_select_name", acid.patchName, "Acid Mouth");
        Assert.equalInt("acidv_poly_select_bank", acid.bank, 0);
        Assert.equalInt("acidv_poly_select_prog", acid.program, 1);

        song.setPresetByName("Fast Travel", -1);
        song.setNextPreset(-1);
        Assert.equalString("acidv_poly_stepNext", acid.patchName, "Formic Tail");
        song.setNextPresetCategory(-1);
        Assert.equalString("acidv_poly_stepNextCat", acid.patchName, "Thoughtful Day");

        song.selectDevice(1);
        song.setPresetByName("Deep Hybridation", -1);
        Assert.equalString("augmallets_poly_select_name", mallets.patchName, "Deep Hybridation");
        Assert.equalInt("augmallets_poly_select_bank", mallets.bank, 0);
        Assert.equalInt("augmallets_poly_select_prog", mallets.program, 0);
        song.setNextPresetCategory(-1);
        Assert.equalString("augmallets_poly_stepNextCat", mallets.patchName, "Celestial Bells");
        Assert.equalInt("augmallets_poly_bells_bank", mallets.bank, 1);
        Assert.equalInt("augmallets_poly_bells_prog", mallets.program, 0);
    }
}
