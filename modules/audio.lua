--- audio: accessing the audio system

local ffi = require "ffi"
local C = ffi.C
-- to cdef the av_Audio stuff:
local builtin = require "builtin"

local driver = C.av_audio_get()
assert(driver ~= nil, "problem acquiring audio driver")

local audio = {
	driver = driver,
}

local msgbuffer = driver.msgbuffer

-- hack for testing buffer wrapping/overflow handling:
msgbuffer.size = 1024 * 128

local function write_header(cmd, size)
	local required = size + 1 -- plus one char for the cmd flag
	local r, w = msgbuffer.read, msgbuffer.write	
	-- first make sure there is enough space:
	if w < r then
		local available = r - w
		if required >= available then
			print(w, r, required)
			error("audio message buffer overflow")
		end
	else
		local size = msgbuffer.size
		local available = size - w - 1
		if required > available then
			-- can't write because we'd hit the loop boundary
			-- but maybe we can skip to the end of the buffer 
			-- and write from the start?
			if required < r then	
				-- insert a skip marker:
				msgbuffer.data[w] = C.AV_AUDIO_CMD_SKIP
				--print("\twrote skip to", w)
				-- move writer to buffer start:
				w = 0
			else
				print(w, r, len)
				error("audio message buffer overflow")
			end
		end
	end
	-- now go ahead and write the command flag:
	msgbuffer.data[w] = cmd
	return w + 1
end




function audio.clear()
	idlast = 0
	idpool = {}
	-- send to audio thread:
	msgbuffer.write = write_header(C.AV_AUDIO_CMD_CLEAR, 0)
end

function audio.setparam(id, pid, value)
	--print("setparam", id, pid, value)
	-- send to audio thread:
	local len = ffi.sizeof("av_msg_param")
	local w = write_header(C.AV_AUDIO_CMD_VOICE_PARAM, len)
	-- write body:
	local msg = ffi.cast("av_msg_param *", msgbuffer.data + w)
	msg.id = id
	msg.pid = pid
	msg.value = value
	-- mark as complete:
	msgbuffer.write = w + len
	--print("WRITE PARAM", w) dump()
end


function audio.setcode(str)
	-- send to audio thread:
	local len = #str+1	-- plus one for null terminator
	local w = write_header(C.AV_AUDIO_CMD_VOICE_CODE, len)
	-- write body:
	ffi.copy(msgbuffer.data + w, str, len)
	-- mark as complete:
	msgbuffer.write = w + len
	--print("WRITE", str, buffer.write) dump()
end

local idpool = {}
local idlast = 0

function audio.add(name)
	local name
	if #idpool > 0 then
		name = table.remove(idpool)
	else
		idlast = idlast + 1
		name = idlast
	end

	-- send to audio thread:
	local len = ffi.sizeof("int")
	local w = write_header(C.AV_AUDIO_CMD_VOICE_ADD, len)
	-- write body:
	local msg = ffi.cast("int *", msgbuffer.data + w)
	msg[0] = name
	-- mark as complete:
	msgbuffer.write = w + len
	--print("WRITE", name, buffer.write) dump()
	
	return name
end

function audio.remove(name)
	-- send to audio thread:
	local len = ffi.sizeof("int")
	local w = write_header(C.AV_AUDIO_CMD_VOICE_REMOVE, len)
	-- write body:
	local msg = ffi.cast("int *", msgbuffer.data + w)
	msg[0] = name
	-- mark as complete:
	msgbuffer.write = w + len
	--print("WRITE", name, buffer.write) dump()
	
	-- recycle name:
	table.insert(idpool, name)
end

function audio.send(str)
	-- send to audio thread:
	local len = #str+1	-- plus one for null terminator
	local w = write_header(C.AV_AUDIO_CMD_GENERIC, len)
	-- write body:
	ffi.copy(msgbuffer.data + w, str, len)
	-- mark as complete:
	msgbuffer.write = w + len
	--print("WRITE", str, buffer.write) dump()
end

function audio.dump()
	msgbuffer_dump()
end

if not pcall(C.av_audio_start) then
	print("unable to start audio")
end

audio.clear()

return audio