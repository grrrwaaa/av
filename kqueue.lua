-- see http://wiki.netbsd.org/tutorials/kqueue_tutorial/#index3h3
-- http://eradman.com/posts//kqueue-tcp.html

-- http://beej.us/guide/bgnet/output/html/singlepage/bgnet.html#clientserverx
-- http://www.linuxhowtos.org/C_C++/socket.htm
-- http://www.paulgriffiths.net/program/c/echoserv.php
-- http://cs.baylor.edu/~donahoo/practical/CSockets/code/TCPEchoServer.c

local ffi = require "ffi"
local C = ffi.C
local bit = require "bit"
local band, bor = bit.band, bit.bor

-- a bit of darwin:

local darwin = [[
// types.h
typedef uint32_t socklen_t;
typedef uint8_t	sa_family_t;
typedef long ssize_t;

// errno.h
enum {
	EPERM = 1,
	ENOENT,
	ESRCH,
	EINTR,
	EIO,
	ENXIO,
	E2BIG,
	ENOEXEC,
	EBADF,
	ECHILD,
	EDEADLK,
	ENOMEM,
	EACCES,
	EFAULT,
	ENOTBLK,
	EBUSY,
	EEXIST,
	EXDEV,
	ENODEV,
	ENOTDIR,
	EISDIR,
	EINVAL,
	ENFILE,
	EMFILE
};

// time.h
struct timespec {
	long	tv_sec;
	long	tv_nsec;
};

// unistd.h
enum {
	O_RDONLY	= 0x0000,		/* open for reading only */
	O_WRONLY	= 0x0001,		/* open for writing only */
	O_RDWR		= 0x0002,		/* open for reading and writing */
	O_ACCMODE	= 0x0003,		/* mask for above modes */
	
	O_EVTONLY	= 0x8000
};

enum {
	S_IWRITE = 0000200,
	S_IREAD = 0000400
};

int open( const char *filename, int access);
int	 close(int);
int	 gethostname(char *, size_t);
ssize_t read(int fildes, void *buf, size_t nbyte);

// string.h
char	*strerror(int);

// socket.h

static const int SOL_SOCKET	= 0xffff;
static const int AF_UNSPEC = 0;
static const int AF_INET = 2;
static const int AF_INET6 = 30;
static const int PF_UNSPEC = 0;
static const int AI_PASSIVE	= 0x00000001; /* get address to use bind() */

static const int	SO_DEBUG		= 0x0001;	/* turn on debugging info recording */
static const int	SO_ACCEPTCONN	= 0x0002;		/* socket has had listen() */
static const int	SO_REUSEADDR	= 0x0004;		/* allow local address reuse */
static const int	SO_KEEPALIVE	= 0x0008;		/* keep connections alive */
static const int	SO_DONTROUTE	= 0x0010;		/* just use interface addresses */
static const int	SO_BROADCAST	= 0x0020;		/* permit sending of broadcast msgs */
static const int	SO_USELOOPBACK	= 0x0040;		/* bypass hardware when possible */
static const int	SO_LINGER		= 0x0080;       /* linger on close if data present (in ticks) */
static const int	SO_OOBINLINE	= 0x0100;		/* leave received OOB data in line */
static const int	SO_REUSEPORT	= 0x0200;		/* allow local address & port reuse */
static const int	SO_TIMESTAMP	= 0x0400;		/* timestamp received dgram traffic */

enum {
	SOCK_STREAM	= 1,		/* stream socket */
	SOCK_DGRAM	= 2,		/* datagram socket */
	SOCK_RAW	= 3,		/* raw-protocol interface */
	SOCK_RDM	= 4,		/* reliably-delivered message */
	SOCK_SEQPACKET	= 5		/* sequenced packet stream */
};

struct sockaddr {
	uint8_t	sa_len;		/* total length */
	sa_family_t	sa_family;	/* [XSI] address family */
	char		sa_data[14];	/* [XSI] addr value (actually larger) */
};

static const int _SS_PAD1SIZE = 6;
static const int _SS_PAD2SIZE = 112;
struct sockaddr_storage {
	uint8_t			ss_len;		/* address length */
	sa_family_t		ss_family;	/* [XSI] address family */
	char			__ss_pad1[_SS_PAD1SIZE];
	int64_t			__ss_align;	/* force structure storage alignment */
	char			__ss_pad2[_SS_PAD2SIZE];
};

// for IPv4:
struct in_addr {
    uint32_t s_addr; // that's a 32-bit int (4 bytes)
};
struct sockaddr_in {
    short int          sin_family;  // Address family, AF_INET
    unsigned short int sin_port;    // Port number
    struct in_addr     sin_addr;    // Internet address
    unsigned char      sin_zero[8]; // Same size as struct sockaddr
};

int	accept(int, struct sockaddr *, socklen_t *);
int	bind(int, const struct sockaddr *, socklen_t);
int	connect(int, const struct sockaddr *, socklen_t);
int	getpeername(int, struct sockaddr *, socklen_t *);
int	getsockname(int, struct sockaddr *, socklen_t *);
int	getsockopt(int, int, int, void *, socklen_t *);
int	listen(int, int);
ssize_t	recv(int, void *, size_t, int);
ssize_t	recvfrom(int, void *, size_t, int, struct sockaddr *, socklen_t *);
ssize_t	recvmsg(int, struct msghdr *, int);
ssize_t	send(int, const void *, size_t, int);
ssize_t	sendmsg(int, const struct msghdr *, int);
ssize_t	sendto(int, const void *, size_t, int, const struct sockaddr *, socklen_t);
int	setsockopt(int, int, int, const void *, socklen_t);
int	shutdown(int, int);
int	sockatmark(int);
int	socket(int, int, int);

// netdb.h
struct addrinfo {
    int              ai_flags;     // AI_PASSIVE, AI_CANONNAME, etc.
    int              ai_family;    // AF_INET, AF_INET6, AF_UNSPEC
    int              ai_socktype;  // SOCK_STREAM, SOCK_DGRAM
    int              ai_protocol;  // use 0 for "any"
    size_t           ai_addrlen;   // size of ai_addr in bytes
    char            *ai_canonname; // full canonical hostname
    struct sockaddr *ai_addr;      // struct sockaddr_in or _in6
    struct addrinfo *ai_next;      // linked list, next node
};

struct hostent {
	char	*h_name;	/* official name of host */
	char	**h_aliases;	/* alias list */
	int	h_addrtype;	/* host address type */
	int	h_length;	/* length of address */
	char	**h_addr_list;	/* list of addresses from name server */
};

const char	* gai_strerror(int);
int getaddrinfo(const char *node,     // e.g. "www.example.com" or IP
                const char *service,  // e.g. "http" or port number
                const struct addrinfo *hints,
                struct addrinfo **res);
void freeaddrinfo(struct addrinfo *);

struct hostent	*gethostbyname(const char *);

// in.h
static const int INET_ADDRSTRLEN = 16;

// in6.h
static const int INET6_ADDRSTRLEN = 46;

// for IPv6:
struct in6_addr {
    unsigned char   s6_addr[16];   // IPv6 address
};
struct sockaddr_in6 {
    uint16_t       sin6_family;   // address family, AF_INET6
    uint16_t       sin6_port;     // port number, Network Byte Order
    uint32_t       sin6_flowinfo; // IPv6 flow information
    struct in6_addr sin6_addr;     // IPv6 address
    uint32_t       sin6_scope_id; // Scope ID
};

// #include <arpa/inet.h>
const char *inet_ntop(int af, const void *src, char *dst, socklen_t size);
int inet_pton(int af, const char *src, void *dst);

// kqueue.h
static const int EVFILT_READ		= (-1);
static const int EVFILT_WRITE		= (-2);
static const int EVFILT_AIO			= (-3); /* attached to aio requests */
static const int EVFILT_VNODE		= (-4); /* attached to vnodes */
static const int EVFILT_PROC		= (-5);	/* attached to struct proc */
static const int EVFILT_SIGNAL		= (-6);	/* attached to struct proc */
static const int EVFILT_TIMER		= (-7);	/* timers */
static const int EVFILT_MACHPORT  	= (-8);	/* Mach portsets */
static const int EVFILT_FS		    = (-9);	/* Filesystem events */
static const int EVFILT_USER        = (-10); /* User events */
static const int EVFILT_SESSION		= (-11); /* Audit session events */
static const int EVFILT_SYSCOUNT	= 11;

enum {
	EV_ADD		= 0x0001,		/* add event to kq (implies enable) */
	EV_DELETE	= 0x0002,		/* delete event from kq */
	EV_ENABLE	= 0x0004,		/* enable event */
	EV_DISABLE	= 0x0008,		/* disable event (not reported) */
	
	EV_ONESHOT	= 0x0010,		/* only report one occurrence */
	EV_CLEAR	= 0x0020,		/* clear event state after reporting */
	EV_RECEIPT	= 0x0040,		/* force EV_ERROR on success, data == 0 */
	EV_DISPATCH = 0x0080,          /* disable event after reporting */
	
	EV_FLAG0	= 0x1000,		/* filter-specific flag */
	EV_FLAG1	= 0x2000,		/* filter-specific flag */
	
	EV_ERROR	= 0x4000,		/* error, data contains errno */
	EV_EOF		= 0x8000,		/* EOF detected */
	
	EV_SYSFLAGS	= 0xF000		/* reserved by system */
};

enum {
	NOTE_DELETE	= 0x00000001,		/* vnode was removed */
	NOTE_WRITE	= 0x00000002,		/* data contents changed */
	NOTE_EXTEND	= 0x00000004,		/* size increased */
	NOTE_ATTRIB	= 0x00000008,		/* attributes changed */
	NOTE_LINK	= 0x00000010,		/* link count changed */
	NOTE_RENAME	= 0x00000020,		/* vnode was renamed */
	NOTE_REVOKE	= 0x00000040,		/* vnode access was revoked */
	NOTE_NONE	= 0x00000080	
};

struct kevent {
	uintptr_t	ident;		/* identifier for this event */
	int16_t		filter;		/* filter for event */
	uint16_t	flags;		/* general flags */
	uint32_t	fflags;		/* filter-specific flags */
	intptr_t	data;		/* filter-specific data */
	void		*udata;		/* opaque user data identifier */
};

struct kevent64_s {
	uint64_t	ident;		/* identifier for this event */
	int16_t		filter;		/* filter for event */
	uint16_t	flags;		/* general flags */
	uint32_t	fflags;		/* filter-specific flags */
	int64_t		data;		/* filter-specific data */
	uint64_t	udata;		/* opaque user data identifier */
	uint64_t	ext[2];		/* filter-specific extensions */
};


int     kqueue(void);
int     kevent(int kq, const struct kevent *changelist, int nchanges,
		    struct kevent *eventlist, int nevents,
		    const struct timespec *timeout);
int     kevent64(int kq, const struct kevent64_s *changelist, 
		    int nchanges, struct kevent64_s *eventlist, 
		    int nevents, unsigned int flags, 
		    const struct timespec *timeout);

]]

ffi.cdef(darwin)

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

-- add all these:
if C.kevent(kq, evSet, 3, nil, 0, nil) == -1 then
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
			error("EV_ERROR")
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
