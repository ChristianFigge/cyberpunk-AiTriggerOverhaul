module AiTriggerOverhaul

public class Settings {

    public static func ModIsEnabled() -> Bool { return true; }
    
    public static func GetLoudNoiseStimRange() -> Float { return 12.0; }

    public static func GetCommonSoundStimRange() -> Float { return 7.0; }

    public static func GetDoorOpeningStimRange() -> Float { return 3.0; }

    public static func GetInvestigateCommonSoundChance() -> Float { return 0.25; }

    public static func GetCommonAttentionLifetime() -> Float { return 2.0; }

    public static func GetUseZoneSpecificChanges() -> Bool { return true; }

    public static func RadiosAreLoud() -> Bool { return true; }

    public static func BodyDisposalIsLoud() -> Bool { return true; }
}