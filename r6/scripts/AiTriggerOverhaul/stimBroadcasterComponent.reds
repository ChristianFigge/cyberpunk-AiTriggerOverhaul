module AiTriggerOverhaul

/*
 * For body disposals with prior takedowns, we check our custom stimRanges against the tweakDB ones (if any), and take
 * the greater value of the 2. That way, only weak sauce gets overwritten and hardcore AI overhauls are safe.
 *
 * I am unaware of non-lethal disposals. Non-lethal takedowns & grapples remain untouched for now.
 */
@wrapMethod(StimBroadcasterComponent)
public final func TriggerNoiseStim(owner: wref<GameObject>, takedownActionType: ETakedownActionType) -> Void {
    if Settings.ModIsEnabled() {
        if IsDefined(owner) {
            let stimRange: Float;
            if Equals(takedownActionType, ETakedownActionType.DisposalTakedown) {
                stimRange = MaxF(
                    TweakDBInterface.GetFloat(t"AIGeneralSettings.takedownNoiseRange", 3.00),
                    Settings.BodyDisposalIsLoud() ? Settings.GetLoudNoiseStimRange() : Settings.GetCommonSoundStimRange()
                );

                /* With the Vanilla stimType SoundDistraction, it's very easy to get away with dumping a body right in front of
                 * another enemy watching you do it, especially in non-dangerous Zones. StimType.Bullet seems to work better,
                 * making enemies hostile on sight. */
                this.TriggerSingleBroadcast(owner, gamedataStimType.Bullet, stimRange); 
            } else {
                // We currently don't touch the other cases, so call original method
                wrappedMethod(owner, takedownActionType);
            };
        };
    } else {
        wrappedMethod(owner, takedownActionType);
    };
}