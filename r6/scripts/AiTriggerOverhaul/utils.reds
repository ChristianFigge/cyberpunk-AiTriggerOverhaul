module AiTriggerOverhaul

public final class Utils {

    public final static func CoinFlip(true_probability: Float) -> Bool {
        if true_probability >= 1.0 { return true; };
        if true_probability > 0.0 { return RandF() < true_probability; };
        return false;
    }

    public final static func PlayerIsInRestrictedOrDangerousZone(playerPuppet: wref<GameObject>) -> Bool {
        if IsDefined(playerPuppet as PlayerPuppet) {
            let zoneType: gameCityAreaType = (playerPuppet as PlayerPuppet).GetCurrentSecurityZoneType(playerPuppet);
            return Equals(zoneType, gameCityAreaType.RestrictedZone) || Equals(zoneType, gameCityAreaType.DangerousZone);
        };
        return false;
    }

    public final static func AiWillInvestigate() -> Bool {
        return Utils.CoinFlip(Settings.GetInvestigateCommonSoundChance());
    }
}