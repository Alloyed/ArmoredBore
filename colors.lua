local function web(color)
	local r, g, b, a, tmp

	tmp = color
	a = tmp % 0x100 -- color & 0x000000FF
	tmp = math.floor(tmp / 0x100)
	b = tmp % 0x100 -- color & 0x0000FF00 >> 2
	tmp = math.floor(tmp / 0x100)
	g = tmp % 0x100 -- color & 0x00FF0000 >> 4
	tmp = math.floor(tmp / 0x100)
	r = tmp % 0x100 -- color & 0xFF000000 >> 6

	return g, b, a
end


return {
	me = {
		idle     = {web(0x0500FF)},
		move     = {web(0x0079FF)},
		cooldown = {web(0x405E80)}
	},

	you = {
		idle     = {web(0xFF9A00)},
		move     = {web(0xFFC000)},
		cooldown = {web(0x806640)}
	},

	bg = {web(0x335410)},
	ui = {0, 255, 10},
	fg = {web(0xFFFFFF)} -- FIXME: used in loads of unspecified places
}
