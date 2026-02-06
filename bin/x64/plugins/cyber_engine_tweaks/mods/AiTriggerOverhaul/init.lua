local movementType = {
    WALK = 1,
    SPRINT = 2,
    JUMP = 3,
    DOUBLE_JUMP = 4,
    -- CHARGED_JUMP = 5,
    -- HOVER_JUMP = 6,
    REGULAR_LANDING = 5,
    HARD_LANDING = 6,
    VERYHARD_LANDING = 7
}

-- String Labels for the Menu Selector
local movementTypeLabels = {
    [movementType.WALK] = "Regular Walk",
    [movementType.SPRINT] = "Sprint/Dash",
    [movementType.JUMP] = "Normal Jump",
    [movementType.DOUBLE_JUMP] = "Double/Charged Jump",
    -- [movementType.CHARGED_JUMP] = "Charged Jump",
    -- [movementType.HOVER_JUMP] = "Hover Jump",
    [movementType.REGULAR_LANDING] = "Regular Landing",
    [movementType.HARD_LANDING] = "Hard Landing",
    [movementType.VERYHARD_LANDING] = "Very Hard Landing"
}

-- DEFAULT VALUES for movement noises
-- Since we cannot define multiple default values in the nativeSettings.addRange functions, we use a table + custom restoreDefaults() func instead
local movementNoiseDefaults = {
    [movementType.WALK] = 12.0,
    [movementType.SPRINT] = 16.0,
    [movementType.JUMP] = 14.0,
    [movementType.DOUBLE_JUMP] = 16.0,
    [movementType.REGULAR_LANDING] = 16.0,
    [movementType.HARD_LANDING] = 20.0,
    [movementType.VERYHARD_LANDING] = 24.0
}

-- Vanilla values
local movementNoiseVanilla = {
    [movementType.WALK] = 6.0,
    [movementType.SPRINT] = 9.0,
    [movementType.JUMP] = 0.0,
    [movementType.DOUBLE_JUMP] = 0.0,
    [movementType.REGULAR_LANDING] = 6.0,
    [movementType.HARD_LANDING] = 9.0,
    [movementType.VERYHARD_LANDING] = 12.0
}

-- Mod Settings struct
local settings = {
    ModIsEnabled = true,
    LoudNoiseStimRange = 16.0,
    CommonSoundStimRange = 8.0,
    InvestigateCommonSoundChance = 0.25,
    CommonAttentionLifetime = 2.0,
    UseZoneSpecificChanges = true,
    RadiosAreLoud = true,
    BodyDisposalIsLoud = true,

    -- Movement noises
    WalkStimRange = movementNoiseDefaults[movementType.WALK],
    SprintStimRange = movementNoiseDefaults[movementType.SPRINT],
    JumpStimRange = movementNoiseDefaults[movementType.JUMP],
    DoubleJumpStimRange = movementNoiseDefaults[movementType.DOUBLE_JUMP],
    ChargedJumpStimRange = movementNoiseDefaults[movementType.DOUBLE_JUMP], -- Seperated only internally; User won't notice
    RegularLandingStimRange = movementNoiseDefaults[movementType.REGULAR_LANDING],
    HardLandingStimRange = movementNoiseDefaults[movementType.HARD_LANDING],
    VeryHardLandingStimRange = movementNoiseDefaults[movementType.VERYHARD_LANDING],
    CrouchedJumpsAreSilent = true,
    DodgeIsSprint = false,

    StealthPerkNoiseReductionFactor = 0.15
}

local selectedMovementType = movementType.WALK
local moveNoiseSliderState = settings.WalkStimRange
local movementNoiseSlider -- optionTable

-- Init Native Settings UI
registerForEvent("onInit", function()
    local nativeSettings = GetMod("nativeSettings") -- Get a reference to the nativeSettings mod

    if nativeSettings then
        LoadSettings()
        BuildSettingsMenu(nativeSettings)
        OverrideRedscriptFunctions()
    else
        print("AiTriggerOverhaul Error: NativeSettings not found! Continuing with default settings.")
        return
    end
end)

-- Helper function for restoring Default or Vanilla Settings 
function applyMovementValuesToSettings(valueTable)
    settings.WalkStimRange = valueTable[movementType.WALK]
    settings.SprintStimRange = valueTable[movementType.SPRINT]
    settings.JumpStimRange = valueTable[movementType.JUMP]
    settings.DoubleJumpStimRange = valueTable[movementType.DOUBLE_JUMP]
    settings.ChargedJumpStimRange = valueTable[movementType.DOUBLE_JUMP]
    settings.RegularLandingStimRange = valueTable[movementType.REGULAR_LANDING]
    settings.HardLandingStimRange = valueTable[movementType.HARD_LANDING]
    settings.VeryHardLandingStimRange = valueTable[movementType.VERYHARD_LANDING]
end

-- Helper function to update noise slider based on currently selected movement type & set values
function updateMovementNoiseSlider(nativeSettings)
    if selectedMovementType == movementType.WALK then nativeSettings.setOption(movementNoiseSlider, settings.WalkStimRange)
    elseif selectedMovementType == movementType.SPRINT then nativeSettings.setOption(movementNoiseSlider, settings.SprintStimRange)
    elseif selectedMovementType == movementType.JUMP then nativeSettings.setOption(movementNoiseSlider, settings.JumpStimRange)
    elseif selectedMovementType == movementType.DOUBLE_JUMP then nativeSettings.setOption(movementNoiseSlider, settings.DoubleJumpStimRange)
    elseif selectedMovementType == movementType.REGULAR_LANDING then nativeSettings.setOption(movementNoiseSlider, settings.RegularLandingStimRange)
    elseif selectedMovementType == movementType.HARD_LANDING then nativeSettings.setOption(movementNoiseSlider, settings.HardLandingStimRange)
    elseif selectedMovementType == movementType.VERYHARD_LANDING then nativeSettings.setOption(movementNoiseSlider, settings.VeryHardLandingStimRange)
    else print("AiTriggerOverhaul Error: Undefined behaviour for movement type ", selectedMovementType) -- Debug help
    end
end

function BuildSettingsMenu(nativeSettings)
    nativeSettings.addTab("/aiTriggerOverhaul", "AI Trigger Overhaul")

    nativeSettings.addSubcategory("/aiTriggerOverhaul/mainSwitch", "Main Switch")

    -- Parameters: path, label, desc, currentValue, defaultValue, callback
    nativeSettings.addSwitch("/aiTriggerOverhaul/mainSwitch", "Enable Mod", "If the switch is off, all changes of this mod are bypassed.", settings.ModIsEnabled, true, function(state)
        settings.ModIsEnabled = state
        SaveSettings()
    end)

    -- STIM RANGES
    nativeSettings.addSubcategory("/aiTriggerOverhaul/stimRanges", "Stimuli Ranges")

    -- Parameters: path, label, desc, min, max, step, format, currentValue, defaultValue, callback
    nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimRanges", "Loud Noises", "The range of unusual and loud sounds, like players demolishing a locked door with brute force.", 0, 32, 0.5, "%.1f", settings.LoudNoiseStimRange, 16.0, function(state)
        settings.LoudNoiseStimRange = state
        SaveSettings()
    end)

    nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimRanges", "Common Sounds", "The range of everyday stimuli like the sound of an opening door. These will catch the enemy's attention for a short time, but won't turn them hostile on their own.", 0, 16, 0.5, "%.1f", settings.CommonSoundStimRange, 8.0, function(state)
        settings.CommonSoundStimRange = state
        SaveSettings()
    end)

    nativeSettings.addSwitch("/aiTriggerOverhaul/stimRanges", "Loud Radios", "If enabled, stimuli by radios will have the same range as 'Loud Noises'. Otherwise, radios are considered to emit 'Common Sounds'.", settings.RadiosAreLoud, true, function(state)
        settings.RadiosAreLoud = state
        SaveSettings()
    end)

    nativeSettings.addSwitch("/aiTriggerOverhaul/stimRanges", "Loud Body Disposal", "If enabled, disposing bodies in a container creates 'Loud Noises'. Otherwise, it has the same stimulus range as 'Common Sounds'.", settings.BodyDisposalIsLoud, true, function(state)
        settings.BodyDisposalIsLoud = state
        SaveSettings()
    end)

    -- Parameters: path, label, desc, elements, currentValue, defaultValue, callback
    nativeSettings.addSelectorString("/aiTriggerOverhaul/stimRanges", "Movement Type", "Select the movement type whose noise should be changed by the 'Movement Type Noise' slider below.\n\nVanilla values for reference:\n\nWalk: 6.0\nSprint/Dash/Dodge: 9.0\nJumps: 0.0 (only emit a noise when landing)\nRegular Landing: 6.0\nHard Landing: 9.0\nVery Hard Landing: 12.0", movementTypeLabels, selectedMovementType, movementType.WALK, function(moveTypeId) 
        selectedMovementType = moveTypeId
        updateMovementNoiseSlider(nativeSettings)
    end)

    movementNoiseSlider = nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimRanges", "Movement Type Noise", "Set the noise level of the selected movement type.", 0.0, 64.0, 1.0, "%.1f", moveNoiseSliderState, movementNoiseDefaults[movementType.WALK], function(state)
        moveNoiseSliderState = state

        -- Update Settings based on currently selected movement type
        if selectedMovementType == movementType.WALK then settings.WalkStimRange = state
        elseif selectedMovementType == movementType.SPRINT then settings.SprintStimRange = state
        elseif selectedMovementType == movementType.JUMP then settings.JumpStimRange = state
        elseif selectedMovementType == movementType.DOUBLE_JUMP then 
            settings.DoubleJumpStimRange = state
            settings.ChargedJumpStimRange = state
        elseif selectedMovementType == movementType.REGULAR_LANDING then settings.RegularLandingStimRange = state
        elseif selectedMovementType == movementType.HARD_LANDING then settings.HardLandingStimRange = state
        elseif selectedMovementType == movementType.VERYHARD_LANDING then settings.VeryHardLandingStimRange = state
        else print("AiTriggerOverhaul Error: Unable to change noise value for unknown movement type ", selectedMovementType) -- Debug help
        end
        SaveSettings()
    end)

    -- Parameters: path, label, desc, buttonText, textSize, callback, optionalIndex
    nativeSettings.addButton("/aiTriggerOverhaul/stimRanges", "Use Vanilla Movement Noises", "This button sets the noise values for all movement types to those from the Vanilla game.", "Go Vanilla", 45, function()
        applyMovementValuesToSettings(movementNoiseVanilla)
        updateMovementNoiseSlider(nativeSettings)
        print("AiTriggerOverhaul Info: Applied Vanilla movement noise values!")
    end)

    nativeSettings.addSwitch("/aiTriggerOverhaul/stimRanges", "Silent Crouched Jumps", "If enabled, normal jumps performed from a crouched position emit no sounds.", settings.CrouchedJumpsAreSilent, true, function(state)
        settings.CrouchedJumpsAreSilent = state
        SaveSettings()
    end)

    nativeSettings.addSwitch("/aiTriggerOverhaul/stimRanges", "Dodge = Sprint", "If enabled, simple Dodging (without the Dash Perk) emits the same noise as Sprinting. This corresponds to Vanilla.\n\nOtherwise, a simple Dodge will be only as loud as a regular Walking footstep.", settings.DodgeIsSprint, false, function(state)
        settings.DodgeIsSprint = state
        SaveSettings()
    end)

    nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimRanges", "Stealth Perk Noise Reduction Factor", "The 'Cool' perks Feline Footwork and each level of Ninjutsu can reduce a player's movement noise by the specified factor.\nThis factor counts once for each of the mentioned perks that the player has unlocked.\nIt does not affect the range of 'Loud Noises' or 'Common Sounds'.\n\nExamples:\nA factor of 0.1 with Feline Footwork plus Ninjutsu Level 2 will result in a movement noise reduction of 3 * 0.1 = 0.3 -> 30%.\n\nA factor of 0.0 will disable the perk-based reduction altogether.\n\nA factor of 0.25 with all 4 perks unlocked will result in perfectly silent movement.", 0, 0.25, 0.01, "%.2f", settings.StealthPerkNoiseReductionFactor, 0.15, function(state)
        settings.StealthPerkNoiseReductionFactor = state
        SaveSettings()
    end)

    -- STIM TYPE PROBABILITIES
    nativeSettings.addSubcategory("/aiTriggerOverhaul/stimTypeChances", "Reaction Type Probabilities")

    nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimTypeChances", "Investigation Chance", "The probability of enemies to actively investigate the source of a common sound, i.e. to approach it physically.", 0, 1, 0.05, "%.2f", settings.InvestigateCommonSoundChance, 0.25, function(state)
        settings.InvestigateCommonSoundChance = state
        SaveSettings()
    end)

    -- ACTIVE STIM LIFETIMES 
    nativeSettings.addSubcategory("/aiTriggerOverhaul/stimDurations", "Stimuli Durations")

    nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimDurations", "Attention Span", "The duration for which enemies pay attention to common stimuli, in seconds.", 0, 10, 0.5, "%.1f", settings.CommonAttentionLifetime, 2.0, function(state)
        settings.CommonAttentionLifetime = state
        SaveSettings()
    end)

    -- MISC SETTINGS
    nativeSettings.addSubcategory("/aiTriggerOverhaul/misc", "Miscellaneous Settings")

    nativeSettings.addSwitch("/aiTriggerOverhaul/misc", "Zone Type Specific Changes", "If enabled, the mod will disable certain stimuli in 'Public' zones of the city, which is intended to prevent some odd NPC behaviours in Vanilla Cyberpunk.\nHowever, as it is practically impossible to test every quest, this might have undesirable (yet harmless) consequences in specific situations which the mod's author is not yet aware of.\n\nIn case you encounter any issues, please turn this switch off and consider informing the author about it. Thanks.", settings.UseZoneSpecificChanges, true, function(state)
        settings.UseZoneSpecificChanges = state
        SaveSettings()
    end)

    -- DEFAULTS
    -- Define custom Restore Defaults Function. Parameters: path, overrideNativeRestoreDefaults, callback
    nativeSettings.registerRestoreDefaultsCallback("/aiTriggerOverhaul", false, function()
        applyMovementValuesToSettings(movementNoiseDefaults)
        -- UI is updated by default here
        print("AiTriggerOverhaul Info: Default values restored!")
    end)
end

function SaveSettings() 
	local validJson, contents = pcall(function() return json.encode(settings) end)
	
	if validJson and contents ~= nil then
		local updatedFile = io.open("settings.json", "w+")
		updatedFile:write(contents)
		updatedFile:close()
	end
end

function LoadSettings() 
	local file = io.open("settings.json", "r")
	if file ~= nil then
		local contents = file:read("*a")
		local validJson, savedState = pcall(function() return json.decode(contents) end)
		
		if validJson then
			file:close();
			for key, _ in pairs(settings) do
				if savedState[key] ~= nil then
					settings[key] = savedState[key]
				end
			end
		end
	end
end

-- Override redscript functions, so the Native Menu Settings can take effect
function OverrideRedscriptFunctions()
    local settingsPath = "AiTriggerOverhaul.Settings";

    Override(settingsPath, "ModIsEnabled;", function() return settings.ModIsEnabled end )
    Override(settingsPath, "GetLoudNoiseStimRange;", function() return settings.LoudNoiseStimRange end)
    Override(settingsPath, "GetCommonSoundStimRange;", function() return settings.CommonSoundStimRange end)
    Override(settingsPath, "GetInvestigateCommonSoundChance;", function() return settings.InvestigateCommonSoundChance end)
    Override(settingsPath, "GetCommonAttentionLifetime;", function() return settings.CommonAttentionLifetime end)
    Override(settingsPath, "GetUseZoneSpecificChanges;", function() return settings.UseZoneSpecificChanges end)
    Override(settingsPath, "RadiosAreLoud;", function() return settings.RadiosAreLoud end)
    Override(settingsPath, "BodyDisposalIsLoud;", function() return settings.BodyDisposalIsLoud end)

    -- Movement noises
    Override(settingsPath, "GetWalkStimRange;", function() return settings.WalkStimRange end)
    Override(settingsPath, "GetSprintStimRange;", function() return settings.SprintStimRange end)
    Override(settingsPath, "GetJumpStimRange;", function() return settings.JumpStimRange end)
    Override(settingsPath, "GetDoubleJumpStimRange;", function() return settings.DoubleJumpStimRange end)
    Override(settingsPath, "GetChargedJumpStimRange;", function() return settings.ChargedJumpStimRange end)
    Override(settingsPath, "GetRegularLandingStimRange;", function() return settings.RegularLandingStimRange end)
    Override(settingsPath, "GetHardLandingStimRange;", function() return settings.HardLandingStimRange end)
    Override(settingsPath, "GetVeryHardLandingStimRange;", function() return settings.VeryHardLandingStimRange end)
    Override(settingsPath, "GetCrouchedJumpsAreSilent;", function() return settings.CrouchedJumpsAreSilent end)
    Override(settingsPath, "GetDodgeIsSprint;", function() return settings.DodgeIsSprint end)

    Override(settingsPath, "GetStealthPerkNoiseReductionFactor;", function() return settings.StealthPerkNoiseReductionFactor end)
end