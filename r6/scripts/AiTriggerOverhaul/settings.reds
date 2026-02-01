module AiTriggerOverhaul

/*
 * Redscript Helper class for Mod Setting values.
 * The functions here are overwritten by Lua code if Native Settings UI is used (see init.lua).
 */
public class Settings {

    public static func ModIsEnabled() -> Bool { return true; }
    
    public static func GetLoudNoiseStimRange() -> Float { return 14.0; }

    public static func GetCommonSoundStimRange() -> Float { return 7.0; }

    public static func GetDoorOpeningStimRange() -> Float { return 3.0; }

    public static func GetInvestigateCommonSoundChance() -> Float { return 0.25; }

    public static func GetCommonAttentionLifetime() -> Float { return 2.0; }

    public static func GetUseZoneSpecificChanges() -> Bool { return true; }

    public static func RadiosAreLoud() -> Bool { return true; }

    public static func BodyDisposalIsLoud() -> Bool { return true; }

    public static func GetSprintNoiseStimRange() -> Float { return 12.0; }

    public static func GetSprintNoisePerkReductionFactor() -> Float { return 0.15; }
}