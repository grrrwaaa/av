local draw2D = require "draw2D"
local audio = require "audio"
local ffi = require "ffi"
local C = ffi.C

local util = require "util"
local conflat = util.conflat
local template = util.template

local win = require "window"
win:setdim(100, 50)

local concat = table.concat
local format = string.format
local pi = math.pi
local twopi = pi * 2

local id = 0
local gensym = function(name)
	id = id + 1
	return format("%s_%d", name, id)
end

local set_mt = {}
set_mt.__index = set_mt

function set_mt:add(s, more, ...)
	if not self[s] then 
		self[#self+1] = s
		self[s] = true
	end
	if more then self:add(more, ...) end
	return self
end

function set(initial, ...)
	local s = setmetatable({}, set_mt)
	if initial then s:add(initial, ...) end
	return s
end

local rope_mt = {}
rope_mt.__index = rope_mt

function rope_mt:write(fmt, ...)
	self[#self+1] = format(fmt, ...)
	return self
end

function rope(...) 
	return setmetatable({...}, rope_mt)
end

local synthcode = template [[
	local system = ...
	local voice = assert(system.voices[$id], "voice does not exist")
	$locals
	$objects
	voice.perform = function(self, out, frames)	
		local lbuf, rbuf = unpack(out)
		$pre
		for i = 0, frames-1 do
			$statements
			lbuf[i] = lbuf[i] + $left
			rbuf[i] = rbuf[i] + $right
		end
		$post
	end
]]

local generator = {}

-- TODO: this doesn't handle multi-channel properly
local function visit(self, v)
	if type(v) == "table" then
		if self.memo[v] then
			return self.memo[v]
		elseif v.op then
			-- parse inputs first:
			local gen = assert(generator[v.op], "missing gen"..tostring(v.op))
			local out = gen(self, v)
			self.memo[v] = out
			return out
		else
			local args = {}
			for i, input in ipairs(v) do
				args[i] = visit(self, input)
			end
			return unpack(args)
		end
	else
		return tostring(v)
	end
end

function generator:Mul(node)
end

function generator:SinOsc(node)
	self.locals:add("local sin = math.sin")
	
	local p = self:member(gensym("phase"), visit(self, node[2]))
	
	local pincr = gensym("pincr")
	local o = gensym("sinosc")
	self.statements:write("local %s = %s * %f", pincr, visit(self, node[1]), twopi / audio.driver.samplerate)
	self.statements:write("%s = %s + %s", p, p, pincr)
	self.statements:write("local %s = sin(%s)", o, p)
	return o
end

function generator:Param(node)
	local name = self:member(node[1], visit(self, node[2]))
	return name
end

local Expr = {}
Expr.__index = Expr

local binops = {
	{ op = "Add", name = "add", meta = "__add", infix = "+" },
	{ op = "Sub", name = "sub", meta = "__sub", infix = "-" },
	{ op = "Mul", name = "mul", meta = "__mul", infix = "*" },
	{ op = "Div", name = "div", meta = "__div", infix = "/" },
	{ op = "Pow", name = "pow", meta = "__pow", infix = "^" },
	{ op = "Mod", name = "mod", meta = "__mod", infix = "%" },
}

for i, v in ipairs(binops) do
	Expr[v.meta] = function(a, b)
		return setmetatable({ op = v.op, a, b }, Expr)
	end
	generator[v.op] = function(self, node)
		local o = gensym(v.name)
		self.statements:write("local %s = %s %s %s", o, visit(self, node[1]), v.infix, visit(self, node[2]))
		return o
	end
end

local function Param(name, default)
	return setmetatable({ op="Param", name or gensym("param"), default or 0 }, Expr)

end

local function SinOsc(frequency, initialphase)
	return setmetatable({ op="SinOsc", frequency or 440, initialphase or 0 }, Expr)
end

local kernel_mt = {}
kernel_mt.__index = kernel_mt

function kernel_mt:member(name, init)
	local id = #self.objects + 1
	self.objects[name] = id
	self.objects:write("voice.data[%d] = %s", id, init)
	self.pre:write("local %s = self[%d]", name, id)
	self.post:write("self[%d] = %s", id, name)
	return name
end

local function Def(t)
	
	-- send to server as a re-usable def now?
	
	return function(init)
		local kernel = setmetatable({
			memo = {},
			locals = set(),	 -- max 60 upvalues
			objects = rope(),	-- max table constructor items?
			statements = rope(), -- max 200 locals
			pre = rope(),
			post = rope(),
		}, kernel_mt)
		
		local l, r = visit(kernel, t)
		kernel.left = l or 0
		kernel.right = r or kernel.left
		
		local id = audio.add()
		kernel.id = id
		local code = synthcode(kernel)
		--print(code)
		audio.setcode(code)
		
		if init then
			for k, v in pairs(init) do
				audio.setparam(id, kernel.objects[k], v)
			end
		end
		return kernel
	end
end

local wobble = Def{ 
	SinOsc((110 * Param("register", 4)) + SinOsc(Param("rate")) * Param("width", 10)) * 0.01 
}

local synths = {}
for i = 1, 50 do	
	local v = wobble{
		width = math.random()*100,
		rate = math.random(10),
	}
	synths[v] = true
end

function draw()	
	for x = 0, 1, 0.01 do
		local y = math.random() * 0.5
		draw2D.line(x, 0.5 + y, x, 0.5 - y)
	end
	for synth in pairs(synths) do	
		if math.random() < 0.01 then
			audio.setparam(synth.id, synth.objects.register, math.random(10))
		end
		if math.random() < 0.0001 then
			audio.remove(synth.id)
			synths[synth] = nil
		end
	end
end
