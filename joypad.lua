local joyh = nil

if string.match(love._os, "TODO") then
	joyh = require "XInput"
else
	joyh = love.joystick
end

local joypad    = {}
joypad.triggers = {}
joypad.sticks   = {}

joypad.lastTriggers = {}
joypad.lastHats     = {}
joypad.lastBtns     = {}

function joypad.newStick(joynum, axisx, axisy)
	joypad.sticks[#joypad.sticks + 1] = {joynum, axisx, axisy}
	return #joypad.sticks
end

function joypad.newTrigger(joynum, axis, threshold)
	joypad.triggers[#joypad.triggers + 1] = {joynum, axis, threshold}
	return #joypad.triggers
end

function joypad.isDown(joynum, btn)
	return joyh.isDown(joynum, btn)
end

function joypad.getStick(stick_id)
	local jn, ax, ay = unpack( joypad.sticks[stick_id] )
	return joyh.getAxis(jn, ax), joyh.getAxis(jn, ay)
end

function joypad.getTrigger(trigger_id, snap)
	snap = snap or false -- TODO: snapping
	local jn, axis, thres = unpack( joypad.triggers[trigger_id] )
	return joyh.getAxis(jn, axis)
end

function joypad.getHat(joynum, hat)
	return joyh.getHat(joynum, hat)
end

function joypad.getHatAsStick(joynum, hat)
	local hat = joypad.getHat(joynum, hat)
	local x, y = 0, 0
	if     string.match(hat, 'c') then return 0, 0 end

	if     string.match(hat, 'u') then y = -1
	elseif string.match(hat, 'd') then y =  1 end

	if     string.match(hat, 'l') then x = -1
	elseif string.match(hat, 'r') then x =  1 end

	-- users can normalize themselves
	return x, y
end

function joypad.getButtons(joynum)
	local i = 0
	local max = joyh.getNumButtons(joynum)
	return function()
		i = i + 1
		if i > max then return nil end
		return i, joypad.isDown(joynum, i)
	end
end

function joypad.getAxes(joynum)
	local i = 0
	local max = joyh.getNumAxes(joynum)
	return function()
		i = i + 1
		if i > max then return nil end
		return i, joyh.getAxis(joynum, i)
	end
end

function joypad.load(fname)
end

function joypad.init()
	print("hi")
end

local function to_btn_id(jnum, bnum)
	return (jnum * 64) + bnum
end

local function from_btn_id(id)
	local jnum = math.floor(id / 64)
	return jnum, id - jnum
end

function joypad.update(dt)
	if joyh.update then
		joyh.update()
	end
	for joynum=1, joyh.getNumJoysticks() do
		-- Buttons
		for n, btn in joypad.getButtons(joynum) do
			local id = to_btn_id(joynum, n)
			-- The `or false` catches the initial state
			if btn ~= (joypad.lastBtns[id] or false) then
				if btn == true and joypad.buttonpressed then
					joypad.buttonpressed(joynum, n)
				elseif btn == false and joypad.buttonreleased then
					joypad.buttonreleased(joynum, n)
				end
			end
			joypad.lastBtns[id] = btn
		end
		-- Triggers
	end
end

function joypad.getCallbacks(from)
	from = from or {}
	for _, cbackname in ipairs(joypad.callbacks) do
		joypad[cbackname] = from[cbackname]
	end
end

joypad.callbacks = {
	"buttonpressed",  -- (joystick, button_number)
	"buttonreleased", -- (joystick, button_number)
	"hatchanged",     -- (joystick, hat_number, newValue)
	"triggeron",      -- (trigger_id)
	"triggeroff",     -- (trigger_id)
}

return joypad
