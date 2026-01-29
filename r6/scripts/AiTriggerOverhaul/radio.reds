module AiTriggerOverhaul

/*
 * This is a rewrite of a Device method which seems to be bugged for Radios.
 * Radios are clearly intended to trigger stimuli, but the Vanilla broadcaster call lacks a propagationChange boolean,
 * which is needed for many NPCs to change states.
 * 
 * Even though this might fix Radios, I'd refrain from changing the original Device method, as it's the super class
 * of every device in the game and could easily fuck up too much stuff.
 */
@addMethod(Radio)
protected final func MyTriggerArreaEffectDistraction(effectData: ref<AreaEffectData>, opt executor: ref<GameObject>) -> Void {
    let investigateData: stimInvestigateData;
    let target: ref<GameObject> = this.GetEntityFromNode(effectData.stimSource) as GameObject;

    // Set up investigate Data
    if target == null {
        target = this.GetStimTarget();
    } else {
        investigateData.mainDeviceEntity = this.GetStimTarget();
    };
    if effectData.investigateController {
        investigateData.controllerEntity = this.GetDistractionControllerSource(effectData);
        if IsDefined(investigateData.controllerEntity) {
            investigateData.investigateController = true;
        };
    };
    investigateData.distrationPoint = this.GetDistractionPointPosition(target);
    investigateData.investigationSpots = this.GetNodePosition(effectData.investigateSpot);
    if IsDefined(executor) {
        investigateData.attackInstigator = executor;
    } else {
        if IsDefined(effectData.action.GetExecutor()) {
            investigateData.attackInstigator = effectData.action.GetExecutor();
        };
    };

    // Broadcast stimuli
    let stimType: gamedataStimType = Utils.AiWillInvestigate() ? gamedataStimType.VisualDistract : gamedataStimType.SoundDistraction;
    let broadcaster: ref<StimBroadcasterComponent> = target.GetStimBroadcasterComponent();
    if IsDefined(broadcaster) {
        let stimRange: Float = Settings.RadiosAreLoud() ? Settings.GetLoudNoiseStimRange() : Settings.GetCommonSoundStimRange();
        broadcaster.SetSingleActiveStimuli(this, stimType, Settings.GetCommonAttentionLifetime(), stimRange, investigateData, true);
    };

    // Vanilla remains, untouched for now
    if ArraySize(effectData.additionaStimSources) > 0 {
        stimType = Device.MapStimType(effectData.stimType);
        let stimLifetime: Float = this.GetDistractionStimLifetime(effectData.stimLifetime);
        let i: Int32 = 0;
        while i < ArraySize(effectData.additionaStimSources) {
            target = this.GetEntityFromNode(effectData.additionaStimSources[i]) as GameObject;
            if IsDefined(target) {
                broadcaster = target.GetStimBroadcasterComponent();
                if IsDefined(broadcaster) {
                    // propagationChange missing here too
                    broadcaster.SetSingleActiveStimuli(this, stimType, stimLifetime, effectData.stimRange);
                };
            };
            i += 1;
        };
    };
}

/*
 * Helper function to keep it DRY
 */
@addMethod(Radio)
private final func TriggerStimuli(executor: ref<GameObject>) -> Void {
    let effectData: ref<AreaEffectData> = this.GetDefaultDistractionAreaEffectData();
    if Settings.ModIsEnabled() && IsDefined(executor) && executor.IsPlayer() {
        this.MyTriggerArreaEffectDistraction(effectData, executor);
        return;
    };
    this.TriggerArreaEffectDistraction(effectData, executor);
}

@replaceMethod(Radio)
protected cb func OnToggleON(evt: ref<ToggleON>) -> Bool {
    super.OnToggleON(evt);
    //this.TriggerArreaEffectDistraction(this.GetDefaultDistractionAreaEffectData(), evt.GetExecutor());

    this.TriggerStimuli(evt.GetExecutor());
}

@replaceMethod(Radio)
protected cb func OnNextStation(evt: ref<NextStation>) -> Bool {
    this.PlayGivenStation();
    this.UpdateDeviceState();
    this.RefreshUI();
    //this.TriggerArreaEffectDistraction(this.GetDefaultDistractionAreaEffectData(), evt.GetExecutor());

    this.TriggerStimuli(evt.GetExecutor());
}

@replaceMethod(Radio)
protected cb func OnPreviousStation(evt: ref<PreviousStation>) -> Bool {
    this.PlayGivenStation();
    this.UpdateDeviceState();
    this.RefreshUI();
    //this.TriggerArreaEffectDistraction(this.GetDefaultDistractionAreaEffectData(), evt.GetExecutor());

    this.TriggerStimuli(evt.GetExecutor());
}