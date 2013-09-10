local Player = require "player"
local moves  = require "moves"

local SG = Class {__includes = Player}

SG.moves = {}
for k, v in pairs(moves) do
	SG.moves[k] = v
end

local Firing = Class {__includes = moves.fire}

local function sndfire()
		local snd = love.audio.newSource("snd/me.wav")
		snd:play()
end

function Firing:init(a, t)
	assert(a)
	local atype = balance.bullet
	self.t  = atype.rate * atype.number * .6
	self.a = a
	local mgun = Timer.new()
	mgun:addPeriodic(.016, function() sndfire() end, atype.number)
	self.mgun = mgun
	self:fire(-.1)
	self:fire(0)
	self:fire(.1)
end

function Firing:fire(ang)
		local me, you, atype = self.a, self.a.other, balance.bullet
		if me.ammo < atype.cost then return end
		me.ammo = me.ammo - atype.cost
		local b = Boolet(self.a)
		-- TODO: proper targeting
		b:point(you.x - me.x, you.y - me.y)
		b.vx, b.vy = lvec.mul(math.random() * .2 + .9, lvec.rotate(ang or 0, b.vx, b.vy))
end

function Firing:update(dt)
	self.t = self.t - dt

	local me = self.a
	local you = self.a.other
	local atype = balance.bullet

	self.mgun:update(dt)

	if self.t < dt then
		self.a:setmove(self.a.moves.cooldown, balance.fireCD)
	end
end

SG.moves.fire = Firing
return SG
