local qu = require "Quickie"
-- A character select screen
local Menu = Class {}

local function wrap(fn, ...)
	local orig_args = {...}
	return function(...)
		local args = {} -- eww imperative arg collection
		for _, a in ipairs(orig_args) do
			table.insert(args, a)
		end
		for _, a in ipairs({...}) do
			table.insert(args, a)
		end
		return fn(unpack(args))
	end
end

schemes = setmetatable( {}, {
	__newindex = function(t, k, v)
		rawset(t, k, v)
		rawset(t, #t+1, v)
	end
})

schemes ['mouse'] = {
	control.schemes.moose,
	"Mouse",
	"Move with mouse, LMB to dodge, RMB to fire"
}

schemes ['ai'] = {
	control.schemes.what,
	"AI",
	"get rekt"
}

local function jn(joynum, joytype)
	return string.format("joy-%d-%s", joynum, joytype)
end

for i=1, ljoy.getNumJoysticks() do
	schemes [jn(i, 'l')] = {
		function(pl)
				return control.schemes.joypad(pl, 'l', 'l', i)
		end,
		"Controller " .. i .. "(left)",
		"Move with the left stick, LB to dodge, LT to fire",
	}

	schemes [jn(i, 'r')] = {
		function(pl)
			return control.schemes.joypad(pl, 'r', 'r', i)
 		end, "Controller " .. i .. "(right)",
		"Move with the right stick, RB to dodge, RT to fire"
	}

	schemes [jn(i, 'c')] = {
		function(pl)
			return control.schemes.joypad(pl, 'l', 'r', i)
		end, "Controller " .. i .. "(full)",
		"Move with the left stick, RB to dodge, RT to fire (FIXME)"
	}
end

schemes ['replay-you'] = {
	function(pl)
		return control.schemes.replay(pl, "you")
	end,
	"Replay as Player 1",
	"Sit back and watch!"
}

schemes ['replay-me'] = {
	function(pl)
		return control.schemes.replay(pl, "me")
	end,
	"Replay as Player 2",
	"Sit back and watch!"
}

schemes ['keyboard'] = {
	control.schemes.numpad,
	"Keyboard (fag)",
	"Arrow keys to move, X to dodge, Z to fire"
}

local left  = {unpack(schemes[config.defaultleft])}
local right = {unpack(schemes[config.defaultright])}
left[4]  = "Player 1 (YELLOW)"
right[4] = "Player 2 (BLUE)"

function pairsByKeys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

local function controls(side, align)
	qu.group.push {grow = 'down', align = {align}}
		qu.Label {text = side[4]}
		qu.Label {text = side[2]}
		for key, scht in ipairs(schemes) do
			local sch, name, decr = unpack(scht)
			if qu.Button {text = name} then
				side[1], side[2] = sch, name -- copy to ref
				side[3] = decr
				config['default' .. align] = key
			end
		end
		qu.Label {text = side[3]}
	qu.group.pop {}
end

function Menu:enter(prev, flavor)
	self.ready = true
end

function Menu:update()
	local w = lg.getWidth()
	local n = 300
	qu.group.push {grow = 'down', pos = {10, 10}, align = {'center'}}
		qu.group.push {grow = 'right', size = {(w-20)/2, 30}}
			controls(left, 'left')
			controls(right, 'right')
		qu.group.pop {}
		if qu.Button {text = self.ready and "Just Like Play Game" or "Not Ready",
			           align = {'center'}, size = {'tight'}} then
			Gamestate.switch(Game(left[1], right[1]))
		end
	qu.group.pop {}
end

function Menu:draw()
	qu.core.draw()
end

function Menu:keypressed(key, uni)
	qu.keyboard.pressed(key, uni)
end
return Menu
