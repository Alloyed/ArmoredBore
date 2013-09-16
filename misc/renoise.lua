local socket = require "socket"
local Class  = require "hump.class"
require "misc.osc"

local pass = function() return nil end

local a = {}


local RnSound = Class {}

a.Source = RnSound

function RnSound:typeOf(str)
	return str == "Object" or str == "Sound" or str == "RnSound"
end

function RnSound:type() return "RnSound" end

function RnSound:init(instr, tr)
	self.instr = instr or -1
	self.track = tr    or self.instr
end

function RnSound:play()
	udp:send(osc.encode {
		'/renoise/trigger/note_on',
		'i', self.instr, -- instrument
		'i', self.track, -- track
		'i', 60-12,         -- midi note
		'i', 127,        -- midi velocity
		} )
end

function RnSound:stop()
	udp:send(osc.encode {
		'/renoise/trigger/note_off',
		'i', self.instr, -- instrument
		'i', self.track, -- track
		'i', 60-12,         -- midi note
		} )
end

RnSound.rewind    = RnSound.stop
RnSound.pause     = RnSound.stop
RnSound.setPitch  = pass
RnSound.setVolume = pass

local sounds = {}

function a.load(addr, port)
	udp = socket.udp()
	udp:setpeername(addr or "localhost", port or 8080)
end

function a.sounds(tab)
	for fname, args in pairs(tab) do
		sounds[fname] = a.Source(unpack(args))
	end
end

function a.newSource(fname)
	return sounds[fname]
end

function a.start(s)
	s:start()
end

function a.stop(s)
	if not s then return end
	s:stop()
end

return a
