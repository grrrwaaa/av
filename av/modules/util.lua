--- A collection of highly re-usable Lua utilities

local format = string.format
local concat = table.concat
local tostring = tostring
local floor = math.floor

-- weak-valued map of objects that have a gc sentinel referencing them:
local gcmap = {}
setmetatable(gcmap, { __mode = 'v' })

--- return an object that will call func when it is garbage collected:
-- (Sentinel pattern)
-- Note: this is not necessary in Lua 5.2 where tables can have __gc metamethods
-- @param self an object to pass to this gcfunc
-- @param gcfunc a function to call
-- @return obj (for method chaining)
local function gc(self, gcfunc)
	if not gcfunc then
		gcfunc, self = self, true
	end
	assert(type(gcfunc) == "function", "gc handler must be a function")
	-- create new raw userdata with metatable:
	local gc = newproxy(true)
	-- needs to be wrapped in a Lua function:
	getmetatable(gc).__gc = function() gcfunc(self) end
	-- keep gc alive as long as self exists:
	gcmap[gc] = self
	-- return self for method chaining (also like ffi.gc)
	return self
end


-- used by conflat()
-- appends items to the rope
local function conflat_impl(rope, v, sep, ext, first)
	if type(v) == "table" then
		for i, e in ipairs(v) do 
			-- insert appropriate separator:
			if i == 1 then 
				rope[#rope+1] = first 
			else
				rope[#rope+1] = sep 
			end
			-- recurse to insert the value:
			conflat_impl(rope, e, sep and sep .. ext, ext, ext)
		end
	elseif type(v) == "function" then
		conflat_impl(rope, v(), sep, ext, first)
	elseif v ~= "nil" then
		rope[#rope+1] = tostring(v)
	end
end

--- Return a string concatenation of all elements in v
-- Similar to table.concat, however conflat also recurses to all nested tables
-- and calls tostring() on all non-table values
-- Any nested functions will also be invoked, and conflat called on their results.
-- @param v the item to concat (e.g. a list)
-- @sep a separator character between items (optional)
-- @ext an extension to the separator applied for nested sublists (optional)
-- @return string
local function conflat(v, sep, ext)
	local rope = {}
	conflat_impl(rope, v, sep, ext)
	return concat(rope)
end


--- Generate a template-filling function based on a template string
-- The template source can contain various template substitution items, indicated by the "$" character followed by a valid Lua variable name, e.g. "$foo", "$_x1", etc. 
-- A template item can optionally be terminated using "{}", in order to distinguish the item name from plain text. E.g. "$foo{}plain" defines the item "foo" followed by the string "plain".  
-- The returned function takes a Lua table as an argument. All substitution item names index corresponding fields in this table to find their data. If the data value is a table, util.conflat() is used to convert this to a string.
-- If a template item is preceded by a newline and whitespace, the newline and whitespace are repeated for all items substituted (via the argument to conflat()).
-- @param source string template source
-- @return function to apply a model
function template(source)
	return function(dict)
		-- ugh. the pattern grabs:
		-- (optional newline)(optional whitespace)$(varname)optional{}
		return (source:gsub("([\n]*)([ \t]*)%$([%a_][%w_]*)[{}]*", function(nl, ext, name)
			local sep = nl .. ext	-- put back what we took out
			-- automatic indentation only happens if newline is found:
			if #nl > 0 then
				return sep .. conflat(dict[name], sep, ext)
			else
				return sep .. conflat(dict[name])
			end
		end))
	end
end


local table_tostring
local keywords = {
	["and"] = true,       
	["break"] = true,     
	["do"] = true,        
	["else"] = true,      
	["elseif"] = true,
    ["end"] = true,       
    ["false"] = true,     
    ["for"] = true,       
    ["function"] = true,  
    ["if"] = true,
    ["in"] = true,        
    ["local"] = true,     
    ["nil"] = true,       
    ["not"] = true,       
    ["or"] = true,
    ["repeat"] = true,    
    ["return"] = true,    
    ["then"] = true,      
    ["true"] = true,      
    ["until"] = true,     
    ["while"] = true,
}

local varpat = "^[%a_][%w_]*$"
local function isvalidluavariablename(k)
	return type(k) == "string" and (k:match("^[%a_][%w_]*$") ~= nil) and not keywords[k]
end

local function isinteger(n)
	return type(n) == "number" and n == floor(n)
end


local function dict_keylist_sorter(a, b)
	local ta,tb = type(a), type(b)
	if ta == tb then
		return a < b
	else 
		return ta > tb
	end
end


local function dict_keylist_only(t, n)
	local res = {}
	for k, v in pairs(t) do
		-- skip if k is an integer from 1..n (array portion)
		if not (isinteger(k) and k > 0 and k < n) then
			res[#res+1] = k
		end
	end
	table.sort(res, dict_keylist_sorter)
	return res
end

local function dict_keylist(t)
	local res = {}
	for k, v in pairs(t) do
		res[#res+1] = k
	end
	table.sort(res, dict_keylist_sorter)
	return res
end

local function dict_keystr(k, ind)
	if isvalidluavariablename(k) then	
		return k
	elseif isinteger(k) then
		return format("%d", k)
	else
		return format("[%q]", k)
	end
end	

local function dict_valstr(v, ind, memo)
	if type(v) == "string" then	-- TODO: and no invalid chars!
		return format("%q", v)
	elseif type(v) == "table" then
		return table_tostring(v, ind, memo)
	else
		return tostring(v)
	end
end	

local function list_tostring(t, ind, ind1)
	
end

-- TODO: handle multiple references without error (but not recursion)
-- TODO: handle recursion without error
-- TODO: handle functions, etc.

table_tostring = function(t, ind, memo)
	if type(t) == "table" then
		-- memoization to trap multiple refs/recursion
		if memo[t] then 
			error("multiple references not supported") 
		end
		memo[t] = true
		-- build up the result list:
		local len = #ind
		local res = {}
		-- grab the array portion:
		for i, v in ipairs(t) do
			local s = table_tostring(v, ind, memo)
			res[i] = s
			len = len + #s + 2
		end
		local n = #res
		if n > 8 then
			-- too many to make sense of as a simple list;
			-- prefix them with index numbers:
			for i = 1, n do
				res[i] = format("[%d]=%s", i, res[i])
			end
			-- force the table to be printed multi-line:
			len = math.huge		
		end
		-- grab the dict portion:
		local keys = dict_keylist_only(t, n)
		local dres = {}
		local dlen = 0
		for i, k in ipairs(keys) do
			local s = format("%s=%s",
				dict_keystr(k, ind1),
				dict_valstr(t[k], ind1, memo)
			)
			res[#res+1] = s
			len = len + #s + 2
		end
		-- format as string:
		local ind1 = ind .. "  "
		local sep
		local pre, post
		-- print short tables on one line:
		if len > 64 then
			return format("{\n%s%s\n%s}", ind1, concat(res, ",\n"..ind1), ind)
		else
			return format("{ %s }", concat(res, ", "))
		end
		return format("{%s%s%s}", pre, concat(res, sep), post)
	else
		return tostring(t)
	end	
end

--- Return a pretty-formatted string representation of a table
-- Array portion is printed after dict portion.
-- Keys are sorted alphanumerically.
-- Could also be used as a replacement of the global tostring()
-- @param t the value (e.g. table) to print
-- @return string
local function tostring(t)
	return table_tostring(t, "", {})
end

return {
	gc = gc,
	conflat = conflat,
	template = template,
	tostring = tostring,
	
	
	keywords = keywords,
	isinteger = isinteger,
	
	-- safer alias:
	table_tostring = tostring,
}
