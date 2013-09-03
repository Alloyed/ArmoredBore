function love.conf(t)
	t.title = "i sort of wish this was a mech game but it isn't"
	t.identity = "mech"

	--t.screen.width = 1280
	--t.screen.height = 720
	t.screen.width  = 1280 * .66
	t.screen.height = 720  * .66
	t.screen.fullscreen = false
	t.screen.vsync = true
	t.screen.fsaa = 4

	--Do not edit pls
	-- t.modules.joystick = false
	t.modules.physics = false
	--t.modules.audio   = false
end
