-- Mod Settings struct
local settings = {
    ModIsEnabled = true,
    LoudNoiseStimRange = 14.0,
    CommonSoundStimRange = 7.0,
    InvestigateCommonSoundChance = 0.25,
    CommonAttentionLifetime = 2.0,
    UseZoneSpecificChanges = true,
    RadiosAreLoud = true,
    BodyDisposalIsLoud = true,
    SprintNoiseStimRange = 12.0,
    SprintNoisePerkReductionFactor = 0.15
}

-- Init Native Settings UI
registerForEvent("onInit", function()
    local nativeSettings = GetMod("nativeSettings") -- Get a reference to the nativeSettings mod

    if nativeSettings then
        LoadSettings()
        BuildSettingsMenu(nativeSettings)
        OverrideRedscriptFunctions()
    else
        print("Error: NativeSettings not found! Continuing with default settings.")
        return
    end
end)

function BuildSettingsMenu(nativeSettings)
    nativeSettings.addTab("/aiTriggerOverhaul", "AI Trigger Overhaul")

    nativeSettings.addSubcategory("/aiTriggerOverhaul/mainSwitch", "Main Switch")

    -- path, label, desc, currentValue, defaultValue, callback
    nativeSettings.addSwitch("/aiTriggerOverhaul/mainSwitch", "Enable Mod", "If the switch is off, all changes of this mod are bypassed.", settings.ModIsEnabled, true, function(state)
        settings.ModIsEnabled = state
        SaveSettings()
    end)

    -- STIM RANGES
    nativeSettings.addSubcategory("/aiTriggerOverhaul/stimRanges", "Stimuli Ranges")

    -- path, label, desc, min, max, step, format, currentValue, defaultValue, callback
    nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimRanges", "Loud Noises", "The range of unusual and loud sounds, like players demolishing a locked door with brute force.", 0, 28, 0.5, "%.1f", settings.LoudNoiseStimRange, 14.0, function(state)
        settings.LoudNoiseStimRange = state
        SaveSettings()
    end)

    nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimRanges", "Common Sounds", "The range of everyday stimuli like the sound of an opening door. These will catch the enemy's attention for a short time, but won't turn them hostile on their own.", 0, 14, 0.5, "%.1f", settings.CommonSoundStimRange, 7.0, function(state)
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

    nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimRanges", "Sprint Noise", "The loudness of the player's footsteps while sprinting, dashing or sliding. These might alert enemies in the vicinity.\n\nThe Vanilla value is around 6.0 (estimate).", 0, 24, 0.5, "%.1f", settings.SprintNoiseStimRange, 12.0, function(state)
        settings.SprintNoiseStimRange = state
        SaveSettings()
    end)

    nativeSettings.addRangeFloat("/aiTriggerOverhaul/stimRanges", "Sprint Noise Perk Reduction Factor", "The 'Cool' perks Feline Footwork and each level of Ninjutsu can reduce a player's sprinting noise by the specified factor.\nThis factor counts once for each of the mentioned perks that the player has unlocked.\n\nExamples:\nA factor of 0.1 with Feline Footwork plus Ninjutsu Level 2 will result in a noise reduction of 3 * 0.1 = 0.3 -> 30%.\n\nA factor of 0.0 will disable the perk-based reduction altogether.\n\nA factor of 0.25 with all 4 perks unlocked will result in perfectly silent sprinting.", 0, 0.25, 0.01, "%.2f", settings.SprintNoisePerkReductionFactor, 0.15, function(state)
        settings.SprintNoisePerkReductionFactor = state
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
    Override(settingsPath, "GetSprintNoiseStimRange;", function() return settings.SprintNoiseStimRange end)
    Override(settingsPath, "GetSprintNoisePerkReductionFactor;", function() return settings.SprintNoisePerkReductionFactor end)
end