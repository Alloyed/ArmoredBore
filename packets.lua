
-- dkjson can't encode functions so any blanks in a packet will fire off errors
-- TODO: make actual asserts that do reflection and give nice errormsgs
local blank = function() end

local t = {}

-- search up 'an explanation' to see why args are strings
function t.command(pack)
	return pack['1']
end

-- If you want to send a json packet give a definition of it here
-- blanks must be filled before being sent obviously
local p          = {
	R_HOST        = { 'rh' },
	S_HOST        = { 'sh', hostname  = blank },
	R_JOIN        = { 'rj', hostname  = blank },
	S_JOIN        = { 'sj', "yeap" },
	R_LOBBIES     = { 'rl' },
	S_LOBBIES     = { 'sl', lobbies   = blank },
	LOBBY_CHANGED = { 'lc', lobby     = blank },
	LOBBY_READY   = { 'lr' },
	LOBBY_FULL    = { 'lf' },
}

function t.is(packet)
	return p[t.command(packet)] ~= nil
end

function t.new(ot)
	local nt = {}
	for k, v in pairs(ot) do
		nt[k] = v
	end
	setmetatable(nt, {__tostring = function(e) return e['1'] end})
	return nt
end

-------------------------------------------------------------------------------
-- So an explanation.                                                        --
-- As you can see above our packets are defined as arrays, /w optional args  --
-- being given string keys. This is illegal json so by default dkjson        --
-- converts them all to strings. Since I still like the style of that        --
-- definition, though, I've just decided to do the escaping myself and handle--
-- it in code accordingly. Writing my own encode decode wrappers, admittedly,--
-- would be much cleaner, if not simpler, so that's a FIXME.                 --
-------------------------------------------------------------------------------
for deftype, def in pairs(p) do
	local pack = {}
	for ind, val in pairs(def) do
		pack[tostring(ind)] = val
	end
	setmetatable(pack, {__tostring = function(e) return e['1'] end})
	--print(deftype, def['1'])
	t[deftype] = pack
end

table.foreach(t, print)
print("\n")

return t
