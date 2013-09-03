-- Put any constants that might need to be tweaked here
return {
	margin = 210,

	--room = {0, 0, 2560, 1440},
	room = {0, 0, 1920, 1080},

	bullet = {
		speed = 15,
		dmg = 1,
		cost = 20,
		rate = .08,
		size = 10,
		number = 3,
		decay = 10 -- s
	},

	maxammo = 180,
	rolldmg = 15,
	fireCD = .01,

	dashradius = 200,
	dashCD = 0, -- unimplemented

	health = 15, -- initial health that is
	iframes = false, -- unimplemented
	initialcountdown = 3, -- The countdown timer at the beginning of the game
	vidya = "video game"
}
