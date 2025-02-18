SystemClock = {}
SystemClock.path = SMODS.current_mod.path
SystemClock.config = SMODS.current_mod.config
local mod_instance = SMODS.current_mod

SMODS.Atlas({
	key = 'modicon',
	path = 'icon.png',
	px = 32,
	py = 32
})

SMODS.current_mod.description_loc_vars = function(self)
	return {
		scale = 1.2,
		background_colour = G.C.CLEAR
	}
end

SMODS.load_file('clock_ui.lua')()
SMODS.load_file('config_tab.lua')()
SMODS.load_file('MoveableContainer.lua')()

SystemClock.CLOCK_FORMATS = {
	{ '%I:%M %p',    true },
	{ '%I:%M',       true },
	{ '%H:%M',       false },
	{ '%I:%M:%S %p', true },
	{ '%I:%M:%S',    true },
	{ '%H:%M:%S',    false }
}

SystemClock.COLOUR_REFS = {
	'WHITE', 'JOKER_GREY', 'GREY', 'L_BLACK', 'BLACK',
	'RED', 'SECONDARY_SET.Voucher', 'ORANGE', 'GOLD',
	'GREEN', 'SECONDARY_SET.Planet', 'BLUE', 'PERISHABLE', 'BOOSTER',
	'PURPLE', 'SECONDARY_SET.Tarot', 'ETERNAL', 'EDITION',
	'DYN_UI.MAIN', 'DYN_UI.DARK'
}

SystemClock.TEXT_SIZES = {
	0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0,
	1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0
}
SystemClock.FORMAT_EXAMPLES = {}
SystemClock.PRESET_OPTIONS = {}

SystemClock.time = ''
SystemClock.current = {}
SystemClock.indices = {}
SystemClock.colours = {}
SystemClock.exampleTime = os.time({ year = 2015, month = 10, day = 21, hour = 16, min = 29, sec = 33 })
SystemClock.drawAsPopup = false

local function index_of(table, val)
	if not val then return nil end
	for i, v in ipairs(table) do
		if v == val then return i end
	end
	return nil
end

function SystemClock.update_config_version()
	if SystemClock.config.clockColourIndex then
		sendInfoMessage("Transferring config settings (v1 -> v2)", 'SystemClock')
		SystemClock.config.clockTextColourRef = SystemClock.COLOUR_REFS[SystemClock.config.clockColourIndex]
		SystemClock.config.clockTextColourIndex = SystemClock.config.clockColourIndex
		SystemClock.config.clockBackColourRef = 'DYN_UI.MAIN'
		SystemClock.config.clockColourIndex = nil
		SystemClock.config.clockColour = nil

		SystemClock.config.clockConfigVersion = 2
	end

	if SystemClock.config.clockConfigVersion == 2 then
		sendInfoMessage("Transferring config settings (v2 -> v3)", 'SystemClock')
		SystemClock.config.clockPresets[5].format = SystemClock.config.clockTimeFormatIndex
		SystemClock.config.clockPresets[5].style = SystemClock.config.clockStyleIndex
		SystemClock.config.clockPresets[5].size = SystemClock.config.clockTextSize
		SystemClock.config.clockPresets[5].colours.text = SystemClock.config.clockTextColourRef
		SystemClock.config.clockPresets[5].colours.back = SystemClock.config.clockBackColourRef
		SystemClock.config.clockPresets[5].position.x = SystemClock.config.clockX
		SystemClock.config.clockPresets[5].position.y = SystemClock.config.clockY
		SystemClock.config.clockPresetIndex = 5

		SystemClock.config.clockTimeFormatIndex = nil
		SystemClock.config.clockStyleIndex = nil
		SystemClock.config.clockTextColourIndex = nil
		SystemClock.config.clockTextColourRef = nil
		SystemClock.config.clockBackColourIndex = nil
		SystemClock.config.clockBackColourRef = nil
		SystemClock.config.clockTextSize = nil
		SystemClock.config.clockTextSizeIndex = nil
		SystemClock.config.clockX = nil
		SystemClock.config.clockY = nil

		SystemClock.config.clockConfigVersion = 3
	end
end

function SystemClock.get_colour_from_ref(ref)
	if not ref then return nil end

	local depth = 0
	local colour = G.C
	for objName in ref:gmatch("[^%.]+") do
		colour = colour[objName]
		depth = depth + 1
		if depth > 2 or not colour then
			return nil
		end
	end
	return type(colour) == 'table' and colour
end

function SystemClock.assign_clock_colours()
	local textColour = SystemClock.get_colour_from_ref(SystemClock.current.colours.text)
	local backColour = SystemClock.get_colour_from_ref(SystemClock.current.colours.back)
	local shadowColour = darken(backColour, 0.3)

	SystemClock.colours = {
		text = textColour,
		back = backColour,
		shadow = shadowColour
	}

	return SystemClock.colours
end

function SystemClock.init_config_preset(presetIndex)
	presetIndex = presetIndex or SystemClock.config.clockPresetIndex
	SystemClock.config.clockPresetIndex = presetIndex

	SystemClock.current = SystemClock.config.clockPresets[presetIndex]
	SystemClock.indices.format = SystemClock.current.format or 1
	SystemClock.indices.style = SystemClock.current.style or 1
	SystemClock.indices.size = index_of(SystemClock.TEXT_SIZES, SystemClock.current.size) or 1
	SystemClock.indices.textColour = index_of(SystemClock.COLOUR_REFS, SystemClock.current.colours.text) or 1
	SystemClock.indices.backColour = index_of(SystemClock.COLOUR_REFS, SystemClock.current.colours.back) or 1
	SystemClock.assign_clock_colours()
end

function SystemClock.get_formatted_time(formatRow, time, forceLeadingZero, hour_offset)
	formatRow = formatRow or SystemClock.CLOCK_FORMATS[SystemClock.indices.format]
	if hour_offset then
		if time == nil then
			time = os.time()
		end
		time = time + (hour_offset * 3600)
	end
	local formatted_time = os.date(formatRow[1], time)
	if not forceLeadingZero and formatRow[2] then
		formatted_time = tostring(formatted_time):gsub("^0", "")
	end
	return formatted_time
end

function SystemClock.generate_example_time_formats()
	for i, formatRow in ipairs(SystemClock.CLOCK_FORMATS) do
		SystemClock.FORMAT_EXAMPLES[i] = SystemClock.get_formatted_time(formatRow, SystemClock.exampleTime)
	end
end

SystemClock.update_config_version()
SystemClock.init_config_preset()
SystemClock.generate_example_time_formats()

local game_update_ref = Game.update
function SystemClock.hook_game_update(state)
	if state == false then
		Game.update = game_update_ref
	else
		function Game:update(dt)
			game_update_ref(self, dt)
			SystemClock.update(dt)
		end
	end
end

local game_start_run_ref = Game.start_run
function Game:start_run(args)
	game_start_run_ref(self, args)
	SystemClock.hook_game_update(true)
	SystemClock.reset_clock_ui()
end

local g_funcs_exit_mods_ref = G.FUNCS.exit_mods
function G.FUNCS.exit_mods(e)
	SystemClock.set_popup(false)
	g_funcs_exit_mods_ref(e)
end

local g_funcs_mods_button_ref = G.FUNCS.mods_button
function G.FUNCS.mods_button(e)
	SystemClock.set_popup(false)
	g_funcs_mods_button_ref(e)
end

local g_funcs_change_tab_ref = G.FUNCS.change_tab
function G.FUNCS.change_tab(e)
	if e and e.config and e.config.id == 'tab_but_' .. mod_instance.id then
		SystemClock.set_popup(false)
	end
	g_funcs_change_tab_ref(e)
end

local g_funcs_set_Trance_font = G.FUNCS.set_Trance_font
function G.FUNCS.set_Trance_font(...)
	if g_funcs_set_Trance_font then
		local ret = { g_funcs_set_Trance_font(...) }
		SystemClock.reset_clock_ui()
		return unpack(ret)
	end
end

function SystemClock.update(dt)
	SystemClock.time = SystemClock.get_formatted_time(nil, nil, false, SystemClock.config.hourOffset)

	if SystemClock.indices.style == 5 and SystemClock.indices.backColour > 17 then
		SystemClock.colours.shadow[1] = SystemClock.colours.back[1]*(0.7)
		SystemClock.colours.shadow[2] = SystemClock.colours.back[2]*(0.7)
		SystemClock.colours.shadow[3] = SystemClock.colours.back[3]*(0.7)
	end

	if G.STAGE ~= G.STAGES.RUN then
		SystemClock.hook_game_update(false)
	end
end

function SystemClock.set_popup(state, forceReset)
	if forceReset or SystemClock.drawAsPopup ~= state then
		SystemClock.drawAsPopup = state
		SystemClock.reset_clock_ui()
	end
end

function SystemClock.save_config()
	if not (SMODS.save_mod_config(mod_instance)) then
		sendErrorMessage("Failed to perform a manual mod config save", 'SystemClock')
	end
end

SystemClock.callback_clock_visibility = function()
	SystemClock.hook_game_update(SystemClock.config.clockVisible)
	SystemClock.reset_clock_ui()
end

G.FUNCS.sysclock_change_clock_preset = function(e)
	SystemClock.init_config_preset(e.to_key)
	SystemClock.reset_clock_ui()
	SystemClock.update_config_ui()
end

G.FUNCS.sysclock_default_current_preset = function(e)
	SystemClock.config.clockPresets[SystemClock.config.clockPresetIndex] = {}
	SystemClock.save_config()
	local loaded_config = SMODS.load_mod_config(mod_instance)
	if loaded_config then
		SystemClock.config.clockPresets = loaded_config.clockPresets
	end
	SystemClock.init_config_preset()
	SystemClock.reset_clock_ui()
	SystemClock.update_config_ui()
end

G.FUNCS.sysclock_change_clock_time_format = function(e)
	SystemClock.indices.format = e.to_key
	SystemClock.current.format = SystemClock.indices.format
	SystemClock.reset_clock_ui()
end

G.FUNCS.sysclock_change_clock_style = function(e)
	SystemClock.indices.style = e.to_key
	SystemClock.current.style = SystemClock.indices.style
	SystemClock.reset_clock_ui()
end

G.FUNCS.sysclock_change_clock_text_colour = function(e)
	SystemClock.indices.textColour = e.to_key
	local textColourRef = SystemClock.COLOUR_REFS[e.to_key]
	SystemClock.current.colours.text = textColourRef
	SystemClock.reset_clock_ui()
end

G.FUNCS.sysclock_change_clock_back_colour = function(e)
	SystemClock.indices.backColour = e.to_key
	local backColourRef = SystemClock.COLOUR_REFS[e.to_key]
	SystemClock.current.colours.back = backColourRef
	SystemClock.reset_clock_ui()
end

G.FUNCS.sysclock_change_clock_size = function(e)
	SystemClock.indices.size = e.to_key
	SystemClock.current.size = e.to_val
	SystemClock.reset_clock_ui()
end

G.FUNCS.sysclock_set_hud_position_x = function(e)
	local x = e.ref_table[e.ref_value]
	if G.HUD_clock then
		G.HUD_clock.T.x = x
	end
	SystemClock.current.position.x = x
end

G.FUNCS.sysclock_set_hud_position_y = function(e)
	local y = e.ref_table[e.ref_value]
	if G.HUD_clock then
		G.HUD_clock.T.y = y
	end
	SystemClock.current.position.y = y
end
