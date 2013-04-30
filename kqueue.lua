-- see http://wiki.netbsd.org/tutorials/kqueue_tutorial/#index3h3
-- http://netbsd.gw.com/cgi-bin/man-cgi?kqueue++NetBSD-current
-- http://eradman.com/posts//kqueue-tcp.html

-- http://beej.us/guide/bgnet/output/html/singlepage/bgnet.html#clientserverx
-- http://www.linuxhowtos.org/C_C++/socket.htm

local ffi = require "ffi"
local C = ffi.C
local bit = require "bit"
local band, bor = bit.band, bit.bor

local sys = require "modules.system.osx.darwin"

--------------------------------------------------------------------------------
-- Socket utils
--------------------------------------------------------------------------------

function print_info(info)
	local ipstr = ffi.new("char[?]", C.INET6_ADDRSTRLEN)
	if info.ai_family == C.AF_INET then
		addr = ffi.cast("struct sockaddr_in *", info.ai_addr).sin_addr
	elseif info.ai_family == C.AF_INET6 then
		addr = ffi.cast("struct sockaddr_in6 *", info.ai_addr).sin6_addr
	else
		error("unknown family", info.ai_family)
	end
	
	C.inet_ntop(info.ai_family, addr, ipstr, C.INET6_ADDRSTRLEN)
	local ip = ffi.string(ipstr)
	return ip
end

-- supports ipv4 and ipv6
-- address is string (IP or name)
-- port is string (port number or service name)
-- returns fd, socket
function getsock(address, port)
	port = tostring(port or 8080)
	-- object to capture head of linked-list of results:
	local servinfo = ffi.new("struct addrinfo *[1]") -- will point to the results
	local hints = ffi.new("struct addrinfo[1]")
	hints[0].ai_family = C.AF_UNSPEC	-- handle both ipv4 and ipv6
	hints[0].ai_socktype = C.SOCK_STREAM -- TCP style
	hints[0].ai_flags = C.AI_PASSIVE 
	status = C.getaddrinfo(address, port, hints, servinfo)
	if status ~= 0 then
		error("getaddrinfo error:" .. C.gai_strerror(status))
	end
	-- iterate through the possible address results:
	local info = servinfo[0]
	local addr
	local first
	local sock, fd
	-- print out all matches:
	while info ~= nil do
		print(address, port, print_info(info))
		
		if not sock then
			fd = C.socket(info.ai_family, info.ai_socktype, info.ai_protocol)
			if fd < 0 then
				print("error", ffi.errno())
				-- convert the IP to a string and print it:
				C.inet_ntop(info.ai_family, addr, ipstr, C.INET6_ADDRSTRLEN)
				print("failed to open socket", ip)
			else
				sock = info
			end
		end	
		info = info.ai_next
	end
	
	--C.freeaddrinfo(servinfo[0])
	return fd, sock
end

function connect(address, port)
	local fd, sock = getsock(address, port)
	if C.connect(fd, sock.ai_addr, sock.ai_addrlen) < 0 then
		error(ffi.string(C.strerror(ffi.errno())))
	end
	return fd, sock
end

function bind(address, port)
	local fd, sock = getsock(address, port)
	-- lose the pesky "Address already in use" error message
	local yes = ffi.new("int[1]", 1)
	if C.setsockopt(fd, C.SOL_SOCKET, C.SO_REUSEADDR, yes, ffi.sizeof("int")) == -1 then
		error("setsockopt");
	end
	if C.bind(fd, sock.ai_addr, sock.ai_addrlen) < 0 then
		error(ffi.string(C.strerror(ffi.errno())))
	end
	return fd, sock
end

function listen(address, port)
	local fd, sock = bind(address, port)
	local backlog = 10	-- how many connections can be held waiting
	if C.listen(fd, backlog) < 0 then
		error(ffi.string(C.strerror(ffi.errno())))
	end
	return fd, sock
end

function accept(fd)
	local remote_addr = ffi.new("struct sockaddr_storage[1]")
	local addrlen = ffi.new("socklen_t[1]", ffi.sizeof("struct sockaddr_storage"))
	local remote_fd = C.accept(fd, ffi.cast("struct sockaddr *", remote_addr), addrlen) 
	if remote_fd < 0 then
		error(ffi.string(C.strerror(ffi.errno())))
	end
	print("connected", remote_fd)
	return remote_fd, remote_addr
end


--------------------------------------------------------------------------------
-- kqueue utils
--------------------------------------------------------------------------------

local kqueue = {}

local function EV_SET(kevp, a, b, c, d, e, f) 
	--kevp should be of type struct kevent *
	kevp.ident = a
	kevp.filter = b
	kevp.flags = c
	kevp.fflags = d
	kevp.data = e
	kevp.udata = f
end
kqueue.EV_SET = EV_SET

function kevent_errno()
	-- find the error:
	local errno = ffi.errno()
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


--------------------------------------------------------------------------------
-- demo
--------------------------------------------------------------------------------

local kq = C.kqueue()
if kq == -1 then error("kqueue") end
print("kq", kq)

local N = 2
-- the changelist:
local evSet = ffi.new("struct kevent[32]")

-- declare interest in file:
local fd = C.open("kqueue.lua", C.O_EVTONLY)
assert(fd > 0, "could not open file for monitoring")
print("fd", fd)
EV_SET(evSet[0], fd, C.EVFILT_VNODE, bor(C.EV_ADD, C.EV_CLEAR), bor(C.NOTE_DELETE, C.NOTE_WRITE, C.NOTE_RENAME), 0, nil)
-- sometime later; when no longer interested in events:
--C.close(fd)

-- declare interest in stdin:
local stdin = 0
EV_SET(evSet[1], stdin, C.EVFILT_READ, C.EV_ADD, 0, 0, nil)

-- declare interest in socket:
local selfsockfd, selfsock = listen("127.0.0.1", "8080")
print("selfsockfd", selfsockfd)
EV_SET(evSet[2], selfsockfd, C.EVFILT_READ, C.EV_ADD, 0, 0, nil)

-- add a timer:
local timerid = 1
-- consider also C.EV_ONESHOT flag
EV_SET(evSet[3], timerid, C.EVFILT_TIMER, bor(C.EV_ADD, C.EV_ENABLE), 0, 1000, nil)

-- EVFILT_WRITE (socket, fifo, tty, file, ...)
-- ev.data shows how much memory is available for writing

-- EVFILT_PROC
-- monitor a process ID; notify when exit, fork, exec, etc.

-- EVFILT_SIGNAL
-- for a particular signal number

-- add all these:
if C.kevent(kq, evSet, 4, nil, 0, nil) == -1 then
	kevent_errno()
end


-- 10ms timeout
local timeout = ffi.new("struct timespec[1]")


-- list of incoming events:
local evList = ffi.new("struct kevent[32]")
-- buffer for messages:
local bufsize = 4097
local buf = ffi.new("char[?]", bufsize)
-- somewhere to store connected clients:
local clients = {}
-- watcher loop:
while true do
	-- do non-event things here:
	--print(".")
	
	-- Reset the timeout.  In case of a signal interrruption, the values may change.
	timeout[0].tv_sec = 0
	timeout[0].tv_nsec = 100e6 -- 10ms
	local nev = C.kevent(kq, nil, 0, evList, 32, timeout)
	for i = 0, nev-1 do
		local ev = evList[i]
		-- needed to cast from ULL type:
		local evfd = tonumber(ev.ident)
		print(string.format("event %d: ident %s filter %d flags %x fflags %x data %s udata %s", i, tostring(evfd), ev.filter, ev.flags, ev.fflags, tostring(ev.data), tostring(ev.udata)))
		if band(ev.flags, C.EV_ERROR) ~= 0 then
			error(ffi.string(C.strerror(ev.data)))
		elseif band(ev.flags, C.EV_EOF) ~= 0 then
			print("EV_EOF")
			print("disconnect")
			local fd = evfd
			C.close(fd)
		elseif evfd == stdin then
			print("data on stdin")
			assert(ev.filter == C.EVFILT_READ)
			-- for fileIO, ev.data indicates the number of bytes readable
			-- (including terminator character)
			-- use C.read here?:
			assert(ev.data < bufsize, "buffer too small for message")
			local bytesread = C.read(stdin, buf, bufsize-1)
			print("data to read", ev.data, ffi.string(buf, bytesread-1))
		elseif evfd == selfsockfd then
			local remotefd = accept(evfd)
			print("accepted remote", remotefd)
			clients[remotefd] = {}
			-- add interest:
			--local evNew = ffi.new("struct kevent[1]")
			EV_SET(evSet[0], remotefd, C.EVFILT_READ, C.EV_ADD, 0, 0, nil)
			if C.kevent(kq, evSet, 1, nil, 0, nil) == -1 then
				error("kevent")
			end
			
			-- send a welcoming message:
			local msg = "hello\n"
			C.send(remotefd, msg, #msg, 0)
			
		elseif clients[evfd] then
			local remotefd = evfd
			print(remotefd, ev.data)
			assert(ev.data < bufsize, "buffer too small for message")
			local bytesread = C.recv(remotefd, buf, bufsize-1, 0)
			
			if bytesread == 0 then
				print("remote disconnected")
				close(evfd)
				clients[evfd] = nil
			elseif bytesread < 0 then
				error(ffi.string(C.strerror(ffi.errno())))
			else
				buf[bytesread] = 0
				print("received:", ev.data, ffi.string(buf))
				
				-- send a welcoming message:
				local msg = "thank you\n"
				C.send(remotefd, buf, bytesread, 0)
			end
		elseif ev.filter == C.EVFILT_TIMER then
			print("timer", evfd)
		elseif ev.filter == C.EVFILT_VNODE then
			local filefd = evfd
			if band(ev.fflags, C.NOTE_WRITE) then
				print("file modified")
				
				print("closing interest in file")
				-- note that this also removes it from the kqueue:
				C.close(filefd)
			else
				print("other file event", ev.fflags)
			end
		else
			error("unhandled event")
		end
	end
end
