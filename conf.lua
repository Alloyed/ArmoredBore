-- Because this is in love.conf, it is officially 
--   the first thing that our app loads. This might be dangerous.
-- TODO look into cases of malformed userconfig.lua files
-- see also main.lua to see how the config gets used and saved
config = love.filesystem.load "userconfig.lua" ()

function love.conf(t)
	t.title = "GAMEPRAY"
	t.identity = "bloomy-circles"

	if config.fullscreen then
		t.screen.width, t.screen.height =
		unpack(config.fullscreenMode or config.windowedMode) -- FIXME : bad juju
		t.screen.fullscreen = true
	else
		t.screen.width, t.screen.height = unpack(config.windowedMode)
		t.screen.fullscreen = false
	end

	t.screen.vsync = true
	t.screen.fsaa = config.fsaa

	-- t.modules.joystick = false
	t.modules.physics = false
	--t.modules.audio   = false
end
