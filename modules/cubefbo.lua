local gl = require "gl"

local cubefbo = {}
cubefbo.__index = cubefbo

local function new(width, height, numtextures) 
	return setmetatable({
		width = width or 512,
		height = height or 512,
		numtextures = numtextures or 1,
		currenttexture = 1,
		
		id = nil,
		rbo = nil,
		tex = nil,
	}, cubefbo)
end

function cubefbo:destroy()
	gl.DeleteTextures(unpack(self.tex))
	gl.DeleteRenderBuffers(self.rbo)
	gl.DeleteFrameBuffers(self.id)
end

function cubefbo:create()
	if not self.id then	
		self.tex = { gl.GenTextures(self.numtextures) }
		for i, tex in ipairs(self.tex) do
			gl.BindTexture(gl.TEXTURE_CUBE_MAP, self.tex[i])
			-- each cube face should clamp at texture edges:
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
			-- normal filtering
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
			-- no mipmapping:
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.GENERATE_MIPMAP, gl.FALSE); -- automatic mipmap
			--[[
			gl.TexGeni( gl.S, gl.TEXTURE_GEN_MODE, gl.OBJECT_LINEAR )
			gl.TexGeni( gl.T, gl.TEXTURE_GEN_MODE, gl.OBJECT_LINEAR )
			gl.TexGeni( gl.R, gl.TEXTURE_GEN_MODE, gl.OBJECT_LINEAR )
			local X = ffi.new("float[4]", { 1,0,0,0 })
			local Y = ffi.new("float[4]", { 0,1,0,0 })
			local Z = ffi.new("float[4]", { 0,0,1,0 })
			gl.TexGenfv( gl.S, gl.OBJECT_PLANE, X )
			gl.TexGenfv( gl.T, gl.OBJECT_PLANE, Y )
			gl.TexGenfv( gl.R, gl.OBJECT_PLANE, Z )
			--]]
			-- allocate:
			for face = 0, 5 do
				gl.TexImage2D(
					gl.TEXTURE_CUBE_MAP_POSITIVE_X+face, 
					0, 
					gl.RGBA8, 
					self.width, self.height, 0, 
					gl.BGRA, gl.UNSIGNED_BYTE, nil
				)
			end
		end
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, 0)
		
		-- one FBO to rule them all...
		self.id = gl.GenFramebuffers(1)
		gl.BindFramebuffer(gl.FRAMEBUFFER, self.id)
		
		self.rbo = gl.GenRenderbuffers()
		gl.BindRenderbuffer(gl.RENDERBUFFER, self.rbo)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, self.width, self.height)
		-- Attach depth buffer to FBO
		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, self.rbo)
	
		-- ...and in the darkness bind them:
		for face = 0, 5 do
			gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0+face, gl.TEXTURE_CUBE_MAP_POSITIVE_X+face, self.tex[self.currenttexture], 0)
		end
		
		-- Does the GPU support current FBO configuration?
		local status = gl.CheckFramebufferStatus(gl.FRAMEBUFFER)
		if status ~= gl.FRAMEBUFFER_COMPLETE then
			error("GPU does not support required FBO configuration\n")
		end
		
		-- cleanup:
		gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		
		gl.assert("intializing cubefbo")
	end
end

function cubefbo:settexture(i)
	self.currenttexture = i or self.currenttexture
	if self.cubefbobound then
		-- switch immediately:
		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_CUBE_MAP, 	self.tex[self.currenttexture], 0)
	end
end

function cubefbo:bind(unit, tex)
	unit = unit or 0
	
	self:create()
	
	gl.ActiveTexture(gl.TEXTURE0+unit)
	gl.Enable(gl.TEXTURE_CUBE_MAP)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, self.tex[tex or self.currenttexture])
end

function cubefbo:unbind(unit)
	unit = unit or 0
	
	gl.ActiveTexture(gl.TEXTURE0+unit)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, 0)
	gl.Disable(gl.TEXTURE_CUBE_MAP)
end

function cubefbo:startcapture()
	self:create()
	
	gl.BindFramebuffer(gl.FRAMEBUFFER, self.id)
	self.cubefbobound = true
	cubefbo:settexture(self.currenttexture)
	gl.DrawBuffer(gl.COLOR_ATTACHMENT0)
	
	gl.Enable(gl.SCISSOR_TEST)
	gl.Scissor(0, 0, self.width, self.height)
	gl.Viewport(0, 0, self.width, self.height)
	
	gl.assert("cubefbo:startcapture")
end

function cubefbo:face(face)
	gl.DrawBuffer(gl.COLOR_ATTACHMENT0 + face)
end

function cubefbo:endcapture()
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	self.cubefbobound = false
	gl.DrawBuffer(gl.BACK)
	gl.Disable(gl.SCISSOR_TEST)
	gl.assert("cubefbo:endcapture")
end

function cubefbo:generatemipmap()	
	-- FBOs don't generate mipmaps by default; do it here:
	self:bind()
	gl.GenerateMipmap(gl.TEXTURE_CUBE_MAP)
	gl.assert("generating mipmap");
	self:unbind()
end

function cubefbo:capture(func, ...)
	self:startcapture()
	func(...)
	self:endcapture()
end

setmetatable(cubefbo, {
	__call = function(t, w, h, n)
		return new(w, h, n)
	end,
})	
return cubefbo