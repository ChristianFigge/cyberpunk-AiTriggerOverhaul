module AiTriggerOverhaul

/*
 * Trigger "sound" stimulus when disposing an unconcious body in a container.
 *
 * Stimuli for body disposals with prior takedowns are handled differently and only indirectly by the DisposalDevice class.
 * In DisposalDevice.TakedownAndDispose(...), StimBroadcasterComponent.TriggerNoiseStim(...) is called, which is hooked 
 * by this mod in the corresponding redscript file 'stimBroadcasterComponent.reds'.
 */
@wrapMethod(DisposalDevice)
protected cb func OnDisposeBody(evt: ref<DisposeBody>) -> Bool {
    let result: Bool = wrappedMethod(evt);

    let executor = evt.GetExecutor();
    if Settings.ModIsEnabled() && IsDefined(executor) && executor.IsPlayer() {
        let broadcaster: ref<StimBroadcasterComponent> = this.GetStimBroadcasterComponent();
        if IsDefined(broadcaster) {
            let stimRange: Float = Settings.BodyDisposalIsLoud() ? Settings.GetLoudNoiseStimRange() : Settings.GetCommonSoundStimRange();
            broadcaster.TriggerSingleBroadcast(this, gamedataStimType.SoundDistraction, stimRange);
        }
    }
    
    return result;
}