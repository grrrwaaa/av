-- lua: FFI interface for creating and manipulating lua_State objects

local bit = require "bit"
local ffi = require "ffi"
local header = [[
typedef long int ptrdiff_t;
typedef long unsigned int size_t;
typedef int wchar_t;
struct lua_State;
typedef struct lua_State lua_State;

typedef int (*lua_CFunction) (lua_State *L);
typedef const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);

typedef int (*lua_Writer) (lua_State *L, const void* p, size_t sz, void* ud);
typedef void * (*lua_Alloc) (void *ud, void *ptr, size_t osize, size_t nsize);
typedef double lua_Number;
typedef ptrdiff_t lua_Integer;

lua_State *(lua_newstate) (lua_Alloc f, void *ud);
void (lua_close) (lua_State *L);
lua_State *(lua_newthread) (lua_State *L);

lua_CFunction (lua_atpanic) (lua_State *L, lua_CFunction panicf);
int (lua_gettop) (lua_State *L);
void (lua_settop) (lua_State *L, int idx);
void (lua_pushvalue) (lua_State *L, int idx);
void (lua_remove) (lua_State *L, int idx);
void (lua_insert) (lua_State *L, int idx);
void (lua_replace) (lua_State *L, int idx);
int (lua_checkstack) (lua_State *L, int sz);

void (lua_xmove) (lua_State *from, lua_State *to, int n);
int (lua_isnumber) (lua_State *L, int idx);
int (lua_isstring) (lua_State *L, int idx);
int (lua_iscfunction) (lua_State *L, int idx);
int (lua_isuserdata) (lua_State *L, int idx);
int (lua_type) (lua_State *L, int idx);
const char *(lua_typename) (lua_State *L, int tp);

int (lua_equal) (lua_State *L, int idx1, int idx2);
int (lua_rawequal) (lua_State *L, int idx1, int idx2);
int (lua_lessthan) (lua_State *L, int idx1, int idx2);

lua_Number (lua_tonumber) (lua_State *L, int idx);
lua_Integer (lua_tointeger) (lua_State *L, int idx);
int (lua_toboolean) (lua_State *L, int idx);
const char *(lua_tolstring) (lua_State *L, int idx, size_t *len);
size_t (lua_objlen) (lua_State *L, int idx);
lua_CFunction (lua_tocfunction) (lua_State *L, int idx);
void *(lua_touserdata) (lua_State *L, int idx);
lua_State *(lua_tothread) (lua_State *L, int idx);
const void *(lua_topointer) (lua_State *L, int idx);
void (lua_pushnil) (lua_State *L);
void (lua_pushnumber) (lua_State *L, lua_Number n);
void (lua_pushinteger) (lua_State *L, lua_Integer n);
void (lua_pushlstring) (lua_State *L, const char *s, size_t l);
void (lua_pushstring) (lua_State *L, const char *s);
const char *(lua_pushvfstring) (lua_State *L, const char *fmt,
                                                      va_list argp);
const char *(lua_pushfstring) (lua_State *L, const char *fmt, ...);
void (lua_pushcclosure) (lua_State *L, lua_CFunction fn, int n);
void (lua_pushboolean) (lua_State *L, int b);
void (lua_pushlightuserdata) (lua_State *L, void *p);
int (lua_pushthread) (lua_State *L);
void (lua_gettable) (lua_State *L, int idx);
void (lua_getfield) (lua_State *L, int idx, const char *k);
void (lua_rawget) (lua_State *L, int idx);
void (lua_rawgeti) (lua_State *L, int idx, int n);
void (lua_createtable) (lua_State *L, int narr, int nrec);
void *(lua_newuserdata) (lua_State *L, size_t sz);
int (lua_getmetatable) (lua_State *L, int objindex);
void (lua_getfenv) (lua_State *L, int idx);
void (lua_settable) (lua_State *L, int idx);
void (lua_setfield) (lua_State *L, int idx, const char *k);
void (lua_rawset) (lua_State *L, int idx);
void (lua_rawseti) (lua_State *L, int idx, int n);
int (lua_setmetatable) (lua_State *L, int objindex);
int (lua_setfenv) (lua_State *L, int idx);
void (lua_call) (lua_State *L, int nargs, int nresults);
int (lua_pcall) (lua_State *L, int nargs, int nresults, int errfunc);
int (lua_cpcall) (lua_State *L, lua_CFunction func, void *ud);
int (lua_load) (lua_State *L, lua_Reader reader, void *dt,
                                        const char *chunkname);
int (lua_dump) (lua_State *L, lua_Writer writer, void *data);
int (lua_yield) (lua_State *L, int nresults);
int (lua_resume) (lua_State *L, int narg);
int (lua_status) (lua_State *L);
int (lua_gc) (lua_State *L, int what, int data);
int (lua_error) (lua_State *L);

int (lua_next) (lua_State *L, int idx);

void (lua_concat) (lua_State *L, int n);

lua_Alloc (lua_getallocf) (lua_State *L, void **ud);
void lua_setallocf (lua_State *L, lua_Alloc f, void *ud);
void lua_setlevel (lua_State *from, lua_State *to);
typedef struct lua_Debug lua_Debug;
typedef void (*lua_Hook) (lua_State *L, lua_Debug *ar);
int lua_getstack (lua_State *L, int level, lua_Debug *ar);
int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);
const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_getupvalue (lua_State *L, int funcindex, int n);
const char *lua_setupvalue (lua_State *L, int funcindex, int n);

int lua_sethook (lua_State *L, lua_Hook func, int mask, int count);
lua_Hook lua_gethook (lua_State *L);
int lua_gethookmask (lua_State *L);
int lua_gethookcount (lua_State *L);
struct lua_Debug {
	int event;
	const char *name;
	const char *namewhat;
	const char *what;
	const char *source;
	int currentline;
	int nups;
	int linedefined;
	int lastlinedefined;
	char short_src[60];
	int i_ci;
};

int (luaopen_base) (lua_State *L);
int (luaopen_table) (lua_State *L);
int (luaopen_io) (lua_State *L);
int (luaopen_os) (lua_State *L);
int (luaopen_string) (lua_State *L);
int (luaopen_math) (lua_State *L);
int (luaopen_debug) (lua_State *L);
int (luaopen_package) (lua_State *L);
void (luaL_openlibs) (lua_State *L);

typedef struct luaL_Reg {
  const char *name;
 lua_CFunction func;
} luaL_Reg;

void (luaL_openlib) (lua_State *L, const char *libname,
                                const luaL_Reg *l, int nup);
void (luaL_register) (lua_State *L, const char *libname,
                                const luaL_Reg *l);
int (luaL_getmetafield) (lua_State *L, int obj, const char *e);
int (luaL_callmeta) (lua_State *L, int obj, const char *e);
int (luaL_typerror) (lua_State *L, int narg, const char *tname);
int (luaL_argerror) (lua_State *L, int numarg, const char *extramsg);
const char *(luaL_checklstring) (lua_State *L, int numArg,
                                                          size_t *l);
const char *(luaL_optlstring) (lua_State *L, int numArg,
                                          const char *def, size_t *l);
lua_Number (luaL_checknumber) (lua_State *L, int numArg);
lua_Number (luaL_optnumber) (lua_State *L, int nArg, lua_Number def);

lua_Integer (luaL_checkinteger) (lua_State *L, int numArg);
lua_Integer (luaL_optinteger) (lua_State *L, int nArg,
                                          lua_Integer def);

void (luaL_checkstack) (lua_State *L, int sz, const char *msg);
void (luaL_checktype) (lua_State *L, int narg, int t);
void (luaL_checkany) (lua_State *L, int narg);

int (luaL_newmetatable) (lua_State *L, const char *tname);
void *(luaL_checkudata) (lua_State *L, int ud, const char *tname);

void (luaL_where) (lua_State *L, int lvl);
int (luaL_error) (lua_State *L, const char *fmt, ...);

int (luaL_checkoption) (lua_State *L, int narg, const char *def,
                                   const char *const lst[]);

int (luaL_ref) (lua_State *L, int t);
void (luaL_unref) (lua_State *L, int t, int ref);

int (luaL_loadfile) (lua_State *L, const char *filename);
int (luaL_loadbuffer) (lua_State *L, const char *buff, size_t sz,
                                  const char *name);
int (luaL_loadstring) (lua_State *L, const char *s);

lua_State *(luaL_newstate) (void);
const char *(luaL_gsub) (lua_State *L, const char *s, const char *p,
                                                  const char *r);

const char *(luaL_findtable) (lua_State *L, int idx,
                                         const char *fname, int szhint);
										 
typedef struct luaL_Buffer {
  char *p;
 int lvl;
 lua_State *L;
 char buffer[1024];
} luaL_Buffer;

void (luaL_buffinit) (lua_State *L, luaL_Buffer *B);
char *(luaL_prepbuffer) (luaL_Buffer *B);
void (luaL_addlstring) (luaL_Buffer *B, const char *s, size_t l);
void (luaL_addstring) (luaL_Buffer *B, const char *s);
void (luaL_addvalue) (luaL_Buffer *B);
void (luaL_pushresult) (luaL_Buffer *B);
]]
ffi.cdef(header)
local lib = ffi.C

-- emulating macros:
local lua = {}

lua.VERSION	= "Lua 5.1"
lua.RELEASE	= "Lua 5.1.4"
lua.VERSION_NUM	= 501
lua.COPYRIGHT	= "Copyright (C) 1994-2008 Lua.org, PUC-Rio"
lua.AUTHORS	= "R. Ierusalimschy, L. H. de Figueiredo & W. Celes"
lua.SIGNATURE	= "\033Lua"

lua.MULTRET	= (-1)

lua.REGISTRYINDEX	= (-10000)
lua.ENVIRONINDEX	= (-10001)
lua.GLOBALSINDEX	= (-10002)

lua.YIELD	= 1
lua.ERRRUN	= 2
lua.ERRSYNTAX	= 3
lua.ERRMEM	= 4
lua.ERRERR	= 5

lua.TNONE		= (-1)
lua.TNIL		= 0
lua.TBOOLEAN		= 1
lua.TLIGHTUSERDATA	= 2
lua.TNUMBER		= 3
lua.TSTRING		= 4
lua.TTABLE		= 5
lua.TFUNCTION		= 6
lua.TUSERDATA		= 7
lua.TTHREAD		= 8

lua.MINSTACK	= 20

lua.GCSTOP		= 0
lua.GCRESTART		= 1
lua.GCCOLLECT		= 2
lua.GCCOUNT		= 3
lua.GCCOUNTB		= 4
lua.GCSTEP		= 5
lua.GCSETPAUSE		= 6
lua.GCSETSTEPMUL	= 7
lua.HOOKCALL	= 0
lua.HOOKRET	= 1
lua.HOOKLINE	= 2
lua.HOOKCOUNT	= 3
lua.HOOKTAILRET = 4

lua.MASKCALL	= bit.lshift(1, lua.HOOKCALL)
lua.MASKRET	= bit.lshift(1, lua.HOOKRET)
lua.MASKLINE	= bit.lshift(1, lua.HOOKLINE)
lua.MASKCOUNT	= bit.lshift(1, lua.HOOKCOUNT)

lua.FILEHANDLE	= "FILE*"

lua.COLIBNAME	= "coroutine"
lua.MATHLIBNAME	= "math"
lua.STRLIBNAME	= "string"
lua.TABLIBNAME	= "table"
lua.IOLIBNAME	= "io"
lua.OSLIBNAME	= "os"
lua.LOADLIBNAME	= "package"
lua.DBLIBNAME	= "debug"
lua.BITLIBNAME	= "bit"
lua.JITLIBNAME	= "jit"
lua.FFILIBNAME	= "ffi"

lua.ERRFILE     = (lua.ERRERR+1)
lua.NOREF       = (-2)
lua.REFNIL      = (-1)

function lua.upvalueindex(i)	return (lua.GLOBALSINDEX-(i)) end

function lua.pop(L,n) return lib.lua_settop(L, -(n)-1) end
function lua.settop(L,n) return lib.lua_settop(L, n) end
function lua.newtable(L) return lib.lua_createtable(L, 0, 0) end

function lua.register(L,n,f) 
	lib.lua_pushcfunction(L, (f))
	lib.lua_setglobal(L, (n))
end

function lua.pushstring(L, s) return lib.lua_pushstring(L, s) end
function lua.pushcfunction(L,f)	return lib.lua_pushcclosure(L, (f), 0) end
function lua.strlen(L,i)		return lib.lua_objlen(L, (i)) end

function lua.isfunction(L,n)	return (lib.lua_type(L, (n)) == lua.TFUNCTION) end
function lua.istable(L,n)	return (lib.lua_type(L, (n)) == lua.TTABLE) end
function lua.islightuserdata(L,n)	return (lib.lua_type(L, (n)) == lua.TLIGHTUSERDATA) end
function lua.isnil(L,n)		return (lib.lua_type(L, (n)) == lua.TNIL) end
function lua.isboolean(L,n)	return (lib.lua_type(L, (n)) == lua.TBOOLEAN) end
function lua.isthread(L,n)	return (lib.lua_type(L, (n)) == lua.TTHREAD) end
function lua.isnone(L,n)		return (lib.lua_type(L, (n)) == lua.TNONE) end
function lua.isnoneornil(L, n)	return (lib.lua_type(L, (n)) <= 0) end

--[[
function lua.pushliteral(L, s)
	return lib.lua_pushlstring(L, "" s, (sizeof(s)/sizeof(char))-1) 
end
--]]

function lua.getfield(L,i,s) return lib.lua_getfield(L, i, s) end
function lua.setfield(L,i,s) return lib.lua_setfield(L, i, s) end

function lua.setglobal(L,s)	return lib.lua_setfield(L, lua.GLOBALSINDEX, (s)) end
function lua.getglobal(L,s)	return lib.lua_getfield(L, lua.GLOBALSINDEX, (s)) end
function lua.tostring(L,i)	return lib.lua_tolstring(L, (i), nil) end

-- Note: this does not install a __gc handler (by intention)
-- the state must be closed manually using L:close()
function lua.open()	return lib.luaL_newstate() end
function lua.close(L) return lib.lua_close(L) end
function lua.openlibs(L) return lib.luaL_openlibs(L) end

function lua.getregistry(L)	return lib.lua_pushvalue(L, lua.REGISTRYINDEX) end
function lua.getgccount(L)	return lib.lua_gc(L, lua.GCCOUNT, 0) end


function lua.getn(L,i)          return lib.lua_objlen(L, i) end
function lua.setn(L,i,j)        return end

function lua.argcheck(L, cond,numarg,extramsg)
	if not cond then lib.luaL_argerror(L, (numarg), (extramsg)) end
end

function lua.checkstring(L,n)	return (lib.luaL_checklstring(L, (n), NULL)) end
function lua.optstring(L,n,d)	return (lib.luaL_optlstring(L, (n), (d), NULL)) end
function lua.checkint(L,n)	return (lib.luaL_checkinteger(L, (n))) end
function lua.optint(L,n,d)	return (lib.luaL_optinteger(L, (n), (d))) end
function lua.checklong(L,n)	return (lib.luaL_checkinteger(L, (n))) end
function lua.optlong(L,n,d)	return (lib.luaL_optinteger(L, (n), (d))) end

function lua.typename(L,i)	
	return lib.lua_typename(L, lib.lua_type(L,(i))) 
end

function lua.dofile(L, fn, ...)
	local err = lib.luaL_loadfile(L, fn)
	if err ~= 0 then
		local errstr = lua.tostring(L, -1)
		error(ffi.string(errstr))
	end
	local argc = select("#", ...)
	for i = 1, argc do
		lua.push(L, (select(i, ...)))
	end
	err = lib.lua_pcall(L, argc, lua.MULTRET, 0) 
	if err ~= 0 then
		local errstr = lua.tostring(L, -1)
		error(ffi.string(errstr))
	end
end

function lua.push(L, v)
	if type(v) == "number" then
		lib.lua_pushnumber(L, v)
	elseif type(v) == "string" then
		lib.lua_pushstring(L, v)
	elseif type(v) == "nil" then
		lib.lua_pushnil(L)
	elseif type(v) == "boolean" then
		lib.lua_pushboolean(L, v)
	elseif type(v) == "userdata" then
		lib.lua_pushlightuserdata(L, v)
	else
		error("cannot push type " .. type(v))
	end
end

function lua.dostring(L, s, ...)
	local err = lib.luaL_loadstring(L, s)
	if err ~= 0 then
		local errstr = lua.tostring(L, -1)
		error(ffi.string(errstr),2)
	end
	
	local argc = select("#", ...)
	for i = 1, argc do
		lua.push(L, (select(i, ...)))
	end
	
	err = lib.lua_pcall(L, argc, lua.MULTRET, 0) 
	if err ~= 0 then
		local errstr = lua.tostring(L, -1)
		error(ffi.string(errstr))
	end
end

function lua.getmetatable(L,n)	
	return (lib.lua_getfield(L, lua.REGISTRYINDEX, (n))) 
end

function lua.opt(L,f,n,d)
	if lib.lua_isnoneornil(L,(n)) then
		return d
	else
		return f(L,(n)) 
	end
end

function lua.ref(L,lock) 
	if lock then 
		return lib.luaL_ref(L, lua.REGISTRYINDEX)
	else
		lib.lua_pushstring(L, "unlocked references are obsolete")
      	lib.lua_error(L)
    end
end
function lua.unref(L,ref)        return lib.luaL_unref(L, lua.REGISTRYINDEX, (ref)) end
function lua.getref(L,ref)       return lib.lua_rawgeti(L, lua.REGISTRYINDEX, (ref)) end

lua.reg	= ffi.typeof("luaL_Reg")

--[[ 
Access using L:<method> style
e.g.:

	local L = lua.open()
	L:openlibs)()
	L:close()

--]]
lua.__index = lua
ffi.metatype("struct lua_State", lua)

local function index(t, k)
	local prefixed = "lua_" .. k
	local v = lib[prefixed]
	t[k] = v
	return v
end
setmetatable(lua, { __index = index, })
return lua