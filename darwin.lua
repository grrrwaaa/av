local ffi = require "ffi"
local C = ffi.C
local bit = require "bit"
local band, bor = bit.band, bit.bor

--[[
The bits of darwin that I needed:
--]]

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
static const int INADDR_ANY = 0x00000000;
static const int INADDR_BROADCAST = 0xffffffff;
static const int INADDR_LOOPBACK = 0x7f000001;

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

return C