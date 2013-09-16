local imoves = require "moves"
local Ring  = require "hump.ringbuffer"

local Dude = Class { }
Dude.moves = setmetatable ( {}, {__index = imoves} )

function Dude:init(game)
		assert(game, "Dude has nogaem")
		self.game     = game
		self.x        = 100
		self.y        = 100
		self.cx       = 100
		self.cy       = 100
		self.joyx     = 0
		self.joyy     = 0

		self.w        = 50 -- radius
		self.segments = 33
		self.hp       = balance.health
		self.ammo     = 0
		self.reload   = Timer.new()
		self.reload:addPeriodic(balance.reloadspeed, function()
			self.ammo = math.min(self.ammo + 1, balance.maxammo)
		end)
		local cd = moves.cooldown
		self.move = cd(self, balance.initialcountdown)
		self.boolets = {}
		self.bnum = 0
		self.movebuf = {}
		self.frame = {}
end

function Dude:setmove(newmove, ...)
	if self.move and self.move.dispose then self.move:dispose() end
	self.move = newmove(self, ...)

	return self.move
end

function Dude:pushmove(newmove, ...)
	local oldmove = self.move
	assert(newmove.priority)
	assert(oldmove.priority)
	if (not oldmove) or (newmove.priority > oldmove.priority) then
		return self:setmove(newmove, ...)
	else
		self.rq = {newmove, {...}}
	end
	return nil
end

function Dude:popmove()
	if self.rq then
		self:setmove(self.rq[1], unpack(self.rq[2]))
	else
		self:setmove(self.moves.idle)
	end
	self.rq = nil
	return self.move
end

function Dude:startupdate(dt)
	self.movebuf[#self.movebuf+1] = {}
end

function Dude:update(dt)
	self.move:update(dt)
end

function Dude:predraw()
	self.move:predraw()
end

local canv = lg.newCanvas()
function Dude:draw()
	local dr = function() return self.move:draw() end
	--lg.draw(canv)
	dr()
	local oldc = lg.getCanvas()
	lg.setCanvas(canv)
	dr()
	lg.setCanvas(oldc)
end

function Dude:hurt(pain)
	self.hp = self.hp - (pain or balance.bulletdmg)
	snd = love.audio.newSource("snd/beep.wav")
	snd:setVolume(.5)
	snd:play()
	if self.hp <= 0 and not self.game.isGameOver then
		Signals.emit("gamelost", self)
	end
end

return Dude
