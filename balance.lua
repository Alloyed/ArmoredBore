-- Put any constants that might need to be tweaked here
return {
	margin = 210,

	HANDSHAKE = 'hs',
	PING      = 'ping~',
	-- SERVER = {addr = '192.241.134.64', port = 64083,},
	SERVER    = {addr = '127.0.0.1',      port = 64083,},

	--room = {0, 0, 2560, 1440},
	room = {0, 0, 1920, 1080},

	bullet         = {
		speed       = 15,
		dmg         = 1,
		cost        = 1,
		rate        = .08,
		size        = 10,
		number      = 3,
		decay       = 4, -- s
		falloffTime = 4, -- ie. no falloff
	},

	powerupsize = 40,

	maxammo     = 9,
	reloadspeed = .3,
	rolldmg     = 15,
	fireCD      = .01,

	dashradius  = 200,
	dashCD      = 0, -- unimplemented

	health = 15, -- initial health that is
	iframes = false, -- unimplemented
	initialcountdown = 3, -- The countdown timer at the beginning of the game
	roundtime = 60, -- seconds
	vidya = "video game",
}
