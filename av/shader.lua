-- shader: Friendly wrapper for OpenGL GLSL shaders

local gl = require "gl"
local glu = require "glu"
local ffi = require "ffi"
local util = require "util"

local shader = {}
shader.__index = shader

local function new(vcode, fcode)
	local self = {
		vertex_shaders = { vcode },
		fragment_shaders = { fcode },
		id = nil,
		attributes = {},
		uniforms = {},
	}
	return util.gc(setmetatable(self, shader), shader.destroy)
end

function shader:vertex(code)
	self.vertex_shaders[#self.vertex_shaders+1] = code
	return self
end

function shader:fragment(code)
	self.fragment_shaders[#self.fragment_shaders+1] = code
	return self
end

local uniformsetters = {
	[gl.FLOAT] = gl.Uniform1f,
	[gl.FLOAT_VEC2] = gl.Uniform2f,
	[gl.FLOAT_VEC3] = gl.Uniform3f,
	[gl.FLOAT_VEC4] = gl.Uniform4f,
	[gl.INT] = gl.Uniform1i,
	[gl.INT_VEC2] = gl.Uniform2i,
	[gl.INT_VEC3] = gl.Uniform3i,
	[gl.INT_VEC4] = gl.Uniform4i,
	-- gl.BOOL, gl.BOOL_VEC2, gl.BOOL_VEC3, gl.BOOL_VEC4, 
	[gl.FLOAT_MAT2] = function(index, v)
		gl.UniformMatrix2fv(index, 1, 0, v)
	end,	
	[gl.FLOAT_MAT3] = function(index, v)
		gl.UniformMatrix3fv(index, 1, 0, v)
	end, 
	[gl.FLOAT_MAT4] = function(index, v)
		gl.UniformMatrix4fv(index, 1, 0, v)
	end, 
	[gl.SAMPLER_2D] = gl.Uniform1i,
	[gl.SAMPLER_3D] = gl.Uniform1i,
	[gl.SAMPLER_CUBE] = gl.Uniform1i,
}
local attributesetters = {
	[gl.FLOAT] = gl.VertexAttrib1f,
	[gl.FLOAT_VEC2] = gl.VertexAttrib2f,
	[gl.FLOAT_VEC3] = gl.VertexAttrib3f,
	[gl.FLOAT_VEC4] = gl.VertexAttrib4f,
}


local 
function checkStatus(program)	
	local status = ffi.new("GLint[1]")
    gl.GetProgramiv(program, gl.LINK_STATUS, status)
	if status[0] == gl.FALSE then
		local infoLogLength = ffi.new("GLint[1]")
		gl.GetProgramiv(program, gl.INFO_LOG_LENGTH, infoLogLength)
		local strInfoLog = ffi.new("GLchar[?]", infoLogLength[0] + 1)
        gl.GetProgramInfoLog(program, infoLogLength[0], nil, strInfoLog)
        gl.DeleteProgram(self.id)
        self.id = 0
		error("gl.LinkProgram " .. ffi.string(strInfoLog))
	end
	return program
end

function shader:bind()
	if not self.id then	
		print("creating shader")
		local shaders = {}
		for i, s in ipairs(self.vertex_shaders) do
			local sh = gl.Shader(gl.VERTEX_SHADER, s)
			glu.assert("creating shader")
			shaders[#shaders+1] = sh
		end
		for i, s in ipairs(self.fragment_shaders) do
			local sh = gl.Shader(gl.FRAGMENT_SHADER, s)
			glu.assert("creating shader")
			shaders[#shaders+1] = sh
		end		
		self.id = gl.Program(unpack(shaders))
		print("created program", self.id)
		glu.assert("creating shader program")
		
		-- query attrs:
		local params = ffi.new("GLint[1]")
		
		gl.GetProgramiv(self.id, gl.ACTIVE_UNIFORMS, params)
		glu.assert("getting shader program uniforms")
		--print("uniforms:", params[0])
		for i = 0, params[0]-1 do
			self:addUniform(i)
		end
		
		gl.GetProgramiv(self.id, gl.ACTIVE_ATTRIBUTES, params)
		glu.assert("getting shader program attributes")
		--print("attributes:", params[0])
		for i = 0, params[0]-1 do
			self:addAttribute(i)
		end
		
		self.id = checkStatus(self.id)
		glu.assert("checking status")
		print("verified program", self.id)
		
		-- cleanup:
		for i, s in ipairs(shaders) do
			gl.DeleteShader(s)
			glu.assert("deleting shaders")
		end
		
	end
	glu.assert("before binding shader")
	gl.UseProgram(self.id)
	glu.assert("binding shader")
	self.bound = true
	return self
end

function shader:unbind()
	gl.UseProgram(0)
	self.bound = false
	return self
end

function shader:destroy()
	if self.id then
		gl.DeleteProgram(self.id)
	end
	self.id = nil
	return self
end

function shader:addUniform(index)
	local length = ffi.new("GLsizei[1]")
	local size = ffi.new("GLint[1]")
	local type = ffi.new("GLenum[1]")
	local buf = ffi.new("GLchar[128]")
	-- get uniform properties:
	gl.GetActiveUniform(self.id, index, 128, length, size, type, buf)
	local k = ffi.string(buf)
	local loc = gl.GetUniformLocation(self.id, k)
	u = {
		index = index,
		loc = loc,
		type = type[0],
		size = size[0],
		length = length[0],
		setter = assert(uniformsetters[type[0] ]),
	}
	--print(string.format("adding uniform setter for %s: index %d (%d), type %d, size %d length %d", k, u.index, u.loc, u.type, u.size, u.length))
	self.uniforms[k] = u
end

function shader:addAttribute(index)
	local length = ffi.new("GLsizei[1]")
	local size = ffi.new("GLint[1]")
	local ty = ffi.new("GLenum[1]")
	local buf = ffi.new("GLchar[128]")
	
	-- get uniform properties:
	gl.GetActiveAttrib(self.id, index, 128, length, size, ty, buf)
	local k = ffi.string(buf)
	local loc = gl.GetAttribLocation(self.id, k)
	u = {
		index = index,
		loc = loc,
		type = ty[0],
		size = size[0],
		length = length[0],
		setter = assert(attributesetters[ ty[0] ]),
	}
	--print(string.format("adding attribute setter for %s: index %d (%d), type %d, size %d length %d", k, u.index, loc, u.type, u.size, u.length))
	self.attributes[k] = u
end

function shader:GetAttribLocation(k)
	return gl.GetAttribLocation(self.id, k)
end

function shader:uniform(k, ...)
	local u = self.uniforms[k]
	if not u then
		error("Shader uniform not found: "..k)
	end
	u.setter(u.loc, ...)
	return self
end

function shader:attribute(k, ...)
	local u = self.attributes[k]
	if not u then
		error("Shader attribute not found: "..k)
	end
	u.setter(u.loc, ...)
	return self
end

setmetatable(shader, {
	__call = function(t, ...)
		return new(...)
	end
})

return shader