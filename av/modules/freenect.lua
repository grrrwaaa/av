
local ffi = require 'ffi'
local bit = require 'bit'
local libs = ffi_OpenGL_libs or {
   OSX     = { x86 = "modules/lib/OSX/freenect.dylib", x64 = "modules/lib/OSX/freenect.dylib" },
   --[[
   Windows = { x86 = "OPENGL32.DLL",            x64 = "OPENGL32.DLL" },
   Linux   = { x86 = "libGL.so",                x64 = "libGL.so", arm = "libGL.so" },
   Linux = { x86 = "libGL.so", x64 = "libGL.so" },
   BSD     = { x86 = "libGL.so",                x64 = "libGL.so" },
   POSIX   = { x86 = "libGL.so",                x64 = "libGL.so" },
   Other   = { x86 = "libGL.so",                x64 = "libGL.so" },
   --]]
}
local lib = lib or ffi.load( ffi_OpenGL_lib or libs[ ffi.os ][ ffi.arch ] )

ffi.cdef [[
typedef enum {
 FREENECT_DEVICE_MOTOR = 0x01,
 FREENECT_DEVICE_CAMERA = 0x02,
 FREENECT_DEVICE_AUDIO = 0x04,
} freenect_device_flags;
struct freenect_device_attributes;
struct freenect_device_attributes {
 struct freenect_device_attributes *next;
 const char* camera_serial;
};
typedef enum {
 FREENECT_RESOLUTION_LOW = 0,
 FREENECT_RESOLUTION_MEDIUM = 1,
 FREENECT_RESOLUTION_HIGH = 2,
 FREENECT_RESOLUTION_DUMMY = 2147483647,
} freenect_resolution;
typedef enum {
 FREENECT_VIDEO_RGB = 0,
 FREENECT_VIDEO_BAYER = 1,
 FREENECT_VIDEO_IR_8BIT = 2,
 FREENECT_VIDEO_IR_10BIT = 3,
 FREENECT_VIDEO_IR_10BIT_PACKED = 4,
 FREENECT_VIDEO_YUV_RGB = 5,
 FREENECT_VIDEO_YUV_RAW = 6,
 FREENECT_VIDEO_DUMMY = 2147483647,
} freenect_video_format;
typedef enum {
 FREENECT_DEPTH_11BIT = 0,
 FREENECT_DEPTH_10BIT = 1,
 FREENECT_DEPTH_11BIT_PACKED = 2,
 FREENECT_DEPTH_10BIT_PACKED = 3,
 FREENECT_DEPTH_REGISTERED = 4,
 FREENECT_DEPTH_MM = 5,
 FREENECT_DEPTH_DUMMY = 2147483647,
} freenect_depth_format;
typedef struct {
 uint32_t reserved;
 freenect_resolution resolution;
 union {
  int32_t dummy;
  freenect_video_format video_format;
  freenect_depth_format depth_format;
 };
 int32_t bytes;
 int16_t width;
 int16_t height;
 int8_t data_bits_per_pixel;
 int8_t padding_bits_per_pixel;
 int8_t framerate;
 int8_t is_valid;
} freenect_frame_mode;
typedef enum {
 FREENECT_LED_OFF = 0,
 FREENECT_LED_GREEN = 1,
 FREENECT_LED_RED = 2,
 FREENECT_LED_YELLOW = 3,
 FREENECT_LED_BLINK_GREEN = 4,
 FREENECT_LED_BLINK_RED_YELLOW = 6,
} freenect_led_options;
typedef enum {
 FREENECT_TILT_STATUS_STOPPED = 0x00,
 FREENECT_TILT_STATUS_LIMIT = 0x01,
 FREENECT_TILT_STATUS_MOVING = 0x04,
} freenect_tilt_status_code;
typedef struct {
 int16_t accelerometer_x;
 int16_t accelerometer_y;
 int16_t accelerometer_z;
 int8_t tilt_angle;
 freenect_tilt_status_code tilt_status;
} freenect_raw_tilt_state;

typedef struct freenect_context freenect_context;
typedef struct freenect_device freenect_device;
typedef void freenect_usb_context;

typedef enum {
 FREENECT_LOG_FATAL = 0,
 FREENECT_LOG_ERROR,
 FREENECT_LOG_WARNING,
 FREENECT_LOG_NOTICE,
 FREENECT_LOG_INFO,
 FREENECT_LOG_DEBUG,
 FREENECT_LOG_SPEW,
 FREENECT_LOG_FLOOD,
} freenect_loglevel;

 int freenect_init(freenect_context **ctx, freenect_usb_context *usb_ctx);
 int freenect_shutdown(freenect_context *ctx);
typedef void (*freenect_log_cb)(freenect_context *dev, freenect_loglevel level, const char *msg);
 void freenect_set_log_level(freenect_context *ctx, freenect_loglevel level);
 void freenect_set_log_callback(freenect_context *ctx, freenect_log_cb cb);
 int freenect_process_events(freenect_context *ctx);
 int freenect_process_events_timeout(freenect_context *ctx, struct timeval* timeout);
 int freenect_num_devices(freenect_context *ctx);
 int freenect_list_device_attributes(freenect_context *ctx, struct freenect_device_attributes** attribute_list);
 void freenect_free_device_attributes(struct freenect_device_attributes* attribute_list);
 int freenect_supported_subdevices(void);
 void freenect_select_subdevices(freenect_context *ctx, freenect_device_flags subdevs);
 int freenect_open_device(freenect_context *ctx, freenect_device **dev, int index);
 int freenect_open_device_by_camera_serial(freenect_context *ctx, freenect_device **dev, const char* camera_serial);
 int freenect_close_device(freenect_device *dev);
 void freenect_set_user(freenect_device *dev, void *user);
 void *freenect_get_user(freenect_device *dev);
typedef void (*freenect_depth_cb)(freenect_device *dev, void *depth, uint32_t timestamp);
typedef void (*freenect_video_cb)(freenect_device *dev, void *video, uint32_t timestamp);
 void freenect_set_depth_callback(freenect_device *dev, freenect_depth_cb cb);
 void freenect_set_video_callback(freenect_device *dev, freenect_video_cb cb);
 int freenect_set_depth_buffer(freenect_device *dev, void *buf);
 int freenect_set_video_buffer(freenect_device *dev, void *buf);
 int freenect_start_depth(freenect_device *dev);
 int freenect_start_video(freenect_device *dev);
 int freenect_stop_depth(freenect_device *dev);
 int freenect_stop_video(freenect_device *dev);
 int freenect_update_tilt_state(freenect_device *dev);
 freenect_raw_tilt_state* freenect_get_tilt_state(freenect_device *dev);
 double freenect_get_tilt_degs(freenect_raw_tilt_state *state);
 int freenect_set_tilt_degs(freenect_device *dev, double angle);
 freenect_tilt_status_code freenect_get_tilt_status(freenect_raw_tilt_state *state);
 int freenect_set_led(freenect_device *dev, freenect_led_options option);
 void freenect_get_mks_accel(freenect_raw_tilt_state *state, double* x, double* y, double* z);
 int freenect_get_video_mode_count();
 freenect_frame_mode freenect_get_video_mode(int mode_num);
 freenect_frame_mode freenect_get_current_video_mode(freenect_device *dev);
 freenect_frame_mode freenect_find_video_mode(freenect_resolution res, freenect_video_format fmt);
 int freenect_set_video_mode(freenect_device* dev, freenect_frame_mode mode);
 int freenect_get_depth_mode_count();
 freenect_frame_mode freenect_get_depth_mode(int mode_num);
 freenect_frame_mode freenect_get_current_depth_mode(freenect_device *dev);
 freenect_frame_mode freenect_find_depth_mode(freenect_resolution res, freenect_depth_format fmt);
 int freenect_set_depth_mode(freenect_device* dev, const freenect_frame_mode mode);
]]
			
local freenect = {
	lib = lib,
}

local function fun(k) return lib["freenect_"..k] end
local function enum(k) return lib["FREENECT_"..k] end
local function index(t, k)
	-- check functions first
	local ok, fun = pcall(fun, k)
	if ok then
		t[k] = fun
	else
		local ok, enum = pcall(enum, k)
		if ok then
			t[k] = enum
		else
			-- allow access to raw calls as a fallback:
			-- gl.glClear()  etc.
			t[k] = lib[k]
		end
	end
	return t[k]
end
-- add lazy loader:
setmetatable(freenect, { __index = index, })

return freenect