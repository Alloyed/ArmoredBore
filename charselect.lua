local qu = require "Quickie"
-- A character select screen
local Menu = Class {}

-- {{{ schemes
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
-- }}}

-- {{{ UI states

local function Status(status, ret)
	return function()
		qu.group.push {grow = 'down', align = {align}}
			qu.Label {text = status}
		qu.group.pop  {}
		return ret
	end
end

local function LobbyList(sock, lobbies)
	return function()
		qu.group.push {grow = 'down', align = {align}}
			qu.Label {text = "join a lobby"}
			for k, v in pairs(lobbies or {}) do
				qu.group.push {grow = 'right', size = {150}}
					qu.Label {text = tostring(v)}
					if qu.Button {text = 'join game'} and v.guest == false then
						local p = packets.new(packets.R_JOIN)
						p.hostname = k
						sock:send(json.encode(p))
					end
				qu.group.pop {}
			end
		qu.group.pop  {}
		return nil
	end
end

local function EnteredLobby(lobby, toret)
	local str = "{\n"
	table.foreach(lobby, function(k, v)
		str = str .. "    " .. tostring(k) .. "=" .. tostring(v) .. ",\n"
	end)
	str = str .. "}"
	return Status(str, lobby[toret] and control.schemes.what or nil)
end

local function Controls(sidename)
	local side = {unpack(schemes[config['default' .. sidename]])}
	local ready = false
	side[4] = sidename
	return function()
	qu.group.push {grow = 'down'}
		qu.Label {text = side[4]}
		qu.Label {text = side[2]}
		for key, scht in ipairs(schemes) do
			local sch, name, decr = unpack(scht)
			if qu.Button {text = name} then
				side[1], side[2] = sch, name -- copy to ref
				side[3] = decr
				config['default' .. sidename] = key
			end
		end
		qu.Label {text = side[3]}
		if qu.Button {text = ready and "Ready" or "Not Ready"} then
			ready = not ready
			Signals.emit(sidename .. '-ready', ready)
		end
	qu.group.pop {}
	return ready and side[1] or nil
	end
end
--}}}

-- {{{ Network stuff
local commands = setmetatable({}, {
	-- Returns the fallback command. FIXME : log a good warning
	__index = function(t, k, v)
		return function() print "Oops" end
	end,
	-- Index by packet type, not the packet table
	__newindex = function(t, k, v)
		return rawset(t, tostring(k), v)
	end,
})

commands[packets.S_HOST] = function(self, data, cid)
	self.right = Status("Waiting for players. Your lobby id is : " .. data.hostname)
end

commands[packets.S_LOBBIES] = function(self, data, cid)
	print("we get lobeats")
	for k, v in pairs(data.lobbies) do
		v = setmetatable(v, {
			__tostring = function(e)
				return "id " .. k .. ", slot is " .. (v.guest and "CLOSED" or "OPEN")
			end
		})
	end
	self.left = LobbyList(self.sock, data.lobbies)
end

commands[packets.LOBBY_FULL] = function(self, data, cid)
	assert(nil, "Lobby full.")
end

commands[packets.LOBBY_CHANGED] = function(self, data, cid)
	local show = EnteredLobby(data.lobby)
	if self.flavor == 'host' then
		self.right = show
	elseif self.flavor == 'join' then
		self.left = show
	end
end

function delegate(self)
	return function(raw, clientid)
		local data, err = json.decode(raw)
		assert(data, err)
		local key = packets.command(data)
		return commands[key](self, data, clientid)
	end
end

function initSock()
	local sock = lube.tcpClient()
	sock.handshake = balance.HANDSHAKE
	sock:setPing(true, 2, balance.PING)
	local S = balance.SERVER
	assert(sock:connect(S.addr, S.port, true))
	return sock
end

-- }}}

function Menu:enter(prev, flavor)
	self.prev = prev
	local left, right = nil, nil
	local sock = nil

	if flavor == 'host' then
		sock = initSock()
		sock.callbacks.recv = delegate(self)
		sock:send(json.encode(packets.R_HOST))

		left  = Controls "left"
		right = Status "Connected to server, waiting for host id..."
		Signals.register('left-ready', function()
			sock:send(json.encode(packets.LOBBY_READY))
		end)
	elseif flavor == 'join' then
		sock = initSock()
		sock.callbacks.recv = delegate(self)
		sock:send(json.encode(packets.R_LOBBIES))

		left = Status "Populating lobbies"
		right = Controls "right"
		Signals.register('right-ready', function()
			sock:send(json.encode(packets.LOBBY_READY))
		end)
	else
		left  = Controls "left"
		right = Controls "right"
	end

	self.sock = sock
	self.left, self.right = left, right
	self.flavor = flavor
end

function Menu:update(dt)
	local sl, sr = nil, nil
	local w = lg.getWidth()
	local n = 300
	qu.group.push {grow = 'down', pos = {10, 10}, size = {(w-20)/2}, align = {'center'}}
		qu.group.push {grow = 'right', size = {(w-20)/2, 30}}
			sl = self.left()
			sr = self.right()
		qu.group.pop {}
		if sl and sr then
			Gamestate.switch(Game(sl, sr))
		end
	qu.group.pop {}
	if self.sock then
		self.sock:update(dt)
	end
end

function Menu:draw()
	qu.core.draw()
end

function Menu:keypressed(key, uni)
	if key == 'escape' then
		Gamestate.switch(self.prev)
	end
	qu.keyboard.pressed(key, uni)
end
return Menu
