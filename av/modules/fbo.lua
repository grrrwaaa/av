local gl = require "gl"
local glu = require "glu"
local ffi = require "ffi"

local fbo = {}
fbo.__index = fbo

local function new(width, height, numtextures) 
	return setmetatable({
		width = width or 512,
		height = height or 512,
		numtextures = numtextures or 1,
		currenttexture = 1,
		
		id = nil,
		rbo = nil,
		tex = nil,
	}, fbo)
end

function fbo:destroy()
	gl.DeleteTextures(unpack(self.tex))
	gl.DeleteRenderBuffers(self.rbo)
	gl.DeleteFrameBuffers(self.id)
end

function fbo:create()
	if not self.id then	
		self.tex = { gl.GenTextures(self.numtextures) }
		for i, tex in ipairs(self.tex) do
			gl.BindTexture(gl.TEXTURE_2D, self.tex[i])
			-- each cube face should clamp at texture edges:
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
			-- normal filtering
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
			-- allocate:
			gl.TexImage2D(
				gl.TEXTURE_2D, 
				0, 
				gl.RGBA8, 
				self.width, self.height, 0, 
				gl.RGBA, gl.UNSIGNED_BYTE, nil
			)
		end
		gl.BindTexture(gl.TEXTURE_2D, 0)
		
		-- one FBO to rule them all...
		self.id = gl.GenFramebuffers(1)
		gl.BindFramebuffer(gl.FRAMEBUFFER, self.id)
		
		self.rbo = gl.GenRenderbuffers()
		gl.BindRenderbuffer(gl.RENDERBUFFER, self.rbo)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, self.width, self.height)
		-- Attach depth buffer to FBO
		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, self.rbo)
	
		-- attach first texture to FBO by default:
		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, self.tex[self.currenttexture], 0)
		
		-- Does the GPU support current FBO configuration?
		local status = gl.CheckFramebufferStatus(gl.FRAMEBUFFER)
		if status ~= gl.FRAMEBUFFER_COMPLETE then
			error("GPU does not support required FBO configuration\n")
		end
		
		-- cleanup:
		gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		
		glu.assert("intializing fbo")
	end
end

function fbo:settexture(i)
	self.currenttexture = i or self.currenttexture
	if self.fbobound then
		-- switch immediately:
		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, 	self.tex[self.currenttexture], 0)
	end
end

function fbo:bind(unit, tex)
	unit = unit or 0
	
	self:create()
	
	gl.ActiveTexture(gl.TEXTURE0+unit)
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, self.tex[tex or self.currenttexture])
end

function fbo:unbind(unit)
	unit = unit or 0
	
	gl.ActiveTexture(gl.TEXTURE0+unit)
	gl.BindTexture(gl.TEXTURE_2D, 0)
	gl.Disable(gl.TEXTURE_2D)
end

function fbo:draw(x, y, w, h)
	x = x or 0
	y = y or 0
	w = w or 1
	h = h or 1
	self:bind()
	gl.Begin(gl.QUADS)
		gl.TexCoord(0, 0) gl.Vertex(x, y)
		gl.TexCoord(1, 0) gl.Vertex(x+w, y)
		gl.TexCoord(1, 1) gl.Vertex(x+w, y+h)
		gl.TexCoord(0, 1) gl.Vertex(x, y+h)
	gl.End()
	self:unbind()
end

function fbo:bindbuffer()
	gl.BindFramebuffer(gl.FRAMEBUFFER, self.id)
	self.fbobound = true
	fbo:settexture(self.currenttexture)
	gl.DrawBuffer(gl.COLOR_ATTACHMENT0)
end


function fbo:unbindbuffer()
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	self.fbobound = false
	gl.DrawBuffer(gl.BACK)
end

function fbo:startcapture()
	self:create()
	self:bindbuffer()
	
	gl.Enable(gl.SCISSOR_TEST)
	gl.Scissor(0, 0, self.width, self.height)
	gl.Viewport(0, 0, self.width, self.height)
	
	glu.assert("fbo:startcapture")
end

function fbo:endcapture()
	self:unbindbuffer()
	gl.Disable(gl.SCISSOR_TEST)
	glu.assert("fbo:endcapture")
end

function fbo:capture(func, ...)
	self:startcapture()
	func(...)
	self:endcapture()
end

function fbo:generatemipmap()	
	for i, tex in ipairs(self.tex) do
		-- FBOs don't generate mipmaps by default; do it here:
		self:bind(0, i)
		gl.GenerateMipmap(gl.TEXTURE_2D)
		glu.assert("generating mipmap");
		self:unbind(0)
	end
end

-- just the simplest implementation for now.
-- pixel layout of ptr can be indexed as y*fbo1.width*4 + x*fbo1.height + rgba:
function fbo:readpixels(ptr)
	ptr = ptr or ffi.new("unsigned char [?]", self.width * self.height * 4)
	self:bindbuffer()
		gl.ReadPixels(0, 0, self.width, self.height, gl.RGBA, gl.UNSIGNED_BYTE, ptr)
	self:unbindbuffer()
	return ptr
end

setmetatable(fbo, {
	__call = function(t, w, h, n)
		return new(w, h, n)
	end,
})	
return fbo