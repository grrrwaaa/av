local audio = require "audio"
local driver = audio.driver

local audio_script = {
	latency = 16, -- 16 blocks of 256 at 44.1kHz is about 100ms.
}

-- to get a lower latency we would need to update() more frequently.
print("latency (seconds)", audio_script.latency * driver.blocksize / driver.samplerate)

function audio_script:update(generate)
	if generate then
		local blocksize = driver.blocksize
		local w = driver.blockwrite
		local r = driver.blockread
		local s = driver.blocks
		local t = (r + self.latency) % driver.blocks
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

local gl = require "gl"

function audio_script:draw()
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
--------------------------------------------------------------------------------

-- the "scene"
local sin = math.sin
local pi = math.pi

function SinOsc(amp, freq)
	local amp = amp or 0.1
	local freq = freq or 440
	local p = 0
	local isr = 1 / driver.samplerate
	return function()
		p = p + freq * isr
		return amp * sin(pi * p * 2)
	end
end	

synth0 = SinOsc(1, 2)
synth1 = SinOsc(1, 6)
synth2 = SinOsc(1, 500)
synth3 = SinOsc(1, 700)

local 
function generate()
	local s0 = synth0()
	local s1 = synth1()
	local s2 = synth2()
	local s3 = synth3()
	return s0 * s2, s1 * s3
end

-- audio scope:
win:setdim(600, 100)

function update()
	audio_script:update(generate)
end

function draw()
	audio_script:draw()
end