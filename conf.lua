--WW = 1280
--HH = 720
WW   = 1280 * .66
HH   = 720  * .66
function love.conf(t)
	t.title = "GAMEPRAY"
	t.identity = "bloomy-circles"

	t.screen.width  = WW
	t.screen.height = HH
	t.screen.fullscreen = false
	t.screen.vsync = true
	t.screen.fsaa = 2

	--Do not edit pls
	-- t.modules.joystick = false
	t.modules.physics = false
	--t.modules.audio   = false
end
