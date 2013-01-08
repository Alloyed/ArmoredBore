-- This looks like the source: 
-- http://twolivesleft.com/Codea/Talk/discussion/138/code-for-pretty-printing-a-table-for-example-the-table-containing-all-global-variables/p1
misc = {}
-- print contents of a table, with keys sorted. second parameter is optional, used for indenting subtables
function misc.dump(t,indent)
    local names = {}
    if not indent then indent = "" end
    for n,g in pairs(t) do
        table.insert(names,n)
    end
    table.sort(names)
    for i,n in pairs(names) do
        local v = t[n]
        if type(v) == "table" then
            if(v==t) then -- prevent endless loop if table contains reference to itself
                print(indent..tostring(n)..": &lt;-")
            else
                print(indent..tostring(n)..":")
                dump(v,indent.."   ")
            end
        else
            if type(v) == "function" then
                print(indent..tostring(n).."()")
            else
                print(indent..tostring(n)..": "..tostring(v))
            end
        end
    end
end

--handle is a bit of convenience for the receive functions in the networking code
function misc.handle(handler, handlee)
	data = {handlee()}
	while data and data[1] do
		misc.dump (data)
		handler(unpack(data))
		data = {handlee()}
	end
	if data and data[2] ~= "timeout" then
		error("Network: " .. data[2])
	end
end

return misc