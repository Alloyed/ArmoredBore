local Timer = require "hump.timer"

local tween = {}
-- Usage Timer.do_for( n, tween.ident(n))
function tween.ident(maxtime)
	local time = 0
	return function(dt)
		time = time + dt
		return time / maxtime
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
		print(i)
		table.insert(fns, function(...) return f(fns[i](...)) end)
	end
	return fns[#fns]
end

function tween.newTween(time, ...)
	local value = 0
	-- this would be 100% illegal if it were declaration instead of application
	-- /me sighs
	local acc = tween.accumulate(time, ..., function(x) value = x end)
	return function() return value end, acc
end

--FIXME : only tween.ident tween.range seems to have an effect in use
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

return tween
