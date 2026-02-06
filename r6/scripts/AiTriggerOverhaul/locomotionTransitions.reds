module AiTriggerOverhaul

/*
 * Helper function. Calculates stimRange for locomotion/movement events based on unlocked Stealth Perks. (Feline Footwork & Ninjutsu)
 */
@addMethod(LocomotionTransition)
protected func ApplyStealthPerksToStimRange(player: wref<GameObject>, baseRange: Float) -> Float {
    if baseRange > 0.0 {
        let perkFactor: Float = Settings.GetStealthPerkNoiseReductionFactor(); // Range 0.0 - 0.25
        if perkFactor > 0.0 { // Possible to disable via Mod Settings
            // Use player perk data to calculate the stim range reduction factor & apply it.
            let pdsData = PlayerDevelopmentSystem.GetData(player);
            let felineLvl: Int32 = pdsData.IsNewPerkBought(gamedataNewPerkType.Cool_Central_Milestone_1); // Get Feline Footwork Level (0-1)
            if felineLvl > 0 { // Feline Perk is required for Ninjutsu Perk
                let ninjutsuLvl: Int32 = pdsData.IsNewPerkBought(gamedataNewPerkType.Cool_Central_Milestone_3); // Get Ninjutsu Level (0-3)
                return baseRange * (1.0 - (Cast<Float>(felineLvl + ninjutsuLvl) * perkFactor));
            };
        };
    };
    return baseRange;  
}


/*
 * Adds custom stimRanges for all Landing Types (regular, hard, very hard) to the stim broadcast call (omitted in Vanilla to use TweakDB flats internally)
 * NOTE: An effective stimRange parameter of 0.0 will result in broadcasting TweakDB values instead (hence the if clause) 
 */
@wrapMethod(AbstractLandEvents)
protected final func BroadcastLandingStim(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>, stimType: gamedataStimType) -> Void {
    if Settings.ModIsEnabled() && scriptInterface.executionOwner.IsPlayer() {
        // Check conditions for skipping stim broadcasting (e.g. regular landing from a crouched jump might have to be silent)
        let broadcastLandingStim: Bool = scriptInterface.GetStatsSystem().GetStatValue(Cast<StatsObjectID>(scriptInterface.ownerEntityID), gamedataStatType.CanLandSilently) < 1.00;
        if !broadcastLandingStim || this.m_blockLandingStimBroadcasting {
            this.m_blockLandingStimBroadcasting = false;
            return;
        };
        if Settings.GetCrouchedJumpsAreSilent() && LocomotionGroundDecisions.CheckCrouchEnterCondition(stateContext, scriptInterface) && Equals(stimType, gamedataStimType.LandingRegular) {
            return;
        };
        let impactSpeed: StateResultFloat = stateContext.GetPermanentFloatParameter(n"ImpactSpeed");
        let speedThresholdToSendStim: Float = this.GetFallingSpeedBasedOnHeight(scriptInterface, 1.20);
        if impactSpeed.value < speedThresholdToSendStim {
            // Broadcast stim
            let broadcaster: ref<StimBroadcasterComponent> = scriptInterface.executionOwner.GetStimBroadcasterComponent();
            if IsDefined(broadcaster) {
                // Get stimRange by landing type from Mod Settings -- Apparently no switch/case in redscript :(
                let stimRange: Float = -1.0;
                if Equals(stimType, gamedataStimType.LandingRegular) {
                    stimRange = Settings.GetRegularLandingStimRange();
                } else { if Equals(stimType, gamedataStimType.LandingHard) {
                        stimRange = Settings.GetHardLandingStimRange();
                    } else { if Equals(stimType, gamedataStimType.LandingVeryHard) {
                            stimRange = Settings.GetVeryHardLandingStimRange();
                        };
                    };
                };

                if stimRange > -1.0 {
                    if Settings.GetApplyStealthPerksToLandings() { stimRange = this.ApplyStealthPerksToStimRange(scriptInterface.executionOwner, stimRange); };
                    if stimRange > 0.0 { broadcaster.TriggerSingleBroadcast(scriptInterface.executionOwner, stimType, stimRange); };
                } else { // Catch default case (Vanilla, no stimRange parameter)
                    broadcaster.TriggerSingleBroadcast(scriptInterface.executionOwner, stimType);
                };
            };
        };
    } else {
        wrappedMethod(stateContext, scriptInterface, stimType);
    };
}

/*
 * Adds (perk-based) stimRange for sprinting/dashing/dodging to the Broadcast call
 */
@wrapMethod(LocomotionTransition)
protected final func BroadcastStimuliFootstepSprint(context: ref<StateGameScriptInterface>) -> Void {
    if Settings.ModIsEnabled() && context.executionOwner.IsPlayer() {
        // Tbh I have no idea how to gain the CanRunSilently Stat in-game. Modder's discord doesn't either. It seems to always be <1.0 and is mentioned nowhere else in the Vanilla code.
        let broadcastFootstepStim: Bool = GameInstance.GetStatsSystem(context.owner.GetGame()).GetStatValue(Cast<StatsObjectID>(context.owner.GetEntityID()), gamedataStatType.CanRunSilently) < 1.00;
        if broadcastFootstepStim { // Probably always true
            let broadcaster: ref<StimBroadcasterComponent> = context.executionOwner.GetStimBroadcasterComponent();
            if IsDefined(broadcaster) {
                let stimRange: Float = this.ApplyStealthPerksToStimRange(context.executionOwner, Settings.GetSprintStimRange());
                if stimRange > 0.0 { broadcaster.TriggerSingleBroadcast(context.executionOwner, gamedataStimType.FootStepSprint, stimRange); };
            };
        };
    } else {
        wrappedMethod(context);
    };
}

/*
 * Adds (perk-based) stimRange for regular walking footsteps to the Broadcast call
 */
@wrapMethod(LocomotionTransition)
protected final func BroadcastStimuliFootstepRegular(context: ref<StateGameScriptInterface>) -> Void {
    if Settings.ModIsEnabled() && context.executionOwner.IsPlayer() {
        let broadcastFootstepStim: Bool = GameInstance.GetStatsSystem(context.owner.GetGame()).GetStatValue(Cast<StatsObjectID>(context.owner.GetEntityID()), gamedataStatType.CanWalkSilently) < 1.00;
        if broadcastFootstepStim {
            let broadcaster: ref<StimBroadcasterComponent> = context.executionOwner.GetStimBroadcasterComponent();
            if IsDefined(broadcaster) {
                let stimRange: Float = this.ApplyStealthPerksToStimRange(context.executionOwner, Settings.GetWalkStimRange());
                if stimRange > 0.0 { broadcaster.TriggerSingleBroadcast(context.executionOwner, gamedataStimType.FootStepRegular, stimRange); };
            };
        };
    } else {
        wrappedMethod(context);
    };
}

/*
 * Differentiate between Dodge/Dash and broadcast stim according to Settings
 */
@wrapMethod(DodgeEvents)
protected func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
    if Settings.ModIsEnabled() && !Settings.GetDodgeIsSprint() && scriptInterface.owner.IsPlayer() {
        super.OnUpdate(timeDelta, stateContext, scriptInterface);
        if !this.m_pressureWaveCreated && this.GetInStateTime() >= 0.15 {
            this.m_pressureWaveCreated = true;
            
            if StatusEffectHelper.HasStatusEffectFromInstigator(scriptInterface.owner, t"BaseStatusEffect.PlayerJustDodged", scriptInterface.owner.GetEntityID()) {
                // Player dodged (without Dash perk), broadcast regular walk stim
                this.BroadcastStimuliFootstepRegular(scriptInterface);
            } else { 
                // Player dashed, broadcast sprint stim
                this.BroadcastStimuliFootstepSprint(scriptInterface);
            };
        };
        // Vanilla code from here on
        if !this.m_isAirDashSaveLockTriggered && !this.IsTouchingGround(scriptInterface) {
            SaveLocksManager.RequestSaveLockAdd(scriptInterface.owner.GetGame(), n"DisableSaveWhileAirDashing");
            this.m_isAirDashSaveLockTriggered = true;
        };
        if scriptInterface.IsActionJustPressed(n"Jump") {
            stateContext.SetConditionBoolParameter(n"JumpPressed", true, true);
        };
        if scriptInterface.IsActionJustPressed(n"ToggleSprint") {
            stateContext.SetConditionBoolParameter(n"SprintToggled", true, true);
        };
        if scriptInterface.IsActionJustTapped(n"ToggleCrouch") || scriptInterface.IsActionJustHeld(n"ToggleCrouch") {
            stateContext.SetConditionBoolParameter(n"CrouchToggled", !this.m_crouching, true);
        };
        this.RemoveOpticalCamoEffect(stateContext, scriptInterface, 7, 0.85);
    } else {
        wrappedMethod(timeDelta, stateContext, scriptInterface);
    };
}

/*
 * Helper function to add custom stim broadcasts to locomotion events
 */
@addMethod(LocomotionTransition)
protected func BroadcastATOStim(execOwner: wref<GameObject>, baseStimRange: Float, stimType: gamedataStimType) -> Void {
    let broadcaster: ref<StimBroadcasterComponent> = execOwner.GetStimBroadcasterComponent();
    if Settings.ModIsEnabled() && execOwner.IsPlayer() && IsDefined(broadcaster) && baseStimRange > 0.0 {
        let stimRange: Float = this.ApplyStealthPerksToStimRange(execOwner, baseStimRange);
        if stimRange > 0.0 { broadcaster.TriggerSingleBroadcast(execOwner, stimType, stimRange); };
    };
}

/*
 * Adds stim broadcast to Regular Jump Events.
 */
@wrapMethod(JumpEvents)
protected func OnEnter(stateContext : ref<StateContext>, scriptInterface : ref<StateGameScriptInterface>) -> Void {
    wrappedMethod(stateContext, scriptInterface);
    // Check Settings & if it's a crouched jump
    if Settings.GetCrouchedJumpsAreSilent() && LocomotionGroundDecisions.CheckCrouchEnterCondition(stateContext, scriptInterface) {
        return;
    };
    // Careful with the stimType here: FootStepSprint can stunlock enemies when spamming Jump. If in doubt, use FootStepRegular
    this.BroadcastATOStim(scriptInterface.executionOwner, Settings.GetJumpStimRange(), gamedataStimType.FootStepRegular);
}

/*
 * Adds stim broadcast to Double Jump Events
 */
@wrapMethod(DoubleJumpEvents)
protected func OnEnter(stateContext : ref<StateContext>, scriptInterface : ref<StateGameScriptInterface>) -> Void {
    wrappedMethod(stateContext, scriptInterface);
    this.BroadcastATOStim(scriptInterface.executionOwner, Settings.GetDoubleJumpStimRange(), gamedataStimType.FootStepSprint);
}

/*
 * Adds stim broadcast to Charge Jump Events
 */
@wrapMethod(ChargeJumpEvents)
protected func OnEnter(stateContext : ref<StateContext>, scriptInterface : ref<StateGameScriptInterface>) -> Void {
    wrappedMethod(stateContext, scriptInterface);
    this.BroadcastATOStim(scriptInterface.executionOwner, Settings.GetChargedJumpStimRange(), gamedataStimType.FootStepSprint);
}

// NOTES
// SlideEvents.OnEnterFromSprint() already broadcasts a sprinting stim, which should suffice
// Since CDPR scrapped Hover Legs with the Cyberware rework, I currently don't plan to modify HoverJumpEvents for the main file of this mod.