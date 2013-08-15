#!/usr/bin/env luajit
local ffi = require "ffi"
local av = require "av"
local gl = require "gl"

function test_window()
	function draw()	
		--if frame % 100 == 0 then print("fps", 1/dt) end

		gl.Clear()
	
		gl.Begin(gl.LINES)
		for i = 1, 100 do
			gl.Vertex(0, 0, 0)
			gl.Vertex(math.random()*2-1, math.random()*2-1, 0)
		end
		gl.End()
	end

	function close()
		print("the end of the world is nigh")
	end
end

function test_timer()
	go(function()
		while true do
			print("  tick", now())
			wait(0.25)
		end
	end)

	go(function()
		while true do
			print(" TOCK", now())
			wait(1)
		end
	end)

	go(function()
		while true do
			wait(math.random(5))
			print("***surprise!***", now())
		end
	end)
end

-- audio script is for generating audio in the main Lua thread
function test_audioscript()
	
	local audio = require "audio"

	-- the "scene"
	local sin = math.sin
	local pi = math.pi

	function SinOsc(amp, freq)
		local amp = amp or 0.1
		local freq = freq or 440
		local p = 0
		local isr = 1 / audio.driver.samplerate
		return function()
			p = p + freq * isr
			return amp * sin(pi * p * 2)
		end
	end	

	synth0 = SinOsc(1, 0.1)
	synth1 = SinOsc(1, 0.4)
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

	go(function()
		while true do
			audio.script(generate)
			wait(0.01)
		end
	end)

	function draw()
		gl.Clear()
		audio.draw()
		
		--if frame % 30 == 0 then print(1/dt) end
	
	end
end


test_window()
--test_timer()
--test_audioscript()

local window = require "window"
go(1, function() window.fullscreen = true end)

av.run()