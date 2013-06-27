local audio = require "audio"
local driver = audio.driver

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

synth0 = SinOsc(0.6, 2)
synth1 = SinOsc(0.6, 3)
synth2 = SinOsc(0.6, 500)
synth3 = SinOsc(0.6, 700)

local blocks = driver.blocks
local chans = driver.outchannels
local blocksize = driver.blocksize

function generate(l, r, frames)
	for i = 0, frames-1 do
		local s0 = synth0()
		local s1 = synth1()
		local s2 = synth2()
		local s3 = synth3()
		l[i] = s0 * s2
		r[i] = s1 * s3
	end
end

local latency = 16	-- 16 blocks of 256 at 44.1kHz is about 100ms.
-- to get a lower latency we would need to update() more frequently.
print("latency (seconds)", latency * driver.blocksize / driver.samplerate)

function update()
	local blocksize = driver.blocksize
	local w = driver.blockwrite
	local r = driver.blockread
	local s = driver.blocks
	local t = (r + latency) % driver.blocks
	local done = 0 -- how many blocks produced on this update
	
	if w > t then
		-- fill up & wrap around:
		while w < s do
			local l = driver.buffer + w * driver.blockstep
			local r = l + blocksize
			generate(l, r, blocksize)
			done = done + 1
			w = w + 1
		end
		w = 0
	end
	while w < t do
		local l = driver.buffer + w * driver.blockstep
		local r = l + blocksize
		generate(l, r, blocksize)
		done = done + 1
		w = w + 1
	end
	driver.blockwrite = w
	--print(done)
end
