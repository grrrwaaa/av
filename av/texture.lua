local gl = require "gl"
local glu = require "glu"

local texture = {}
texture.__index = texture

local function new(width, height, numtextures) 
	return setmetatable({
	
		target = gl.TEXTURE_2D,
		magfilter = gl.LINEAR,
		minfilter = gl.LINEAR_MIPMAP_LINEAR,
		clamp = gl.CLAMP_TO_EDGE,
		internalformat = gl.RGBA,
		format = gl.RGBA,
		type = gl.UNSIGNED_BYTE,
		data = nil,
		dirty = true,
		
		-- assume 2D for now
		width = width or 512,
		height = height or 512,
		
		numtextures = numtextures or 1,
		currenttexture = 1,
		
		tex = nil,
	}, texture)
end

function texture:destroy()
	if self.tex then
		gl.DeleteTextures(unpack(self.tex))
		self.tex = nil
	end
end

function texture:send()
	if self.bound then	
		gl.TexImage2D(
			self.target, 
			0, 
			self.internalformat, 
			self.width, self.height, 0, 
			self.format, self.type, self.data
		)
	else
		self:bind()
		gl.TexImage2D(
			self.target, 
			0, 
			self.internalformat, 
			self.width, self.height, 0, 
			self.format, self.type, self.data
		)
		self:unbind()
	end
	self.dirty = false
end

function texture:create()
	if not self.tex then	
		self.tex = { gl.GenTextures(self.numtextures) }
		for i, tex in ipairs(self.tex) do
			gl.BindTexture(self.target, self.tex[i])
			self.bound = true
			-- each cube face should clamp at texture edges:
			gl.TexParameteri(self.target, gl.TEXTURE_WRAP_S, self.clamp)
			gl.TexParameteri(self.target, gl.TEXTURE_WRAP_T, self.clamp)
			gl.TexParameteri(self.target, gl.TEXTURE_WRAP_R, self.clamp)
			-- normal filtering
			gl.TexParameteri(self.target, gl.TEXTURE_MAG_FILTER, self.magfilter)
			gl.TexParameteri(self.target, gl.TEXTURE_MIN_FILTER, self.minfilter)
			-- automatic mipmap
			gl.TexParameteri(self.target, gl.GENERATE_MIPMAP, gl.TRUE)
			-- allocate:
			self:send()
		end
		gl.BindTexture(self.target, 0)
		self.bound = false
		glu.assert("intializing texture")
	end
end

function texture:settexture(i)
	self.currenttexture = i or self.currenttexture
end

function texture:bind(unit, tex)
	unit = unit or 0
	if tex then self:settexture(tex) end
	
	self:create()
	
	gl.ActiveTexture(gl.TEXTURE0+unit)
	gl.Enable(self.target)
	gl.BindTexture(self.target, self.tex[self.currenttexture])
	self.bound = true
	
	if self.dirty then
		self:send()
	end
end

function texture:unbind(unit)
	unit = unit or 0
	
	gl.ActiveTexture(gl.TEXTURE0+unit)
	gl.BindTexture(self.target, 0)
	gl.Disable(self.target)
	self.bound = false
end

function texture:quad(x, y, w, h, unit)
	if not y then 
		unit, x = x, nil
	end
	self:bind(unit)
	gl.sketch.quad(x, y, w, h)
	self:unbind(unit)
end

setmetatable(texture, {
	__call = function(t, w, h, n)
		return new(w, h, n)
	end,
})	
return texture