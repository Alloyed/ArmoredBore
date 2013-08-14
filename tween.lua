local Timer = require "hump.timer"

local tween = {}
-- Usage Timer.do_for( n, tween.ident(n))
function tween.ident(maxtime)
	local time = 0
	return function(dt)
		time = time + dt
		return time / maxtime, "("
	end
end

local function fold(fn, list, init)
	init = init or list[1]
	for _, v in pairs(list) do
		init = fn(init, v)
	end
	return init
end

function tween.compose2(f, g)
	return function(...)
		return f(g(...))
	end
end

function tween.accumulate(time, ...)
	local funcs = { ... }
	local fns = {tween.ident(time)}
	for i, f in ipairs( funcs ) do
		table.insert(fns, tween.compose2(f, fns[i]))
	end
	return fns[#fns]
end

function tween.newTween(time, ...)
	local value = 0
	local fns = {...}
	fns[#fns+1] = function(x) value = x end
	local acc = tween.accumulate(time, unpack(fns))
	acc(0)
	return function() return value end, acc
end

function tween.tween_for(time, ...)
	local getter, tween = tween.newTween(time, ...)
	Timer.do_for(time, tween)
	return getter
end

function tween.range(bvalue, evalue)
	local dvalue = evalue - bvalue
	return function(t) return bvalue + (dvalue * t) end
end

function tween.linear()
	return function(t) return t end
end

function tween.exp()
	return function(t) return t*t end
end

function tween.pow(n)
	return function(t) return math.pow(t, n) end
end

function tween.sin()
	return function(t) return math.sin(t * math.pi * .5) end
end

function tween.test()
	local f = {}
	f[1] = tween.accumulate(10, tween.linear())
	f[2] = tween.accumulate(10, tween.linear(), tween.exp())
	f[3] = tween.accumulate(10, tween.linear(), tween.pow(2), tween.linear())
	f[4] = tween.accumulate(10, tween.linear(), tween.range(5, 10))
	f[5] = tween.accumulate(10, tween.linear(), tween.range(6, 7))
	local ot = 0
	for t=0,10 do
		local s = t .. ""
		for _, fn in ipairs(f) do
			s = s .. '\t' .. fn(t - ot)
		end
		print(s)
		ot = t
	end
end


return tween
