--[[ 
on Linux, use epoll
on OSX, use kqueue
--]]

local ffi = require "ffi"
local C = ffi.C

--local syscall = require "syscall"

local function cmd(str) print(str) return io.popen(str):read("*a") end
local header = [[

enum {
	EVENT_TYPE_READ,
	EVENT_TYPE_CLOSE,
	EVENT_TYPE_TIMER,
	
	EVENT_TYPE_COUNT
};

typedef struct no_event_t {
	int type;
	int fd;
} no_event_t;

typedef struct no_loop_t {
	int q;
} no_loop_t;

no_loop_t * loop_new();
void loop_destroy(no_loop_t * loop);
int loop_add_fd(no_loop_t * loop, int fd);
int loop_add_timer(no_loop_t * loop, int id, double seconds);

int loop_run_once(no_loop_t * loop, no_event_t * event, double seconds);

int tcp_socket_server(const char * address, const char * port);
int socket_listen(int sfd, int backlog);
int socket_accept(int fd);

int socket_write(int fd, const char * msg, int len);

int stream_read(int fd, char * buf, int size);
]]

local src = header .. [[


#include <sys/socket.h>       /*  socket definitions        */
#include <sys/time.h> 
#include <sys/types.h>        /*  socket types              */
#include <netdb.h>
#include <fcntl.h>
#include <unistd.h>           /*  misc. UNIX functions      */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#ifdef __APPLE__
	#define NO_POLL_USE_KQUEUE
	#include <sys/event.h>
	#define NO_POLL_CREATE(n) kqueue()
	#define NO_POLL_EVENT	struct kevent
#else
	#define NO_POLL_USE_EPOLL
	#include <sys/epoll.h>
	#define NO_POLL_CREATE(n) epoll_create(n)
	#define NO_POLL_EVENT	struct epoll_event
#endif

no_loop_t * loop_new() {
	no_loop_t * loop;
	int q;
	
	q = NO_POLL_CREATE(100);
	if (q == -1) {
		fprintf(stderr, "failed to create epoll/kqueue");
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	
	loop = calloc(1, sizeof(no_loop_t));
	loop->q = q;
	return loop;
}

NO_POLL_EVENT newevent;

int loop_add_fd(no_loop_t * loop, int fd) {
	int res;
	
	#ifdef NO_POLL_USE_KQUEUE
	EV_SET(&newevent, fd, EVFILT_READ, EV_ADD, 0, 0, NULL);
	res = kevent(loop->q, &newevent, 1, NULL, 0, NULL) == -1;
	#endif
	
	#ifdef NO_POLL_USE_EPOLL
	newevent.data.fd = fd;
	newevent.events = EPOLLIN;
	res = epoll_ctl(loop->q, EPOLL_CTL_ADD, fd, &newevent);
	#endif
	
	if (res != 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	return res;
}

int loop_add_timer(no_loop_t * loop, int id, double seconds) {
	int res;
	
	#ifdef NO_POLL_USE_KQUEUE
	EV_SET(&newevent, id, EVFILT_TIMER, EV_ADD | EV_ENABLE, 0, seconds * 1000.0, NULL);
	res = kevent(loop->q, &newevent, 1, NULL, 0, NULL) == -1;
	#endif
	
	#ifdef NO_POLL_USE_EPOLL
	res = -1; /// NYI
	//newevent.data.fd = fd;
	//newevent.events = EPOLLIN;
	//res = epoll_ctl(loop->q, EPOLL_CTL_ADD, fd, &newevent);
	#endif
	
	if (res != 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	return res;
}

NO_POLL_EVENT change;

int loop_run_once(no_loop_t * loop, no_event_t * event, double seconds) {
	int nev, fd;
	
	#ifdef NO_POLL_USE_KQUEUE
	struct timespec timeout;
	timeout.tv_sec = seconds;
	timeout.tv_nsec = (seconds - (long)seconds) * 1.0e9;
	nev = kevent(loop->q, NULL, 0, &change, 1, &timeout);
	#endif
	
	#ifdef NO_POLL_USE_EPOLL
	int timeout = seconds * 1000.;
	nev = epoll_wait(loop->q, &change, 1, timeout);
	#endif
	
	if (nev) {
		#ifdef NO_POLL_USE_KQUEUE
		fd = change.ident;
		event->fd = fd;
		if ((change.flags & EV_ERROR) != 0) {
			fprintf(stderr, "%s\n", strerror( errno ));
		} else if ((change.flags & EV_EOF) != 0) {
			// file closed.
			event->type = EVENT_TYPE_CLOSE;
			close(fd); // safe assumption?
		} else if (change.filter == EVFILT_TIMER) {
			event->type = EVENT_TYPE_TIMER;
		} else {
			event->type = EVENT_TYPE_READ;
		}
		#endif
		
		#ifdef NO_POLL_USE_EPOLL
		fd = change.data.fd;
		event->fd = fd;
		if (change.events & EPOLLERR) {
			fprintf(stderr, "%s\n", strerror( errno ));
		} else if (change.events & EPOLLHUP) {
			// file closed.
			event->type = EVENT_TYPE_CLOSE;
			close(fd); // safe assumption?
		} else if (change.events & EPOLLIN) {
			event->type = EVENT_TYPE_READ;
		}
		#endif
	}
	return nev;
}

void loop_destroy(no_loop_t * loop) {
	close(loop->q);
	free(loop);
}

void set_nonblocking(int fd) {
	int flags;
	if (-1 == (flags = fcntl(fd, F_GETFL, 0))) {
        flags = 0;
		if (fcntl(fd, F_SETFL, flags | O_NONBLOCK)) { 
			fprintf(stderr, "%s\n", strerror( errno ));
		}
	}	
}

int tcp_socket_server(const char * address, const char * port) {
	struct addrinfo hints;
	struct addrinfo *result, *rp;
	int sfd, s;
	int yes = 1;
	
	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;    /* Allow IPv4 or IPv6 */
    hints.ai_socktype = SOCK_STREAM; /* TCP socket */
    hints.ai_flags = AI_PASSIVE;    /* For wildcard IP address */
    hints.ai_protocol = 0;          /* Any protocol */
    hints.ai_canonname = NULL;
    hints.ai_addr = NULL;
    hints.ai_next = NULL;

	s = getaddrinfo(address, port, &hints, &result);
    if (s != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
       	return -1;
    }
    
    /* getaddrinfo() returns a list of address structures.
       Try each address until we successfully bind(2).
       If socket(2) (or bind(2)) fails, we (close the socket
       and) try the next address. */
	for (rp = result; rp != NULL; rp = rp->ai_next) {
		sfd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
		if (sfd == -1)
			continue;
		
		// try to re-use addresses:
		if (setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) == -1) {
			fprintf(stderr, "failed to set SO_REUSEADDR=1");
			fprintf(stderr, "%s\n", strerror( errno ));
		}
		
		if (bind(sfd, rp->ai_addr, rp->ai_addrlen) == 0)
			break;                  /* Success */
		close(sfd);
	}

  	freeaddrinfo(result);           /* No longer needed */
	
	if (rp == NULL) {               /* No address succeeded */
        fprintf(stderr, "%s\n", strerror( errno ));
        return -1;
    }
    
	set_nonblocking(sfd);
    
	return sfd;
}

int socket_listen(int sfd, int backlog) {
	int res = listen(sfd, backlog);
	if (res < 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	return res;
}

int socket_accept(int fd) {
	struct sockaddr_storage remote_addr;
	socklen_t addrlen;
	int client;
	
	addrlen = sizeof(struct sockaddr_storage);
	client = accept(fd, (struct sockaddr *)(&remote_addr), &addrlen);
	if (client < 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
		return client;
	}
	
	// FD_ISSET(client, &working_set);
	
	// set non-blocking
    set_nonblocking(client);
	
	return client;
}

int socket_write(int fd, const char * msg, int len) {
	int res;
	res = write(fd, msg, len);
	if (res < 0) {
		if (errno == EWOULDBLOCK) {
			// safe to ignore, happens due to nonblocking sockets
			return 0;
		} else {
			fprintf(stderr, "%s\n", strerror( errno ));
		}
	}
	return res;
}

int stream_read(int fd, char * buf, int size) {
	return read(fd, buf, size);
}

]]
local f = io.open("no.c", "w")
f:write(src)
f:close()
local libname
if ffi.os == "Linux" then
	local res = cmd("gcc -O3 -fPIC no.c -shared -o libno.so")
	libname = "./libno.so"
elseif ffi.os == "OSX" then
	local res = cmd("gcc -arch i386 -arch x86_64 -O3 -fPIC no.c -shared -o libno.dylib")
	libname = "no"
end
if res then error(res) end
local no = ffi.load(libname)
ffi.cdef(header)

local loop = no.loop_new()
local timers = {}
local readers = {}
print("loop", loop)

function readbytes(id)
	local buf = ffi.new("char[1024]")
	local bytesread = no.stream_read(id, buf, 1024) --C.read(id, buf, 1024)
	--print(id, "bytesread", bytesread)
	if bytesread > 0 then
		return ffi.string(buf, bytesread)
	end
end

local socket = {}
socket.__index = socket

function socket:send(str)
	return no.socket_write(self.fd, str, #str)
end

function socket:on(event, callback)
	local list = self.listeners[event]
	assert(list, "no such event")
	list[#list+1] = callback
end

function socket:pipe(dst)
	self:on("data", function(data) dst:send(data) end)
end

local net = {}

function net.server(port, callback)
	port = port and tostring(port) or "8080"
	local fd = no.tcp_socket_server("127.0.0.1", port)
	assert(fd >= 0, "failed to create server socket")
	
	readers[fd] = function(fd)
		print("incoming connection from", fd)
		
		-- accept this connection:
		local clientfd = no.socket_accept(fd)
		assert(clientfd >= 0)
		
		local client = setmetatable({ 
			fd = clientfd,
			listeners = {
				data = {},
			}, 
		}, socket)
		
		-- add client automatically:
		assert(no.loop_add_fd(loop, clientfd) == 0)
		readers[clientfd] = function(fd)
			local data = readbytes(fd)
			for i, l in ipairs(client.listeners.data) do
				l(data)
			end
		end
		
		callback(client)
	end
	assert(no.loop_add_fd(loop, fd) == 0)
	assert(no.socket_listen(fd, 10) == 0)
	
	return fd
end


-- also listen to stdin:
assert(no.loop_add_fd(loop, 0) == 0)
readers[0] = function(fd)
	readbytes(fd)
end

--[[
-- also add a timer:
local timerid = 1
assert(no.loop_add_timer(loop, 1, 2.5) == 0, "failed to add timer")
timers[timerid] = function()
	print("timer callback")
end
--]]

local ev = ffi.new("no_event_t[1]")
function run_once()
	local n = no.loop_run_once(loop, ev, 1.)
	if n > 0 then
		local ty = ev[0].type
		local id = ev[0].fd
		print("event", ty, id)
		if ty == no.EVENT_TYPE_READ then
			print("read", id)
			local f = readers[id]
			if f then
				f(id)
			else
				print("no reader", id)
			end
		elseif ty == no.EVENT_TYPE_TIMER then
			local f = timers[id]
			if f then
				f(id)
			else
				print("no timer", id)
			end
		elseif ty == no.EVENT_TYPE_CLOSE then
			print("closed", id)
		else
			print("unhandled event type")
		end
	end
end		

function run()
	while true do
		run_once()
	end	
end

--------------------------------------------------------------------------------
-- TEST
--------------------------------------------------------------------------------

local server = net.server(8080, function(client)
	-- send a welcoming message:
	client:send("welcome!")
	-- echo back to client:
	client:pipe(client)
	-- print all received:
	client:on("data", function(data)
		print("received", data)
	end)
end)

run()
