-- rgbd: Accessing depth-cameras 

local ffi = require "ffi"
local lib = ffi.C

ffi.cdef [[
	typedef struct vec1 { double x, y; } vec1;
	typedef struct vec3 { double x, y, z; } vec3;
	typedef struct vec4 { double x, y, z, w; } vec4;
	typedef struct quat { double x, y, z, w; } quat;
	typedef struct mat4 { double data[16]; } mat4;
	typedef struct vec2f { float x, y; } vec2f;
	typedef struct vec3f { float x, y, z; } vec3f;
	typedef struct vec4f { float x, y, z, w; } vec4f;
	typedef struct quatf { float x, y, z, w; } quatf;
	typedef struct mat4f { float data[16]; } mat4f;

	typedef struct rgbd_device rgbd_device;
	typedef struct av_RGBDSensor {

	 rgbd_device * dev;
	 const char * serial;

	 void (*onframe)(struct av_RGBDSensor * self);

	 uint8_t rgb_back[640*480*3];
	 uint8_t depth_back[640*480*4];
	 vec3f rawpoints[640*480];
	 vec3f points[640*480];
	 int numpoints;
	 vec3f translate, rotate, scale;
	 vec3f minbound, maxbound;

	} av_RGBDSensor;

	typedef struct av_RGBD {

	 int numdevices;
	 av_RGBDSensor sensors[4];

	} av_RGBD;

	av_RGBD * av_rgbd_init();
	void av_rgbd_start();
	void av_rgbd_transform_rawpoints(av_RGBDSensor& sensor);
	void av_rgbd_draw(int dev, int w, int h);
	void av_rgbd_write_obj(int dev, const char * path);
]]

local rgbd = {
	start = lib.av_rgbd_start(),
	instance = lib.av_rgbd_init(),
}

local function fun(k) return lib["av_rgbd_"..k] end
local function index(t, k)
	-- check functions first
	local ok, fun = pcall(fun, k)
	if ok then
		t[k] = fun
	else
		-- allow access to raw calls as a fallback:
		-- gl.glClear()  etc.
		t[k] = lib[k]
	end
	return t[k]
end
-- add lazy loader:
return setmetatable(rgbd, { __index = index, })

