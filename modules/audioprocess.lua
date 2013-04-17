--- audioprocess: (audio thread internal use only)

local ffi = require "ffi"
local C = ffi.C
-- to cdef the av_Audio stuff:
local builtin = require "builtin"

local sin, cos = math.sin, math.cos
local random = math.random
local pi = math.pi

local driver = C.av_audio_get()
local msgbuffer = driver.msgbuffer

-- opportunities to optimize here:
--[[
don't convert msg to string unless necessary; 
use ffi cdef'd message structs and ffi.cast instead
pre-allocate space for voices instead of creating tables
use a linked list for voices
use int keys for voices
cache def constructors?
--]]

-- active synth voices:
local voices = {}
-- current output buffer pointers:
local outbuffers = {}

local system = {
	voices = voices,
	outbuffers = outbuffers,
	driver = driver,
}

function handlemessage(cmd, data)
	if cmd == C.AV_AUDIO_CMD_VOICE_PARAM then
		-- parse the param
		local msg = ffi.cast("av_msg_param *", data)
		print("READ PARAM", msg.id, msg.pid, msg.value)
		
		voices[msg.id].data[msg.pid] = msg.value
		
		return ffi.sizeof("av_msg_param")
	elseif cmd == C.AV_AUDIO_CMD_GENERIC then
		-- if message body is a string, continue like this:
		local msg = ffi.string(data)
		print("READ STRING", msg, #msg)
		return #msg + 1
	elseif cmd == C.AV_AUDIO_CMD_VOICE_ADD then
		-- if message body is a string, continue like this:
		local msg = ffi.cast("int *", data)
		local name = msg[0]
		print("READ ADD", msg[0])
		
		-- add to voices
		voices[name] = { data={} }
		
		return ffi.sizeof("int")
	elseif cmd == C.AV_AUDIO_CMD_VOICE_CODE then
		-- if message body is a string, continue like this:
		local msg = ffi.string(data)
		print("READ CODE") --, msg, #msg)
		
		local ok, f = pcall(loadstring, msg)
		if ok then ok, f = pcall(f, system) end
		if not ok then print(f) end
		
		return #msg + 1
	elseif cmd == C.AV_AUDIO_CMD_VOICE_REMOVE then
		-- if message body is a string, continue like this:
		local msg = ffi.cast("int *", data)
		local name = msg[0]
		print("READ REMOVE", name)
		
		-- remove from voices
		voices[name].perform = nil
		
		return ffi.sizeof("int")
	elseif cmd == C.AV_AUDIO_CMD_CLEAR then
		print("READ CLEAR")
		-- remove all voices
		for k in pairs(voices) do 
			voices[k].perform = nil 
		end
		print("cleared audio system")
		return 0
	else
		-- probably want to bail the program if there is an error here... 
		assert(cmd == C.AV_AUDIO_CMD_EMPTY, "unexpected message type")
		return 0
	end
end

local function callback(self, time, inputs, outputs, frames)
	-- read any incoming messages:
	local r, w = msgbuffer.read, msgbuffer.write
	-- r ~= w implies that the buffer is not empty:
	while r ~= w do		
		local cmd = msgbuffer.data[r]
		--print("reading cmd at", cmd, r, type(cmd))
		if cmd == C.AV_AUDIO_CMD_SKIP then
			--print("\tfound skip at", r)
			r = 0
			cmd = msgbuffer.data[r]
		end
		r = r + 1
		r = r + handlemessage(cmd, msgbuffer.data + r)
		if r >= msgbuffer.size then r = 0 end
		
		-- could do this outside the loop?:
		msgbuffer.read = r
	end	
	
	-- get and clear output buffers:
	for c = 1, 2 do
		local buf = outputs + frames * (c-1)
		for i = 0, frames-1 do
			buf[i] = 0
		end
		outbuffers[c] = buf
	end
	
	-- play all voices:
	for id, v in pairs(voices) do
		if v.perform then
			v.perform(v.data, outbuffers, frames)
		end
	end
	
	--[[
	local w0 = speakers[0].weights
	local w1 = speakers[1].weights
	
	-- process incoming messages
	local m = self.peek(time)
	while m ~= nil do
		
		local cmd = m.cmd
		if cmd == C.AV_AUDIO_VOICE_NEW then
			local id = m.id
			assert(m.id, "missing id for new voice")
			voices[id] = {
				ugen = fly(((id % 10) + srandom() * 0.2) * 110),
				pos = vec3(),
			}
			--print("added voice", type(id), id, voices[id])
			
		elseif cmd == C.AV_AUDIO_VOICE_FREE then
			local id = m.id
			assert(id, "missing id to free voice")
			voices[id] = nil
			--print("freed voice", id)
			
		elseif cmd == C.AV_AUDIO_VOICE_POS then
			local id = m.id
			assert(id, "missing id to position voice")
			if not voices[id] then
				--print("missing voice", type(id), id, voices[id])	
				error("missing voice "..tostring(id))
			end
			voices[id].pos.x = m.x
			voices[id].pos.y = m.y
			voices[id].pos.z = m.z
			
		elseif cmd == C.AV_AUDIO_POS then
			view.pos.x = m.x
			view.pos.y = m.y
			view.pos.z = m.z
			
		elseif cmd == C.AV_AUDIO_QUAT then
			view.quat.x = m.x
			view.quat.y = m.y
			view.quat.z = m.z
			view.quat.w = m.w
		elseif cmd == C.AV_AUDIO_CLEAR then
			for k, v in pairs(voices) do
				voices[k] = nil
			end
			--print("cleared voices")
		end

		m = self.next(time)
	end
	
	-- play voices
	-- play all voices:
	for id, v in pairs(voices) do
		local ugen = v.ugen
		local amp = 0.05
		local pan = 0.5
		local omni = 0
		
		-- get position in 'view space':
		local rel = quat_unrotate(view.quat, v.pos - view.pos)
		
		-- distance squared:
		local d2 = rel:dot(rel)
		-- distance
		local d = sqrt(d2)
		-- unit rel:
		local direction = rel / d
		
		-- amplitude scale by distance:
		local atten = attenuate(d2, 0.2, 1/32)
		
		
		-- omni mix is also distance-dependent. 
		-- at near distances, the signal should be omnidirectional
		-- the minimum really depends on the radii of the listener/emitter
		local spatial = 1 - attenuate(d2, 0.2, 1/4)
		
		
		-- encode:
		local w = SQRT2
		-- first 3 harmonics are the same as the unit direction:
		local x = spatial * direction.x
		local y = spatial * direction.y
		local z = spatial * direction.z
		
		
		for i=0, frames-1 do
			local s = ugen() * amp * atten
			
			-- decode:
			out0[i] = out0[i]
				+ w0[0] * w * s
				+ w0[1] * x * s
				+ w0[2] * y * s 
				+ w0[3] * z * s
			
			out1[i] = out1[i]
				+ w1[0] * w * s 
				+ w1[1] * x * s 
				+ w1[2] * y * s 
				+ w1[3] * z * s
		end
	end
	
	--]]
	
	-- TODO: tune this
	collectgarbage("step")
end

function nullonframes(self, time, inputs, outputs, frames) end

function driver:onframes(time, inputs, outputs, frames)
	local ok, err = pcall(callback, self, time, inputs, outputs, frames)
	if not ok then 
		print(debug.traceback(err))
		-- kill audio at this point:
		print("disabling audio processing...")
		driver.onframes:set(nullonframes)
	end
end

-- one way to prevent gc issues:
return callback