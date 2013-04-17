local gl = require "gl"

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
		
		-- assume 2D for now
		width = width or 512,
		height = height or 512,
		
		numtextures = numtextures or 1,
		currenttexture = 1,
		
		tex = nil,
	}, texture)
end

function texture:destroy()
	gl.DeleteTextures(unpack(self.tex))
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
		gl.assert("intializing texture")
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
end

function texture:unbind(unit)
	unit = unit or 0
	
	gl.ActiveTexture(gl.TEXTURE0+unit)
	gl.BindTexture(self.target, 0)
	gl.Disable(self.target)
	self.bound = false
end

setmetatable(texture, {
	__call = function(t, w, h, n)
		return new(w, h, n)
	end,
})	
return texture