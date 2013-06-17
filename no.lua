--[[ 
on Linux, use epoll
on OSX, use kqueue
--]]

local ffi = require "ffi"
local C = ffi.C

local syscall = require "syscall"

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
	int kq;
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
]]

local src = header .. [[
#include <sys/event.h>
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

no_loop_t * loop_new() {
	no_loop_t * loop;
	int kq;
	
	kq = kqueue();
	if (kq == -1) {
		fprintf(stderr, "failed to create kqueue");
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	
	loop = calloc(1, sizeof(no_loop_t));
	loop->kq = kq;
	return loop;
}

struct kevent newevent;

int loop_add_fd(no_loop_t * loop, int fd) {
	EV_SET(&newevent, fd, EVFILT_READ, EV_ADD, 0, 0, NULL);
	int res = kevent(loop->kq, &newevent, 1, NULL, 0, NULL) == -1;
	if (res != 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	return res;
}

int loop_add_timer(no_loop_t * loop, int id, double seconds) {
	EV_SET(&newevent, id, EVFILT_TIMER, EV_ADD | EV_ENABLE, 0, seconds * 1000.0, NULL);
	int res = kevent(loop->kq, &newevent, 1, NULL, 0, NULL) == -1;
	if (res != 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	return res;
}

struct kevent change;

int loop_run_once(no_loop_t * loop, no_event_t * event, double seconds) {
	struct timespec timeout;
	int nev;
	timeout.tv_sec = seconds;
	timeout.tv_nsec = (seconds - (long)seconds) * 1.0e9;
	nev = kevent(loop->kq, NULL, 0, &change, 1, &timeout);
	if (nev) {
		int fd = change.ident;
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
	}
	return nev;
}

void loop_destroy(no_loop_t * loop) {
	close(loop->kq);
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

]]
local f = io.open("no.c", "w")
f:write(src)
f:close()
if ffi.os == "Linux" then
	local res = cmd("gcc -O3 -fPIC no.c -shared -o libno.so")
elseif ffi.os == "OSX" then
	local res = cmd("gcc -arch i386 -arch x86_64 -O3 -fPIC no.c -shared -o libno.dylib")
end
if res then error(res) end
local no = ffi.load("no")
ffi.cdef(header)

local loop = no.loop_new()
local timers = {}
local readers = {}
print("loop", loop)

function readbytes(id)
	local buf = ffi.new("char[1024]")
	local bytesread = C.read(id, buf, 1024)
	print(id, "bytesread", bytesread)
	if bytesread > 0 then
		print(ffi.string(buf, bytesread))
	end
end

function sendmsg(fd, str)
	no.socket_write(fd, str, #str)
	--C.send(fd, str .. "\n", #str, 0)
end

-- creates & binds this socket:
local server = no.tcp_socket_server("127.0.0.1", "8080")
print("server", server)	
assert(no.socket_listen(server, 10) == 0)

assert(no.loop_add_fd(loop, server) == 0)
readers[server] = function(fd)
	print("read data from", fd)
	
	-- accept this connection:
	local client = no.socket_accept(fd)
	assert(client >= 0)
	
	sendmsg(client, "welcome!")
	
	-- add client:
	assert(no.loop_add_fd(loop, client) == 0)
	readers[client] = function(fd)
		print("from client")
		readbytes(fd)
	end
end
-- also listen to stdin:
assert(no.loop_add_fd(loop, 0) == 0)
readers[0] = function(fd)
	readbytes(fd)
end
-- also add a timer:
local timerid = 1
assert(no.loop_add_timer(loop, 1, 2.5) == 0)
timers[timerid] = function()
	print("timer callback")
end

local ev = ffi.new("no_event_t[1]")
for i = 1, 1000 do
	local n = no.loop_run_once(loop, ev, 1.)
	if n > 0 then
		local ty = ev[0].type
		local id = ev[0].fd
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

--local server_addr = 








