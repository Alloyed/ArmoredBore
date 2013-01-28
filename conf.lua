function love.conf(t)
	t.title = "press esc for console, type in help() for help"

	t.screen.width = 1024
	t.screen.height = 896
	t.screen.fullscreen = false
	t.screen.vsync = true
	t.screen.fsaa = 8
	
	--Do not edit pls
	t.modules.joystick = false
	t.modules.physics = false
end
