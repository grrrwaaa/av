local ffi = require "ffi"
local C = ffi.C
local gl = require "gl"

local driver = core.av_audio_get()
assert(driver ~= nil, "problem acquiring audio driver")


local audio = {
	driver = driver,
	
	latency = 16, -- 16 blocks of 256 at 44.1kHz is about 100ms.
}

-- to get a lower latency we would need to update() more frequently.
print("audio script latency (seconds)", audio.latency * driver.blocksize / driver.samplerate)


function audio.start()
	if not pcall(core.av_audio_start) then
		print("unable to start audio")
	else
		print("audio started")
	end
end
audio.start()

function audio.script(generate)
	if generate then
		local blocksize = driver.blocksize
		local w = driver.blockwrite
		local r = driver.blockread
		local s = driver.blocks
		local t = (r + audio.latency) % driver.blocks
		local done = 0 -- how many blocks produced on this update
	
		if w > t then
			-- fill up & wrap around:
			while w < s do
				local out = driver.buffer + w * driver.blockstep
				for i = 0, blocksize-1 do
					local l, r = generate()
					out[i*2] = l
					out[i*2+1] = r or l
				end
				done = done + 1
				w = w + 1
			end
			w = 0
		end
		while w < t do
			local out = driver.buffer + w * driver.blockstep
			for i = 0, blocksize-1 do
				local l, r = generate()
				out[i*2] = l
				out[i*2+1] = r or l
			end
			done = done + 1
			w = w + 1
		end
		driver.blockwrite = w
		--print(done)
	end
end

-- render the contents of the audio buffer
function audio.draw()
	local buffer = driver.buffer
	
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE)
	
	gl.Begin(gl.LINE_STRIP)
	local dim = driver.blocksize * driver.blocks * driver.outchannels - 1
	for i = 0, dim do
		local x = i / dim
		local y = 0.5 + 0.5 * buffer[i]
		gl.Vertex(x, y, 0)
	end
	gl.End()
end

return audio