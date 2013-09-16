
local luasocket = require "socket"

local Net = Class {}

function Net:connect()
	local S = balance.SERVER
	local tcp, err = luasocket.connect(s.addr, s.port)
	if not tcp then
		return tcp, err
	end
	self.tcp = tcp
	return true
end

return Net
