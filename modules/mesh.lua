
local vertexPositions = ffi.new("float[?]",   
	 0.75f, 0.75f, 0.0f, 1.0f,
    0.75f, -0.75f, 0.0f, 1.0f,
    -0.75f, -0.75f, 0.0f, 1.0f,
)

function initbuffer()

	local id = ffi.new("GLuint[1]")
	
	gl.GenBuffers(1, id)
		
	gl.BindBuffer(gl.ARRAY_BUFFER, positionBufferObject)
	gl.BufferData(gl.ARRAY_BUFFER, ffi.sizeof(vertexPositions), vertexPositions, gl.STATIC_DRAW)
	glBindBuffer(GL_ARRAY_BUFFER, 0)
	
	return id[0]
end
	
	glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject)
	glEnableVertexAttribArray(0)
	glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0)
	
	glDrawArrays(GL_TRIANGLES, 0, 3)
	
	glDisableVertexAttribArray(0)