// Preset & Synth-Specific Preset Subclasses
// Purpose: Common data model for synth presets and thin per-synth subclasses.
// Imports: none
// Imported by: framework/devices/presets/preset-collection.ck, generated/*.ck

public class Preset
{
    int program;
    int bank;
    string code;
    string name;
    string category;

    fun Preset(int p, int b, string c, string n, string cat)
    {
        p => program;
        b => bank;
        c => code;
        n => name;
        cat => category;
    }
}

public class HydraPreset extends Preset
{
    fun HydraPreset(int p, int b, string c, string n, string cat)
    {
        Preset(p, b, c, n, cat);
    }
}

public class SH4dPreset extends Preset
{
    fun SH4dPreset(int p, int b, string n, string cat)
    {
        Preset(p, b, "", n, cat);
    }
}

public class V3Preset extends Preset
{
    fun V3Preset(int p, int b, string n, string cat)
    {
        Preset(p, b, "", n, cat);
    }
}

public class AcidVPreset extends Preset
{
    fun AcidVPreset(int p, int b, string n, string cat)
    {
        Preset(p, b, "", n, cat);
    }
}

public class AugmentedMalletsPreset extends Preset
{
    fun AugmentedMalletsPreset(int p, int b, string n, string cat)
    {
        Preset(p, b, "", n, cat);
    }
}
