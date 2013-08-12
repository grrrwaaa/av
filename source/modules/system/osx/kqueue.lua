local ffi = require "ffi"
local C = ffi.C

local darwin = require "system.osx.darwin"

local kqueue = {}

function kqueue.EV_SET(kevp, a, b, c, d, e, f) 
	--kevp should be of type struct kevent *
	kevp.ident = a
	kevp.filter = b
	kevp.flags = c
	kevp.fflags = d
	kevp.data = e
	kevp.udata = f
end

function kqueue.errno()
	-- find the error:
	local errno = ffi.errno()
	
	-- why not just error(ffi.string(C.strerror(ffi.errno())))?
	
	if errno == C.EACCES then
		error("kevent: The process does not have permission to register a filter.")
	elseif errno == C.EFAULT then
		error("kevent: There was an error reading or writing the kevent or kevent64_s structure.")
	elseif errno == C.EBADF then
		 error("kevent: The specified descriptor is invalid.")
	elseif errno == C.EINTR then           
		error("kevent: A signal was delivered before the timeout expired and before any events were placed on the kqueue for return.")
	 elseif errno == C.EINVAL then           
		error("kevent: The specified time limit or filter is invalid.")
	 elseif errno == C.ENOENT then           
		error("kevent: The event could not be found to be modified or deleted.")
	 elseif errno == C.ENOMEM then       
		error("kevent: No memory was available to register the event.")
	 elseif errno == C.ESRCH then
		error("kevent: The specified process to attach to does not exist.")
	else
		error("kevent")
	end
end

-- a changelist:
local change = ffi.new("struct kevent[1]")

function kqueue.addfilter(kq, fd, filter, flags, filterflags, filterdata)
	kqueue.EV_SET(change[0], 
		-- event identifier (e.g. file descriptor)
		fd, 
		-- event filter
		-- EVFILT_READ/EVFILT_WRITE, EVFILT_VNODE, EVFILT_PROC, EVFILT_SIGNAL, EVFILT_MACHPORT, EVFILT_TIMER
		filter, 
		-- general flags	
		-- EV_ADD/EV_DELETE, EV_ENABLE/EV_DISABLE, EV_ONESHOT, EV_CLEAR
		flags or C.EV_ADD, 
		-- filter flags
		-- NOTE_DELETE, NOTE_WRITE, NOTE_EXTEND, NOTE_ATTRIB, NOTE_LINK, NOTE_RENAME, NOTE_REVOKE
		-- NOTE_SECONDS, NOTE_USECONDS, NOTE_NSECONDS
		filterflags or 0, 
		-- filter data
		filterdata or 0, 
		-- other data
		nil)
	-- add to pollset:
	if C.kevent(kq, change, 1, nil, 0, nil) == -1 then
		kqueue.errno()
	end
end

function kqueue.new()
	local kq = C.kqueue()
	if kq == -1 then error("failed to initialize kqueue") end
	return kq
end

return kqueue