module AiTriggerOverhaul

/*
 * Redscript Helper class for Mod Setting values.
 * The functions here are overwritten by Lua code if Native Settings UI is used (see init.lua).
 */
public class Settings {

    public static func ModIsEnabled() -> Bool { return true; }
    
    public static func GetLoudNoiseStimRange() -> Float { return 16.0; }

    public static func GetCommonSoundStimRange() -> Float { return 8.0; }

    public static func GetDoorOpeningStimRange() -> Float { return 3.0; }

    public static func GetInvestigateCommonSoundChance() -> Float { return 0.25; }

    public static func GetCommonAttentionLifetime() -> Float { return 2.0; }

    public static func GetUseZoneSpecificChanges() -> Bool { return true; }

    public static func RadiosAreLoud() -> Bool { return true; }

    public static func BodyDisposalIsLoud() -> Bool { return true; }

    // Movement noises
    public static func GetWalkStimRange() -> Float { return 12.0; }

    public static func GetSprintStimRange() -> Float { return 16.0; }

    public static func GetJumpStimRange() -> Float { return 14.0; }

    public static func GetDoubleJumpStimRange() -> Float { return 16.0; }

    public static func GetChargedJumpStimRange() -> Float { return 16.0; }

    public static func GetHoverJumpStimRange() -> Float { return 0.0; } // Unused

    public static func GetRegularLandingStimRange() -> Float { return 16.0; }

    public static func GetHardLandingStimRange() -> Float { return 20.0; }

    public static func GetVeryHardLandingStimRange() -> Float { return 24.0; }

    public static func GetCrouchedJumpsAreSilent() -> Bool { return true; }

    public static func GetDodgeIsSprint() -> Bool { return false; }


    public static func GetStealthPerkNoiseReductionFactor() -> Float { return 0.15; }

    public static func GetApplyStealthPerksToLandings() -> Bool { return true; }
}