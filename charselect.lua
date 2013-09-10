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

schemes = {}

for i=1, ljoy.getNumJoysticks() do
	table.insert(schemes, function()
		return function(pl)
				return control.schemes.joypad(pl, 'l', 'l', i)
		end, "Controller " .. i .. "(left)"
	end)
	table.insert(schemes, function()
		return function(pl)
			return control.schemes.joypad(pl, 'r', 'r', i)
 		end, "Controller " .. i .. "(right)"
	end)
	table.insert(schemes, function()
		return function(pl)
			return control.schemes.joypad(pl, 'l', 'r', i)
		end, "Controller " .. i .. "(full)"
	end)
end

table.insert(schemes, function()
	return control.schemes.moose,
	"Mouse",
	"Move with mouse, LMB to dodge, RMB to fire"
end)

table.insert(schemes, function()
	return control.schemes.what, "AI", "get rekt"
end)

table.insert(schemes, function()
	return function(pl)
		return control.schemes.replay(pl, "you")
	end,
	"Replay as Player 1",
	"Sit back and watch!"
end)

table.insert(schemes, function()
	return function(pl)
		return control.schemes.replay(pl, "me")
	end,
	"Replay as Player 2",
	"Sit back and watch!"
end)

table.insert(schemes, function()
	return control.schemes.numpad,
	"Keyboard (fag)",
	"Arrow keys to move, X to dodge, Z to fire"
end)

local left  = {schemes[1]()}
local right = {schemes[2]()}
left[4] = "Player 1 (YELLOW)"
right[4] = "Player 2 (BLUE)"

local function side(side, align)
	qu.group.push {grow = 'down', align = {align}}
		qu.Label {text = side[4]}
		qu.Label {text = side[2]}
		for _, fn in ipairs(schemes) do
			local sch, name, decr = fn()
			if qu.Button {text = name} then
				side[1], side[2] = sch, name -- copy to ref
				if decr then
					side[3] = decr
				end
			end
		end
		qu.Label {text = side[3]}
	qu.group.pop {}
end

function Menu:update()
	local w = lg.getWidth()
	local n = 300
	qu.group.push {grow = 'down', pos = {10, 10}, align = {'center'}}
		qu.group.push {grow = 'right', size = {(w-20)/2, 30}}
			side(left, 'left')
			side(right, 'right')
		qu.group.pop {}
		if qu.Button {text = "Just Like Play Game", align = {'center'}, size = {'tight'}} then
			Gamestate.switch(Game(), left[1], right[1])
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
