module AiTriggerOverhaul

/*
 * Adds custom stimRange for Body Disposals with prior Takedowns (in a single action).
 * Please note that this bypasses the Vanilla usage of TweakDB values.
 *
 * Regarding the other ActionTypes:
 * I am unaware of non-lethal disposals. Non-lethal takedowns & grapples remain untouched for now.
 */
@wrapMethod(StimBroadcasterComponent)
public final func TriggerNoiseStim(owner: wref<GameObject>, takedownActionType: ETakedownActionType) -> Void {
    if Settings.ModIsEnabled() {
        if IsDefined(owner) {
            let stimRange: Float;
            if Equals(takedownActionType, ETakedownActionType.DisposalTakedown) {
                stimRange = Settings.BodyDisposalIsLoud() ? Settings.GetLoudNoiseStimRange() : Settings.GetCommonSoundStimRange();

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