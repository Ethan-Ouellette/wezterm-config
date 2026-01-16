-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 12
-- config.font = wezterm.font({
-- 	family = "JetBrains Mono",
-- 	harfbuzz_features = {
-- 		"calt=0",
-- 		"clig=0",
-- 		"liga=0",
-- 	},
-- })

-- color scheming
-- The set of schemes that we like and want to put in our rotation
local schemes = { "Abernathy" }
-- for name, scheme in pairs(wezterm.get_builtin_color_schemes()) do
-- 	table.insert(schemes, name)
-- end

wezterm.on("window-config-reloaded", function(window, pane)
	math.randomseed(os.time())
	-- If there are no overrides, this is our first time seeing
	-- this window, so we can pick a random scheme.
	if not window:get_config_overrides() then
		-- Pick a random scheme name
		local scheme = schemes[math.random(#schemes)]
		window:set_config_overrides({
			color_scheme = scheme,
		})
	end
end)

-- config.color_scheme = "Wez"
-- config.window_background_opacity = 0.9
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false

-----------
-- Keymaps
-----------
config.leader = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 2000,
}

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

local function scrollback_or_send(key, scroll_dir)
	return {
		key = key,
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			if is_vim(pane) then
				-- Forward Ctrl+<key> to Neovim
				window:perform_action(act.SendKey({ key = key, mods = "CTRL" }), pane)
			else
				-- Scroll terminal scrollback
				window:perform_action(act.ScrollByPage(scroll_dir), pane)
			end
		end),
	}
end

config.keys = {
	{
		key = "[",
		mods = "LEADER",
		action = act.ActivateCopyMode,
	},
	{
		key = "c",
		mods = "LEADER",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	-- move between split panes
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	-- resize panes
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
	{
		key = "h",
		mods = "CMD|SHIFT",
		action = act.ActivateTab(0),
	},
	{
		key = "j",
		mods = "CMD|SHIFT",
		action = act.ActivateTab(1),
	},
	{
		key = "k",
		mods = "CMD|SHIFT",
		action = act.ActivateTab(2),
	},
	{
		key = "l",
		mods = "CMD|SHIFT",
		action = act.ActivateTab(3),
	},
	{
		key = "n",
		mods = "CMD|SHIFT",
		action = act.ActivateTabRelative(1),
	},
	{
		key = "p",
		mods = "CMD|SHIFT",
		action = act.ActivateTabRelative(-1),
	},
	scrollback_or_send("u", -0.5),
	scrollback_or_send("d", 0.5),
}

-- Finally, return the configuration to wezterm:
return config
