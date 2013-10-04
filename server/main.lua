if love then love.event.push('quit') return end

package.path = '../?/init.lua;../?.lua;' .. package.path
--init
log = function()end info = function()end dbg = function()end

--uncomment to disable
log  = print
info = print
dbg  = print

Class   = require "hump.class"
Timer   = require "hump.timer"
json    = require "misc.dkjson"
luasock = require "socket"
lube    = require "lube"
balance = require "balance"
packets  = require "packets"

sleep = luasock.sleep

tcp = nil

local function tail(data)
	local the_tail = {}
	for i, v in ipairs(data) do
		the_tail[i-1] = v
	end
	the_tail[0] = nil
	return unpack(the_tail)
end

local commands = setmetatable({}, {
	__index = function(t, k, v)
		return function() print "Oops" end -- the fallback command
	end,
	__newindex = function(t, k, v)
		print(k[1])
		return rawset(t, tostring(k), v)
	end,
})

players = {}
lobbies = {}

commands[packets.R_HOST] = function(data, cid)
	local tosend = packets.new(packets.S_HOST)
	tosend.hostname = #lobbies+1

	lobbies[tosend.hostname] = {
		key                   = tosend.hostname,
		host                  = cid,
		guest                 = nil,
		hready                = false,
		gready                = false,
	}
	players[cid] = lobbies[tosend.hostname]
	tcp:send(json.encode(tosend), cid)
	info("lobby " .. tosend.hostname .. " created.")
end

function packLobby(lobby)
		local packedLobby      = {}
		packedLobby.host       = lobby.host and true or false
		packedLobby.guest      = lobby.guest and true or false
		packedLobby.hready     = lobby.hready
		packedLobby.gready     = lobby.gready
		return packedLobby
end

commands[packets.R_LOBBIES] = function(data, cid)
	local tosend = packets.new(packets.S_LOBBIES)
	tosend.lobbies = {}
	for id, lobby in pairs(lobbies) do
		tosend.lobbies[id] = packLobby(lobby)
	end
	tcp:send(json.encode(tosend), cid)
	dbg("lobby list sent to " .. tostring(cid))
end

commands[packets.R_JOIN] = function(data, cid)
	local lobbyid = data.hostname
	local lobby = lobbies[lobbyid]
	if lobby.guest then tcp:send(json.encode(packets.LOBBY_FULL), cid) return end
	lobby.guest = cid
	players[cid] = lobby
	local tosend = packets.LOBBY_CHANGED
	tosend.lobby = packLobby(lobby)
	tcp:send(json.encode(tosend), lobby.host)
	tcp:send(json.encode(tosend), lobby.guest)
end


function delegate(raw, clientid)
	local data, err = json.decode(raw)
	assert(data, err)
	local key = packets.command(data)
	return commands[key](data, clientid)
end

function disconnect(cid)
	info(tostring(cid) .. " disconnected")
	local lobby = players[cid]
	if lobby == nil then return end
	if lobby.host == cid then
		lobbies[lobby.key] = nil
		info("Lobby " .. lobby.key .. " has been removed")
	else
		lobby.guest = nil
	end
	players[cid] = nil
end

function init()
	tcp = lube.tcpServer()
	tcp.handshake = balance.HANDSHAKE
	tcp:setPing(true, 4, balance.PING)
	tcp:listen(balance.SERVER.port)
	log("Server listening on " .. balance.SERVER.port)
	tcp.callbacks.recv = delegate
	tcp.callbacks.disconnect = disconnect
end

function update(dt)
	tcp:update(dt)
	Timer.update(dt)
end

function main()
	local playing = true

	init()

	while playing do
		sleep(1/60) -- not "accurate" per se but idgaf
		playing = not update(1/60) -- nil(ie the default) continues cause of the not
	end
end


main(...)
