module AiTriggerOverhaul

/*
 * Calculates stimRange for sprinting footsteps based on certain Stealth Perks. (Feline Footwork & Ninjutsu)
 * Adds stimRange to the Broadcast call (omitted in Vanilla).
 */
@wrapMethod(LocomotionTransition)
protected final func BroadcastStimuliFootstepSprint(context: ref<StateGameScriptInterface>) -> Void {
    if Settings.ModIsEnabled() && context.executionOwner.IsPlayer() {
        let broadcaster: ref<StimBroadcasterComponent>;
        // I have no idea how to gain the CanRunSilently Stat in-game. Modder's discord doesn't eeither. It seems to always be <1.0 and is mentioned nowhere else in the Vanilla code.
        let broadcastFootstepStim: Bool = GameInstance.GetStatsSystem(context.owner.GetGame()).GetStatValue(Cast<StatsObjectID>(context.owner.GetEntityID()), gamedataStatType.CanRunSilently) < 1.00;
        if broadcastFootstepStim { // Probably always true
            broadcaster = context.executionOwner.GetStimBroadcasterComponent();
            if IsDefined(broadcaster) {
                let stimRange: Float = Settings.GetSprintNoiseStimRange();
                let perkFactor: Float = Settings.GetSprintNoisePerkReductionFactor(); // Range 0.0 - 0.25
                if perkFactor > 0.0 { // Possible to disable via Mod Settings
                    // Use player perk data to calculate the stim range reduction factor & apply it.
                    // TODO This shouldn't be calculated every footstep. It'll do for now though
                    let pdsData = PlayerDevelopmentSystem.GetData(context.executionOwner);
                    let felineLvl: Int32 = pdsData.IsNewPerkBought(gamedataNewPerkType.Cool_Central_Milestone_1); // Get Feline Footwork Level (0-1)
                    if felineLvl > 0 { // Feline Perk is required for Ninjutsu Perk
                        let ninjutsuLvl: Int32 = pdsData.IsNewPerkBought(gamedataNewPerkType.Cool_Central_Milestone_3); // Get Ninjutsu Level (0-3)
                        stimRange *= 1.0 - (Cast<Float>(felineLvl + ninjutsuLvl) * perkFactor);
                    };
                };
                if stimRange > 0.0 { broadcaster.TriggerSingleBroadcast(context.executionOwner, gamedataStimType.FootStepSprint, stimRange); };
            };
        };
    } else {
        wrappedMethod(context);
    };
}
