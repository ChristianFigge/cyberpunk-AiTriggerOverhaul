module AiTriggerOverhaul

/*
 * Custom data field to store info about the loudness of a door opening.
 * Set in the corresponding callback functions to change broadcasting calls.
 * For safety, remember to reset it to false after usage.
 */
@addField(Door)
private let m_openedLoudly: Bool;

/*
 * Wrapper for the vanilla Door method that causes AI stimuli to trigger.
 * Here we define our custom triggers and differentiate between loud and normal door openings.
 */
@wrapMethod(Door)
protected func TriggerMoveDoorStimBroadcaster(broadcaster: ref<StimBroadcasterComponent>, reactionData: stimInvestigateData) -> Void {
	if Settings.ModIsEnabled() { 
		if IsDefined(broadcaster) {
			if this.m_openedLoudly {
				// LOUD DOOR OPENING (e.g. with brute force)
				broadcaster.TriggerSingleBroadcast(this, gamedataStimType.OpeningDoor, Settings.GetLoudNoiseStimRange(), reactionData);
			} 
			else {
				// NORMAL DOOR OPENING			
				// If enabled in Mod Settings, Stimuli are only triggered in Restricted or Dangerous Zones.
				if Settings.GetUseZoneSpecificChanges() && !Utils.PlayerIsInRestrictedOrDangerousZone(this.m_whoOpened) {
					return;
				};
				// Choose stim type based on set probabilities
				let stimType: gamedataStimType = Utils.AiWillInvestigate() ? gamedataStimType.VisualDistract : gamedataStimType.Attention;
				broadcaster.AddActiveStimuli(this, stimType, Settings.GetCommonAttentionLifetime(), Settings.GetCommonSoundStimRange(), reactionData, true);

				/* In vanilla, the following line is called with stimRange 0.0 by default, which makes it pretty much useless. We keep it,
				 * but call it with a small range (check Settings.reds) in order to add stimulus for NPCs who are standing right next to a door. */
				broadcaster.TriggerSingleBroadcast(this, gamedataStimType.OpeningDoor, Settings.GetDoorOpeningStimRange(), reactionData);
			};
		};
    } else {
		// If the mod is disabled, call original method (no changes will apply)
		wrappedMethod(broadcaster, reactionData);
	};
}

@wrapMethod(Door)
protected cb func OnActionDemolition(evt: ref<ActionDemolition>) -> Bool {
	// The demolition is loud. Changes stimuli range on broadcast
	this.m_openedLoudly = true;

	// Call original method (broadcasts stimuli)
	let result: Bool = wrappedMethod(evt);

	// Reset bool, because I can't be sure that no doors in the game 
	// can be opened/closed after being unlocked forcefully.
	this.m_openedLoudly = false;

    return result;
}

/*
 * Helper function to safely trigger the stim broadcaster function
 */
@addMethod(Door)
private func TriggerStimuli() -> Void {
	if Settings.ModIsEnabled() && IsDefined(this.m_whoOpened) && this.m_whoOpened.IsPlayer() {
		let broadcaster = this.GetStimBroadcasterComponent();
		let reactionData: stimInvestigateData;
      	this.TriggerMoveDoorStimBroadcaster(broadcaster, reactionData);
    };
}

/*
 * Trigger audio stimulus on closing doors as well.
 * In Vanilla, it's only triggered when opening, because many doors close automatically
 * behind the player. Now players have to be extra careful using doors, which is the point.
 */
@wrapMethod(Door)
private final func MoveDoor(shouldBeOpened: Bool, immediate: Bool, opt movingSpeedMultiplier: Float) -> Bool {
	let result: Bool = wrappedMethod(shouldBeOpened, immediate, movingSpeedMultiplier);

	if !shouldBeOpened { this.TriggerStimuli(); };
	
	return result;
}

/*
 * Trigger stimuli when opening a locked door using the Technical Ability.
 * This is not considered "loud" and will fire the same stimuli as opening 
 * an unlocked door normally.
 * In Vanilla, no stimuli are broadcasted at all.
 */
@wrapMethod(Door)
protected cb func OnActionEngineering(evt: ref<ActionEngineering>) -> Bool {
	// Call original method (broadcasts NO audio stimulus by default)
	let result: Bool = wrappedMethod(evt);

	this.TriggerStimuli();

    return result;
}