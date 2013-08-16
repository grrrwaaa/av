-- Forked from: https://github.com/malkia/ufo/

-- FFI based GL bindings
-- supports both gl.glClear() and gl.Clear() calling modes
-- adds generic functions, such as gl.Vertex in place of gl.Vertex4f etc.

local ffi = require 'ffi'
local bit = require 'bit'
local C = ffi.C

print("loading OpenGL")



local ok, lib
if ffi.os == "Linux" then
	
	-- prefer to use nvidia drivers if available:	
	local linux_libs = {
		"/usr/lib/nvidia-current/libGL.so",
		--"/usr/lib/nvidia-current-updates/libGL.so",
		"/usr/lib/nvidia-304/libGL.so",
		"GL",
	}
	
	for i, v in ipairs(linux_libs) do
		print("trying", i, v)
		ok, lib = pcall(ffi.load, v)
		if ok then
			print("using ", v)
			break
		end
	end
	assert(ok, "failed to load libGL.so")
	
elseif ffi.os == "OSX" then
	ok, lib = pcall(ffi.load, "OpenGL.framework/OpenGL")

elseif ffi.os == "Windows" then
	ok, lib = pcall(ffi.load, "OPENGL32.DLL")
	ffi.cdef[[
		void * wglGetProcAddress(const char *);
	]]
end

print(lib)

-- fall back to looking in executable:
if not ok then lib = ffi.C end

ffi.cdef [[
enum {
 GL_ACCUM                          = 0x0100,
 GL_LOAD                           = 0x0101,
 GL_RETURN                         = 0x0102,
 GL_MULT                           = 0x0103,
 GL_ADD                            = 0x0104,
 GL_NEVER                          = 0x0200,
 GL_LESS                           = 0x0201,
 GL_EQUAL                          = 0x0202,
 GL_LEQUAL                         = 0x0203,
 GL_GREATER                        = 0x0204,
 GL_NOTEQUAL                       = 0x0205,
 GL_GEQUAL                         = 0x0206,
 GL_ALWAYS                         = 0x0207,
 GL_CURRENT_BIT                    = 0x00000001,
 GL_POINT_BIT                      = 0x00000002,
 GL_LINE_BIT                       = 0x00000004,
 GL_POLYGON_BIT                    = 0x00000008,
 GL_POLYGON_STIPPLE_BIT            = 0x00000010,
 GL_PIXEL_MODE_BIT                 = 0x00000020,
 GL_LIGHTING_BIT                   = 0x00000040,
 GL_FOG_BIT                        = 0x00000080,
 GL_DEPTH_BUFFER_BIT               = 0x00000100,
 GL_ACCUM_BUFFER_BIT               = 0x00000200,
 GL_STENCIL_BUFFER_BIT             = 0x00000400,
 GL_VIEWPORT_BIT                   = 0x00000800,
 GL_TRANSFORM_BIT                  = 0x00001000,
 GL_ENABLE_BIT                     = 0x00002000,
 GL_COLOR_BUFFER_BIT               = 0x00004000,
 GL_HINT_BIT                       = 0x00008000,
 GL_EVAL_BIT                       = 0x00010000,
 GL_LIST_BIT                       = 0x00020000,
 GL_TEXTURE_BIT                    = 0x00040000,
 GL_SCISSOR_BIT                    = 0x00080000,
 GL_ALL_ATTRIB_BITS                = 0x000fffff,
 GL_POINTS                         = 0x0000,
 GL_LINES                          = 0x0001,
 GL_LINE_LOOP                      = 0x0002,
 GL_LINE_STRIP                     = 0x0003,
 GL_TRIANGLES                      = 0x0004,
 GL_TRIANGLE_STRIP                 = 0x0005,
 GL_TRIANGLE_FAN                   = 0x0006,
 GL_QUADS                          = 0x0007,
 GL_QUAD_STRIP                     = 0x0008,
 GL_POLYGON                        = 0x0009,
 GL_ZERO                           = 0,
 GL_ONE                            = 1,
 GL_SRC_COLOR                      = 0x0300,
 GL_ONE_MINUS_SRC_COLOR            = 0x0301,
 GL_SRC_ALPHA                      = 0x0302,
 GL_ONE_MINUS_SRC_ALPHA            = 0x0303,
 GL_DST_ALPHA                      = 0x0304,
 GL_ONE_MINUS_DST_ALPHA            = 0x0305,
 GL_DST_COLOR                      = 0x0306,
 GL_ONE_MINUS_DST_COLOR            = 0x0307,
 GL_SRC_ALPHA_SATURATE             = 0x0308,
 GL_TRUE                           = 1,
 GL_FALSE                          = 0,
 GL_CLIP_PLANE0                    = 0x3000,
 GL_CLIP_PLANE1                    = 0x3001,
 GL_CLIP_PLANE2                    = 0x3002,
 GL_CLIP_PLANE3                    = 0x3003,
 GL_CLIP_PLANE4                    = 0x3004,
 GL_CLIP_PLANE5                    = 0x3005,
 GL_BYTE                           = 0x1400,
 GL_UNSIGNED_BYTE                  = 0x1401,
 GL_SHORT                          = 0x1402,
 GL_UNSIGNED_SHORT                 = 0x1403,
 GL_INT                            = 0x1404,
 GL_UNSIGNED_INT                   = 0x1405,
 GL_FLOAT                          = 0x1406,
 GL_2_BYTES                        = 0x1407,
 GL_3_BYTES                        = 0x1408,
 GL_4_BYTES                        = 0x1409,
 GL_DOUBLE                         = 0x140A,
 GL_NONE                           = 0,
 GL_FRONT_LEFT                     = 0x0400,
 GL_FRONT_RIGHT                    = 0x0401,
 GL_BACK_LEFT                      = 0x0402,
 GL_BACK_RIGHT                     = 0x0403,
 GL_FRONT                          = 0x0404,
 GL_BACK                           = 0x0405,
 GL_LEFT                           = 0x0406,
 GL_RIGHT                          = 0x0407,
 GL_FRONT_AND_BACK                 = 0x0408,
 GL_AUX0                           = 0x0409,
 GL_AUX1                           = 0x040A,
 GL_AUX2                           = 0x040B,
 GL_AUX3                           = 0x040C,
 GL_NO_ERROR                       = 0,
 GL_INVALID_ENUM                   = 0x0500,
 GL_INVALID_VALUE                  = 0x0501,
 GL_INVALID_OPERATION              = 0x0502,
 GL_STACK_OVERFLOW                 = 0x0503,
 GL_STACK_UNDERFLOW                = 0x0504,
 GL_OUT_OF_MEMORY                  = 0x0505,
 GL_2D                             = 0x0600,
 GL_3D                             = 0x0601,
 GL_3D_COLOR                       = 0x0602,
 GL_3D_COLOR_TEXTURE               = 0x0603,
 GL_4D_COLOR_TEXTURE               = 0x0604,
 GL_PASS_THROUGH_TOKEN             = 0x0700,
 GL_POINT_TOKEN                    = 0x0701,
 GL_LINE_TOKEN                     = 0x0702,
 GL_POLYGON_TOKEN                  = 0x0703,
 GL_BITMAP_TOKEN                   = 0x0704,
 GL_DRAW_PIXEL_TOKEN               = 0x0705,
 GL_COPY_PIXEL_TOKEN               = 0x0706,
 GL_LINE_RESET_TOKEN               = 0x0707,
 GL_EXP                            = 0x0800,
 GL_EXP2                           = 0x0801,
 GL_CW                             = 0x0900,
 GL_CCW                            = 0x0901,
 GL_COEFF                          = 0x0A00,
 GL_ORDER                          = 0x0A01,
 GL_DOMAIN                         = 0x0A02,
 GL_CURRENT_COLOR                  = 0x0B00,
 GL_CURRENT_INDEX                  = 0x0B01,
 GL_CURRENT_NORMAL                 = 0x0B02,
 GL_CURRENT_TEXTURE_COORDS         = 0x0B03,
 GL_CURRENT_RASTER_COLOR           = 0x0B04,
 GL_CURRENT_RASTER_INDEX           = 0x0B05,
 GL_CURRENT_RASTER_TEXTURE_COORDS  = 0x0B06,
 GL_CURRENT_RASTER_POSITION        = 0x0B07,
 GL_CURRENT_RASTER_POSITION_VALID  = 0x0B08,
 GL_CURRENT_RASTER_DISTANCE        = 0x0B09,
 GL_POINT_SMOOTH                   = 0x0B10,
 GL_POINT_SIZE                     = 0x0B11,
 GL_POINT_SIZE_RANGE               = 0x0B12,
 GL_POINT_SIZE_GRANULARITY         = 0x0B13,
 GL_LINE_SMOOTH                    = 0x0B20,
 GL_LINE_WIDTH                     = 0x0B21,
 GL_LINE_WIDTH_RANGE               = 0x0B22,
 GL_LINE_WIDTH_GRANULARITY         = 0x0B23,
 GL_LINE_STIPPLE                   = 0x0B24,
 GL_LINE_STIPPLE_PATTERN           = 0x0B25,
 GL_LINE_STIPPLE_REPEAT            = 0x0B26,
 GL_LIST_MODE                      = 0x0B30,
 GL_MAX_LIST_NESTING               = 0x0B31,
 GL_LIST_BASE                      = 0x0B32,
 GL_LIST_INDEX                     = 0x0B33,
 GL_POLYGON_MODE                   = 0x0B40,
 GL_POLYGON_SMOOTH                 = 0x0B41,
 GL_POLYGON_STIPPLE                = 0x0B42,
 GL_EDGE_FLAG                      = 0x0B43,
 GL_CULL_FACE                      = 0x0B44,
 GL_CULL_FACE_MODE                 = 0x0B45,
 GL_FRONT_FACE                     = 0x0B46,
 GL_LIGHTING                       = 0x0B50,
 GL_LIGHT_MODEL_LOCAL_VIEWER       = 0x0B51,
 GL_LIGHT_MODEL_TWO_SIDE           = 0x0B52,
 GL_LIGHT_MODEL_AMBIENT            = 0x0B53,
 GL_SHADE_MODEL                    = 0x0B54,
 GL_COLOR_MATERIAL_FACE            = 0x0B55,
 GL_COLOR_MATERIAL_PARAMETER       = 0x0B56,
 GL_COLOR_MATERIAL                 = 0x0B57,
 GL_FOG                            = 0x0B60,
 GL_FOG_INDEX                      = 0x0B61,
 GL_FOG_DENSITY                    = 0x0B62,
 GL_FOG_START                      = 0x0B63,
 GL_FOG_END                        = 0x0B64,
 GL_FOG_MODE                       = 0x0B65,
 GL_FOG_COLOR                      = 0x0B66,
 GL_DEPTH_RANGE                    = 0x0B70,
 GL_DEPTH_TEST                     = 0x0B71,
 GL_DEPTH_WRITEMASK                = 0x0B72,
 GL_DEPTH_CLEAR_VALUE              = 0x0B73,
 GL_DEPTH_FUNC                     = 0x0B74,
 GL_ACCUM_CLEAR_VALUE              = 0x0B80,
 GL_STENCIL_TEST                   = 0x0B90,
 GL_STENCIL_CLEAR_VALUE            = 0x0B91,
 GL_STENCIL_FUNC                   = 0x0B92,
 GL_STENCIL_VALUE_MASK             = 0x0B93,
 GL_STENCIL_FAIL                   = 0x0B94,
 GL_STENCIL_PASS_DEPTH_FAIL        = 0x0B95,
 GL_STENCIL_PASS_DEPTH_PASS        = 0x0B96,
 GL_STENCIL_REF                    = 0x0B97,
 GL_STENCIL_WRITEMASK              = 0x0B98,
 GL_MATRIX_MODE                    = 0x0BA0,
 GL_NORMALIZE                      = 0x0BA1,
 GL_VIEWPORT                       = 0x0BA2,
 GL_MODELVIEW_STACK_DEPTH          = 0x0BA3,
 GL_PROJECTION_STACK_DEPTH         = 0x0BA4,
 GL_TEXTURE_STACK_DEPTH            = 0x0BA5,
 GL_MODELVIEW_MATRIX               = 0x0BA6,
 GL_PROJECTION_MATRIX              = 0x0BA7,
 GL_TEXTURE_MATRIX                 = 0x0BA8,
 GL_ATTRIB_STACK_DEPTH             = 0x0BB0,
 GL_CLIENT_ATTRIB_STACK_DEPTH      = 0x0BB1,
 GL_ALPHA_TEST                     = 0x0BC0,
 GL_ALPHA_TEST_FUNC                = 0x0BC1,
 GL_ALPHA_TEST_REF                 = 0x0BC2,
 GL_DITHER                         = 0x0BD0,
 GL_BLEND_DST                      = 0x0BE0,
 GL_BLEND_SRC                      = 0x0BE1,
 GL_BLEND                          = 0x0BE2,
 GL_LOGIC_OP_MODE                  = 0x0BF0,
 GL_INDEX_LOGIC_OP                 = 0x0BF1,
 GL_COLOR_LOGIC_OP                 = 0x0BF2,
 GL_AUX_BUFFERS                    = 0x0C00,
 GL_DRAW_BUFFER                    = 0x0C01,
 GL_READ_BUFFER                    = 0x0C02,
 GL_SCISSOR_BOX                    = 0x0C10,
 GL_SCISSOR_TEST                   = 0x0C11,
 GL_INDEX_CLEAR_VALUE              = 0x0C20,
 GL_INDEX_WRITEMASK                = 0x0C21,
 GL_COLOR_CLEAR_VALUE              = 0x0C22,
 GL_COLOR_WRITEMASK                = 0x0C23,
 GL_INDEX_MODE                     = 0x0C30,
 GL_RGBA_MODE                      = 0x0C31,
 GL_DOUBLEBUFFER                   = 0x0C32,
 GL_STEREO                         = 0x0C33,
 GL_RENDER_MODE                    = 0x0C40,
 GL_PERSPECTIVE_CORRECTION_HINT    = 0x0C50,
 GL_POINT_SMOOTH_HINT              = 0x0C51,
 GL_LINE_SMOOTH_HINT               = 0x0C52,
 GL_POLYGON_SMOOTH_HINT            = 0x0C53,
 GL_FOG_HINT                       = 0x0C54,
 GL_TEXTURE_GEN_S                  = 0x0C60,
 GL_TEXTURE_GEN_T                  = 0x0C61,
 GL_TEXTURE_GEN_R                  = 0x0C62,
 GL_TEXTURE_GEN_Q                  = 0x0C63,
 GL_PIXEL_MAP_I_TO_I               = 0x0C70,
 GL_PIXEL_MAP_S_TO_S               = 0x0C71,
 GL_PIXEL_MAP_I_TO_R               = 0x0C72,
 GL_PIXEL_MAP_I_TO_G               = 0x0C73,
 GL_PIXEL_MAP_I_TO_B               = 0x0C74,
 GL_PIXEL_MAP_I_TO_A               = 0x0C75,
 GL_PIXEL_MAP_R_TO_R               = 0x0C76,
 GL_PIXEL_MAP_G_TO_G               = 0x0C77,
 GL_PIXEL_MAP_B_TO_B               = 0x0C78,
 GL_PIXEL_MAP_A_TO_A               = 0x0C79,
 GL_PIXEL_MAP_I_TO_I_SIZE          = 0x0CB0,
 GL_PIXEL_MAP_S_TO_S_SIZE          = 0x0CB1,
 GL_PIXEL_MAP_I_TO_R_SIZE          = 0x0CB2,
 GL_PIXEL_MAP_I_TO_G_SIZE          = 0x0CB3,
 GL_PIXEL_MAP_I_TO_B_SIZE          = 0x0CB4,
 GL_PIXEL_MAP_I_TO_A_SIZE          = 0x0CB5,
 GL_PIXEL_MAP_R_TO_R_SIZE          = 0x0CB6,
 GL_PIXEL_MAP_G_TO_G_SIZE          = 0x0CB7,
 GL_PIXEL_MAP_B_TO_B_SIZE          = 0x0CB8,
 GL_PIXEL_MAP_A_TO_A_SIZE          = 0x0CB9,
 GL_UNPACK_SWAP_BYTES              = 0x0CF0,
 GL_UNPACK_LSB_FIRST               = 0x0CF1,
 GL_UNPACK_ROW_LENGTH              = 0x0CF2,
 GL_UNPACK_SKIP_ROWS               = 0x0CF3,
 GL_UNPACK_SKIP_PIXELS             = 0x0CF4,
 GL_UNPACK_ALIGNMENT               = 0x0CF5,
 GL_PACK_SWAP_BYTES                = 0x0D00,
 GL_PACK_LSB_FIRST                 = 0x0D01,
 GL_PACK_ROW_LENGTH                = 0x0D02,
 GL_PACK_SKIP_ROWS                 = 0x0D03,
 GL_PACK_SKIP_PIXELS               = 0x0D04,
 GL_PACK_ALIGNMENT                 = 0x0D05,
 GL_MAP_COLOR                      = 0x0D10,
 GL_MAP_STENCIL                    = 0x0D11,
 GL_INDEX_SHIFT                    = 0x0D12,
 GL_INDEX_OFFSET                   = 0x0D13,
 GL_RED_SCALE                      = 0x0D14,
 GL_RED_BIAS                       = 0x0D15,
 GL_ZOOM_X                         = 0x0D16,
 GL_ZOOM_Y                         = 0x0D17,
 GL_GREEN_SCALE                    = 0x0D18,
 GL_GREEN_BIAS                     = 0x0D19,
 GL_BLUE_SCALE                     = 0x0D1A,
 GL_BLUE_BIAS                      = 0x0D1B,
 GL_ALPHA_SCALE                    = 0x0D1C,
 GL_ALPHA_BIAS                     = 0x0D1D,
 GL_DEPTH_SCALE                    = 0x0D1E,
 GL_DEPTH_BIAS                     = 0x0D1F,
 GL_MAX_EVAL_ORDER                 = 0x0D30,
 GL_MAX_LIGHTS                     = 0x0D31,
 GL_MAX_CLIP_PLANES                = 0x0D32,
 GL_MAX_TEXTURE_SIZE               = 0x0D33,
 GL_MAX_PIXEL_MAP_TABLE            = 0x0D34,
 GL_MAX_ATTRIB_STACK_DEPTH         = 0x0D35,
 GL_MAX_MODELVIEW_STACK_DEPTH      = 0x0D36,
 GL_MAX_NAME_STACK_DEPTH           = 0x0D37,
 GL_MAX_PROJECTION_STACK_DEPTH     = 0x0D38,
 GL_MAX_TEXTURE_STACK_DEPTH        = 0x0D39,
 GL_MAX_VIEWPORT_DIMS              = 0x0D3A,
 GL_MAX_CLIENT_ATTRIB_STACK_DEPTH  = 0x0D3B,
 GL_SUBPIXEL_BITS                  = 0x0D50,
 GL_INDEX_BITS                     = 0x0D51,
 GL_RED_BITS                       = 0x0D52,
 GL_GREEN_BITS                     = 0x0D53,
 GL_BLUE_BITS                      = 0x0D54,
 GL_ALPHA_BITS                     = 0x0D55,
 GL_DEPTH_BITS                     = 0x0D56,
 GL_STENCIL_BITS                   = 0x0D57,
 GL_ACCUM_RED_BITS                 = 0x0D58,
 GL_ACCUM_GREEN_BITS               = 0x0D59,
 GL_ACCUM_BLUE_BITS                = 0x0D5A,
 GL_ACCUM_ALPHA_BITS               = 0x0D5B,
 GL_NAME_STACK_DEPTH               = 0x0D70,
 GL_AUTO_NORMAL                    = 0x0D80,
 GL_MAP1_COLOR_4                   = 0x0D90,
 GL_MAP1_INDEX                     = 0x0D91,
 GL_MAP1_NORMAL                    = 0x0D92,
 GL_MAP1_TEXTURE_COORD_1           = 0x0D93,
 GL_MAP1_TEXTURE_COORD_2           = 0x0D94,
 GL_MAP1_TEXTURE_COORD_3           = 0x0D95,
 GL_MAP1_TEXTURE_COORD_4           = 0x0D96,
 GL_MAP1_VERTEX_3                  = 0x0D97,
 GL_MAP1_VERTEX_4                  = 0x0D98,
 GL_MAP2_COLOR_4                   = 0x0DB0,
 GL_MAP2_INDEX                     = 0x0DB1,
 GL_MAP2_NORMAL                    = 0x0DB2,
 GL_MAP2_TEXTURE_COORD_1           = 0x0DB3,
 GL_MAP2_TEXTURE_COORD_2           = 0x0DB4,
 GL_MAP2_TEXTURE_COORD_3           = 0x0DB5,
 GL_MAP2_TEXTURE_COORD_4           = 0x0DB6,
 GL_MAP2_VERTEX_3                  = 0x0DB7,
 GL_MAP2_VERTEX_4                  = 0x0DB8,
 GL_MAP1_GRID_DOMAIN               = 0x0DD0,
 GL_MAP1_GRID_SEGMENTS             = 0x0DD1,
 GL_MAP2_GRID_DOMAIN               = 0x0DD2,
 GL_MAP2_GRID_SEGMENTS             = 0x0DD3,
 GL_TEXTURE_1D                     = 0x0DE0,
 GL_TEXTURE_2D                     = 0x0DE1,
 GL_FEEDBACK_BUFFER_POINTER        = 0x0DF0,
 GL_FEEDBACK_BUFFER_SIZE           = 0x0DF1,
 GL_FEEDBACK_BUFFER_TYPE           = 0x0DF2,
 GL_SELECTION_BUFFER_POINTER       = 0x0DF3,
 GL_SELECTION_BUFFER_SIZE          = 0x0DF4,
 GL_TEXTURE_WIDTH                  = 0x1000,
 GL_TEXTURE_HEIGHT                 = 0x1001,
 GL_TEXTURE_INTERNAL_FORMAT        = 0x1003,
 GL_TEXTURE_BORDER_COLOR           = 0x1004,
 GL_TEXTURE_BORDER                 = 0x1005,
 GL_DONT_CARE                      = 0x1100,
 GL_FASTEST                        = 0x1101,
 GL_NICEST                         = 0x1102,
 GL_LIGHT0                         = 0x4000,
 GL_LIGHT1                         = 0x4001,
 GL_LIGHT2                         = 0x4002,
 GL_LIGHT3                         = 0x4003,
 GL_LIGHT4                         = 0x4004,
 GL_LIGHT5                         = 0x4005,
 GL_LIGHT6                         = 0x4006,
 GL_LIGHT7                         = 0x4007,
 GL_AMBIENT                        = 0x1200,
 GL_DIFFUSE                        = 0x1201,
 GL_SPECULAR                       = 0x1202,
 GL_POSITION                       = 0x1203,
 GL_SPOT_DIRECTION                 = 0x1204,
 GL_SPOT_EXPONENT                  = 0x1205,
 GL_SPOT_CUTOFF                    = 0x1206,
 GL_CONSTANT_ATTENUATION           = 0x1207,
 GL_LINEAR_ATTENUATION             = 0x1208,
 GL_QUADRATIC_ATTENUATION          = 0x1209,
 GL_COMPILE                        = 0x1300,
 GL_COMPILE_AND_EXECUTE            = 0x1301,
 GL_CLEAR                          = 0x1500,
 GL_AND                            = 0x1501,
 GL_AND_REVERSE                    = 0x1502,
 GL_COPY                           = 0x1503,
 GL_AND_INVERTED                   = 0x1504,
 GL_NOOP                           = 0x1505,
 GL_XOR                            = 0x1506,
 GL_OR                             = 0x1507,
 GL_NOR                            = 0x1508,
 GL_EQUIV                          = 0x1509,
 GL_INVERT                         = 0x150A,
 GL_OR_REVERSE                     = 0x150B,
 GL_COPY_INVERTED                  = 0x150C,
 GL_OR_INVERTED                    = 0x150D,
 GL_NAND                           = 0x150E,
 GL_SET                            = 0x150F,
 GL_EMISSION                       = 0x1600,
 GL_SHININESS                      = 0x1601,
 GL_AMBIENT_AND_DIFFUSE            = 0x1602,
 GL_COLOR_INDEXES                  = 0x1603,
 GL_MODELVIEW                      = 0x1700,
 GL_PROJECTION                     = 0x1701,
 GL_TEXTURE                        = 0x1702,
 GL_COLOR                          = 0x1800,
 GL_DEPTH                          = 0x1801,
 GL_STENCIL                        = 0x1802,
 GL_COLOR_INDEX                    = 0x1900,
 GL_STENCIL_INDEX                  = 0x1901,
 GL_DEPTH_COMPONENT                = 0x1902,
 GL_RED                            = 0x1903,
 GL_GREEN                          = 0x1904,
 GL_BLUE                           = 0x1905,
 GL_ALPHA                          = 0x1906,
 GL_RGB                            = 0x1907,
 GL_RGBA                           = 0x1908,
 GL_LUMINANCE                      = 0x1909,
 GL_LUMINANCE_ALPHA                = 0x190A,
 GL_BITMAP                         = 0x1A00,
 GL_POINT                          = 0x1B00,
 GL_LINE                           = 0x1B01,
 GL_FILL                           = 0x1B02,
 GL_RENDER                         = 0x1C00,
 GL_FEEDBACK                       = 0x1C01,
 GL_SELECT                         = 0x1C02,
 GL_FLAT                           = 0x1D00,
 GL_SMOOTH                         = 0x1D01,
 GL_KEEP                           = 0x1E00,
 GL_REPLACE                        = 0x1E01,
 GL_INCR                           = 0x1E02,
 GL_DECR                           = 0x1E03,
 GL_VENDOR                         = 0x1F00,
 GL_RENDERER                       = 0x1F01,
 GL_VERSION                        = 0x1F02,
 GL_EXTENSIONS                     = 0x1F03,
 GL_S                              = 0x2000,
 GL_T                              = 0x2001,
 GL_R                              = 0x2002,
 GL_Q                              = 0x2003,
 GL_MODULATE                       = 0x2100,
 GL_DECAL                          = 0x2101,
 GL_TEXTURE_ENV_MODE               = 0x2200,
 GL_TEXTURE_ENV_COLOR              = 0x2201,
 GL_TEXTURE_ENV                    = 0x2300,
 GL_EYE_LINEAR                     = 0x2400,
 GL_OBJECT_LINEAR                  = 0x2401,
 GL_SPHERE_MAP                     = 0x2402,
 GL_TEXTURE_GEN_MODE               = 0x2500,
 GL_OBJECT_PLANE                   = 0x2501,
 GL_EYE_PLANE                      = 0x2502,
 GL_NEAREST                        = 0x2600,
 GL_LINEAR                         = 0x2601,
 GL_NEAREST_MIPMAP_NEAREST         = 0x2700,
 GL_LINEAR_MIPMAP_NEAREST          = 0x2701,
 GL_NEAREST_MIPMAP_LINEAR          = 0x2702,
 GL_LINEAR_MIPMAP_LINEAR           = 0x2703,
 GL_TEXTURE_MAG_FILTER             = 0x2800,
 GL_TEXTURE_MIN_FILTER             = 0x2801,
 GL_TEXTURE_WRAP_S                 = 0x2802,
 GL_TEXTURE_WRAP_T                 = 0x2803,
 GL_CLAMP                          = 0x2900,
 GL_REPEAT                         = 0x2901,
 GL_CLIENT_PIXEL_STORE_BIT         = 0x00000001,
 GL_CLIENT_VERTEX_ARRAY_BIT        = 0x00000002,
 GL_CLIENT_ALL_ATTRIB_BITS         = 0xffffffff,
 GL_POLYGON_OFFSET_FACTOR          = 0x8038,
 GL_POLYGON_OFFSET_UNITS           = 0x2A00,
 GL_POLYGON_OFFSET_POINT           = 0x2A01,
 GL_POLYGON_OFFSET_LINE            = 0x2A02,
 GL_POLYGON_OFFSET_FILL            = 0x8037,
 GL_ALPHA4                         = 0x803B,
 GL_ALPHA8                         = 0x803C,
 GL_ALPHA12                        = 0x803D,
 GL_ALPHA16                        = 0x803E,
 GL_LUMINANCE4                     = 0x803F,
 GL_LUMINANCE8                     = 0x8040,
 GL_LUMINANCE12                    = 0x8041,
 GL_LUMINANCE16                    = 0x8042,
 GL_LUMINANCE4_ALPHA4              = 0x8043,
 GL_LUMINANCE6_ALPHA2              = 0x8044,
 GL_LUMINANCE8_ALPHA8              = 0x8045,
 GL_LUMINANCE12_ALPHA4             = 0x8046,
 GL_LUMINANCE12_ALPHA12            = 0x8047,
 GL_LUMINANCE16_ALPHA16            = 0x8048,
 GL_INTENSITY                      = 0x8049,
 GL_INTENSITY4                     = 0x804A,
 GL_INTENSITY8                     = 0x804B,
 GL_INTENSITY12                    = 0x804C,
 GL_INTENSITY16                    = 0x804D,
 GL_R3_G3_B2                       = 0x2A10,
 GL_RGB4                           = 0x804F,
 GL_RGB5                           = 0x8050,
 GL_RGB8                           = 0x8051,
 GL_RGB10                          = 0x8052,
 GL_RGB12                          = 0x8053,
 GL_RGB16                          = 0x8054,
 GL_RGBA2                          = 0x8055,
 GL_RGBA4                          = 0x8056,
 GL_RGB5_A1                        = 0x8057,
 GL_RGBA8                          = 0x8058,
 GL_RGB10_A2                       = 0x8059,
 GL_RGBA12                         = 0x805A,
 GL_RGBA16                         = 0x805B,
 GL_TEXTURE_RED_SIZE               = 0x805C,
 GL_TEXTURE_GREEN_SIZE             = 0x805D,
 GL_TEXTURE_BLUE_SIZE              = 0x805E,
 GL_TEXTURE_ALPHA_SIZE             = 0x805F,
 GL_TEXTURE_LUMINANCE_SIZE         = 0x8060,
 GL_TEXTURE_INTENSITY_SIZE         = 0x8061,
 GL_PROXY_TEXTURE_1D               = 0x8063,
 GL_PROXY_TEXTURE_2D               = 0x8064,
 GL_TEXTURE_PRIORITY               = 0x8066,
 GL_TEXTURE_RESIDENT               = 0x8067,
 GL_TEXTURE_BINDING_1D             = 0x8068,
 GL_TEXTURE_BINDING_2D             = 0x8069,
 GL_TEXTURE_BINDING_3D             = 0x806A,
 GL_VERTEX_ARRAY                   = 0x8074,
 GL_NORMAL_ARRAY                   = 0x8075,
 GL_COLOR_ARRAY                    = 0x8076,
 GL_INDEX_ARRAY                    = 0x8077,
 GL_TEXTURE_COORD_ARRAY            = 0x8078,
 GL_EDGE_FLAG_ARRAY                = 0x8079,
 GL_VERTEX_ARRAY_SIZE              = 0x807A,
 GL_VERTEX_ARRAY_TYPE              = 0x807B,
 GL_VERTEX_ARRAY_STRIDE            = 0x807C,
 GL_NORMAL_ARRAY_TYPE              = 0x807E,
 GL_NORMAL_ARRAY_STRIDE            = 0x807F,
 GL_COLOR_ARRAY_SIZE               = 0x8081,
 GL_COLOR_ARRAY_TYPE               = 0x8082,
 GL_COLOR_ARRAY_STRIDE             = 0x8083,
 GL_INDEX_ARRAY_TYPE               = 0x8085,
 GL_INDEX_ARRAY_STRIDE             = 0x8086,
 GL_TEXTURE_COORD_ARRAY_SIZE       = 0x8088,
 GL_TEXTURE_COORD_ARRAY_TYPE       = 0x8089,
 GL_TEXTURE_COORD_ARRAY_STRIDE     = 0x808A,
 GL_EDGE_FLAG_ARRAY_STRIDE         = 0x808C,
 GL_VERTEX_ARRAY_POINTER           = 0x808E,
 GL_NORMAL_ARRAY_POINTER           = 0x808F,
 GL_COLOR_ARRAY_POINTER            = 0x8090,
 GL_INDEX_ARRAY_POINTER            = 0x8091,
 GL_TEXTURE_COORD_ARRAY_POINTER    = 0x8092,
 GL_EDGE_FLAG_ARRAY_POINTER        = 0x8093,
 GL_V2F                            = 0x2A20,
 GL_V3F                            = 0x2A21,
 GL_C4UB_V2F                       = 0x2A22,
 GL_C4UB_V3F                       = 0x2A23,
 GL_C3F_V3F                        = 0x2A24,
 GL_N3F_V3F                        = 0x2A25,
 GL_C4F_N3F_V3F                    = 0x2A26,
 GL_T2F_V3F                        = 0x2A27,
 GL_T4F_V4F                        = 0x2A28,
 GL_T2F_C4UB_V3F                   = 0x2A29,
 GL_T2F_C3F_V3F                    = 0x2A2A,
 GL_T2F_N3F_V3F                    = 0x2A2B,
 GL_T2F_C4F_N3F_V3F                = 0x2A2C,
 GL_T4F_C4F_N3F_V4F                = 0x2A2D,
 GL_BGR                            = 0x80E0,
 GL_BGRA                           = 0x80E1,
 GL_CONSTANT_COLOR                 = 0x8001,
 GL_ONE_MINUS_CONSTANT_COLOR       = 0x8002,
 GL_CONSTANT_ALPHA                 = 0x8003,
 GL_ONE_MINUS_CONSTANT_ALPHA       = 0x8004,
 GL_BLEND_COLOR                    = 0x8005,
 GL_FUNC_ADD                       = 0x8006,
 GL_MIN                            = 0x8007,
 GL_MAX                            = 0x8008,
 GL_BLEND_EQUATION                 = 0x8009,
 GL_BLEND_EQUATION_RGB             = 0x8009,
 GL_BLEND_EQUATION_ALPHA           = 0x883D,
 GL_FUNC_SUBTRACT                  = 0x800A,
 GL_FUNC_REVERSE_SUBTRACT          = 0x800B,
 GL_COLOR_MATRIX                   = 0x80B1,
 GL_COLOR_MATRIX_STACK_DEPTH       = 0x80B2,
 GL_MAX_COLOR_MATRIX_STACK_DEPTH   = 0x80B3,
 GL_POST_COLOR_MATRIX_RED_SCALE    = 0x80B4,
 GL_POST_COLOR_MATRIX_GREEN_SCALE  = 0x80B5,
 GL_POST_COLOR_MATRIX_BLUE_SCALE   = 0x80B6,
 GL_POST_COLOR_MATRIX_ALPHA_SCALE  = 0x80B7,
 GL_POST_COLOR_MATRIX_RED_BIAS     = 0x80B8,
 GL_POST_COLOR_MATRIX_GREEN_BIAS   = 0x80B9,
 GL_POST_COLOR_MATRIX_BLUE_BIAS    = 0x80BA,
 GL_POST_COLOR_MATRIX_ALPHA_BIAS   = 0x80BB,
 GL_COLOR_TABLE                    = 0x80D0,
 GL_POST_CONVOLUTION_COLOR_TABLE   = 0x80D1,
 GL_POST_COLOR_MATRIX_COLOR_TABLE  = 0x80D2,
 GL_PROXY_COLOR_TABLE              = 0x80D3,
 GL_PROXY_POST_CONVOLUTION_COLOR_TABLE = 0x80D4,
 GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE = 0x80D5,
 GL_COLOR_TABLE_SCALE              = 0x80D6,
 GL_COLOR_TABLE_BIAS               = 0x80D7,
 GL_COLOR_TABLE_FORMAT             = 0x80D8,
 GL_COLOR_TABLE_WIDTH              = 0x80D9,
 GL_COLOR_TABLE_RED_SIZE           = 0x80DA,
 GL_COLOR_TABLE_GREEN_SIZE         = 0x80DB,
 GL_COLOR_TABLE_BLUE_SIZE          = 0x80DC,
 GL_COLOR_TABLE_ALPHA_SIZE         = 0x80DD,
 GL_COLOR_TABLE_LUMINANCE_SIZE     = 0x80DE,
 GL_COLOR_TABLE_INTENSITY_SIZE     = 0x80DF,
 GL_CONVOLUTION_1D                 = 0x8010,
 GL_CONVOLUTION_2D                 = 0x8011,
 GL_SEPARABLE_2D                   = 0x8012,
 GL_CONVOLUTION_BORDER_MODE        = 0x8013,
 GL_CONVOLUTION_FILTER_SCALE       = 0x8014,
 GL_CONVOLUTION_FILTER_BIAS        = 0x8015,
 GL_REDUCE                         = 0x8016,
 GL_CONVOLUTION_FORMAT             = 0x8017,
 GL_CONVOLUTION_WIDTH              = 0x8018,
 GL_CONVOLUTION_HEIGHT             = 0x8019,
 GL_MAX_CONVOLUTION_WIDTH          = 0x801A,
 GL_MAX_CONVOLUTION_HEIGHT         = 0x801B,
 GL_POST_CONVOLUTION_RED_SCALE     = 0x801C,
 GL_POST_CONVOLUTION_GREEN_SCALE   = 0x801D,
 GL_POST_CONVOLUTION_BLUE_SCALE    = 0x801E,
 GL_POST_CONVOLUTION_ALPHA_SCALE   = 0x801F,
 GL_POST_CONVOLUTION_RED_BIAS      = 0x8020,
 GL_POST_CONVOLUTION_GREEN_BIAS    = 0x8021,
 GL_POST_CONVOLUTION_BLUE_BIAS     = 0x8022,
 GL_POST_CONVOLUTION_ALPHA_BIAS    = 0x8023,
 GL_CONSTANT_BORDER                = 0x8151,
 GL_REPLICATE_BORDER               = 0x8153,
 GL_CONVOLUTION_BORDER_COLOR       = 0x8154,
 GL_MAX_ELEMENTS_VERTICES          = 0x80E8,
 GL_MAX_ELEMENTS_INDICES           = 0x80E9,
 GL_HISTOGRAM                      = 0x8024,
 GL_PROXY_HISTOGRAM                = 0x8025,
 GL_HISTOGRAM_WIDTH                = 0x8026,
 GL_HISTOGRAM_FORMAT               = 0x8027,
 GL_HISTOGRAM_RED_SIZE             = 0x8028,
 GL_HISTOGRAM_GREEN_SIZE           = 0x8029,
 GL_HISTOGRAM_BLUE_SIZE            = 0x802A,
 GL_HISTOGRAM_ALPHA_SIZE           = 0x802B,
 GL_HISTOGRAM_LUMINANCE_SIZE       = 0x802C,
 GL_HISTOGRAM_SINK                 = 0x802D,
 GL_MINMAX                         = 0x802E,
 GL_MINMAX_FORMAT                  = 0x802F,
 GL_MINMAX_SINK                    = 0x8030,
 GL_TABLE_TOO_LARGE                = 0x8031,
 GL_UNSIGNED_BYTE_3_3_2            = 0x8032,
 GL_UNSIGNED_SHORT_4_4_4_4         = 0x8033,
 GL_UNSIGNED_SHORT_5_5_5_1         = 0x8034,
 GL_UNSIGNED_INT_8_8_8_8           = 0x8035,
 GL_UNSIGNED_INT_10_10_10_2        = 0x8036,
 GL_UNSIGNED_BYTE_2_3_3_REV        = 0x8362,
 GL_UNSIGNED_SHORT_5_6_5           = 0x8363,
 GL_UNSIGNED_SHORT_5_6_5_REV       = 0x8364,
 GL_UNSIGNED_SHORT_4_4_4_4_REV     = 0x8365,
 GL_UNSIGNED_SHORT_1_5_5_5_REV     = 0x8366,
 GL_UNSIGNED_INT_8_8_8_8_REV       = 0x8367,
 GL_UNSIGNED_INT_2_10_10_10_REV    = 0x8368,
 GL_RESCALE_NORMAL                 = 0x803A,
 GL_LIGHT_MODEL_COLOR_CONTROL      = 0x81F8,
 GL_SINGLE_COLOR                   = 0x81F9,
 GL_SEPARATE_SPECULAR_COLOR        = 0x81FA,
 GL_PACK_SKIP_IMAGES               = 0x806B,
 GL_PACK_IMAGE_HEIGHT              = 0x806C,
 GL_UNPACK_SKIP_IMAGES             = 0x806D,
 GL_UNPACK_IMAGE_HEIGHT            = 0x806E,
 GL_TEXTURE_3D                     = 0x806F,
 GL_PROXY_TEXTURE_3D               = 0x8070,
 GL_TEXTURE_DEPTH                  = 0x8071,
 GL_TEXTURE_WRAP_R                 = 0x8072,
 GL_MAX_3D_TEXTURE_SIZE            = 0x8073,
 GL_CLAMP_TO_EDGE                  = 0x812F,
 GL_CLAMP_TO_BORDER                = 0x812D,
 GL_TEXTURE_MIN_LOD                = 0x813A,
 GL_TEXTURE_MAX_LOD                = 0x813B,
 GL_TEXTURE_BASE_LEVEL             = 0x813C,
 GL_TEXTURE_MAX_LEVEL              = 0x813D,
 GL_SMOOTH_POINT_SIZE_RANGE        = 0x0B12,
 GL_SMOOTH_POINT_SIZE_GRANULARITY  = 0x0B13,
 GL_SMOOTH_LINE_WIDTH_RANGE        = 0x0B22,
 GL_SMOOTH_LINE_WIDTH_GRANULARITY  = 0x0B23,
 GL_ALIASED_POINT_SIZE_RANGE       = 0x846D,
 GL_ALIASED_LINE_WIDTH_RANGE       = 0x846E,
 GL_TEXTURE0                       = 0x84C0,
 GL_TEXTURE1                       = 0x84C1,
 GL_TEXTURE2                       = 0x84C2,
 GL_TEXTURE3                       = 0x84C3,
 GL_TEXTURE4                       = 0x84C4,
 GL_TEXTURE5                       = 0x84C5,
 GL_TEXTURE6                       = 0x84C6,
 GL_TEXTURE7                       = 0x84C7,
 GL_TEXTURE8                       = 0x84C8,
 GL_TEXTURE9                       = 0x84C9,
 GL_TEXTURE10                      = 0x84CA,
 GL_TEXTURE11                      = 0x84CB,
 GL_TEXTURE12                      = 0x84CC,
 GL_TEXTURE13                      = 0x84CD,
 GL_TEXTURE14                      = 0x84CE,
 GL_TEXTURE15                      = 0x84CF,
 GL_TEXTURE16                      = 0x84D0,
 GL_TEXTURE17                      = 0x84D1,
 GL_TEXTURE18                      = 0x84D2,
 GL_TEXTURE19                      = 0x84D3,
 GL_TEXTURE20                      = 0x84D4,
 GL_TEXTURE21                      = 0x84D5,
 GL_TEXTURE22                      = 0x84D6,
 GL_TEXTURE23                      = 0x84D7,
 GL_TEXTURE24                      = 0x84D8,
 GL_TEXTURE25                      = 0x84D9,
 GL_TEXTURE26                      = 0x84DA,
 GL_TEXTURE27                      = 0x84DB,
 GL_TEXTURE28                      = 0x84DC,
 GL_TEXTURE29                      = 0x84DD,
 GL_TEXTURE30                      = 0x84DE,
 GL_TEXTURE31                      = 0x84DF,
 GL_ACTIVE_TEXTURE                 = 0x84E0,
 GL_CLIENT_ACTIVE_TEXTURE          = 0x84E1,
 GL_MAX_TEXTURE_UNITS              = 0x84E2,
 GL_COMBINE                        = 0x8570,
 GL_COMBINE_RGB                    = 0x8571,
 GL_COMBINE_ALPHA                  = 0x8572,
 GL_RGB_SCALE                      = 0x8573,
 GL_ADD_SIGNED                     = 0x8574,
 GL_INTERPOLATE                    = 0x8575,
 GL_CONSTANT                       = 0x8576,
 GL_PRIMARY_COLOR                  = 0x8577,
 GL_PREVIOUS                       = 0x8578,
 GL_SUBTRACT                       = 0x84E7,
 GL_SR0_RGB                       = 0x8580,
 GL_SRC1_RGB                       = 0x8581,
 GL_SRC2_RGB                       = 0x8582,
 GL_SRC3_RGB                       = 0x8583,
 GL_SRC4_RGB                       = 0x8584,
 GL_SRC5_RGB                       = 0x8585,
 GL_SRC6_RGB                       = 0x8586,
 GL_SRC7_RGB                       = 0x8587,
 GL_SRC0_ALPHA                     = 0x8588,
 GL_SRC1_ALPHA                     = 0x8589,
 GL_SRC2_ALPHA                     = 0x858A,
 GL_SRC3_ALPHA                     = 0x858B,
 GL_SRC4_ALPHA                     = 0x858C,
 GL_SRC5_ALPHA                     = 0x858D,
 GL_SRC6_ALPHA                     = 0x858E,
 GL_SRC7_ALPHA                     = 0x858F,
 GL_SOURCE0_RGB                    = 0x8580,
 GL_SOURCE1_RGB                    = 0x8581,
 GL_SOURCE2_RGB                    = 0x8582,
 GL_SOURCE3_RGB                    = 0x8583,
 GL_SOURCE4_RGB                    = 0x8584,
 GL_SOURCE5_RGB                    = 0x8585,
 GL_SOURCE6_RGB                    = 0x8586,
 GL_SOURCE7_RGB                    = 0x8587,
 GL_SOURCE0_ALPHA                  = 0x8588,
 GL_SOURCE1_ALPHA                  = 0x8589,
 GL_SOURCE2_ALPHA                  = 0x858A,
 GL_SOURCE3_ALPHA                  = 0x858B,
 GL_SOURCE4_ALPHA                  = 0x858C,
 GL_SOURCE5_ALPHA                  = 0x858D,
 GL_SOURCE6_ALPHA                  = 0x858E,
 GL_SOURCE7_ALPHA                  = 0x858F,
 GL_OPERAND0_RGB                   = 0x8590,
 GL_OPERAND1_RGB                   = 0x8591,
 GL_OPERAND2_RGB                   = 0x8592,
 GL_OPERAND3_RGB                   = 0x8593,
 GL_OPERAND4_RGB                   = 0x8594,
 GL_OPERAND5_RGB                   = 0x8595,
 GL_OPERAND6_RGB                   = 0x8596,
 GL_OPERAND7_RGB                   = 0x8597,
 GL_OPERAND0_ALPHA                 = 0x8598,
 GL_OPERAND1_ALPHA                 = 0x8599,
 GL_OPERAND2_ALPHA                 = 0x859A,
 GL_OPERAND3_ALPHA                 = 0x859B,
 GL_OPERAND4_ALPHA                 = 0x859C,
 GL_OPERAND5_ALPHA                 = 0x859D,
 GL_OPERAND6_ALPHA                 = 0x859E,
 GL_OPERAND7_ALPHA                 = 0x859F,
 GL_DOT3_RGB                       = 0x86AE,
 GL_DOT3_RGBA                      = 0x86AF,
 GL_TRANSPOSE_MODELVIEW_MATRIX     = 0x84E3,
 GL_TRANSPOSE_PROJECTION_MATRIX    = 0x84E4,
 GL_TRANSPOSE_TEXTURE_MATRIX       = 0x84E5,
 GL_TRANSPOSE_COLOR_MATRIX         = 0x84E6,
 GL_NORMAL_MAP                     = 0x8511,
 GL_REFLECTION_MAP                 = 0x8512,
 GL_TEXTURE_CUBE_MAP               = 0x8513,
 GL_TEXTURE_BINDING_CUBE_MAP       = 0x8514,
 GL_TEXTURE_CUBE_MAP_POSITIVE_X    = 0x8515,
 GL_TEXTURE_CUBE_MAP_NEGATIVE_X    = 0x8516,
 GL_TEXTURE_CUBE_MAP_POSITIVE_Y    = 0x8517,
 GL_TEXTURE_CUBE_MAP_NEGATIVE_Y    = 0x8518,
 GL_TEXTURE_CUBE_MAP_POSITIVE_Z    = 0x8519,
 GL_TEXTURE_CUBE_MAP_NEGATIVE_Z    = 0x851A,
 GL_PROXY_TEXTURE_CUBE_MAP         = 0x851B,
 GL_MAX_CUBE_MAP_TEXTURE_SIZE      = 0x851C,
 GL_COMPRESSED_ALPHA               = 0x84E9,
 GL_COMPRESSED_LUMINANCE           = 0x84EA,
 GL_COMPRESSED_LUMINANCE_ALPHA     = 0x84EB,
 GL_COMPRESSED_INTENSITY           = 0x84EC,
 GL_COMPRESSED_RGB                 = 0x84ED,
 GL_COMPRESSED_RGBA                = 0x84EE,
 GL_TEXTURE_COMPRESSION_HINT       = 0x84EF,
 GL_TEXTURE_COMPRESSED_IMAGE_SIZE  = 0x86A0,
 GL_TEXTURE_COMPRESSED             = 0x86A1,
 GL_NUM_COMPRESSED_TEXTURE_FORMATS = 0x86A2,
 GL_COMPRESSED_TEXTURE_FORMATS     = 0x86A3,
 GL_MULTISAMPLE                    = 0x809D,
 GL_SAMPLE_ALPHA_TO_COVERAGE       = 0x809E,
 GL_SAMPLE_ALPHA_TO_ONE            = 0x809F,
 GL_SAMPLE_COVERAGE                = 0x80A0,
 GL_SAMPLE_BUFFERS                 = 0x80A8,
 GL_SAMPLES                        = 0x80A9,
 GL_SAMPLE_COVERAGE_VALUE          = 0x80AA,
 GL_SAMPLE_COVERAGE_INVERT         = 0x80AB,
 GL_MULTISAMPLE_BIT                = 0x20000000,
 GL_DEPTH_COMPONENT16              = 0x81A5,
 GL_DEPTH_COMPONENT24              = 0x81A6,
 GL_DEPTH_COMPONENT32              = 0x81A7,
 GL_TEXTURE_DEPTH_SIZE             = 0x884A,
 GL_DEPTH_TEXTURE_MODE             = 0x884B,
 GL_TEXTURE_COMPARE_MODE           = 0x884C,
 GL_TEXTURE_COMPARE_FUNC           = 0x884D,
 GL_COMPARE_R_TO_TEXTURE           = 0x884E,
 GL_QUERY_COUNTER_BITS             = 0x8864,
 GL_CURRENT_QUERY                  = 0x8865,
 GL_QUERY_RESULT                   = 0x8866,
 GL_QUERY_RESULT_AVAILABLE         = 0x8867,
 GL_SAMPLES_PASSED                 = 0x8914,
 GL_FOG_COORD_SRC                  = 0x8450,
 GL_FOG_COORD                      = 0x8451,
 GL_FRAGMENT_DEPTH                 = 0x8452,
 GL_CURRENT_FOG_COORD              = 0x8453  ,
 GL_FOG_COORD_ARRAY_TYPE           = 0x8454,
 GL_FOG_COORD_ARRAY_STRIDE         = 0x8455,
 GL_FOG_COORD_ARRAY_POINTER        = 0x8456,
 GL_FOG_COORD_ARRAY                = 0x8457,
 GL_FOG_COORDINATE_SOURCE          = 0x8450,
 GL_FOG_COORDINATE                 = 0x8451,
 GL_CURRENT_FOG_COORDINATE         = 0x8453  ,
 GL_FOG_COORDINATE_ARRAY_TYPE      = 0x8454,
 GL_FOG_COORDINATE_ARRAY_STRIDE    = 0x8455,
 GL_FOG_COORDINATE_ARRAY_POINTER   = 0x8456,
 GL_FOG_COORDINATE_ARRAY           = 0x8457,
 GL_COLOR_SUM                      = 0x8458,
 GL_CURRENT_SECONDARY_COLOR        = 0x8459,
 GL_SECONDARY_COLOR_ARRAY_SIZE     = 0x845A,
 GL_SECONDARY_COLOR_ARRAY_TYPE     = 0x845B,
 GL_SECONDARY_COLOR_ARRAY_STRIDE   = 0x845C,
 GL_SECONDARY_COLOR_ARRAY_POINTER  = 0x845D,
 GL_SECONDARY_COLOR_ARRAY          = 0x845E,
 GL_POINT_SIZE_MIN                 = 0x8126,
 GL_POINT_SIZE_MAX                 = 0x8127,
 GL_POINT_FADE_THRESHOLD_SIZE      = 0x8128,
 GL_POINT_DISTANCE_ATTENUATION     = 0x8129,
 GL_BLEND_DST_RGB                  = 0x80C8,
 GL_BLEND_SRC_RGB                  = 0x80C9,
 GL_BLEND_DST_ALPHA                = 0x80CA,
 GL_BLEND_SRC_ALPHA                = 0x80CB,
 GL_GENERATE_MIPMAP                = 0x8191,
 GL_GENERATE_MIPMAP_HINT           = 0x8192,
 GL_INCR_WRAP                      = 0x8507,
 GL_DECR_WRAP                      = 0x8508,
 GL_MIRRORED_REPEAT                = 0x8370,
 GL_MAX_TEXTURE_LOD_BIAS           = 0x84FD,
 GL_TEXTURE_FILTER_CONTROL         = 0x8500,
 GL_TEXTURE_LOD_BIAS               = 0x8501,
 GL_ARRAY_BUFFER                                = 0x8892,
 GL_ELEMENT_ARRAY_BUFFER                        = 0x8893,
 GL_ARRAY_BUFFER_BINDING                        = 0x8894,
 GL_ELEMENT_ARRAY_BUFFER_BINDING                = 0x8895,
 GL_VERTEX_ARRAY_BUFFER_BINDING                 = 0x8896,
 GL_NORMAL_ARRAY_BUFFER_BINDING                 = 0x8897,
 GL_COLOR_ARRAY_BUFFER_BINDING                  = 0x8898,
 GL_INDEX_ARRAY_BUFFER_BINDING                  = 0x8899,
 GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING          = 0x889A,
 GL_EDGE_FLAG_ARRAY_BUFFER_BINDING              = 0x889B,
 GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING        = 0x889C,
 GL_FOG_COORD_ARRAY_BUFFER_BINDING              = 0x889D,
 GL_WEIGHT_ARRAY_BUFFER_BINDING                 = 0x889E,
 GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING          = 0x889F,
 GL_STREAM_DRAW                                 = 0x88E0,
 GL_STREAM_READ                                 = 0x88E1,
 GL_STREAM_COPY                                 = 0x88E2,
 GL_STATIC_DRAW                                 = 0x88E4,
 GL_STATIC_READ                                 = 0x88E5,
 GL_STATIC_COPY                                 = 0x88E6,
 GL_DYNAMIC_DRAW                                = 0x88E8,
 GL_DYNAMIC_READ                                = 0x88E9,
 GL_DYNAMIC_COPY                                = 0x88EA,
 GL_READ_ONLY                                   = 0x88B8,
 GL_WRITE_ONLY                                  = 0x88B9,
 GL_READ_WRITE                                  = 0x88BA,
 GL_BUFFER_SIZE                                 = 0x8764,
 GL_BUFFER_USAGE                                = 0x8765,
 GL_BUFFER_ACCESS                               = 0x88BB,
 GL_BUFFER_MAPPED                               = 0x88BC,
 GL_BUFFER_MAP_POINTER                          = 0x88BD,
 GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING         = 0x889D,
 GL_CURRENT_PROGRAM                = 0x8B8D,
 GL_SHADER_TYPE                    = 0x8B4F,
 GL_DELETE_STATUS                  = 0x8B80,
 GL_COMPILE_STATUS                 = 0x8B81,
 GL_LINK_STATUS                    = 0x8B82,
 GL_VALIDATE_STATUS                = 0x8B83,
 GL_INFO_LOG_LENGTH                = 0x8B84,
 GL_ATTACHED_SHADERS               = 0x8B85,
 GL_ACTIVE_UNIFORMS                = 0x8B86,
 GL_ACTIVE_UNIFORM_MAX_LENGTH      = 0x8B87,
 GL_SHADER_SOURCE_LENGTH           = 0x8B88,
 GL_FLOAT_VEC2                     = 0x8B50,
 GL_FLOAT_VEC3                     = 0x8B51,
 GL_FLOAT_VEC4                     = 0x8B52,
 GL_INT_VEC2                       = 0x8B53,
 GL_INT_VEC3                       = 0x8B54,
 GL_INT_VEC4                       = 0x8B55,
 GL_BOOL                           = 0x8B56,
 GL_BOOL_VEC2                      = 0x8B57,
 GL_BOOL_VEC3                      = 0x8B58,
 GL_BOOL_VEC4                      = 0x8B59,
 GL_FLOAT_MAT2                     = 0x8B5A,
 GL_FLOAT_MAT3                     = 0x8B5B,
 GL_FLOAT_MAT4                     = 0x8B5C,
 GL_SAMPLER_1D                     = 0x8B5D,
 GL_SAMPLER_2D                     = 0x8B5E,
 GL_SAMPLER_3D                     = 0x8B5F,
 GL_SAMPLER_CUBE                   = 0x8B60,
 GL_SAMPLER_1D_SHADOW              = 0x8B61,
 GL_SAMPLER_2D_SHADOW              = 0x8B62,
 GL_SHADING_LANGUAGE_VERSION       = 0x8B8C,
 GL_VERTEX_SHADER                  = 0x8B31,
 GL_MAX_VERTEX_UNIFORM_COMPONENTS  = 0x8B4A,
 GL_MAX_VARYING_FLOATS             = 0x8B4B,
 GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C,
 GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D,
 GL_ACTIVE_ATTRIBUTES              = 0x8B89,
 GL_ACTIVE_ATTRIBUTE_MAX_LENGTH    = 0x8B8A,
 GL_FRAGMENT_SHADER                = 0x8B30,
 GL_MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49,
 GL_FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B,
 GL_MAX_VERTEX_ATTRIBS             = 0x8869,
 GL_VERTEX_ATTRIB_ARRAY_ENABLED    = 0x8622,
 GL_VERTEX_ATTRIB_ARRAY_SIZE       = 0x8623,
 GL_VERTEX_ATTRIB_ARRAY_STRIDE     = 0x8624,
 GL_VERTEX_ATTRIB_ARRAY_TYPE       = 0x8625,
 GL_VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A,
 GL_CURRENT_VERTEX_ATTRIB          = 0x8626,
 GL_VERTEX_ATTRIB_ARRAY_POINTER    = 0x8645,
 GL_VERTEX_PROGRAM_POINT_SIZE      = 0x8642,
 GL_VERTEX_PROGRAM_TWO_SIDE        = 0x8643,
 GL_MAX_TEXTURE_COORDS             = 0x8871,
 GL_MAX_TEXTURE_IMAGE_UNITS        = 0x8872,
 GL_MAX_DRAW_BUFFERS               = 0x8824,
 GL_DRAW_BUFFER0                   = 0x8825,
 GL_DRAW_BUFFER1                   = 0x8826,
 GL_DRAW_BUFFER2                   = 0x8827,
 GL_DRAW_BUFFER3                   = 0x8828,
 GL_DRAW_BUFFER4                   = 0x8829,
 GL_DRAW_BUFFER5                   = 0x882A,
 GL_DRAW_BUFFER6                   = 0x882B,
 GL_DRAW_BUFFER7                   = 0x882C,
 GL_DRAW_BUFFER8                   = 0x882D,
 GL_DRAW_BUFFER9                   = 0x882E,
 GL_DRAW_BUFFER10                  = 0x882F,
 GL_DRAW_BUFFER11                  = 0x8830,
 GL_DRAW_BUFFER12                  = 0x8831,
 GL_DRAW_BUFFER13                  = 0x8832,
 GL_DRAW_BUFFER14                  = 0x8833,
 GL_DRAW_BUFFER15                  = 0x8834,
 GL_POINT_SPRITE                   = 0x8861,
 GL_COORD_REPLACE                  = 0x8862,
 
 
 GL_TEXTURE_RED_TYPE_ARB           = 0x8C10,
 GL_TEXTURE_GREEN_TYPE_ARB         = 0x8C11,
 GL_TEXTURE_BLUE_TYPE_ARB          = 0x8C12,
 GL_TEXTURE_ALPHA_TYPE_ARB         = 0x8C13,
 GL_TEXTURE_LUMINANCE_TYPE_ARB     = 0x8C14,
 GL_TEXTURE_INTENSITY_TYPE_ARB     = 0x8C15,
 GL_TEXTURE_DEPTH_TYPE_ARB         = 0x8C16,
 GL_UNSIGNED_NORMALIZED_ARB        = 0x8C17,
 GL_RGBA32F_ARB                    = 0x8814,
 GL_RGB32F_ARB                     = 0x8815,
 GL_ALPHA32F_ARB                   = 0x8816,
 GL_INTENSITY32F_ARB               = 0x8817,
 GL_LUMINANCE32F_ARB               = 0x8818,
 GL_LUMINANCE_ALPHA32F_ARB         = 0x8819,
 GL_RGBA16F_ARB                    = 0x881A,
 GL_RGB16F_ARB                     = 0x881B,
 GL_ALPHA16F_ARB                   = 0x881C,
 GL_INTENSITY16F_ARB               = 0x881D,
 GL_LUMINANCE16F_ARB               = 0x881E,
 GL_LUMINANCE_ALPHA16F_ARB         = 0x881F,
 GL_RGBA_FLOAT_MODE_ARB            = 0x8820,
 GL_CLAMP_VERTEX_COLOR_ARB         = 0x891A,
 GL_CLAMP_FRAGMENT_COLOR_ARB       = 0x891B,
 GL_CLAMP_READ_COLOR_ARB           = 0x891C,
 GL_FIXED_ONLY_ARB                 = 0x891D,

 GL_POINT_SPRITE_COORD_ORIGIN      = 0x8CA0,
 GL_LOWER_LEFT                     = 0x8CA1,
 GL_UPPER_LEFT                     = 0x8CA2,
 GL_STENCIL_BACK_FUNC              = 0x8800,
 GL_STENCIL_BACK_VALUE_MASK        = 0x8CA4,
 GL_STENCIL_BACK_REF               = 0x8CA3,
 GL_STENCIL_BACK_FAIL              = 0x8801,
 GL_STENCIL_BACK_PASS_DEPTH_FAIL   = 0x8802,
 GL_STENCIL_BACK_PASS_DEPTH_PASS   = 0x8803,
 GL_STENCIL_BACK_WRITEMASK         = 0x8CA5,
 GL_CURRENT_RASTER_SECONDARY_COLOR = 0x845F,
 GL_PIXEL_PACK_BUFFER              = 0x88EB,
 GL_PIXEL_UNPACK_BUFFER            = 0x88EC,
 GL_PIXEL_PACK_BUFFER_BINDING      = 0x88ED,
 GL_PIXEL_UNPACK_BUFFER_BINDING    = 0x88EF,
 GL_FLOAT_MAT2x3                   = 0x8B65,
 GL_FLOAT_MAT2x4                   = 0x8B66,
 GL_FLOAT_MAT3x2                   = 0x8B67,
 GL_FLOAT_MAT3x4                   = 0x8B68,
 GL_FLOAT_MAT4x2                   = 0x8B69,
 GL_FLOAT_MAT4x3                   = 0x8B6A,
 GL_SRGB                           = 0x8C40,
 GL_SRGB8                          = 0x8C41,
 GL_SRGB_ALPHA                     = 0x8C42,
 GL_SRGB8_ALPHA8                   = 0x8C43,
 GL_SLUMINANCE_ALPHA               = 0x8C44,
 GL_SLUMINANCE8_ALPHA8             = 0x8C45,
 GL_SLUMINANCE                     = 0x8C46,
 GL_SLUMINANCE8                    = 0x8C47,
 GL_COMPRESSED_SRGB                = 0x8C48,
 GL_COMPRESSED_SRGB_ALPHA          = 0x8C49,
 GL_COMPRESSED_SLUMINANCE          = 0x8C4A,
 GL_COMPRESSED_SLUMINANCE_ALPHA    = 0x8C4B,


 
GL_FRAMEBUFFER_COMPLETE           = 0x8CD5,
 GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6,
 GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7,
 GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER = 0x8CDB,
 GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER = 0x8CDC,
 GL_FRAMEBUFFER_UNSUPPORTED        = 0x8CDD,
 GL_COLOR_ATTACHMENT0              = 0x8CE0,
 GL_COLOR_ATTACHMENT1              = 0x8CE1,
 GL_COLOR_ATTACHMENT2              = 0x8CE2,
 GL_COLOR_ATTACHMENT3              = 0x8CE3,
 GL_COLOR_ATTACHMENT4              = 0x8CE4,
 GL_COLOR_ATTACHMENT5              = 0x8CE5,
 GL_COLOR_ATTACHMENT6              = 0x8CE6,
 GL_COLOR_ATTACHMENT7              = 0x8CE7,
 GL_COLOR_ATTACHMENT8              = 0x8CE8,
 GL_COLOR_ATTACHMENT9              = 0x8CE9,
 GL_COLOR_ATTACHMENT10             = 0x8CEA,
 GL_COLOR_ATTACHMENT11             = 0x8CEB,
 GL_COLOR_ATTACHMENT12             = 0x8CEC,
 GL_COLOR_ATTACHMENT13             = 0x8CED,
 GL_COLOR_ATTACHMENT14             = 0x8CEE,
 GL_COLOR_ATTACHMENT15             = 0x8CEF,
 GL_DEPTH_ATTACHMENT               = 0x8D00,
 GL_STENCIL_ATTACHMENT             = 0x8D20,
 GL_FRAMEBUFFER                    = 0x8D40,
 GL_RENDERBUFFER                   = 0x8D41,
 GL_RENDERBUFFER_WIDTH             = 0x8D42,
 GL_RENDERBUFFER_HEIGHT            = 0x8D43,
 GL_RENDERBUFFER_INTERNAL_FORMAT   = 0x8D44
};
typedef unsigned int GLenum;
typedef unsigned char GLboolean;
typedef unsigned int GLbitfield;
typedef signed char GLbyte;
typedef short GLshort;
typedef int GLint;
typedef int GLsizei;
typedef uint8_t GLubyte;
typedef unsigned short GLushort;
typedef unsigned int GLuint;
typedef float GLfloat;
typedef float GLclampf;
typedef double GLdouble;
typedef double GLclampd;
typedef void GLvoid;
typedef char GLchar;
typedef char GLcharARB;
typedef unsigned int GLhandleARB;
//typedef void *GLhandleARB;
typedef unsigned short GLhalfARB;
typedef unsigned short GLhalf;
typedef unsigned short GLhalfNV;

typedef ptrdiff_t GLintptr;
typedef ptrdiff_t GLsizeiptr;
typedef ptrdiff_t GLintptrARB;
typedef ptrdiff_t GLsizeiptrARB;
//typedef long GLintptr;
//typedef long GLsizeiptr;
//typedef long GLintptrARB;
//typedef long GLsizeiptrARB;

typedef int64_t GLint64EXT;
typedef uint64_t GLuint64EXT;
typedef int64_t GLint64;
typedef uint64_t GLuint64;
typedef struct __GLsync *GLsync;

void glActiveTextureARB (GLenum);
void glClientActiveTextureARB (GLenum);
void glMultiTexCoord1dARB (GLenum, GLdouble);
void glMultiTexCoord1dvARB (GLenum, const GLdouble *);
void glMultiTexCoord1fARB (GLenum, GLfloat);
void glMultiTexCoord1fvARB (GLenum, const GLfloat *);
void glMultiTexCoord1iARB (GLenum, GLint);
void glMultiTexCoord1ivARB (GLenum, const GLint *);
void glMultiTexCoord1sARB (GLenum, GLshort);
void glMultiTexCoord1svARB (GLenum, const GLshort *);
void glMultiTexCoord2dARB (GLenum, GLdouble, GLdouble);
void glMultiTexCoord2dvARB (GLenum, const GLdouble *);
void glMultiTexCoord2fARB (GLenum, GLfloat, GLfloat);
void glMultiTexCoord2fvARB (GLenum, const GLfloat *);
void glMultiTexCoord2iARB (GLenum, GLint, GLint);
void glMultiTexCoord2ivARB (GLenum, const GLint *);
void glMultiTexCoord2sARB (GLenum, GLshort, GLshort);
void glMultiTexCoord2svARB (GLenum, const GLshort *);
void glMultiTexCoord3dARB (GLenum, GLdouble, GLdouble, GLdouble);
void glMultiTexCoord3dvARB (GLenum, const GLdouble *);
void glMultiTexCoord3fARB (GLenum, GLfloat, GLfloat, GLfloat);
void glMultiTexCoord3fvARB (GLenum, const GLfloat *);
void glMultiTexCoord3iARB (GLenum, GLint, GLint, GLint);
void glMultiTexCoord3ivARB (GLenum, const GLint *);
void glMultiTexCoord3sARB (GLenum, GLshort, GLshort, GLshort);
void glMultiTexCoord3svARB (GLenum, const GLshort *);
void glMultiTexCoord4dARB (GLenum, GLdouble, GLdouble, GLdouble, GLdouble);
void glMultiTexCoord4dvARB (GLenum, const GLdouble *);
void glMultiTexCoord4fARB (GLenum, GLfloat, GLfloat, GLfloat, GLfloat);
void glMultiTexCoord4fvARB (GLenum, const GLfloat *);
void glMultiTexCoord4iARB (GLenum, GLint, GLint, GLint, GLint);
void glMultiTexCoord4ivARB (GLenum, const GLint *);
void glMultiTexCoord4sARB (GLenum, GLshort, GLshort, GLshort, GLshort);
void glMultiTexCoord4svARB (GLenum, const GLshort *);
void glLoadTransposeMatrixfARB (const GLfloat *);
void glLoadTransposeMatrixdARB (const GLdouble *);
void glMultTransposeMatrixfARB (const GLfloat *);
void glMultTransposeMatrixdARB (const GLdouble *);
void glSampleCoverageARB (GLclampf, GLboolean);
void glSamplePassARB (GLenum);
void glCompressedTexImage3DARB (GLenum, GLint, GLenum, GLsizei, GLsizei, GLsizei, GLint, GLsizei, const GLvoid *);
void glCompressedTexImage2DARB (GLenum, GLint, GLenum, GLsizei, GLsizei, GLint, GLsizei, const GLvoid *);
void glCompressedTexImage1DARB (GLenum, GLint, GLenum, GLsizei, GLint, GLsizei, const GLvoid *);
void glCompressedTexSubImage3DARB (GLenum, GLint, GLint, GLint, GLint, GLsizei, GLsizei, GLsizei, GLenum, GLsizei, const GLvoid *);
void glCompressedTexSubImage2DARB (GLenum, GLint, GLint, GLint, GLsizei, GLsizei, GLenum, GLsizei, const GLvoid *);
void glCompressedTexSubImage1DARB (GLenum, GLint, GLint, GLsizei, GLenum, GLsizei, const GLvoid *);
void glGetCompressedTexImageARB (GLenum, GLint, GLvoid *);
void glWeightbvARB(GLint, const GLbyte *);
void glWeightsvARB(GLint, const GLshort *);
void glWeightivARB(GLint, const GLint *);
void glWeightfvARB(GLint, const GLfloat *);
void glWeightdvARB(GLint, const GLdouble *);
void glWeightubvARB(GLint, const GLubyte *);
void glWeightusvARB(GLint, const GLushort *);
void glWeightuivARB(GLint, const GLuint *);
void glWeightPointerARB(GLint, GLenum, GLsizei, const GLvoid *);
void glVertexBlendARB(GLint);
void glWindowPos2dARB (GLdouble, GLdouble);
void glWindowPos2dvARB (const GLdouble *);
void glWindowPos2fARB (GLfloat, GLfloat);
void glWindowPos2fvARB (const GLfloat *);
void glWindowPos2iARB (GLint, GLint);
void glWindowPos2ivARB (const GLint *);
void glWindowPos2sARB (GLshort, GLshort);
void glWindowPos2svARB (const GLshort *);
void glWindowPos3dARB (GLdouble, GLdouble, GLdouble);
void glWindowPos3dvARB (const GLdouble *);
void glWindowPos3fARB (GLfloat, GLfloat, GLfloat);
void glWindowPos3fvARB (const GLfloat *);
void glWindowPos3iARB (GLint, GLint, GLint);
void glWindowPos3ivARB (const GLint *);
void glWindowPos3sARB (GLshort, GLshort, GLshort);
void glWindowPos3svARB (const GLshort *);
void glGenQueriesARB(GLsizei n, GLuint *ids);
void glDeleteQueriesARB(GLsizei n, const GLuint *ids);
GLboolean glIsQueryARB(GLuint id);
void glBeginQueryARB(GLenum target, GLuint id);
void glEndQueryARB(GLenum target);
void glGetQueryivARB(GLenum target, GLenum pname, GLint *params);
void glGetQueryObjectivARB(GLuint id, GLenum pname, GLint *params);
void glGetQueryObjectuivARB(GLuint id, GLenum pname, GLuint *params);
void glPointParameterfARB(GLenum pname, GLfloat param);
void glPointParameterfvARB(GLenum pname, const GLfloat *params);
void glBindProgramARB(GLenum target, GLuint program);
void glDeleteProgramsARB(GLsizei n, const GLuint *programs);
void glGenProgramsARB(GLsizei n, GLuint *programs);
GLboolean glIsProgramARB(GLuint program);
void glProgramEnvParameter4dARB(GLenum target, GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
void glProgramEnvParameter4dvARB(GLenum target, GLuint index, const GLdouble *params);
void glProgramEnvParameter4fARB(GLenum target, GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
void glProgramEnvParameter4fvARB(GLenum target, GLuint index, const GLfloat *params);
void glProgramLocalParameter4dARB(GLenum target, GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
void glProgramLocalParameter4dvARB(GLenum target, GLuint index, const GLdouble *params);
void glProgramLocalParameter4fARB(GLenum target, GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
void glProgramLocalParameter4fvARB(GLenum target, GLuint index, const GLfloat *params);
void glGetProgramEnvParameterdvARB(GLenum target, GLuint index, GLdouble *params);
void glGetProgramEnvParameterfvARB(GLenum target, GLuint index, GLfloat *params);
void glProgramEnvParameters4fvEXT(GLenum target, GLuint index, GLsizei count, const GLfloat *params);
void glProgramLocalParameters4fvEXT(GLenum target, GLuint index, GLsizei count, const GLfloat *params);
void glGetProgramLocalParameterdvARB(GLenum target, GLuint index, GLdouble *params);
void glGetProgramLocalParameterfvARB(GLenum target, GLuint index, GLfloat *params);
void glProgramStringARB(GLenum target, GLenum format, GLsizei len, const GLvoid *string);
void glGetProgramStringARB(GLenum target, GLenum pname, GLvoid *string);
void glGetProgramivARB(GLenum target, GLenum pname, GLint *params);
void glVertexAttrib1dARB(GLuint index, GLdouble x);
void glVertexAttrib1dvARB(GLuint index, const GLdouble *v);
void glVertexAttrib1fARB(GLuint index, GLfloat x);
void glVertexAttrib1fvARB(GLuint index, const GLfloat *v);
void glVertexAttrib1sARB(GLuint index, GLshort x);
void glVertexAttrib1svARB(GLuint index, const GLshort *v);
void glVertexAttrib2dARB(GLuint index, GLdouble x, GLdouble y);
void glVertexAttrib2dvARB(GLuint index, const GLdouble *v);
void glVertexAttrib2fARB(GLuint index, GLfloat x, GLfloat y);
void glVertexAttrib2fvARB(GLuint index, const GLfloat *v);
void glVertexAttrib2sARB(GLuint index, GLshort x, GLshort y);
void glVertexAttrib2svARB(GLuint index, const GLshort *v);
void glVertexAttrib3dARB(GLuint index, GLdouble x, GLdouble y, GLdouble z);
void glVertexAttrib3dvARB(GLuint index, const GLdouble *v);
void glVertexAttrib3fARB(GLuint index, GLfloat x, GLfloat y, GLfloat z);
void glVertexAttrib3fvARB(GLuint index, const GLfloat *v);
void glVertexAttrib3sARB(GLuint index, GLshort x, GLshort y, GLshort z);
void glVertexAttrib3svARB(GLuint index, const GLshort *v);
void glVertexAttrib4NbvARB(GLuint index, const GLbyte *v);
void glVertexAttrib4NivARB(GLuint index, const GLint *v);
void glVertexAttrib4NsvARB(GLuint index, const GLshort *v);
void glVertexAttrib4NubARB(GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
void glVertexAttrib4NubvARB(GLuint index, const GLubyte *v);
void glVertexAttrib4NuivARB(GLuint index, const GLuint *v);
void glVertexAttrib4NusvARB(GLuint index, const GLushort *v);
void glVertexAttrib4bvARB(GLuint index, const GLbyte *v);
void glVertexAttrib4dARB(GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
void glVertexAttrib4dvARB(GLuint index, const GLdouble *v);
void glVertexAttrib4fARB(GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
void glVertexAttrib4fvARB(GLuint index, const GLfloat *v);
void glVertexAttrib4ivARB(GLuint index, const GLint *v);
void glVertexAttrib4sARB(GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
void glVertexAttrib4svARB(GLuint index, const GLshort *v);
void glVertexAttrib4ubvARB(GLuint index, const GLubyte *v);
void glVertexAttrib4uivARB(GLuint index, const GLuint *v);
void glVertexAttrib4usvARB(GLuint index, const GLushort *v);
void glVertexAttribPointerARB(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer);
void glDisableVertexAttribArrayARB(GLuint index);
void glEnableVertexAttribArrayARB(GLuint index);
void glGetVertexAttribPointervARB(GLuint index, GLenum pname, GLvoid **pointer);
void glGetVertexAttribdvARB(GLuint index, GLenum pname, GLdouble *params);
void glGetVertexAttribfvARB(GLuint index, GLenum pname, GLfloat *params);
void glGetVertexAttribivARB(GLuint index, GLenum pname, GLint *params);
void glDeleteObjectARB(GLhandleARB obj);
GLhandleARB glGetHandleARB(GLenum pname);
void glDetachObjectARB(GLhandleARB containerObj, GLhandleARB attachedObj);
GLhandleARB glCreateShaderObjectARB(GLenum shaderType);
void glShaderSourceARB(GLhandleARB shaderObj, GLsizei count, const GLcharARB **string, const GLint *length);
void glCompileShaderARB(GLhandleARB shaderObj);
GLhandleARB glCreateProgramObjectARB(void);
void glAttachObjectARB(GLhandleARB containerObj, GLhandleARB obj);
void glLinkProgramARB(GLhandleARB programObj);
void glUseProgramObjectARB(GLhandleARB programObj);
void glValidateProgramARB(GLhandleARB programObj);
void glUniform1fARB(GLint location, GLfloat v0);
void glUniform2fARB(GLint location, GLfloat v0, GLfloat v1);
void glUniform3fARB(GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
void glUniform4fARB(GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
void glUniform1iARB(GLint location, GLint v0);
void glUniform2iARB(GLint location, GLint v0, GLint v1);
void glUniform3iARB(GLint location, GLint v0, GLint v1, GLint v2);
void glUniform4iARB(GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
void glUniform1fvARB(GLint location, GLsizei count, const GLfloat *value);
void glUniform2fvARB(GLint location, GLsizei count, const GLfloat *value);
void glUniform3fvARB(GLint location, GLsizei count, const GLfloat *value);
void glUniform4fvARB(GLint location, GLsizei count, const GLfloat *value);
void glUniform1ivARB(GLint location, GLsizei count, const GLint *value);
void glUniform2ivARB(GLint location, GLsizei count, const GLint *value);
void glUniform3ivARB(GLint location, GLsizei count, const GLint *value);
void glUniform4ivARB(GLint location, GLsizei count, const GLint *value);
void glUniformMatrix2fvARB(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix3fvARB(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix4fvARB(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glGetObjectParameterfvARB(GLhandleARB obj, GLenum pname, GLfloat *params);
void glGetObjectParameterivARB(GLhandleARB obj, GLenum pname, GLint *params);
void glGetInfoLogARB(GLhandleARB obj, GLsizei maxLength, GLsizei *length, GLcharARB *infoLog);
void glGetAttachedObjectsARB(GLhandleARB containerObj, GLsizei maxCount, GLsizei *count, GLhandleARB *obj);
GLint glGetUniformLocationARB(GLhandleARB programObj, const GLcharARB *name);
void glGetActiveUniformARB(GLhandleARB programObj, GLuint index, GLsizei maxLength, GLsizei *length, GLint *size, GLenum *type, GLcharARB *name);
void glGetUniformfvARB(GLhandleARB programObj, GLint location, GLfloat *params);
void glGetUniformivARB(GLhandleARB programObj, GLint location, GLint *params);
void glGetShaderSourceARB(GLhandleARB obj, GLsizei maxLength, GLsizei *length, GLcharARB *source);
void glBindAttribLocationARB(GLhandleARB programObj, GLuint index, const GLcharARB *name);
void glGetActiveAttribARB(GLhandleARB programObj, GLuint index, GLsizei maxLength, GLsizei *length, GLint *size, GLenum *type, GLcharARB *name);
GLint glGetAttribLocationARB(GLhandleARB programObj, const GLcharARB *name);
void glBindBufferARB(GLenum target, GLuint buffer);
void glDeleteBuffersARB(GLsizei n, const GLuint *buffers);
void glGenBuffersARB(GLsizei n, GLuint *buffers);
GLboolean glIsBufferARB(GLuint buffer);
void glBufferDataARB(GLenum target, GLsizeiptrARB size, const GLvoid *data, GLenum usage);
void glBufferSubDataARB(GLenum target, GLintptrARB offset, GLsizeiptrARB size, const GLvoid *data);
void glGetBufferSubDataARB(GLenum target, GLintptrARB offset, GLsizeiptrARB size, GLvoid *data);
GLvoid *glMapBufferARB(GLenum target, GLenum access);
GLboolean glUnmapBufferARB(GLenum target);
void glGetBufferParameterivARB(GLenum target, GLenum pname, GLint *params);
void glGetBufferPointervARB(GLenum target, GLenum pname, GLvoid **params);
void glDrawBuffersARB(GLsizei n, const GLenum *bufs);
void glClampColorARB(GLenum target, GLenum clamp);
void glDrawArraysInstancedARB(GLenum mode, GLint first, GLsizei count, GLsizei primcount);
void glDrawElementsInstancedARB(GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLsizei primcount);
void glVertexAttribDivisorARB(GLuint index, GLuint divisor);
void glGetUniformIndices(GLuint program, GLsizei uniformCount, const GLchar** uniformNames, GLuint* uniformIndices);
void glGetActiveUniformsiv(GLuint program, GLsizei uniformCount, const GLuint* uniformIndices, GLenum pname, GLint* params);
void glGetActiveUniformName(GLuint program, GLuint uniformIndex, GLsizei bufSize, GLsizei* length, GLchar* uniformName);
GLuint glGetUniformBlockIndex(GLuint program, const GLchar* uniformBlockName);
void glGetActiveUniformBlockiv(GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint* params);
void glGetActiveUniformBlockName(GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei* length, GLchar* uniformBlockName);
void glBindBufferRange(GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
void glBindBufferBase(GLenum target, GLuint index, GLuint buffer);
void glGetIntegeri_v(GLenum pname, GLuint index, GLint* data);
void glUniformBlockBinding(GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding);
void glBlendColorEXT (GLclampf, GLclampf, GLclampf, GLclampf);
void glBlendEquationEXT (GLenum);
void glLockArraysEXT (GLint, GLsizei);
void glUnlockArraysEXT (void);
void glDrawRangeElementsEXT (GLenum, GLuint, GLuint, GLsizei, GLenum, const GLvoid *);
void glSecondaryColor3bEXT (GLbyte, GLbyte, GLbyte);
void glSecondaryColor3bvEXT (const GLbyte *);
void glSecondaryColor3dEXT (GLdouble, GLdouble, GLdouble);
void glSecondaryColor3dvEXT (const GLdouble *);
void glSecondaryColor3fEXT (GLfloat, GLfloat, GLfloat);
void glSecondaryColor3fvEXT (const GLfloat *);
void glSecondaryColor3iEXT (GLint, GLint, GLint);
void glSecondaryColor3ivEXT (const GLint *);
void glSecondaryColor3sEXT (GLshort, GLshort, GLshort);
void glSecondaryColor3svEXT (const GLshort *);
void glSecondaryColor3ubEXT (GLubyte, GLubyte, GLubyte);
void glSecondaryColor3ubvEXT (const GLubyte *);
void glSecondaryColor3uiEXT (GLuint, GLuint, GLuint);
void glSecondaryColor3uivEXT (const GLuint *);
void glSecondaryColor3usEXT (GLushort, GLushort, GLushort);
void glSecondaryColor3usvEXT (const GLushort *);
void glSecondaryColorPointerEXT (GLint, GLenum, GLsizei, const GLvoid *);
void glMultiDrawArraysEXT (GLenum, const GLint *, const GLsizei *, GLsizei);
void glMultiDrawElementsEXT (GLenum, const GLsizei *, GLenum, const GLvoid* *, GLsizei);
void glFogCoordfEXT (GLfloat);
void glFogCoordfvEXT (const GLfloat *);
void glFogCoorddEXT (GLdouble);
void glFogCoorddvEXT (const GLdouble *);
void glFogCoordPointerEXT (GLenum, GLsizei, const GLvoid *);
void glBlendFuncSeparateEXT (GLenum, GLenum, GLenum, GLenum);
void glActiveStencilFaceEXT(GLenum face);
void glDepthBoundsEXT(GLclampd zmin, GLclampd zmax);
void glBlendEquationSeparateEXT(GLenum modeRGB, GLenum modeAlpha);
GLboolean glIsRenderbufferEXT(GLuint renderbuffer);
void glBindRenderbufferEXT(GLenum target, GLuint renderbuffer);
void glDeleteRenderbuffersEXT(GLsizei n, const GLuint *renderbuffers);
void glGenRenderbuffersEXT(GLsizei n, GLuint *renderbuffers);
void glRenderbufferStorageEXT(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
void glGetRenderbufferParameterivEXT(GLenum target, GLenum pname, GLint *params);
GLboolean glIsFramebufferEXT(GLuint framebuffer);
void glBindFramebufferEXT(GLenum target, GLuint framebuffer);
void glDeleteFramebuffersEXT(GLsizei n, const GLuint *framebuffers);
void glGenFramebuffersEXT(GLsizei n, GLuint *framebuffers);
GLenum glCheckFramebufferStatusEXT(GLenum target);
void glFramebufferTexture1DEXT(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
void glFramebufferTexture2DEXT(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
void glFramebufferTexture3DEXT(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset);
void glFramebufferRenderbufferEXT(GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
void glGetFramebufferAttachmentParameterivEXT(GLenum target, GLenum attachment, GLenum pname, GLint *params);
void glGenerateMipmapEXT(GLenum target);
void glBlitFramebufferEXT(GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
void glRenderbufferStorageMultisampleEXT(GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
void glProgramParameteriEXT(GLuint program, GLenum pname, GLint value);
void glFramebufferTextureEXT(GLenum target, GLenum attachment, GLuint texture, GLint level);
void glFramebufferTextureFaceEXT(GLenum target, GLenum attachment, GLuint texture, GLint level, GLenum face);
void glFramebufferTextureLayerEXT(GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);
GLboolean glIsRenderbuffer (GLuint);
void glBindRenderbuffer (GLenum, GLuint);
void glDeleteRenderbuffers (GLsizei, const GLuint *);
void glGenRenderbuffers (GLsizei, GLuint *);
void glRenderbufferStorage (GLenum, GLenum, GLsizei, GLsizei);
void glGetRenderbufferParameteriv (GLenum, GLenum, GLint *);
GLboolean glIsFramebuffer (GLuint);
void glBindFramebuffer (GLenum, GLuint);
void glDeleteFramebuffers (GLsizei, const GLuint *);
void glGenFramebuffers (GLsizei, GLuint *);
GLenum glCheckFramebufferStatus (GLenum);
void glFramebufferTexture1D (GLenum, GLenum, GLenum, GLuint, GLint);
void glFramebufferTexture2D (GLenum, GLenum, GLenum, GLuint, GLint);
void glFramebufferTexture3D (GLenum, GLenum, GLenum, GLuint, GLint, GLint);
void glFramebufferRenderbuffer (GLenum, GLenum, GLenum, GLuint);
void glGetFramebufferAttachmentParameteriv (GLenum, GLenum, GLenum, GLint *);
void glGenerateMipmap (GLenum);
void glBlitFramebuffer (GLint, GLint, GLint, GLint, GLint, GLint, GLint, GLint, GLbitfield, GLenum);
void glRenderbufferStorageMultisample (GLenum, GLsizei, GLenum, GLsizei, GLsizei);
void glFramebufferTextureLayer (GLenum, GLenum, GLuint, GLint, GLint);
void glBindBufferRangeEXT(GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
void glBindBufferOffsetEXT(GLenum target, GLuint index, GLuint buffer, GLintptr offset);
void glBindBufferBaseEXT(GLenum target, GLuint index, GLuint buffer);
void glBeginTransformFeedbackEXT(GLenum primitiveMode);
void glEndTransformFeedbackEXT(void);
void glTransformFeedbackVaryingsEXT(GLuint program, GLsizei count, const GLchar **varyings, GLenum bufferMode);
void glGetTransformFeedbackVaryingEXT(GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLsizei *size, GLenum *type, GLchar *name);
void glGetIntegerIndexedvEXT(GLenum param, GLuint index, GLint *values);
void glGetBooleanIndexedvEXT(GLenum param, GLuint index, GLboolean *values);
void glUniformBufferEXT(GLuint program, GLint location, GLuint buffer);
GLint glGetUniformBufferSizeEXT(GLuint program, GLint location);
GLintptr glGetUniformOffsetEXT(GLuint program, GLint location);
void glClearColorIiEXT( GLint r, GLint g, GLint b, GLint a );
void glClearColorIuiEXT( GLuint r, GLuint g, GLuint b, GLuint a );
void glTexParameterIivEXT( GLenum target, GLenum pname, GLint *params );
void glTexParameterIuivEXT( GLenum target, GLenum pname, GLuint *params );
void glGetTexParameterIivEXT( GLenum target, GLenum pname, GLint *params);
void glGetTexParameterIuivEXT( GLenum target, GLenum pname, GLuint *params);
void glVertexAttribI1iEXT(GLuint index, GLint x);
void glVertexAttribI2iEXT(GLuint index, GLint x, GLint y);
void glVertexAttribI3iEXT(GLuint index, GLint x, GLint y, GLint z);
void glVertexAttribI4iEXT(GLuint index, GLint x, GLint y, GLint z, GLint w);
void glVertexAttribI1uiEXT(GLuint index, GLuint x);
void glVertexAttribI2uiEXT(GLuint index, GLuint x, GLuint y);
void glVertexAttribI3uiEXT(GLuint index, GLuint x, GLuint y, GLuint z);
void glVertexAttribI4uiEXT(GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
void glVertexAttribI1ivEXT(GLuint index, const GLint *v);
void glVertexAttribI2ivEXT(GLuint index, const GLint *v);
void glVertexAttribI3ivEXT(GLuint index, const GLint *v);
void glVertexAttribI4ivEXT(GLuint index, const GLint *v);
void glVertexAttribI1uivEXT(GLuint index, const GLuint *v);
void glVertexAttribI2uivEXT(GLuint index, const GLuint *v);
void glVertexAttribI3uivEXT(GLuint index, const GLuint *v);
void glVertexAttribI4uivEXT(GLuint index, const GLuint *v);
void glVertexAttribI4bvEXT(GLuint index, const GLbyte *v);
void glVertexAttribI4svEXT(GLuint index, const GLshort *v);
void glVertexAttribI4ubvEXT(GLuint index, const GLubyte *v);
void glVertexAttribI4usvEXT(GLuint index, const GLushort *v);
void glVertexAttribIPointerEXT(GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
void glGetVertexAttribIivEXT(GLuint index, GLenum pname, GLint *params);
void glGetVertexAttribIuivEXT(GLuint index, GLenum pname, GLuint *params);
void glUniform1uiEXT(GLint location, GLuint v0);
void glUniform2uiEXT(GLint location, GLuint v0, GLuint v1);
void glUniform3uiEXT(GLint location, GLuint v0, GLuint v1, GLuint v2);
void glUniform4uiEXT(GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
void glUniform1uivEXT(GLint location, GLsizei count, const GLuint *value);
void glUniform2uivEXT(GLint location, GLsizei count, const GLuint *value);
void glUniform3uivEXT(GLint location, GLsizei count, const GLuint *value);
void glUniform4uivEXT(GLint location, GLsizei count, const GLuint *value);
void glGetUniformuivEXT(GLuint program, GLint location, GLuint *params);
void glBindFragDataLocationEXT(GLuint program, GLuint colorNumber, const GLchar *name);
GLint glGetFragDataLocationEXT(GLuint program, const GLchar *name);
void glColorMaskIndexedEXT(GLuint index, GLboolean r, GLboolean g, GLboolean b, GLboolean a);
void glEnableIndexedEXT(GLenum target, GLuint index);
void glDisableIndexedEXT(GLenum target, GLuint index);
GLboolean glIsEnabledIndexedEXT(GLenum target, GLuint index);
void glProvokingVertexEXT(GLenum mode);
void glTextureRangeAPPLE(GLenum target, GLsizei length, const GLvoid *pointer);
void glGetTexParameterPointervAPPLE(GLenum target, GLenum pname, GLvoid **params);
void glVertexArrayRangeAPPLE(GLsizei length, const GLvoid *pointer);
void glFlushVertexArrayRangeAPPLE(GLsizei length, const GLvoid *pointer);
void glVertexArrayParameteriAPPLE(GLenum pname, GLint param);
void glBindVertexArrayAPPLE(GLuint id);
void glDeleteVertexArraysAPPLE(GLsizei n, const GLuint *ids);
void glGenVertexArraysAPPLE(GLsizei n, GLuint *ids);
GLboolean glIsVertexArrayAPPLE(GLuint id);
void glGenFencesAPPLE(GLsizei n, GLuint *fences);
void glDeleteFencesAPPLE(GLsizei n, const GLuint *fences);
void glSetFenceAPPLE(GLuint fence);
GLboolean glIsFenceAPPLE(GLuint fence);
GLboolean glTestFenceAPPLE(GLuint fence);
void glFinishFenceAPPLE(GLuint fence);
GLboolean glTestObjectAPPLE(GLenum object, GLuint name);
void glFinishObjectAPPLE(GLenum object, GLuint name);
void glElementPointerAPPLE(GLenum type, const GLvoid *pointer);
void glDrawElementArrayAPPLE(GLenum mode, GLint first, GLsizei count);
void glDrawRangeElementArrayAPPLE(GLenum mode, GLuint start, GLuint end, GLint first, GLsizei count);
void glMultiDrawElementArrayAPPLE(GLenum mode, const GLint *first, const GLsizei *count, GLsizei primcount);
void glMultiDrawRangeElementArrayAPPLE(GLenum mode, GLuint start, GLuint end, const GLint *first, const GLsizei *count, GLsizei primcount);
void glFlushRenderAPPLE(void);
void glFinishRenderAPPLE(void);
void glSwapAPPLE(void);
void glEnableVertexAttribAPPLE(GLuint index, GLenum pname);
void glDisableVertexAttribAPPLE(GLuint index, GLenum pname);
GLboolean glIsVertexAttribEnabledAPPLE(GLuint index, GLenum pname);
void glMapVertexAttrib1dAPPLE(GLuint index, GLuint size, GLdouble u1, GLdouble u2, GLint stride, GLint order, const GLdouble *points);
void glMapVertexAttrib1fAPPLE(GLuint index, GLuint size, GLfloat u1, GLfloat u2, GLint stride, GLint order, const GLfloat *points);
void glMapVertexAttrib2dAPPLE(GLuint index, GLuint size, GLdouble u1, GLdouble u2, GLint ustride, GLint uorder, GLdouble v1, GLdouble v2, GLint vstride, GLint vorder, const GLdouble *points);
void glMapVertexAttrib2fAPPLE(GLuint index, GLuint size, GLfloat u1, GLfloat u2, GLint ustride, GLint uorder, GLfloat v1, GLfloat v2, GLint vstride, GLint vorder, const GLfloat *points);
void glBufferParameteriAPPLE(GLenum target, GLenum pname, GLint param);
void glFlushMappedBufferRangeAPPLE(GLenum target, GLintptr offset, GLsizeiptr size);
GLenum glObjectPurgeableAPPLE(GLenum objectType, GLuint name, GLenum option);
GLenum glObjectUnpurgeableAPPLE(GLenum objectType, GLuint name, GLenum option);
void glGetObjectParameterivAPPLE(GLenum objectType, GLuint name, GLenum pname, GLint* params);
void glPNTrianglesiATI(GLenum pname, GLint param);
void glPNTrianglesfATI(GLenum pname, GLfloat param);
void glBlendEquationSeparateATI(GLenum equationRGB, GLenum equationAlpha);
void glStencilOpSeparateATI(GLenum face, GLenum sfail, GLenum dpfail, GLenum dppass);
void glStencilFuncSeparateATI(GLenum frontfunc, GLenum backfunc, GLint ref, GLuint mask);
void glPNTrianglesiATIX(GLenum pname, GLint param);
void glPNTrianglesfATIX(GLenum pname, GLfloat param);
void glPointParameteriNV(GLenum pname, GLint param);
void glPointParameterivNV(GLenum pname, const GLint *params);
void glBeginConditionalRenderNV (GLuint id, GLenum mode);
void glEndConditionalRenderNV (void);
void glAccum (GLenum op, GLfloat value);
void glAlphaFunc (GLenum func, GLclampf ref);
GLboolean glAreTexturesResident (GLsizei n, const GLuint *textures, GLboolean *residences);
void glArrayElement (GLint i);
void glBegin (GLenum mode);
void glBindTexture (GLenum target, GLuint texture);
void glBitmap (GLsizei width, GLsizei height, GLfloat xorig, GLfloat yorig, GLfloat xmove, GLfloat ymove, const GLubyte *bitmap);
void glBlendColor (GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
void glBlendEquation (GLenum mode);
void glBlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha);
void glBlendFunc (GLenum sfactor, GLenum dfactor);
void glCallList (GLuint list);
void glCallLists (GLsizei n, GLenum type, const GLvoid *lists);
void glClear (GLbitfield mask);
void glClearAccum (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void glClearColor (GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
void glClearDepth (GLclampd depth);
void glClearIndex (GLfloat c);
void glClearStencil (GLint s);
void glClipPlane (GLenum plane, const GLdouble *equation);
void glColor3b (GLbyte red, GLbyte green, GLbyte blue);
void glColor3bv (const GLbyte *v);
void glColor3d (GLdouble red, GLdouble green, GLdouble blue);
void glColor3dv (const GLdouble *v);
void glColor3f (GLfloat red, GLfloat green, GLfloat blue);
void glColor3fv (const GLfloat *v);
void glColor3i (GLint red, GLint green, GLint blue);
void glColor3iv (const GLint *v);
void glColor3s (GLshort red, GLshort green, GLshort blue);
void glColor3sv (const GLshort *v);
void glColor3ub (GLubyte red, GLubyte green, GLubyte blue);
void glColor3ubv (const GLubyte *v);
void glColor3ui (GLuint red, GLuint green, GLuint blue);
void glColor3uiv (const GLuint *v);
void glColor3us (GLushort red, GLushort green, GLushort blue);
void glColor3usv (const GLushort *v);
void glColor4b (GLbyte red, GLbyte green, GLbyte blue, GLbyte alpha);
void glColor4bv (const GLbyte *v);
void glColor4d (GLdouble red, GLdouble green, GLdouble blue, GLdouble alpha);
void glColor4dv (const GLdouble *v);
void glColor4f (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void glColor4fv (const GLfloat *v);
void glColor4i (GLint red, GLint green, GLint blue, GLint alpha);
void glColor4iv (const GLint *v);
void glColor4s (GLshort red, GLshort green, GLshort blue, GLshort alpha);
void glColor4sv (const GLshort *v);
void glColor4ub (GLubyte red, GLubyte green, GLubyte blue, GLubyte alpha);
void glColor4ubv (const GLubyte *v);
void glColor4ui (GLuint red, GLuint green, GLuint blue, GLuint alpha);
void glColor4uiv (const GLuint *v);
void glColor4us (GLushort red, GLushort green, GLushort blue, GLushort alpha);
void glColor4usv (const GLushort *v);
void glColorMask (GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
void glColorMaterial (GLenum face, GLenum mode);
void glColorPointer (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
void glColorSubTable (GLenum target, GLsizei start, GLsizei count, GLenum format, GLenum type, const GLvoid *data);
void glColorTable (GLenum target, GLenum internalformat, GLsizei width, GLenum format, GLenum type, const GLvoid *table);
void glColorTableParameterfv (GLenum target, GLenum pname, const GLfloat *params);
void glColorTableParameteriv (GLenum target, GLenum pname, const GLint *params);
void glConvolutionFilter1D (GLenum target, GLenum internalformat, GLsizei width, GLenum format, GLenum type, const GLvoid *image);
void glConvolutionFilter2D (GLenum target, GLenum internalformat, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *image);
void glConvolutionParameterf (GLenum target, GLenum pname, GLfloat params);
void glConvolutionParameterfv (GLenum target, GLenum pname, const GLfloat *params);
void glConvolutionParameteri (GLenum target, GLenum pname, GLint params);
void glConvolutionParameteriv (GLenum target, GLenum pname, const GLint *params);
void glCopyColorSubTable (GLenum target, GLsizei start, GLint x, GLint y, GLsizei width);
void glCopyColorTable (GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width);
void glCopyConvolutionFilter1D (GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width);
void glCopyConvolutionFilter2D (GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height);
void glCopyPixels (GLint x, GLint y, GLsizei width, GLsizei height, GLenum type);
void glCopyTexImage1D (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLint border);
void glCopyTexImage2D (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
void glCopyTexSubImage1D (GLenum target, GLint level, GLint xoffset, GLint x, GLint y, GLsizei width);
void glCopyTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
void glCopyTexSubImage3D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);
void glCullFace (GLenum mode);
void glDeleteLists (GLuint list, GLsizei range);
void glDeleteTextures (GLsizei n, const GLuint *textures);
void glDepthFunc (GLenum func);
void glDepthMask (GLboolean flag);
void glDepthRange (GLclampd zNear, GLclampd zFar);
void glDisable (GLenum cap);
void glDisableClientState (GLenum array);
void glDrawArrays (GLenum mode, GLint first, GLsizei count);
void glDrawBuffer (GLenum mode);
void glDrawElements (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices);
void glDrawPixels (GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels);
void glDrawRangeElements (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indices);
void glEdgeFlag (GLboolean flag);
void glEdgeFlagPointer (GLsizei stride, const GLvoid *pointer);
void glEdgeFlagv (const GLboolean *flag);
void glEnable (GLenum cap);
void glEnableClientState (GLenum array);
void glEnd (void);
void glEndList (void);
void glEvalCoord1d (GLdouble u);
void glEvalCoord1dv (const GLdouble *u);
void glEvalCoord1f (GLfloat u);
void glEvalCoord1fv (const GLfloat *u);
void glEvalCoord2d (GLdouble u, GLdouble v);
void glEvalCoord2dv (const GLdouble *u);
void glEvalCoord2f (GLfloat u, GLfloat v);
void glEvalCoord2fv (const GLfloat *u);
void glEvalMesh1 (GLenum mode, GLint i1, GLint i2);
void glEvalMesh2 (GLenum mode, GLint i1, GLint i2, GLint j1, GLint j2);
void glEvalPoint1 (GLint i);
void glEvalPoint2 (GLint i, GLint j);
void glFeedbackBuffer (GLsizei size, GLenum type, GLfloat *buffer);
void glFinish (void);
void glFlush (void);
void glFogf (GLenum pname, GLfloat param);
void glFogfv (GLenum pname, const GLfloat *params);
void glFogi (GLenum pname, GLint param);
void glFogiv (GLenum pname, const GLint *params);
void glFrontFace (GLenum mode);
void glFrustum (GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble zNear, GLdouble zFar);
GLuint glGenLists (GLsizei range);
void glGenTextures (GLsizei n, GLuint *textures);
void glGetBooleanv (GLenum pname, GLboolean *params);
void glGetClipPlane (GLenum plane, GLdouble *equation);
void glGetColorTable (GLenum target, GLenum format, GLenum type, GLvoid *table);
void glGetColorTableParameterfv (GLenum target, GLenum pname, GLfloat *params);
void glGetColorTableParameteriv (GLenum target, GLenum pname, GLint *params);
void glGetConvolutionFilter (GLenum target, GLenum format, GLenum type, GLvoid *image);
void glGetConvolutionParameterfv (GLenum target, GLenum pname, GLfloat *params);
void glGetConvolutionParameteriv (GLenum target, GLenum pname, GLint *params);
void glGetDoublev (GLenum pname, GLdouble *params);
GLenum glGetError (void);
void glGetFloatv (GLenum pname, GLfloat *params);
void glGetHistogram (GLenum target, GLboolean reset, GLenum format, GLenum type, GLvoid *values);
void glGetHistogramParameterfv (GLenum target, GLenum pname, GLfloat *params);
void glGetHistogramParameteriv (GLenum target, GLenum pname, GLint *params);
void glGetIntegerv (GLenum pname, GLint *params);
void glGetLightfv (GLenum light, GLenum pname, GLfloat *params);
void glGetLightiv (GLenum light, GLenum pname, GLint *params);
void glGetMapdv (GLenum target, GLenum query, GLdouble *v);
void glGetMapfv (GLenum target, GLenum query, GLfloat *v);
void glGetMapiv (GLenum target, GLenum query, GLint *v);
void glGetMaterialfv (GLenum face, GLenum pname, GLfloat *params);
void glGetMaterialiv (GLenum face, GLenum pname, GLint *params);
void glGetMinmax (GLenum target, GLboolean reset, GLenum format, GLenum type, GLvoid *values);
void glGetMinmaxParameterfv (GLenum target, GLenum pname, GLfloat *params);
void glGetMinmaxParameteriv (GLenum target, GLenum pname, GLint *params);
void glGetPixelMapfv (GLenum map, GLfloat *values);
void glGetPixelMapuiv (GLenum map, GLuint *values);
void glGetPixelMapusv (GLenum map, GLushort *values);
void glGetPointerv (GLenum pname, GLvoid* *params);
void glGetPolygonStipple (GLubyte *mask);
void glGetSeparableFilter (GLenum target, GLenum format, GLenum type, GLvoid *row, GLvoid *column, GLvoid *span);
const GLubyte * glGetString (GLenum name);
void glGetTexEnvfv (GLenum target, GLenum pname, GLfloat *params);
void glGetTexEnviv (GLenum target, GLenum pname, GLint *params);
void glGetTexGendv (GLenum coord, GLenum pname, GLdouble *params);
void glGetTexGenfv (GLenum coord, GLenum pname, GLfloat *params);
void glGetTexGeniv (GLenum coord, GLenum pname, GLint *params);
void glGetTexImage (GLenum target, GLint level, GLenum format, GLenum type, GLvoid *pixels);
void glGetTexLevelParameterfv (GLenum target, GLint level, GLenum pname, GLfloat *params);
void glGetTexLevelParameteriv (GLenum target, GLint level, GLenum pname, GLint *params);
void glGetTexParameterfv (GLenum target, GLenum pname, GLfloat *params);
void glGetTexParameteriv (GLenum target, GLenum pname, GLint *params);
void glHint (GLenum target, GLenum mode);
void glHistogram (GLenum target, GLsizei width, GLenum internalformat, GLboolean sink);
void glIndexMask (GLuint mask);
void glIndexPointer (GLenum type, GLsizei stride, const GLvoid *pointer);
void glIndexd (GLdouble c);
void glIndexdv (const GLdouble *c);
void glIndexf (GLfloat c);
void glIndexfv (const GLfloat *c);
void glIndexi (GLint c);
void glIndexiv (const GLint *c);
void glIndexs (GLshort c);
void glIndexsv (const GLshort *c);
void glIndexub (GLubyte c);
void glIndexubv (const GLubyte *c);
void glInitNames (void);
void glInterleavedArrays (GLenum format, GLsizei stride, const GLvoid *pointer);
GLboolean glIsEnabled (GLenum cap);
GLboolean glIsList (GLuint list);
GLboolean glIsTexture (GLuint texture);
void glLightModelf (GLenum pname, GLfloat param);
void glLightModelfv (GLenum pname, const GLfloat *params);
void glLightModeli (GLenum pname, GLint param);
void glLightModeliv (GLenum pname, const GLint *params);
void glLightf (GLenum light, GLenum pname, GLfloat param);
void glLightfv (GLenum light, GLenum pname, const GLfloat *params);
void glLighti (GLenum light, GLenum pname, GLint param);
void glLightiv (GLenum light, GLenum pname, const GLint *params);
void glLineStipple (GLint factor, GLushort pattern);
void glLineWidth (GLfloat width);
void glListBase (GLuint base);
void glLoadIdentity (void);
void glLoadMatrixd (const GLdouble *m);
void glLoadMatrixf (const GLfloat *m);
void glLoadName (GLuint name);
void glLogicOp (GLenum opcode);
void glMap1d (GLenum target, GLdouble u1, GLdouble u2, GLint stride, GLint order, const GLdouble *points);
void glMap1f (GLenum target, GLfloat u1, GLfloat u2, GLint stride, GLint order, const GLfloat *points);
void glMap2d (GLenum target, GLdouble u1, GLdouble u2, GLint ustride, GLint uorder, GLdouble v1, GLdouble v2, GLint vstride, GLint vorder, const GLdouble *points);
void glMap2f (GLenum target, GLfloat u1, GLfloat u2, GLint ustride, GLint uorder, GLfloat v1, GLfloat v2, GLint vstride, GLint vorder, const GLfloat *points);
void glMapGrid1d (GLint un, GLdouble u1, GLdouble u2);
void glMapGrid1f (GLint un, GLfloat u1, GLfloat u2);
void glMapGrid2d (GLint un, GLdouble u1, GLdouble u2, GLint vn, GLdouble v1, GLdouble v2);
void glMapGrid2f (GLint un, GLfloat u1, GLfloat u2, GLint vn, GLfloat v1, GLfloat v2);
void glMaterialf (GLenum face, GLenum pname, GLfloat param);
void glMaterialfv (GLenum face, GLenum pname, const GLfloat *params);
void glMateriali (GLenum face, GLenum pname, GLint param);
void glMaterialiv (GLenum face, GLenum pname, const GLint *params);
void glMatrixMode (GLenum mode);
void glMinmax (GLenum target, GLenum internalformat, GLboolean sink);
void glMultMatrixd (const GLdouble *m);
void glMultMatrixf (const GLfloat *m);
void glNewList (GLuint list, GLenum mode);
void glNormal3b (GLbyte nx, GLbyte ny, GLbyte nz);
void glNormal3bv (const GLbyte *v);
void glNormal3d (GLdouble nx, GLdouble ny, GLdouble nz);
void glNormal3dv (const GLdouble *v);
void glNormal3f (GLfloat nx, GLfloat ny, GLfloat nz);
void glNormal3fv (const GLfloat *v);
void glNormal3i (GLint nx, GLint ny, GLint nz);
void glNormal3iv (const GLint *v);
void glNormal3s (GLshort nx, GLshort ny, GLshort nz);
void glNormal3sv (const GLshort *v);
void glNormalPointer (GLenum type, GLsizei stride, const GLvoid *pointer);
void glOrtho (GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble zNear, GLdouble zFar);
void glPassThrough (GLfloat token);
void glPixelMapfv (GLenum map, GLint mapsize, const GLfloat *values);
void glPixelMapuiv (GLenum map, GLint mapsize, const GLuint *values);
void glPixelMapusv (GLenum map, GLint mapsize, const GLushort *values);
void glPixelStoref (GLenum pname, GLfloat param);
void glPixelStorei (GLenum pname, GLint param);
void glPixelTransferf (GLenum pname, GLfloat param);
void glPixelTransferi (GLenum pname, GLint param);
void glPixelZoom (GLfloat xfactor, GLfloat yfactor);
void glPointSize (GLfloat size);
void glPolygonMode (GLenum face, GLenum mode);
void glPolygonOffset (GLfloat factor, GLfloat units);
void glPolygonStipple (const GLubyte *mask);
void glPopAttrib (void);
void glPopClientAttrib (void);
void glPopMatrix (void);
void glPopName (void);
void glPrioritizeTextures (GLsizei n, const GLuint *textures, const GLclampf *priorities);
void glPushAttrib (GLbitfield mask);
void glPushClientAttrib (GLbitfield mask);
void glPushMatrix (void);
void glPushName (GLuint name);
void glRasterPos2d (GLdouble x, GLdouble y);
void glRasterPos2dv (const GLdouble *v);
void glRasterPos2f (GLfloat x, GLfloat y);
void glRasterPos2fv (const GLfloat *v);
void glRasterPos2i (GLint x, GLint y);
void glRasterPos2iv (const GLint *v);
void glRasterPos2s (GLshort x, GLshort y);
void glRasterPos2sv (const GLshort *v);
void glRasterPos3d (GLdouble x, GLdouble y, GLdouble z);
void glRasterPos3dv (const GLdouble *v);
void glRasterPos3f (GLfloat x, GLfloat y, GLfloat z);
void glRasterPos3fv (const GLfloat *v);
void glRasterPos3i (GLint x, GLint y, GLint z);
void glRasterPos3iv (const GLint *v);
void glRasterPos3s (GLshort x, GLshort y, GLshort z);
void glRasterPos3sv (const GLshort *v);
void glRasterPos4d (GLdouble x, GLdouble y, GLdouble z, GLdouble w);
void glRasterPos4dv (const GLdouble *v);
void glRasterPos4f (GLfloat x, GLfloat y, GLfloat z, GLfloat w);
void glRasterPos4fv (const GLfloat *v);
void glRasterPos4i (GLint x, GLint y, GLint z, GLint w);
void glRasterPos4iv (const GLint *v);
void glRasterPos4s (GLshort x, GLshort y, GLshort z, GLshort w);
void glRasterPos4sv (const GLshort *v);
void glReadBuffer (GLenum mode);
void glReadPixels (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid *pixels);
void glRectd (GLdouble x1, GLdouble y1, GLdouble x2, GLdouble y2);
void glRectdv (const GLdouble *v1, const GLdouble *v2);
void glRectf (GLfloat x1, GLfloat y1, GLfloat x2, GLfloat y2);
void glRectfv (const GLfloat *v1, const GLfloat *v2);
void glRecti (GLint x1, GLint y1, GLint x2, GLint y2);
void glRectiv (const GLint *v1, const GLint *v2);
void glRects (GLshort x1, GLshort y1, GLshort x2, GLshort y2);
void glRectsv (const GLshort *v1, const GLshort *v2);
GLint glRenderMode (GLenum mode);
void glResetHistogram (GLenum target);
void glResetMinmax (GLenum target);
void glRotated (GLdouble angle, GLdouble x, GLdouble y, GLdouble z);
void glRotatef (GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
void glScaled (GLdouble x, GLdouble y, GLdouble z);
void glScalef (GLfloat x, GLfloat y, GLfloat z);
void glScissor (GLint x, GLint y, GLsizei width, GLsizei height);
void glSelectBuffer (GLsizei size, GLuint *buffer);
void glSeparableFilter2D (GLenum target, GLenum internalformat, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *row, const GLvoid *column);
void glShadeModel (GLenum mode);
void glStencilFunc (GLenum func, GLint ref, GLuint mask);
void glStencilMask (GLuint mask);
void glStencilOp (GLenum fail, GLenum zfail, GLenum zpass);
void glTexCoord1d (GLdouble s);
void glTexCoord1dv (const GLdouble *v);
void glTexCoord1f (GLfloat s);
void glTexCoord1fv (const GLfloat *v);
void glTexCoord1i (GLint s);
void glTexCoord1iv (const GLint *v);
void glTexCoord1s (GLshort s);
void glTexCoord1sv (const GLshort *v);
void glTexCoord2d (GLdouble s, GLdouble t);
void glTexCoord2dv (const GLdouble *v);
void glTexCoord2f (GLfloat s, GLfloat t);
void glTexCoord2fv (const GLfloat *v);
void glTexCoord2i (GLint s, GLint t);
void glTexCoord2iv (const GLint *v);
void glTexCoord2s (GLshort s, GLshort t);
void glTexCoord2sv (const GLshort *v);
void glTexCoord3d (GLdouble s, GLdouble t, GLdouble r);
void glTexCoord3dv (const GLdouble *v);
void glTexCoord3f (GLfloat s, GLfloat t, GLfloat r);
void glTexCoord3fv (const GLfloat *v);
void glTexCoord3i (GLint s, GLint t, GLint r);
void glTexCoord3iv (const GLint *v);
void glTexCoord3s (GLshort s, GLshort t, GLshort r);
void glTexCoord3sv (const GLshort *v);
void glTexCoord4d (GLdouble s, GLdouble t, GLdouble r, GLdouble q);
void glTexCoord4dv (const GLdouble *v);
void glTexCoord4f (GLfloat s, GLfloat t, GLfloat r, GLfloat q);
void glTexCoord4fv (const GLfloat *v);
void glTexCoord4i (GLint s, GLint t, GLint r, GLint q);
void glTexCoord4iv (const GLint *v);
void glTexCoord4s (GLshort s, GLshort t, GLshort r, GLshort q);
void glTexCoord4sv (const GLshort *v);
void glTexCoordPointer (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
void glTexEnvf (GLenum target, GLenum pname, GLfloat param);
void glTexEnvfv (GLenum target, GLenum pname, const GLfloat *params);
void glTexEnvi (GLenum target, GLenum pname, GLint param);
void glTexEnviv (GLenum target, GLenum pname, const GLint *params);
void glTexGend (GLenum coord, GLenum pname, GLdouble param);
void glTexGendv (GLenum coord, GLenum pname, const GLdouble *params);
void glTexGenf (GLenum coord, GLenum pname, GLfloat param);
void glTexGenfv (GLenum coord, GLenum pname, const GLfloat *params);
void glTexGeni (GLenum coord, GLenum pname, GLint param);
void glTexGeniv (GLenum coord, GLenum pname, const GLint *params);
void glTexImage1D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
void glTexImage2D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
void glTexImage3D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
void glTexParameterf (GLenum target, GLenum pname, GLfloat param);
void glTexParameterfv (GLenum target, GLenum pname, const GLfloat *params);
void glTexParameteri (GLenum target, GLenum pname, GLint param);
void glTexParameteriv (GLenum target, GLenum pname, const GLint *params);
void glTexSubImage1D (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLenum type, const GLvoid *pixels);
void glTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels);
void glTexSubImage3D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid *pixels);
void glTranslated (GLdouble x, GLdouble y, GLdouble z);
void glTranslatef (GLfloat x, GLfloat y, GLfloat z);
void glVertex2d (GLdouble x, GLdouble y);
void glVertex2dv (const GLdouble *v);
void glVertex2f (GLfloat x, GLfloat y);
void glVertex2fv (const GLfloat *v);
void glVertex2i (GLint x, GLint y);
void glVertex2iv (const GLint *v);
void glVertex2s (GLshort x, GLshort y);
void glVertex2sv (const GLshort *v);
void glVertex3d (GLdouble x, GLdouble y, GLdouble z);
void glVertex3dv (const GLdouble *v);
void glVertex3f (GLfloat x, GLfloat y, GLfloat z);
void glVertex3fv (const GLfloat *v);
void glVertex3i (GLint x, GLint y, GLint z);
void glVertex3iv (const GLint *v);
void glVertex3s (GLshort x, GLshort y, GLshort z);
void glVertex3sv (const GLshort *v);
void glVertex4d (GLdouble x, GLdouble y, GLdouble z, GLdouble w);
void glVertex4dv (const GLdouble *v);
void glVertex4f (GLfloat x, GLfloat y, GLfloat z, GLfloat w);
void glVertex4fv (const GLfloat *v);
void glVertex4i (GLint x, GLint y, GLint z, GLint w);
void glVertex4iv (const GLint *v);
void glVertex4s (GLshort x, GLshort y, GLshort z, GLshort w);
void glVertex4sv (const GLshort *v);
void glVertexPointer (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
void glViewport (GLint x, GLint y, GLsizei width, GLsizei height);
void glSampleCoverage (GLclampf value, GLboolean invert);
void glSamplePass (GLenum pass);
void glLoadTransposeMatrixf (const GLfloat *m);
void glLoadTransposeMatrixd (const GLdouble *m);
void glMultTransposeMatrixf (const GLfloat *m);
void glMultTransposeMatrixd (const GLdouble *m);
void glCompressedTexImage3D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid *data);
void glCompressedTexImage2D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid *data);
void glCompressedTexImage1D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLsizei imageSize, const GLvoid *data);
void glCompressedTexSubImage3D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid *data);
void glCompressedTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid *data);
void glCompressedTexSubImage1D (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, const GLvoid *data);
void glGetCompressedTexImage (GLenum target, GLint lod, GLvoid *img);
void glActiveTexture (GLenum texture);
void glClientActiveTexture (GLenum texture);
void glMultiTexCoord1d (GLenum target, GLdouble s);
void glMultiTexCoord1dv (GLenum target, const GLdouble *v);
void glMultiTexCoord1f (GLenum target, GLfloat s);
void glMultiTexCoord1fv (GLenum target, const GLfloat *v);
void glMultiTexCoord1i (GLenum target, GLint s);
void glMultiTexCoord1iv (GLenum target, const GLint *v);
void glMultiTexCoord1s (GLenum target, GLshort s);
void glMultiTexCoord1sv (GLenum target, const GLshort *v);
void glMultiTexCoord2d (GLenum target, GLdouble s, GLdouble t);
void glMultiTexCoord2dv (GLenum target, const GLdouble *v);
void glMultiTexCoord2f (GLenum target, GLfloat s, GLfloat t);
void glMultiTexCoord2fv (GLenum target, const GLfloat *v);
void glMultiTexCoord2i (GLenum target, GLint s, GLint t);
void glMultiTexCoord2iv (GLenum target, const GLint *v);
void glMultiTexCoord2s (GLenum target, GLshort s, GLshort t);
void glMultiTexCoord2sv (GLenum target, const GLshort *v);
void glMultiTexCoord3d (GLenum target, GLdouble s, GLdouble t, GLdouble r);
void glMultiTexCoord3dv (GLenum target, const GLdouble *v);
void glMultiTexCoord3f (GLenum target, GLfloat s, GLfloat t, GLfloat r);
void glMultiTexCoord3fv (GLenum target, const GLfloat *v);
void glMultiTexCoord3i (GLenum target, GLint s, GLint t, GLint r);
void glMultiTexCoord3iv (GLenum target, const GLint *v);
void glMultiTexCoord3s (GLenum target, GLshort s, GLshort t, GLshort r);
void glMultiTexCoord3sv (GLenum target, const GLshort *v);
void glMultiTexCoord4d (GLenum target, GLdouble s, GLdouble t, GLdouble r, GLdouble q);
void glMultiTexCoord4dv (GLenum target, const GLdouble *v);
void glMultiTexCoord4f (GLenum target, GLfloat s, GLfloat t, GLfloat r, GLfloat q);
void glMultiTexCoord4fv (GLenum target, const GLfloat *v);
void glMultiTexCoord4i (GLenum target, GLint, GLint s, GLint t, GLint r);
void glMultiTexCoord4iv (GLenum target, const GLint *v);
void glMultiTexCoord4s (GLenum target, GLshort s, GLshort t, GLshort r, GLshort q);
void glMultiTexCoord4sv (GLenum target, const GLshort *v);
void glFogCoordf (GLfloat coord);
void glFogCoordfv (const GLfloat *coord);
void glFogCoordd (GLdouble coord);
void glFogCoorddv (const GLdouble * coord);
void glFogCoordPointer (GLenum type, GLsizei stride, const GLvoid *pointer);
void glSecondaryColor3b (GLbyte red, GLbyte green, GLbyte blue);
void glSecondaryColor3bv (const GLbyte *v);
void glSecondaryColor3d (GLdouble red, GLdouble green, GLdouble blue);
void glSecondaryColor3dv (const GLdouble *v);
void glSecondaryColor3f (GLfloat red, GLfloat green, GLfloat blue);
void glSecondaryColor3fv (const GLfloat *v);
void glSecondaryColor3i (GLint red, GLint green, GLint blue);
void glSecondaryColor3iv (const GLint *v);
void glSecondaryColor3s (GLshort red, GLshort green, GLshort blue);
void glSecondaryColor3sv (const GLshort *v);
void glSecondaryColor3ub (GLubyte red, GLubyte green, GLubyte blue);
void glSecondaryColor3ubv (const GLubyte *v);
void glSecondaryColor3ui (GLuint red, GLuint green, GLuint blue);
void glSecondaryColor3uiv (const GLuint *v);
void glSecondaryColor3us (GLushort red, GLushort green, GLushort blue);
void glSecondaryColor3usv (const GLushort *v);
void glSecondaryColorPointer (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
void glPointParameterf (GLenum pname, GLfloat param);
void glPointParameterfv (GLenum pname, const GLfloat *params);
void glPointParameteri (GLenum pname, GLint param);
void glPointParameteriv (GLenum pname, const GLint *params);
void glBlendFuncSeparate (GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);
void glMultiDrawArrays (GLenum mode, const GLint *first, const GLsizei *count, GLsizei primcount);
void glMultiDrawElements (GLenum mode, const GLsizei *count, GLenum type, const GLvoid* *indices, GLsizei primcount);
void glWindowPos2d (GLdouble x, GLdouble y);
void glWindowPos2dv (const GLdouble *v);
void glWindowPos2f (GLfloat x, GLfloat y);
void glWindowPos2fv (const GLfloat *v);
void glWindowPos2i (GLint x, GLint y);
void glWindowPos2iv (const GLint *v);
void glWindowPos2s (GLshort x, GLshort y);
void glWindowPos2sv (const GLshort *v);
void glWindowPos3d (GLdouble x, GLdouble y, GLdouble z);
void glWindowPos3dv (const GLdouble *v);
void glWindowPos3f (GLfloat x, GLfloat y, GLfloat z);
void glWindowPos3fv (const GLfloat *v);
void glWindowPos3i (GLint x, GLint y, GLint z);
void glWindowPos3iv (const GLint *v);
void glWindowPos3s (GLshort x, GLshort y, GLshort z);
void glWindowPos3sv (const GLshort *v);
void glGenQueries(GLsizei n, GLuint *ids);
void glDeleteQueries(GLsizei n, const GLuint *ids);
GLboolean glIsQuery(GLuint id);
void glBeginQuery(GLenum target, GLuint id);
void glEndQuery(GLenum target);
void glGetQueryiv(GLenum target, GLenum pname, GLint *params);
void glGetQueryObjectiv(GLuint id, GLenum pname, GLint *params);
void glGetQueryObjectuiv(GLuint id, GLenum pname, GLuint *params);
void glBindBuffer (GLenum target, GLuint buffer);
void glDeleteBuffers (GLsizei n, const GLuint *buffers);
void glGenBuffers (GLsizei n, GLuint *buffers);
GLboolean glIsBuffer (GLuint buffer);
void glBufferData (GLenum target, GLsizeiptr size, const GLvoid *data, GLenum usage);
void glBufferSubData (GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid *data);
void glGetBufferSubData (GLenum target, GLintptr offset, GLsizeiptr size, GLvoid *data);
GLvoid * glMapBuffer (GLenum target, GLenum access);
GLboolean glUnmapBuffer (GLenum target);
void glGetBufferParameteriv (GLenum target, GLenum pname, GLint *params);
void glGetBufferPointerv (GLenum target, GLenum pname, GLvoid **params);
void glDrawBuffers (GLsizei n, const GLenum *bufs);
void glVertexAttrib1d (GLuint index, GLdouble x);
void glVertexAttrib1dv (GLuint index, const GLdouble *v);
void glVertexAttrib1f (GLuint index, GLfloat x);
void glVertexAttrib1fv (GLuint index, const GLfloat *v);
void glVertexAttrib1s (GLuint index, GLshort x);
void glVertexAttrib1sv (GLuint index, const GLshort *v);
void glVertexAttrib2d (GLuint index, GLdouble x, GLdouble y);
void glVertexAttrib2dv (GLuint index, const GLdouble *v);
void glVertexAttrib2f (GLuint index, GLfloat x, GLfloat y);
void glVertexAttrib2fv (GLuint index, const GLfloat *v);
void glVertexAttrib2s (GLuint index, GLshort x, GLshort y);
void glVertexAttrib2sv (GLuint index, const GLshort *v);
void glVertexAttrib3d (GLuint index, GLdouble x, GLdouble y, GLdouble z);
void glVertexAttrib3dv (GLuint index, const GLdouble *v);
void glVertexAttrib3f (GLuint index, GLfloat x, GLfloat y, GLfloat z);
void glVertexAttrib3fv (GLuint index, const GLfloat *v);
void glVertexAttrib3s (GLuint index, GLshort x, GLshort y, GLshort z);
void glVertexAttrib3sv (GLuint index, const GLshort *v);
void glVertexAttrib4Nbv (GLuint index, const GLbyte *v);
void glVertexAttrib4Niv (GLuint index, const GLint *v);
void glVertexAttrib4Nsv (GLuint index, const GLshort *v);
void glVertexAttrib4Nub (GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
void glVertexAttrib4Nubv (GLuint index, const GLubyte *v);
void glVertexAttrib4Nuiv (GLuint index, const GLuint *v);
void glVertexAttrib4Nusv (GLuint index, const GLushort *v);
void glVertexAttrib4bv (GLuint index, const GLbyte *v);
void glVertexAttrib4d (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
void glVertexAttrib4dv (GLuint index, const GLdouble *v);
void glVertexAttrib4f (GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
void glVertexAttrib4fv (GLuint index, const GLfloat *v);
void glVertexAttrib4iv (GLuint index, const GLint *v);
void glVertexAttrib4s (GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
void glVertexAttrib4sv (GLuint index, const GLshort *v);
void glVertexAttrib4ubv (GLuint index, const GLubyte *v);
void glVertexAttrib4uiv (GLuint index, const GLuint *v);
void glVertexAttrib4usv (GLuint index, const GLushort *v);
void glVertexAttribPointer (GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer);
void glEnableVertexAttribArray (GLuint index);
void glDisableVertexAttribArray (GLuint index);
void glGetVertexAttribdv (GLuint index, GLenum pname, GLdouble *params);
void glGetVertexAttribfv (GLuint index, GLenum pname, GLfloat *params);
void glGetVertexAttribiv (GLuint index, GLenum pname, GLint *params);
void glGetVertexAttribPointerv (GLuint index, GLenum pname, GLvoid* *pointer);
void glDeleteShader (GLuint shader);
void glDetachShader (GLuint program, GLuint shader);
GLuint glCreateShader (GLenum type);
void glShaderSource (GLuint shader, GLsizei count, const GLchar* *string, const GLint *length);
void glCompileShader (GLuint shader);
GLuint glCreateProgram (void);
void glAttachShader (GLuint program, GLuint shader);
void glLinkProgram (GLuint program);
void glUseProgram (GLuint program);
void glDeleteProgram (GLuint program);
void glValidateProgram (GLuint program);
void glUniform1f (GLint location, GLfloat v0);
void glUniform2f (GLint location, GLfloat v0, GLfloat v1);
void glUniform3f (GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
void glUniform4f (GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
void glUniform1i (GLint location, GLint v0);
void glUniform2i (GLint location, GLint v0, GLint v1);
void glUniform3i (GLint location, GLint v0, GLint v1, GLint v2);
void glUniform4i (GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
void glUniform1fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform2fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform3fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform4fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform1iv (GLint location, GLsizei count, const GLint *value);
void glUniform2iv (GLint location, GLsizei count, const GLint *value);
void glUniform3iv (GLint location, GLsizei count, const GLint *value);
void glUniform4iv (GLint location, GLsizei count, const GLint *value);
void glUniformMatrix2fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix3fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLboolean glIsShader (GLuint shader);
GLboolean glIsProgram (GLuint program);
void glGetShaderiv (GLuint shader, GLenum pname, GLint *params);
void glGetProgramiv (GLuint program, GLenum pname, GLint *params);
void glGetAttachedShaders (GLuint program, GLsizei maxCount, GLsizei *count, GLuint *shaders);
void glGetShaderInfoLog (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
void glGetProgramInfoLog (GLuint program, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
GLint glGetUniformLocation (GLuint program, const GLchar *name);
void glGetActiveUniform (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
void glGetUniformfv (GLuint program, GLint location, GLfloat *params);
void glGetUniformiv (GLuint program, GLint location, GLint *params);
void glGetShaderSource (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *source);
void glBindAttribLocation (GLuint program, GLuint index, const GLchar *name);
void glGetActiveAttrib (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
GLint glGetAttribLocation (GLuint program, const GLchar *name);
void glStencilFuncSeparate (GLenum face, GLenum func, GLint ref, GLuint mask);
void glStencilOpSeparate (GLenum face, GLenum fail, GLenum zfail, GLenum zpass);
void glStencilMaskSeparate (GLenum face, GLuint mask);
void glUniformMatrix2x3fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix3x2fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix2x4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix4x2fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix3x4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix4x3fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
]]

local gl = { 
	["debug"] = false,	-- automatically follow gl calls with glGetError()
}

if ffi.os == "Windows" then
	gl.WGL_WGLEXT_VERSION = 24
	
	ffi.cdef [[		
		typedef struct __GLsync *GLsync;
		typedef void (*GLDEBUGPROCARB)(GLenum source,GLenum type,GLuint id,GLenum severity,GLsizei length,const GLchar *message,GLvoid *userParam);
		typedef void (*GLDEBUGPROCAMD)(GLuint id,GLenum category,GLenum severity,GLsizei length,const GLchar *message,GLvoid *userParam);
		typedef void (*GLDEBUGPROC)(GLenum source,GLenum type,GLuint id,GLenum severity,GLsizei length,const GLchar *message,GLvoid *userParam);
		typedef GLintptr GLvdpauSurfaceNV;
		typedef GLint GLfixed;
		typedef void (* PFNGLBLENDCOLORPROC) (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
		typedef void (* PFNGLBLENDEQUATIONPROC) (GLenum mode);
		typedef void (* PFNGLDRAWRANGEELEMENTSPROC) (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indices);
		typedef void (* PFNGLTEXIMAGE3DPROC) (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLCOPYTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLCOLORTABLEPROC) (GLenum target, GLenum internalformat, GLsizei width, GLenum format, GLenum type, const GLvoid *table);
		typedef void (* PFNGLCOLORTABLEPARAMETERFVPROC) (GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLCOLORTABLEPARAMETERIVPROC) (GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLCOPYCOLORTABLEPROC) (GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width);
		typedef void (* PFNGLGETCOLORTABLEPROC) (GLenum target, GLenum format, GLenum type, GLvoid *table);
		typedef void (* PFNGLGETCOLORTABLEPARAMETERFVPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETCOLORTABLEPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLCOLORSUBTABLEPROC) (GLenum target, GLsizei start, GLsizei count, GLenum format, GLenum type, const GLvoid *data);
		typedef void (* PFNGLCOPYCOLORSUBTABLEPROC) (GLenum target, GLsizei start, GLint x, GLint y, GLsizei width);
		typedef void (* PFNGLCONVOLUTIONFILTER1DPROC) (GLenum target, GLenum internalformat, GLsizei width, GLenum format, GLenum type, const GLvoid *image);
		typedef void (* PFNGLCONVOLUTIONFILTER2DPROC) (GLenum target, GLenum internalformat, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *image);
		typedef void (* PFNGLCONVOLUTIONPARAMETERFPROC) (GLenum target, GLenum pname, GLfloat params);
		typedef void (* PFNGLCONVOLUTIONPARAMETERFVPROC) (GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLCONVOLUTIONPARAMETERIPROC) (GLenum target, GLenum pname, GLint params);
		typedef void (* PFNGLCONVOLUTIONPARAMETERIVPROC) (GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLCOPYCONVOLUTIONFILTER1DPROC) (GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width);
		typedef void (* PFNGLCOPYCONVOLUTIONFILTER2DPROC) (GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLGETCONVOLUTIONFILTERPROC) (GLenum target, GLenum format, GLenum type, GLvoid *image);
		typedef void (* PFNGLGETCONVOLUTIONPARAMETERFVPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETCONVOLUTIONPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETSEPARABLEFILTERPROC) (GLenum target, GLenum format, GLenum type, GLvoid *row, GLvoid *column, GLvoid *span);
		typedef void (* PFNGLSEPARABLEFILTER2DPROC) (GLenum target, GLenum internalformat, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *row, const GLvoid *column);
		typedef void (* PFNGLGETHISTOGRAMPROC) (GLenum target, GLboolean reset, GLenum format, GLenum type, GLvoid *values);
		typedef void (* PFNGLGETHISTOGRAMPARAMETERFVPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETHISTOGRAMPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETMINMAXPROC) (GLenum target, GLboolean reset, GLenum format, GLenum type, GLvoid *values);
		typedef void (* PFNGLGETMINMAXPARAMETERFVPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETMINMAXPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLHISTOGRAMPROC) (GLenum target, GLsizei width, GLenum internalformat, GLboolean sink);
		typedef void (* PFNGLMINMAXPROC) (GLenum target, GLenum internalformat, GLboolean sink);
		typedef void (* PFNGLRESETHISTOGRAMPROC) (GLenum target);
		typedef void (* PFNGLRESETMINMAXPROC) (GLenum target);
		typedef void (* PFNGLACTIVETEXTUREPROC) (GLenum texture);
		typedef void (* PFNGLSAMPLECOVERAGEPROC) (GLfloat value, GLboolean invert);
		typedef void (* PFNGLCOMPRESSEDTEXIMAGE3DPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXIMAGE2DPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXIMAGE1DPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXSUBIMAGE2DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXSUBIMAGE1DPROC) (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLGETCOMPRESSEDTEXIMAGEPROC) (GLenum target, GLint level, GLvoid *img);
		typedef void (* PFNGLCLIENTACTIVETEXTUREPROC) (GLenum texture);
		typedef void (* PFNGLMULTITEXCOORD1DPROC) (GLenum target, GLdouble s);
		typedef void (* PFNGLMULTITEXCOORD1DVPROC) (GLenum target, const GLdouble *v);
		typedef void (* PFNGLMULTITEXCOORD1FPROC) (GLenum target, GLfloat s);
		typedef void (* PFNGLMULTITEXCOORD1FVPROC) (GLenum target, const GLfloat *v);
		typedef void (* PFNGLMULTITEXCOORD1IPROC) (GLenum target, GLint s);
		typedef void (* PFNGLMULTITEXCOORD1IVPROC) (GLenum target, const GLint *v);
		typedef void (* PFNGLMULTITEXCOORD1SPROC) (GLenum target, GLshort s);
		typedef void (* PFNGLMULTITEXCOORD1SVPROC) (GLenum target, const GLshort *v);
		typedef void (* PFNGLMULTITEXCOORD2DPROC) (GLenum target, GLdouble s, GLdouble t);
		typedef void (* PFNGLMULTITEXCOORD2DVPROC) (GLenum target, const GLdouble *v);
		typedef void (* PFNGLMULTITEXCOORD2FPROC) (GLenum target, GLfloat s, GLfloat t);
		typedef void (* PFNGLMULTITEXCOORD2FVPROC) (GLenum target, const GLfloat *v);
		typedef void (* PFNGLMULTITEXCOORD2IPROC) (GLenum target, GLint s, GLint t);
		typedef void (* PFNGLMULTITEXCOORD2IVPROC) (GLenum target, const GLint *v);
		typedef void (* PFNGLMULTITEXCOORD2SPROC) (GLenum target, GLshort s, GLshort t);
		typedef void (* PFNGLMULTITEXCOORD2SVPROC) (GLenum target, const GLshort *v);
		typedef void (* PFNGLMULTITEXCOORD3DPROC) (GLenum target, GLdouble s, GLdouble t, GLdouble r);
		typedef void (* PFNGLMULTITEXCOORD3DVPROC) (GLenum target, const GLdouble *v);
		typedef void (* PFNGLMULTITEXCOORD3FPROC) (GLenum target, GLfloat s, GLfloat t, GLfloat r);
		typedef void (* PFNGLMULTITEXCOORD3FVPROC) (GLenum target, const GLfloat *v);
		typedef void (* PFNGLMULTITEXCOORD3IPROC) (GLenum target, GLint s, GLint t, GLint r);
		typedef void (* PFNGLMULTITEXCOORD3IVPROC) (GLenum target, const GLint *v);
		typedef void (* PFNGLMULTITEXCOORD3SPROC) (GLenum target, GLshort s, GLshort t, GLshort r);
		typedef void (* PFNGLMULTITEXCOORD3SVPROC) (GLenum target, const GLshort *v);
		typedef void (* PFNGLMULTITEXCOORD4DPROC) (GLenum target, GLdouble s, GLdouble t, GLdouble r, GLdouble q);
		typedef void (* PFNGLMULTITEXCOORD4DVPROC) (GLenum target, const GLdouble *v);
		typedef void (* PFNGLMULTITEXCOORD4FPROC) (GLenum target, GLfloat s, GLfloat t, GLfloat r, GLfloat q);
		typedef void (* PFNGLMULTITEXCOORD4FVPROC) (GLenum target, const GLfloat *v);
		typedef void (* PFNGLMULTITEXCOORD4IPROC) (GLenum target, GLint s, GLint t, GLint r, GLint q);
		typedef void (* PFNGLMULTITEXCOORD4IVPROC) (GLenum target, const GLint *v);
		typedef void (* PFNGLMULTITEXCOORD4SPROC) (GLenum target, GLshort s, GLshort t, GLshort r, GLshort q);
		typedef void (* PFNGLMULTITEXCOORD4SVPROC) (GLenum target, const GLshort *v);
		typedef void (* PFNGLLOADTRANSPOSEMATRIXFPROC) (const GLfloat *m);
		typedef void (* PFNGLLOADTRANSPOSEMATRIXDPROC) (const GLdouble *m);
		typedef void (* PFNGLMULTTRANSPOSEMATRIXFPROC) (const GLfloat *m);
		typedef void (* PFNGLMULTTRANSPOSEMATRIXDPROC) (const GLdouble *m);
		typedef void (* PFNGLBLENDFUNCSEPARATEPROC) (GLenum sfactorRGB, GLenum dfactorRGB, GLenum sfactorAlpha, GLenum dfactorAlpha);
		typedef void (* PFNGLMULTIDRAWARRAYSPROC) (GLenum mode, const GLint *first, const GLsizei *count, GLsizei drawcount);
		typedef void (* PFNGLMULTIDRAWELEMENTSPROC) (GLenum mode, const GLsizei *count, GLenum type, const GLvoid* const *indices, GLsizei drawcount);
		typedef void (* PFNGLPOINTPARAMETERFPROC) (GLenum pname, GLfloat param);
		typedef void (* PFNGLPOINTPARAMETERFVPROC) (GLenum pname, const GLfloat *params);
		typedef void (* PFNGLPOINTPARAMETERIPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLPOINTPARAMETERIVPROC) (GLenum pname, const GLint *params);
		typedef void (* PFNGLFOGCOORDFPROC) (GLfloat coord);
		typedef void (* PFNGLFOGCOORDFVPROC) (const GLfloat *coord);
		typedef void (* PFNGLFOGCOORDDPROC) (GLdouble coord);
		typedef void (* PFNGLFOGCOORDDVPROC) (const GLdouble *coord);
		typedef void (* PFNGLFOGCOORDPOINTERPROC) (GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLSECONDARYCOLOR3BPROC) (GLbyte red, GLbyte green, GLbyte blue);
		typedef void (* PFNGLSECONDARYCOLOR3BVPROC) (const GLbyte *v);
		typedef void (* PFNGLSECONDARYCOLOR3DPROC) (GLdouble red, GLdouble green, GLdouble blue);
		typedef void (* PFNGLSECONDARYCOLOR3DVPROC) (const GLdouble *v);
		typedef void (* PFNGLSECONDARYCOLOR3FPROC) (GLfloat red, GLfloat green, GLfloat blue);
		typedef void (* PFNGLSECONDARYCOLOR3FVPROC) (const GLfloat *v);
		typedef void (* PFNGLSECONDARYCOLOR3IPROC) (GLint red, GLint green, GLint blue);
		typedef void (* PFNGLSECONDARYCOLOR3IVPROC) (const GLint *v);
		typedef void (* PFNGLSECONDARYCOLOR3SPROC) (GLshort red, GLshort green, GLshort blue);
		typedef void (* PFNGLSECONDARYCOLOR3SVPROC) (const GLshort *v);
		typedef void (* PFNGLSECONDARYCOLOR3UBPROC) (GLubyte red, GLubyte green, GLubyte blue);
		typedef void (* PFNGLSECONDARYCOLOR3UBVPROC) (const GLubyte *v);
		typedef void (* PFNGLSECONDARYCOLOR3UIPROC) (GLuint red, GLuint green, GLuint blue);
		typedef void (* PFNGLSECONDARYCOLOR3UIVPROC) (const GLuint *v);
		typedef void (* PFNGLSECONDARYCOLOR3USPROC) (GLushort red, GLushort green, GLushort blue);
		typedef void (* PFNGLSECONDARYCOLOR3USVPROC) (const GLushort *v);
		typedef void (* PFNGLSECONDARYCOLORPOINTERPROC) (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLWINDOWPOS2DPROC) (GLdouble x, GLdouble y);
		typedef void (* PFNGLWINDOWPOS2DVPROC) (const GLdouble *v);
		typedef void (* PFNGLWINDOWPOS2FPROC) (GLfloat x, GLfloat y);
		typedef void (* PFNGLWINDOWPOS2FVPROC) (const GLfloat *v);
		typedef void (* PFNGLWINDOWPOS2IPROC) (GLint x, GLint y);
		typedef void (* PFNGLWINDOWPOS2IVPROC) (const GLint *v);
		typedef void (* PFNGLWINDOWPOS2SPROC) (GLshort x, GLshort y);
		typedef void (* PFNGLWINDOWPOS2SVPROC) (const GLshort *v);
		typedef void (* PFNGLWINDOWPOS3DPROC) (GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLWINDOWPOS3DVPROC) (const GLdouble *v);
		typedef void (* PFNGLWINDOWPOS3FPROC) (GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLWINDOWPOS3FVPROC) (const GLfloat *v);
		typedef void (* PFNGLWINDOWPOS3IPROC) (GLint x, GLint y, GLint z);
		typedef void (* PFNGLWINDOWPOS3IVPROC) (const GLint *v);
		typedef void (* PFNGLWINDOWPOS3SPROC) (GLshort x, GLshort y, GLshort z);
		typedef void (* PFNGLWINDOWPOS3SVPROC) (const GLshort *v);
		typedef void (* PFNGLGENQUERIESPROC) (GLsizei n, GLuint *ids);
		typedef void (* PFNGLDELETEQUERIESPROC) (GLsizei n, const GLuint *ids);
		typedef GLboolean (* PFNGLISQUERYPROC) (GLuint id);
		typedef void (* PFNGLBEGINQUERYPROC) (GLenum target, GLuint id);
		typedef void (* PFNGLENDQUERYPROC) (GLenum target);
		typedef void (* PFNGLGETQUERYIVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETQUERYOBJECTIVPROC) (GLuint id, GLenum pname, GLint *params);
		typedef void (* PFNGLGETQUERYOBJECTUIVPROC) (GLuint id, GLenum pname, GLuint *params);
		typedef void (* PFNGLBINDBUFFERPROC) (GLenum target, GLuint buffer);
		typedef void (* PFNGLDELETEBUFFERSPROC) (GLsizei n, const GLuint *buffers);
		typedef void (* PFNGLGENBUFFERSPROC) (GLsizei n, GLuint *buffers);
		typedef GLboolean (* PFNGLISBUFFERPROC) (GLuint buffer);
		typedef void (* PFNGLBUFFERDATAPROC) (GLenum target, GLsizeiptr size, const GLvoid *data, GLenum usage);
		typedef void (* PFNGLBUFFERSUBDATAPROC) (GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid *data);
		typedef void (* PFNGLGETBUFFERSUBDATAPROC) (GLenum target, GLintptr offset, GLsizeiptr size, GLvoid *data);
		typedef GLvoid* (* PFNGLMAPBUFFERPROC) (GLenum target, GLenum access);
		typedef GLboolean (* PFNGLUNMAPBUFFERPROC) (GLenum target);
		typedef void (* PFNGLGETBUFFERPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETBUFFERPOINTERVPROC) (GLenum target, GLenum pname, GLvoid* *params);
		typedef void (* PFNGLBLENDEQUATIONSEPARATEPROC) (GLenum modeRGB, GLenum modeAlpha);
		typedef void (* PFNGLDRAWBUFFERSPROC) (GLsizei n, const GLenum *bufs);
		typedef void (* PFNGLSTENCILOPSEPARATEPROC) (GLenum face, GLenum sfail, GLenum dpfail, GLenum dppass);
		typedef void (* PFNGLSTENCILFUNCSEPARATEPROC) (GLenum face, GLenum func, GLint ref, GLuint mask);
		typedef void (* PFNGLSTENCILMASKSEPARATEPROC) (GLenum face, GLuint mask);
		typedef void (* PFNGLATTACHSHADERPROC) (GLuint program, GLuint shader);
		typedef void (* PFNGLBINDATTRIBLOCATIONPROC) (GLuint program, GLuint index, const GLchar *name);
		typedef void (* PFNGLCOMPILESHADERPROC) (GLuint shader);
		typedef GLuint (* PFNGLCREATEPROGRAMPROC) (void);
		typedef GLuint (* PFNGLCREATESHADERPROC) (GLenum type);
		typedef void (* PFNGLDELETEPROGRAMPROC) (GLuint program);
		typedef void (* PFNGLDELETESHADERPROC) (GLuint shader);
		typedef void (* PFNGLDETACHSHADERPROC) (GLuint program, GLuint shader);
		typedef void (* PFNGLDISABLEVERTEXATTRIBARRAYPROC) (GLuint index);
		typedef void (* PFNGLENABLEVERTEXATTRIBARRAYPROC) (GLuint index);
		typedef void (* PFNGLGETACTIVEATTRIBPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
		typedef void (* PFNGLGETACTIVEUNIFORMPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
		typedef void (* PFNGLGETATTACHEDSHADERSPROC) (GLuint program, GLsizei maxCount, GLsizei *count, GLuint *obj);
		typedef GLint (* PFNGLGETATTRIBLOCATIONPROC) (GLuint program, const GLchar *name);
		typedef void (* PFNGLGETPROGRAMIVPROC) (GLuint program, GLenum pname, GLint *params);
		typedef void (* PFNGLGETPROGRAMINFOLOGPROC) (GLuint program, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
		typedef void (* PFNGLGETSHADERIVPROC) (GLuint shader, GLenum pname, GLint *params);
		typedef void (* PFNGLGETSHADERINFOLOGPROC) (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
		typedef void (* PFNGLGETSHADERSOURCEPROC) (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *source);
		typedef GLint (* PFNGLGETUNIFORMLOCATIONPROC) (GLuint program, const GLchar *name);
		typedef void (* PFNGLGETUNIFORMFVPROC) (GLuint program, GLint location, GLfloat *params);
		typedef void (* PFNGLGETUNIFORMIVPROC) (GLuint program, GLint location, GLint *params);
		typedef void (* PFNGLGETVERTEXATTRIBDVPROC) (GLuint index, GLenum pname, GLdouble *params);
		typedef void (* PFNGLGETVERTEXATTRIBFVPROC) (GLuint index, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETVERTEXATTRIBIVPROC) (GLuint index, GLenum pname, GLint *params);
		typedef void (* PFNGLGETVERTEXATTRIBPOINTERVPROC) (GLuint index, GLenum pname, GLvoid* *pointer);
		typedef GLboolean (* PFNGLISPROGRAMPROC) (GLuint program);
		typedef GLboolean (* PFNGLISSHADERPROC) (GLuint shader);
		typedef void (* PFNGLLINKPROGRAMPROC) (GLuint program);
		typedef void (* PFNGLSHADERSOURCEPROC) (GLuint shader, GLsizei count, const GLchar* const *string, const GLint *length);
		typedef void (* PFNGLUSEPROGRAMPROC) (GLuint program);
		typedef void (* PFNGLUNIFORM1FPROC) (GLint location, GLfloat v0);
		typedef void (* PFNGLUNIFORM2FPROC) (GLint location, GLfloat v0, GLfloat v1);
		typedef void (* PFNGLUNIFORM3FPROC) (GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
		typedef void (* PFNGLUNIFORM4FPROC) (GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
		typedef void (* PFNGLUNIFORM1IPROC) (GLint location, GLint v0);
		typedef void (* PFNGLUNIFORM2IPROC) (GLint location, GLint v0, GLint v1);
		typedef void (* PFNGLUNIFORM3IPROC) (GLint location, GLint v0, GLint v1, GLint v2);
		typedef void (* PFNGLUNIFORM4IPROC) (GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
		typedef void (* PFNGLUNIFORM1FVPROC) (GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLUNIFORM2FVPROC) (GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLUNIFORM3FVPROC) (GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLUNIFORM4FVPROC) (GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLUNIFORM1IVPROC) (GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLUNIFORM2IVPROC) (GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLUNIFORM3IVPROC) (GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLUNIFORM4IVPROC) (GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLUNIFORMMATRIX2FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLUNIFORMMATRIX3FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLUNIFORMMATRIX4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLVALIDATEPROGRAMPROC) (GLuint program);
		typedef void (* PFNGLVERTEXATTRIB1DPROC) (GLuint index, GLdouble x);
		typedef void (* PFNGLVERTEXATTRIB1DVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB1FPROC) (GLuint index, GLfloat x);
		typedef void (* PFNGLVERTEXATTRIB1FVPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB1SPROC) (GLuint index, GLshort x);
		typedef void (* PFNGLVERTEXATTRIB1SVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB2DPROC) (GLuint index, GLdouble x, GLdouble y);
		typedef void (* PFNGLVERTEXATTRIB2DVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB2FPROC) (GLuint index, GLfloat x, GLfloat y);
		typedef void (* PFNGLVERTEXATTRIB2FVPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB2SPROC) (GLuint index, GLshort x, GLshort y);
		typedef void (* PFNGLVERTEXATTRIB2SVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB3DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLVERTEXATTRIB3DVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB3FPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLVERTEXATTRIB3FVPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB3SPROC) (GLuint index, GLshort x, GLshort y, GLshort z);
		typedef void (* PFNGLVERTEXATTRIB3SVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB4NBVPROC) (GLuint index, const GLbyte *v);
		typedef void (* PFNGLVERTEXATTRIB4NIVPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIB4NSVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB4NUBPROC) (GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
		typedef void (* PFNGLVERTEXATTRIB4NUBVPROC) (GLuint index, const GLubyte *v);
		typedef void (* PFNGLVERTEXATTRIB4NUIVPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIB4NUSVPROC) (GLuint index, const GLushort *v);
		typedef void (* PFNGLVERTEXATTRIB4BVPROC) (GLuint index, const GLbyte *v);
		typedef void (* PFNGLVERTEXATTRIB4DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLVERTEXATTRIB4DVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB4FPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLVERTEXATTRIB4FVPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB4IVPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIB4SPROC) (GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
		typedef void (* PFNGLVERTEXATTRIB4SVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB4UBVPROC) (GLuint index, const GLubyte *v);
		typedef void (* PFNGLVERTEXATTRIB4UIVPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIB4USVPROC) (GLuint index, const GLushort *v);
		typedef void (* PFNGLVERTEXATTRIBPOINTERPROC) (GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLUNIFORMMATRIX2X3FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLUNIFORMMATRIX3X2FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLUNIFORMMATRIX2X4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLUNIFORMMATRIX4X2FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLUNIFORMMATRIX3X4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLUNIFORMMATRIX4X3FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLCOLORMASKIPROC) (GLuint index, GLboolean r, GLboolean g, GLboolean b, GLboolean a);
		typedef void (* PFNGLGETBOOLEANI_VPROC) (GLenum target, GLuint index, GLboolean *data);
		typedef void (* PFNGLGETINTEGERI_VPROC) (GLenum target, GLuint index, GLint *data);
		typedef void (* PFNGLENABLEIPROC) (GLenum target, GLuint index);
		typedef void (* PFNGLDISABLEIPROC) (GLenum target, GLuint index);
		typedef GLboolean (* PFNGLISENABLEDIPROC) (GLenum target, GLuint index);
		typedef void (* PFNGLBEGINTRANSFORMFEEDBACKPROC) (GLenum primitiveMode);
		typedef void (* PFNGLENDTRANSFORMFEEDBACKPROC) (void);
		typedef void (* PFNGLBINDBUFFERRANGEPROC) (GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
		typedef void (* PFNGLBINDBUFFERBASEPROC) (GLenum target, GLuint index, GLuint buffer);
		typedef void (* PFNGLTRANSFORMFEEDBACKVARYINGSPROC) (GLuint program, GLsizei count, const GLchar* const *varyings, GLenum bufferMode);
		typedef void (* PFNGLGETTRANSFORMFEEDBACKVARYINGPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLsizei *size, GLenum *type, GLchar *name);
		typedef void (* PFNGLCLAMPCOLORPROC) (GLenum target, GLenum clamp);
		typedef void (* PFNGLBEGINCONDITIONALRENDERPROC) (GLuint id, GLenum mode);
		typedef void (* PFNGLENDCONDITIONALRENDERPROC) (void);
		typedef void (* PFNGLVERTEXATTRIBIPOINTERPROC) (GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLGETVERTEXATTRIBIIVPROC) (GLuint index, GLenum pname, GLint *params);
		typedef void (* PFNGLGETVERTEXATTRIBIUIVPROC) (GLuint index, GLenum pname, GLuint *params);
		typedef void (* PFNGLVERTEXATTRIBI1IPROC) (GLuint index, GLint x);
		typedef void (* PFNGLVERTEXATTRIBI2IPROC) (GLuint index, GLint x, GLint y);
		typedef void (* PFNGLVERTEXATTRIBI3IPROC) (GLuint index, GLint x, GLint y, GLint z);
		typedef void (* PFNGLVERTEXATTRIBI4IPROC) (GLuint index, GLint x, GLint y, GLint z, GLint w);
		typedef void (* PFNGLVERTEXATTRIBI1UIPROC) (GLuint index, GLuint x);
		typedef void (* PFNGLVERTEXATTRIBI2UIPROC) (GLuint index, GLuint x, GLuint y);
		typedef void (* PFNGLVERTEXATTRIBI3UIPROC) (GLuint index, GLuint x, GLuint y, GLuint z);
		typedef void (* PFNGLVERTEXATTRIBI4UIPROC) (GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
		typedef void (* PFNGLVERTEXATTRIBI1IVPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIBI2IVPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIBI3IVPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIBI4IVPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIBI1UIVPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIBI2UIVPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIBI3UIVPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIBI4UIVPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIBI4BVPROC) (GLuint index, const GLbyte *v);
		typedef void (* PFNGLVERTEXATTRIBI4SVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIBI4UBVPROC) (GLuint index, const GLubyte *v);
		typedef void (* PFNGLVERTEXATTRIBI4USVPROC) (GLuint index, const GLushort *v);
		typedef void (* PFNGLGETUNIFORMUIVPROC) (GLuint program, GLint location, GLuint *params);
		typedef void (* PFNGLBINDFRAGDATALOCATIONPROC) (GLuint program, GLuint color, const GLchar *name);
		typedef GLint (* PFNGLGETFRAGDATALOCATIONPROC) (GLuint program, const GLchar *name);
		typedef void (* PFNGLUNIFORM1UIPROC) (GLint location, GLuint v0);
		typedef void (* PFNGLUNIFORM2UIPROC) (GLint location, GLuint v0, GLuint v1);
		typedef void (* PFNGLUNIFORM3UIPROC) (GLint location, GLuint v0, GLuint v1, GLuint v2);
		typedef void (* PFNGLUNIFORM4UIPROC) (GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
		typedef void (* PFNGLUNIFORM1UIVPROC) (GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLUNIFORM2UIVPROC) (GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLUNIFORM3UIVPROC) (GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLUNIFORM4UIVPROC) (GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLTEXPARAMETERIIVPROC) (GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLTEXPARAMETERIUIVPROC) (GLenum target, GLenum pname, const GLuint *params);
		typedef void (* PFNGLGETTEXPARAMETERIIVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETTEXPARAMETERIUIVPROC) (GLenum target, GLenum pname, GLuint *params);
		typedef void (* PFNGLCLEARBUFFERIVPROC) (GLenum buffer, GLint drawbuffer, const GLint *value);
		typedef void (* PFNGLCLEARBUFFERUIVPROC) (GLenum buffer, GLint drawbuffer, const GLuint *value);
		typedef void (* PFNGLCLEARBUFFERFVPROC) (GLenum buffer, GLint drawbuffer, const GLfloat *value);
		typedef void (* PFNGLCLEARBUFFERFIPROC) (GLenum buffer, GLint drawbuffer, GLfloat depth, GLint stencil);
		typedef const GLubyte * (* PFNGLGETSTRINGIPROC) (GLenum name, GLuint index);
		typedef void (* PFNGLDRAWARRAYSINSTANCEDPROC) (GLenum mode, GLint first, GLsizei count, GLsizei instancecount);
		typedef void (* PFNGLDRAWELEMENTSINSTANCEDPROC) (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLsizei instancecount);
		typedef void (* PFNGLTEXBUFFERPROC) (GLenum target, GLenum internalformat, GLuint buffer);
		typedef void (* PFNGLPRIMITIVERESTARTINDEXPROC) (GLuint index);
		typedef void (* PFNGLGETINTEGER64I_VPROC) (GLenum target, GLuint index, GLint64 *data);
		typedef void (* PFNGLGETBUFFERPARAMETERI64VPROC) (GLenum target, GLenum pname, GLint64 *params);
		typedef void (* PFNGLFRAMEBUFFERTEXTUREPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level);
		typedef void (* PFNGLVERTEXATTRIBDIVISORPROC) (GLuint index, GLuint divisor);
		typedef void (* PFNGLMINSAMPLESHADINGPROC) (GLfloat value);
		typedef void (* PFNGLBLENDEQUATIONIPROC) (GLuint buf, GLenum mode);
		typedef void (* PFNGLBLENDEQUATIONSEPARATEIPROC) (GLuint buf, GLenum modeRGB, GLenum modeAlpha);
		typedef void (* PFNGLBLENDFUNCIPROC) (GLuint buf, GLenum src, GLenum dst);
		typedef void (* PFNGLBLENDFUNCSEPARATEIPROC) (GLuint buf, GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);
		typedef void (* PFNGLACTIVETEXTUREARBPROC) (GLenum texture);
		typedef void (* PFNGLCLIENTACTIVETEXTUREARBPROC) (GLenum texture);
		typedef void (* PFNGLMULTITEXCOORD1DARBPROC) (GLenum target, GLdouble s);
		typedef void (* PFNGLMULTITEXCOORD1DVARBPROC) (GLenum target, const GLdouble *v);
		typedef void (* PFNGLMULTITEXCOORD1FARBPROC) (GLenum target, GLfloat s);
		typedef void (* PFNGLMULTITEXCOORD1FVARBPROC) (GLenum target, const GLfloat *v);
		typedef void (* PFNGLMULTITEXCOORD1IARBPROC) (GLenum target, GLint s);
		typedef void (* PFNGLMULTITEXCOORD1IVARBPROC) (GLenum target, const GLint *v);
		typedef void (* PFNGLMULTITEXCOORD1SARBPROC) (GLenum target, GLshort s);
		typedef void (* PFNGLMULTITEXCOORD1SVARBPROC) (GLenum target, const GLshort *v);
		typedef void (* PFNGLMULTITEXCOORD2DARBPROC) (GLenum target, GLdouble s, GLdouble t);
		typedef void (* PFNGLMULTITEXCOORD2DVARBPROC) (GLenum target, const GLdouble *v);
		typedef void (* PFNGLMULTITEXCOORD2FARBPROC) (GLenum target, GLfloat s, GLfloat t);
		typedef void (* PFNGLMULTITEXCOORD2FVARBPROC) (GLenum target, const GLfloat *v);
		typedef void (* PFNGLMULTITEXCOORD2IARBPROC) (GLenum target, GLint s, GLint t);
		typedef void (* PFNGLMULTITEXCOORD2IVARBPROC) (GLenum target, const GLint *v);
		typedef void (* PFNGLMULTITEXCOORD2SARBPROC) (GLenum target, GLshort s, GLshort t);
		typedef void (* PFNGLMULTITEXCOORD2SVARBPROC) (GLenum target, const GLshort *v);
		typedef void (* PFNGLMULTITEXCOORD3DARBPROC) (GLenum target, GLdouble s, GLdouble t, GLdouble r);
		typedef void (* PFNGLMULTITEXCOORD3DVARBPROC) (GLenum target, const GLdouble *v);
		typedef void (* PFNGLMULTITEXCOORD3FARBPROC) (GLenum target, GLfloat s, GLfloat t, GLfloat r);
		typedef void (* PFNGLMULTITEXCOORD3FVARBPROC) (GLenum target, const GLfloat *v);
		typedef void (* PFNGLMULTITEXCOORD3IARBPROC) (GLenum target, GLint s, GLint t, GLint r);
		typedef void (* PFNGLMULTITEXCOORD3IVARBPROC) (GLenum target, const GLint *v);
		typedef void (* PFNGLMULTITEXCOORD3SARBPROC) (GLenum target, GLshort s, GLshort t, GLshort r);
		typedef void (* PFNGLMULTITEXCOORD3SVARBPROC) (GLenum target, const GLshort *v);
		typedef void (* PFNGLMULTITEXCOORD4DARBPROC) (GLenum target, GLdouble s, GLdouble t, GLdouble r, GLdouble q);
		typedef void (* PFNGLMULTITEXCOORD4DVARBPROC) (GLenum target, const GLdouble *v);
		typedef void (* PFNGLMULTITEXCOORD4FARBPROC) (GLenum target, GLfloat s, GLfloat t, GLfloat r, GLfloat q);
		typedef void (* PFNGLMULTITEXCOORD4FVARBPROC) (GLenum target, const GLfloat *v);
		typedef void (* PFNGLMULTITEXCOORD4IARBPROC) (GLenum target, GLint s, GLint t, GLint r, GLint q);
		typedef void (* PFNGLMULTITEXCOORD4IVARBPROC) (GLenum target, const GLint *v);
		typedef void (* PFNGLMULTITEXCOORD4SARBPROC) (GLenum target, GLshort s, GLshort t, GLshort r, GLshort q);
		typedef void (* PFNGLMULTITEXCOORD4SVARBPROC) (GLenum target, const GLshort *v);
		typedef void (* PFNGLLOADTRANSPOSEMATRIXFARBPROC) (const GLfloat *m);
		typedef void (* PFNGLLOADTRANSPOSEMATRIXDARBPROC) (const GLdouble *m);
		typedef void (* PFNGLMULTTRANSPOSEMATRIXFARBPROC) (const GLfloat *m);
		typedef void (* PFNGLMULTTRANSPOSEMATRIXDARBPROC) (const GLdouble *m);
		typedef void (* PFNGLSAMPLECOVERAGEARBPROC) (GLfloat value, GLboolean invert);
		typedef void (* PFNGLCOMPRESSEDTEXIMAGE3DARBPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXIMAGE2DARBPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXIMAGE1DARBPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXSUBIMAGE3DARBPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXSUBIMAGE2DARBPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLCOMPRESSEDTEXSUBIMAGE1DARBPROC) (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, const GLvoid *data);
		typedef void (* PFNGLGETCOMPRESSEDTEXIMAGEARBPROC) (GLenum target, GLint level, GLvoid *img);
		typedef void (* PFNGLPOINTPARAMETERFARBPROC) (GLenum pname, GLfloat param);
		typedef void (* PFNGLPOINTPARAMETERFVARBPROC) (GLenum pname, const GLfloat *params);
		typedef void (* PFNGLWEIGHTBVARBPROC) (GLint size, const GLbyte *weights);
		typedef void (* PFNGLWEIGHTSVARBPROC) (GLint size, const GLshort *weights);
		typedef void (* PFNGLWEIGHTIVARBPROC) (GLint size, const GLint *weights);
		typedef void (* PFNGLWEIGHTFVARBPROC) (GLint size, const GLfloat *weights);
		typedef void (* PFNGLWEIGHTDVARBPROC) (GLint size, const GLdouble *weights);
		typedef void (* PFNGLWEIGHTUBVARBPROC) (GLint size, const GLubyte *weights);
		typedef void (* PFNGLWEIGHTUSVARBPROC) (GLint size, const GLushort *weights);
		typedef void (* PFNGLWEIGHTUIVARBPROC) (GLint size, const GLuint *weights);
		typedef void (* PFNGLWEIGHTPOINTERARBPROC) (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLVERTEXBLENDARBPROC) (GLint count);
		typedef void (* PFNGLCURRENTPALETTEMATRIXARBPROC) (GLint index);
		typedef void (* PFNGLMATRIXINDEXUBVARBPROC) (GLint size, const GLubyte *indices);
		typedef void (* PFNGLMATRIXINDEXUSVARBPROC) (GLint size, const GLushort *indices);
		typedef void (* PFNGLMATRIXINDEXUIVARBPROC) (GLint size, const GLuint *indices);
		typedef void (* PFNGLMATRIXINDEXPOINTERARBPROC) (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLWINDOWPOS2DARBPROC) (GLdouble x, GLdouble y);
		typedef void (* PFNGLWINDOWPOS2DVARBPROC) (const GLdouble *v);
		typedef void (* PFNGLWINDOWPOS2FARBPROC) (GLfloat x, GLfloat y);
		typedef void (* PFNGLWINDOWPOS2FVARBPROC) (const GLfloat *v);
		typedef void (* PFNGLWINDOWPOS2IARBPROC) (GLint x, GLint y);
		typedef void (* PFNGLWINDOWPOS2IVARBPROC) (const GLint *v);
		typedef void (* PFNGLWINDOWPOS2SARBPROC) (GLshort x, GLshort y);
		typedef void (* PFNGLWINDOWPOS2SVARBPROC) (const GLshort *v);
		typedef void (* PFNGLWINDOWPOS3DARBPROC) (GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLWINDOWPOS3DVARBPROC) (const GLdouble *v);
		typedef void (* PFNGLWINDOWPOS3FARBPROC) (GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLWINDOWPOS3FVARBPROC) (const GLfloat *v);
		typedef void (* PFNGLWINDOWPOS3IARBPROC) (GLint x, GLint y, GLint z);
		typedef void (* PFNGLWINDOWPOS3IVARBPROC) (const GLint *v);
		typedef void (* PFNGLWINDOWPOS3SARBPROC) (GLshort x, GLshort y, GLshort z);
		typedef void (* PFNGLWINDOWPOS3SVARBPROC) (const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB1DARBPROC) (GLuint index, GLdouble x);
		typedef void (* PFNGLVERTEXATTRIB1DVARBPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB1FARBPROC) (GLuint index, GLfloat x);
		typedef void (* PFNGLVERTEXATTRIB1FVARBPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB1SARBPROC) (GLuint index, GLshort x);
		typedef void (* PFNGLVERTEXATTRIB1SVARBPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB2DARBPROC) (GLuint index, GLdouble x, GLdouble y);
		typedef void (* PFNGLVERTEXATTRIB2DVARBPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB2FARBPROC) (GLuint index, GLfloat x, GLfloat y);
		typedef void (* PFNGLVERTEXATTRIB2FVARBPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB2SARBPROC) (GLuint index, GLshort x, GLshort y);
		typedef void (* PFNGLVERTEXATTRIB2SVARBPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB3DARBPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLVERTEXATTRIB3DVARBPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB3FARBPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLVERTEXATTRIB3FVARBPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB3SARBPROC) (GLuint index, GLshort x, GLshort y, GLshort z);
		typedef void (* PFNGLVERTEXATTRIB3SVARBPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB4NBVARBPROC) (GLuint index, const GLbyte *v);
		typedef void (* PFNGLVERTEXATTRIB4NIVARBPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIB4NSVARBPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB4NUBARBPROC) (GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
		typedef void (* PFNGLVERTEXATTRIB4NUBVARBPROC) (GLuint index, const GLubyte *v);
		typedef void (* PFNGLVERTEXATTRIB4NUIVARBPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIB4NUSVARBPROC) (GLuint index, const GLushort *v);
		typedef void (* PFNGLVERTEXATTRIB4BVARBPROC) (GLuint index, const GLbyte *v);
		typedef void (* PFNGLVERTEXATTRIB4DARBPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLVERTEXATTRIB4DVARBPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB4FARBPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLVERTEXATTRIB4FVARBPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB4IVARBPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIB4SARBPROC) (GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
		typedef void (* PFNGLVERTEXATTRIB4SVARBPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB4UBVARBPROC) (GLuint index, const GLubyte *v);
		typedef void (* PFNGLVERTEXATTRIB4UIVARBPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIB4USVARBPROC) (GLuint index, const GLushort *v);
		typedef void (* PFNGLVERTEXATTRIBPOINTERARBPROC) (GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLENABLEVERTEXATTRIBARRAYARBPROC) (GLuint index);
		typedef void (* PFNGLDISABLEVERTEXATTRIBARRAYARBPROC) (GLuint index);
		typedef void (* PFNGLPROGRAMSTRINGARBPROC) (GLenum target, GLenum format, GLsizei len, const GLvoid *string);
		typedef void (* PFNGLBINDPROGRAMARBPROC) (GLenum target, GLuint program);
		typedef void (* PFNGLDELETEPROGRAMSARBPROC) (GLsizei n, const GLuint *programs);
		typedef void (* PFNGLGENPROGRAMSARBPROC) (GLsizei n, GLuint *programs);
		typedef void (* PFNGLPROGRAMENVPARAMETER4DARBPROC) (GLenum target, GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLPROGRAMENVPARAMETER4DVARBPROC) (GLenum target, GLuint index, const GLdouble *params);
		typedef void (* PFNGLPROGRAMENVPARAMETER4FARBPROC) (GLenum target, GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLPROGRAMENVPARAMETER4FVARBPROC) (GLenum target, GLuint index, const GLfloat *params);
		typedef void (* PFNGLPROGRAMLOCALPARAMETER4DARBPROC) (GLenum target, GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLPROGRAMLOCALPARAMETER4DVARBPROC) (GLenum target, GLuint index, const GLdouble *params);
		typedef void (* PFNGLPROGRAMLOCALPARAMETER4FARBPROC) (GLenum target, GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLPROGRAMLOCALPARAMETER4FVARBPROC) (GLenum target, GLuint index, const GLfloat *params);
		typedef void (* PFNGLGETPROGRAMENVPARAMETERDVARBPROC) (GLenum target, GLuint index, GLdouble *params);
		typedef void (* PFNGLGETPROGRAMENVPARAMETERFVARBPROC) (GLenum target, GLuint index, GLfloat *params);
		typedef void (* PFNGLGETPROGRAMLOCALPARAMETERDVARBPROC) (GLenum target, GLuint index, GLdouble *params);
		typedef void (* PFNGLGETPROGRAMLOCALPARAMETERFVARBPROC) (GLenum target, GLuint index, GLfloat *params);
		typedef void (* PFNGLGETPROGRAMIVARBPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETPROGRAMSTRINGARBPROC) (GLenum target, GLenum pname, GLvoid *string);
		typedef void (* PFNGLGETVERTEXATTRIBDVARBPROC) (GLuint index, GLenum pname, GLdouble *params);
		typedef void (* PFNGLGETVERTEXATTRIBFVARBPROC) (GLuint index, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETVERTEXATTRIBIVARBPROC) (GLuint index, GLenum pname, GLint *params);
		typedef void (* PFNGLGETVERTEXATTRIBPOINTERVARBPROC) (GLuint index, GLenum pname, GLvoid* *pointer);
		typedef GLboolean (* PFNGLISPROGRAMARBPROC) (GLuint program);
		typedef void (* PFNGLBINDBUFFERARBPROC) (GLenum target, GLuint buffer);
		typedef void (* PFNGLDELETEBUFFERSARBPROC) (GLsizei n, const GLuint *buffers);
		typedef void (* PFNGLGENBUFFERSARBPROC) (GLsizei n, GLuint *buffers);
		typedef GLboolean (* PFNGLISBUFFERARBPROC) (GLuint buffer);
		typedef void (* PFNGLBUFFERDATAARBPROC) (GLenum target, GLsizeiptrARB size, const GLvoid *data, GLenum usage);
		typedef void (* PFNGLBUFFERSUBDATAARBPROC) (GLenum target, GLintptrARB offset, GLsizeiptrARB size, const GLvoid *data);
		typedef void (* PFNGLGETBUFFERSUBDATAARBPROC) (GLenum target, GLintptrARB offset, GLsizeiptrARB size, GLvoid *data);
		typedef GLvoid* (* PFNGLMAPBUFFERARBPROC) (GLenum target, GLenum access);
		typedef GLboolean (* PFNGLUNMAPBUFFERARBPROC) (GLenum target);
		typedef void (* PFNGLGETBUFFERPARAMETERIVARBPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETBUFFERPOINTERVARBPROC) (GLenum target, GLenum pname, GLvoid* *params);
		typedef void (* PFNGLGENQUERIESARBPROC) (GLsizei n, GLuint *ids);
		typedef void (* PFNGLDELETEQUERIESARBPROC) (GLsizei n, const GLuint *ids);
		typedef GLboolean (* PFNGLISQUERYARBPROC) (GLuint id);
		typedef void (* PFNGLBEGINQUERYARBPROC) (GLenum target, GLuint id);
		typedef void (* PFNGLENDQUERYARBPROC) (GLenum target);
		typedef void (* PFNGLGETQUERYIVARBPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETQUERYOBJECTIVARBPROC) (GLuint id, GLenum pname, GLint *params);
		typedef void (* PFNGLGETQUERYOBJECTUIVARBPROC) (GLuint id, GLenum pname, GLuint *params);
		typedef void (* PFNGLDELETEOBJECTARBPROC) (GLhandleARB obj);
		typedef GLhandleARB (* PFNGLGETHANDLEARBPROC) (GLenum pname);
		typedef void (* PFNGLDETACHOBJECTARBPROC) (GLhandleARB containerObj, GLhandleARB attachedObj);
		typedef GLhandleARB (* PFNGLCREATESHADEROBJECTARBPROC) (GLenum shaderType);
		typedef void (* PFNGLSHADERSOURCEARBPROC) (GLhandleARB shaderObj, GLsizei count, const GLcharARB* *string, const GLint *length);
		typedef void (* PFNGLCOMPILESHADERARBPROC) (GLhandleARB shaderObj);
		typedef GLhandleARB (* PFNGLCREATEPROGRAMOBJECTARBPROC) (void);
		typedef void (* PFNGLATTACHOBJECTARBPROC) (GLhandleARB containerObj, GLhandleARB obj);
		typedef void (* PFNGLLINKPROGRAMARBPROC) (GLhandleARB programObj);
		typedef void (* PFNGLUSEPROGRAMOBJECTARBPROC) (GLhandleARB programObj);
		typedef void (* PFNGLVALIDATEPROGRAMARBPROC) (GLhandleARB programObj);
		typedef void (* PFNGLUNIFORM1FARBPROC) (GLint location, GLfloat v0);
		typedef void (* PFNGLUNIFORM2FARBPROC) (GLint location, GLfloat v0, GLfloat v1);
		typedef void (* PFNGLUNIFORM3FARBPROC) (GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
		typedef void (* PFNGLUNIFORM4FARBPROC) (GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
		typedef void (* PFNGLUNIFORM1IARBPROC) (GLint location, GLint v0);
		typedef void (* PFNGLUNIFORM2IARBPROC) (GLint location, GLint v0, GLint v1);
		typedef void (* PFNGLUNIFORM3IARBPROC) (GLint location, GLint v0, GLint v1, GLint v2);
		typedef void (* PFNGLUNIFORM4IARBPROC) (GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
		typedef void (* PFNGLUNIFORM1FVARBPROC) (GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLUNIFORM2FVARBPROC) (GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLUNIFORM3FVARBPROC) (GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLUNIFORM4FVARBPROC) (GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLUNIFORM1IVARBPROC) (GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLUNIFORM2IVARBPROC) (GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLUNIFORM3IVARBPROC) (GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLUNIFORM4IVARBPROC) (GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLUNIFORMMATRIX2FVARBPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLUNIFORMMATRIX3FVARBPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLUNIFORMMATRIX4FVARBPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLGETOBJECTPARAMETERFVARBPROC) (GLhandleARB obj, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETOBJECTPARAMETERIVARBPROC) (GLhandleARB obj, GLenum pname, GLint *params);
		typedef void (* PFNGLGETINFOLOGARBPROC) (GLhandleARB obj, GLsizei maxLength, GLsizei *length, GLcharARB *infoLog);
		typedef void (* PFNGLGETATTACHEDOBJECTSARBPROC) (GLhandleARB containerObj, GLsizei maxCount, GLsizei *count, GLhandleARB *obj);
		typedef GLint (* PFNGLGETUNIFORMLOCATIONARBPROC) (GLhandleARB programObj, const GLcharARB *name);
		typedef void (* PFNGLGETACTIVEUNIFORMARBPROC) (GLhandleARB programObj, GLuint index, GLsizei maxLength, GLsizei *length, GLint *size, GLenum *type, GLcharARB *name);
		typedef void (* PFNGLGETUNIFORMFVARBPROC) (GLhandleARB programObj, GLint location, GLfloat *params);
		typedef void (* PFNGLGETUNIFORMIVARBPROC) (GLhandleARB programObj, GLint location, GLint *params);
		typedef void (* PFNGLGETSHADERSOURCEARBPROC) (GLhandleARB obj, GLsizei maxLength, GLsizei *length, GLcharARB *source);
		typedef void (* PFNGLBINDATTRIBLOCATIONARBPROC) (GLhandleARB programObj, GLuint index, const GLcharARB *name);
		typedef void (* PFNGLGETACTIVEATTRIBARBPROC) (GLhandleARB programObj, GLuint index, GLsizei maxLength, GLsizei *length, GLint *size, GLenum *type, GLcharARB *name);
		typedef GLint (* PFNGLGETATTRIBLOCATIONARBPROC) (GLhandleARB programObj, const GLcharARB *name);
		typedef void (* PFNGLDRAWBUFFERSARBPROC) (GLsizei n, const GLenum *bufs);
		typedef void (* PFNGLCLAMPCOLORARBPROC) (GLenum target, GLenum clamp);
		typedef void (* PFNGLDRAWARRAYSINSTANCEDARBPROC) (GLenum mode, GLint first, GLsizei count, GLsizei primcount);
		typedef void (* PFNGLDRAWELEMENTSINSTANCEDARBPROC) (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLsizei primcount);
		typedef GLboolean (* PFNGLISRENDERBUFFERPROC) (GLuint renderbuffer);
		typedef void (* PFNGLBINDRENDERBUFFERPROC) (GLenum target, GLuint renderbuffer);
		typedef void (* PFNGLDELETERENDERBUFFERSPROC) (GLsizei n, const GLuint *renderbuffers);
		typedef void (* PFNGLGENRENDERBUFFERSPROC) (GLsizei n, GLuint *renderbuffers);
		typedef void (* PFNGLRENDERBUFFERSTORAGEPROC) (GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLGETRENDERBUFFERPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef GLboolean (* PFNGLISFRAMEBUFFERPROC) (GLuint framebuffer);
		typedef void (* PFNGLBINDFRAMEBUFFERPROC) (GLenum target, GLuint framebuffer);
		typedef void (* PFNGLDELETEFRAMEBUFFERSPROC) (GLsizei n, const GLuint *framebuffers);
		typedef void (* PFNGLGENFRAMEBUFFERSPROC) (GLsizei n, GLuint *framebuffers);
		typedef GLenum (* PFNGLCHECKFRAMEBUFFERSTATUSPROC) (GLenum target);
		typedef void (* PFNGLFRAMEBUFFERTEXTURE1DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
		typedef void (* PFNGLFRAMEBUFFERTEXTURE2DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
		typedef void (* PFNGLFRAMEBUFFERTEXTURE3DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset);
		typedef void (* PFNGLFRAMEBUFFERRENDERBUFFERPROC) (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
		typedef void (* PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVPROC) (GLenum target, GLenum attachment, GLenum pname, GLint *params);
		typedef void (* PFNGLGENERATEMIPMAPPROC) (GLenum target);
		typedef void (* PFNGLBLITFRAMEBUFFERPROC) (GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
		typedef void (* PFNGLRENDERBUFFERSTORAGEMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLFRAMEBUFFERTEXTURELAYERPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);
		typedef void (* PFNGLPROGRAMPARAMETERIARBPROC) (GLuint program, GLenum pname, GLint value);
		typedef void (* PFNGLFRAMEBUFFERTEXTUREARBPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level);
		typedef void (* PFNGLFRAMEBUFFERTEXTURELAYERARBPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);
		typedef void (* PFNGLFRAMEBUFFERTEXTUREFACEARBPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level, GLenum face);
		typedef void (* PFNGLVERTEXATTRIBDIVISORARBPROC) (GLuint index, GLuint divisor);
		typedef GLvoid* (* PFNGLMAPBUFFERRANGEPROC) (GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access);
		typedef void (* PFNGLFLUSHMAPPEDBUFFERRANGEPROC) (GLenum target, GLintptr offset, GLsizeiptr length);
		typedef void (* PFNGLTEXBUFFERARBPROC) (GLenum target, GLenum internalformat, GLuint buffer);
		typedef void (* PFNGLBINDVERTEXARRAYPROC) (GLuint array);
		typedef void (* PFNGLDELETEVERTEXARRAYSPROC) (GLsizei n, const GLuint *arrays);
		typedef void (* PFNGLGENVERTEXARRAYSPROC) (GLsizei n, GLuint *arrays);
		typedef GLboolean (* PFNGLISVERTEXARRAYPROC) (GLuint array);
		typedef void (* PFNGLGETUNIFORMINDICESPROC) (GLuint program, GLsizei uniformCount, const GLchar* const *uniformNames, GLuint *uniformIndices);
		typedef void (* PFNGLGETACTIVEUNIFORMSIVPROC) (GLuint program, GLsizei uniformCount, const GLuint *uniformIndices, GLenum pname, GLint *params);
		typedef void (* PFNGLGETACTIVEUNIFORMNAMEPROC) (GLuint program, GLuint uniformIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformName);
		typedef GLuint (* PFNGLGETUNIFORMBLOCKINDEXPROC) (GLuint program, const GLchar *uniformBlockName);
		typedef void (* PFNGLGETACTIVEUNIFORMBLOCKIVPROC) (GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint *params);
		typedef void (* PFNGLGETACTIVEUNIFORMBLOCKNAMEPROC) (GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformBlockName);
		typedef void (* PFNGLUNIFORMBLOCKBINDINGPROC) (GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding);
		typedef void (* PFNGLCOPYBUFFERSUBDATAPROC) (GLenum readTarget, GLenum writeTarget, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size);
		typedef void (* PFNGLDRAWELEMENTSBASEVERTEXPROC) (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLint basevertex);
		typedef void (* PFNGLDRAWRANGEELEMENTSBASEVERTEXPROC) (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indices, GLint basevertex);
		typedef void (* PFNGLDRAWELEMENTSINSTANCEDBASEVERTEXPROC) (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLsizei instancecount, GLint basevertex);
		typedef void (* PFNGLMULTIDRAWELEMENTSBASEVERTEXPROC) (GLenum mode, const GLsizei *count, GLenum type, const GLvoid* const *indices, GLsizei drawcount, const GLint *basevertex);
		typedef void (* PFNGLPROVOKINGVERTEXPROC) (GLenum mode);
		typedef GLsync (* PFNGLFENCESYNCPROC) (GLenum condition, GLbitfield flags);
		typedef GLboolean (* PFNGLISSYNCPROC) (GLsync sync);
		typedef void (* PFNGLDELETESYNCPROC) (GLsync sync);
		typedef GLenum (* PFNGLCLIENTWAITSYNCPROC) (GLsync sync, GLbitfield flags, GLuint64 timeout);
		typedef void (* PFNGLWAITSYNCPROC) (GLsync sync, GLbitfield flags, GLuint64 timeout);
		typedef void (* PFNGLGETINTEGER64VPROC) (GLenum pname, GLint64 *params);
		typedef void (* PFNGLGETSYNCIVPROC) (GLsync sync, GLenum pname, GLsizei bufSize, GLsizei *length, GLint *values);
		typedef void (* PFNGLTEXIMAGE2DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLint internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
		typedef void (* PFNGLTEXIMAGE3DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);
		typedef void (* PFNGLGETMULTISAMPLEFVPROC) (GLenum pname, GLuint index, GLfloat *val);
		typedef void (* PFNGLSAMPLEMASKIPROC) (GLuint index, GLbitfield mask);
		typedef void (* PFNGLBLENDEQUATIONIARBPROC) (GLuint buf, GLenum mode);
		typedef void (* PFNGLBLENDEQUATIONSEPARATEIARBPROC) (GLuint buf, GLenum modeRGB, GLenum modeAlpha);
		typedef void (* PFNGLBLENDFUNCIARBPROC) (GLuint buf, GLenum src, GLenum dst);
		typedef void (* PFNGLBLENDFUNCSEPARATEIARBPROC) (GLuint buf, GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);
		typedef void (* PFNGLMINSAMPLESHADINGARBPROC) (GLfloat value);
		typedef void (* PFNGLNAMEDSTRINGARBPROC) (GLenum type, GLint namelen, const GLchar *name, GLint stringlen, const GLchar *string);
		typedef void (* PFNGLDELETENAMEDSTRINGARBPROC) (GLint namelen, const GLchar *name);
		typedef void (* PFNGLCOMPILESHADERINCLUDEARBPROC) (GLuint shader, GLsizei count, const GLchar* *path, const GLint *length);
		typedef GLboolean (* PFNGLISNAMEDSTRINGARBPROC) (GLint namelen, const GLchar *name);
		typedef void (* PFNGLGETNAMEDSTRINGARBPROC) (GLint namelen, const GLchar *name, GLsizei bufSize, GLint *stringlen, GLchar *string);
		typedef void (* PFNGLGETNAMEDSTRINGIVARBPROC) (GLint namelen, const GLchar *name, GLenum pname, GLint *params);
		typedef void (* PFNGLBINDFRAGDATALOCATIONINDEXEDPROC) (GLuint program, GLuint colorNumber, GLuint index, const GLchar *name);
		typedef GLint (* PFNGLGETFRAGDATAINDEXPROC) (GLuint program, const GLchar *name);
		typedef void (* PFNGLGENSAMPLERSPROC) (GLsizei count, GLuint *samplers);
		typedef void (* PFNGLDELETESAMPLERSPROC) (GLsizei count, const GLuint *samplers);
		typedef GLboolean (* PFNGLISSAMPLERPROC) (GLuint sampler);
		typedef void (* PFNGLBINDSAMPLERPROC) (GLuint unit, GLuint sampler);
		typedef void (* PFNGLSAMPLERPARAMETERIPROC) (GLuint sampler, GLenum pname, GLint param);
		typedef void (* PFNGLSAMPLERPARAMETERIVPROC) (GLuint sampler, GLenum pname, const GLint *param);
		typedef void (* PFNGLSAMPLERPARAMETERFPROC) (GLuint sampler, GLenum pname, GLfloat param);
		typedef void (* PFNGLSAMPLERPARAMETERFVPROC) (GLuint sampler, GLenum pname, const GLfloat *param);
		typedef void (* PFNGLSAMPLERPARAMETERIIVPROC) (GLuint sampler, GLenum pname, const GLint *param);
		typedef void (* PFNGLSAMPLERPARAMETERIUIVPROC) (GLuint sampler, GLenum pname, const GLuint *param);
		typedef void (* PFNGLGETSAMPLERPARAMETERIVPROC) (GLuint sampler, GLenum pname, GLint *params);
		typedef void (* PFNGLGETSAMPLERPARAMETERIIVPROC) (GLuint sampler, GLenum pname, GLint *params);
		typedef void (* PFNGLGETSAMPLERPARAMETERFVPROC) (GLuint sampler, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETSAMPLERPARAMETERIUIVPROC) (GLuint sampler, GLenum pname, GLuint *params);
		typedef void (* PFNGLQUERYCOUNTERPROC) (GLuint id, GLenum target);
		typedef void (* PFNGLGETQUERYOBJECTI64VPROC) (GLuint id, GLenum pname, GLint64 *params);
		typedef void (* PFNGLGETQUERYOBJECTUI64VPROC) (GLuint id, GLenum pname, GLuint64 *params);
		typedef void (* PFNGLVERTEXP2UIPROC) (GLenum type, GLuint value);
		typedef void (* PFNGLVERTEXP2UIVPROC) (GLenum type, const GLuint *value);
		typedef void (* PFNGLVERTEXP3UIPROC) (GLenum type, GLuint value);
		typedef void (* PFNGLVERTEXP3UIVPROC) (GLenum type, const GLuint *value);
		typedef void (* PFNGLVERTEXP4UIPROC) (GLenum type, GLuint value);
		typedef void (* PFNGLVERTEXP4UIVPROC) (GLenum type, const GLuint *value);
		typedef void (* PFNGLTEXCOORDP1UIPROC) (GLenum type, GLuint coords);
		typedef void (* PFNGLTEXCOORDP1UIVPROC) (GLenum type, const GLuint *coords);
		typedef void (* PFNGLTEXCOORDP2UIPROC) (GLenum type, GLuint coords);
		typedef void (* PFNGLTEXCOORDP2UIVPROC) (GLenum type, const GLuint *coords);
		typedef void (* PFNGLTEXCOORDP3UIPROC) (GLenum type, GLuint coords);
		typedef void (* PFNGLTEXCOORDP3UIVPROC) (GLenum type, const GLuint *coords);
		typedef void (* PFNGLTEXCOORDP4UIPROC) (GLenum type, GLuint coords);
		typedef void (* PFNGLTEXCOORDP4UIVPROC) (GLenum type, const GLuint *coords);
		typedef void (* PFNGLMULTITEXCOORDP1UIPROC) (GLenum texture, GLenum type, GLuint coords);
		typedef void (* PFNGLMULTITEXCOORDP1UIVPROC) (GLenum texture, GLenum type, const GLuint *coords);
		typedef void (* PFNGLMULTITEXCOORDP2UIPROC) (GLenum texture, GLenum type, GLuint coords);
		typedef void (* PFNGLMULTITEXCOORDP2UIVPROC) (GLenum texture, GLenum type, const GLuint *coords);
		typedef void (* PFNGLMULTITEXCOORDP3UIPROC) (GLenum texture, GLenum type, GLuint coords);
		typedef void (* PFNGLMULTITEXCOORDP3UIVPROC) (GLenum texture, GLenum type, const GLuint *coords);
		typedef void (* PFNGLMULTITEXCOORDP4UIPROC) (GLenum texture, GLenum type, GLuint coords);
		typedef void (* PFNGLMULTITEXCOORDP4UIVPROC) (GLenum texture, GLenum type, const GLuint *coords);
		typedef void (* PFNGLNORMALP3UIPROC) (GLenum type, GLuint coords);
		typedef void (* PFNGLNORMALP3UIVPROC) (GLenum type, const GLuint *coords);
		typedef void (* PFNGLCOLORP3UIPROC) (GLenum type, GLuint color);
		typedef void (* PFNGLCOLORP3UIVPROC) (GLenum type, const GLuint *color);
		typedef void (* PFNGLCOLORP4UIPROC) (GLenum type, GLuint color);
		typedef void (* PFNGLCOLORP4UIVPROC) (GLenum type, const GLuint *color);
		typedef void (* PFNGLSECONDARYCOLORP3UIPROC) (GLenum type, GLuint color);
		typedef void (* PFNGLSECONDARYCOLORP3UIVPROC) (GLenum type, const GLuint *color);
		typedef void (* PFNGLVERTEXATTRIBP1UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
		typedef void (* PFNGLVERTEXATTRIBP1UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
		typedef void (* PFNGLVERTEXATTRIBP2UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
		typedef void (* PFNGLVERTEXATTRIBP2UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
		typedef void (* PFNGLVERTEXATTRIBP3UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
		typedef void (* PFNGLVERTEXATTRIBP3UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
		typedef void (* PFNGLVERTEXATTRIBP4UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
		typedef void (* PFNGLVERTEXATTRIBP4UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
		typedef void (* PFNGLDRAWARRAYSINDIRECTPROC) (GLenum mode, const GLvoid *indirect);
		typedef void (* PFNGLDRAWELEMENTSINDIRECTPROC) (GLenum mode, GLenum type, const GLvoid *indirect);
		typedef void (* PFNGLUNIFORM1DPROC) (GLint location, GLdouble x);
		typedef void (* PFNGLUNIFORM2DPROC) (GLint location, GLdouble x, GLdouble y);
		typedef void (* PFNGLUNIFORM3DPROC) (GLint location, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLUNIFORM4DPROC) (GLint location, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLUNIFORM1DVPROC) (GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLUNIFORM2DVPROC) (GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLUNIFORM3DVPROC) (GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLUNIFORM4DVPROC) (GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLUNIFORMMATRIX2DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLUNIFORMMATRIX3DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLUNIFORMMATRIX4DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLUNIFORMMATRIX2X3DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLUNIFORMMATRIX2X4DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLUNIFORMMATRIX3X2DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLUNIFORMMATRIX3X4DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLUNIFORMMATRIX4X2DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLUNIFORMMATRIX4X3DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLGETUNIFORMDVPROC) (GLuint program, GLint location, GLdouble *params);
		typedef GLint (* PFNGLGETSUBROUTINEUNIFORMLOCATIONPROC) (GLuint program, GLenum shadertype, const GLchar *name);
		typedef GLuint (* PFNGLGETSUBROUTINEINDEXPROC) (GLuint program, GLenum shadertype, const GLchar *name);
		typedef void (* PFNGLGETACTIVESUBROUTINEUNIFORMIVPROC) (GLuint program, GLenum shadertype, GLuint index, GLenum pname, GLint *values);
		typedef void (* PFNGLGETACTIVESUBROUTINEUNIFORMNAMEPROC) (GLuint program, GLenum shadertype, GLuint index, GLsizei bufsize, GLsizei *length, GLchar *name);
		typedef void (* PFNGLGETACTIVESUBROUTINENAMEPROC) (GLuint program, GLenum shadertype, GLuint index, GLsizei bufsize, GLsizei *length, GLchar *name);
		typedef void (* PFNGLUNIFORMSUBROUTINESUIVPROC) (GLenum shadertype, GLsizei count, const GLuint *indices);
		typedef void (* PFNGLGETUNIFORMSUBROUTINEUIVPROC) (GLenum shadertype, GLint location, GLuint *params);
		typedef void (* PFNGLGETPROGRAMSTAGEIVPROC) (GLuint program, GLenum shadertype, GLenum pname, GLint *values);
		typedef void (* PFNGLPATCHPARAMETERIPROC) (GLenum pname, GLint value);
		typedef void (* PFNGLPATCHPARAMETERFVPROC) (GLenum pname, const GLfloat *values);
		typedef void (* PFNGLBINDTRANSFORMFEEDBACKPROC) (GLenum target, GLuint id);
		typedef void (* PFNGLDELETETRANSFORMFEEDBACKSPROC) (GLsizei n, const GLuint *ids);
		typedef void (* PFNGLGENTRANSFORMFEEDBACKSPROC) (GLsizei n, GLuint *ids);
		typedef GLboolean (* PFNGLISTRANSFORMFEEDBACKPROC) (GLuint id);
		typedef void (* PFNGLPAUSETRANSFORMFEEDBACKPROC) (void);
		typedef void (* PFNGLRESUMETRANSFORMFEEDBACKPROC) (void);
		typedef void (* PFNGLDRAWTRANSFORMFEEDBACKPROC) (GLenum mode, GLuint id);
		typedef void (* PFNGLDRAWTRANSFORMFEEDBACKSTREAMPROC) (GLenum mode, GLuint id, GLuint stream);
		typedef void (* PFNGLBEGINQUERYINDEXEDPROC) (GLenum target, GLuint index, GLuint id);
		typedef void (* PFNGLENDQUERYINDEXEDPROC) (GLenum target, GLuint index);
		typedef void (* PFNGLGETQUERYINDEXEDIVPROC) (GLenum target, GLuint index, GLenum pname, GLint *params);
		typedef void (* PFNGLRELEASESHADERCOMPILERPROC) (void);
		typedef void (* PFNGLSHADERBINARYPROC) (GLsizei count, const GLuint *shaders, GLenum binaryformat, const GLvoid *binary, GLsizei length);
		typedef void (* PFNGLGETSHADERPRECISIONFORMATPROC) (GLenum shadertype, GLenum precisiontype, GLint *range, GLint *precision);
		typedef void (* PFNGLDEPTHRANGEFPROC) (GLfloat n, GLfloat f);
		typedef void (* PFNGLCLEARDEPTHFPROC) (GLfloat d);
		typedef void (* PFNGLGETPROGRAMBINARYPROC) (GLuint program, GLsizei bufSize, GLsizei *length, GLenum *binaryFormat, GLvoid *binary);
		typedef void (* PFNGLPROGRAMBINARYPROC) (GLuint program, GLenum binaryFormat, const GLvoid *binary, GLsizei length);
		typedef void (* PFNGLPROGRAMPARAMETERIPROC) (GLuint program, GLenum pname, GLint value);
		typedef void (* PFNGLUSEPROGRAMSTAGESPROC) (GLuint pipeline, GLbitfield stages, GLuint program);
		typedef void (* PFNGLACTIVESHADERPROGRAMPROC) (GLuint pipeline, GLuint program);
		typedef GLuint (* PFNGLCREATESHADERPROGRAMVPROC) (GLenum type, GLsizei count, const GLchar* const *strings);
		typedef void (* PFNGLBINDPROGRAMPIPELINEPROC) (GLuint pipeline);
		typedef void (* PFNGLDELETEPROGRAMPIPELINESPROC) (GLsizei n, const GLuint *pipelines);
		typedef void (* PFNGLGENPROGRAMPIPELINESPROC) (GLsizei n, GLuint *pipelines);
		typedef GLboolean (* PFNGLISPROGRAMPIPELINEPROC) (GLuint pipeline);
		typedef void (* PFNGLGETPROGRAMPIPELINEIVPROC) (GLuint pipeline, GLenum pname, GLint *params);
		typedef void (* PFNGLPROGRAMUNIFORM1IPROC) (GLuint program, GLint location, GLint v0);
		typedef void (* PFNGLPROGRAMUNIFORM1IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLPROGRAMUNIFORM1FPROC) (GLuint program, GLint location, GLfloat v0);
		typedef void (* PFNGLPROGRAMUNIFORM1FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORM1DPROC) (GLuint program, GLint location, GLdouble v0);
		typedef void (* PFNGLPROGRAMUNIFORM1DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORM1UIPROC) (GLuint program, GLint location, GLuint v0);
		typedef void (* PFNGLPROGRAMUNIFORM1UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLPROGRAMUNIFORM2IPROC) (GLuint program, GLint location, GLint v0, GLint v1);
		typedef void (* PFNGLPROGRAMUNIFORM2IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLPROGRAMUNIFORM2FPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1);
		typedef void (* PFNGLPROGRAMUNIFORM2FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORM2DPROC) (GLuint program, GLint location, GLdouble v0, GLdouble v1);
		typedef void (* PFNGLPROGRAMUNIFORM2DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORM2UIPROC) (GLuint program, GLint location, GLuint v0, GLuint v1);
		typedef void (* PFNGLPROGRAMUNIFORM2UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLPROGRAMUNIFORM3IPROC) (GLuint program, GLint location, GLint v0, GLint v1, GLint v2);
		typedef void (* PFNGLPROGRAMUNIFORM3IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLPROGRAMUNIFORM3FPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
		typedef void (* PFNGLPROGRAMUNIFORM3FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORM3DPROC) (GLuint program, GLint location, GLdouble v0, GLdouble v1, GLdouble v2);
		typedef void (* PFNGLPROGRAMUNIFORM3DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORM3UIPROC) (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2);
		typedef void (* PFNGLPROGRAMUNIFORM3UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLPROGRAMUNIFORM4IPROC) (GLuint program, GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
		typedef void (* PFNGLPROGRAMUNIFORM4IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLPROGRAMUNIFORM4FPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
		typedef void (* PFNGLPROGRAMUNIFORM4FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORM4DPROC) (GLuint program, GLint location, GLdouble v0, GLdouble v1, GLdouble v2, GLdouble v3);
		typedef void (* PFNGLPROGRAMUNIFORM4DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORM4UIPROC) (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
		typedef void (* PFNGLPROGRAMUNIFORM4UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2X3FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3X2FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2X4FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4X2FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3X4FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4X3FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2X3DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3X2DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2X4DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4X2DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3X4DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4X3DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLVALIDATEPROGRAMPIPELINEPROC) (GLuint pipeline);
		typedef void (* PFNGLGETPROGRAMPIPELINEINFOLOGPROC) (GLuint pipeline, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
		typedef void (* PFNGLVERTEXATTRIBL1DPROC) (GLuint index, GLdouble x);
		typedef void (* PFNGLVERTEXATTRIBL2DPROC) (GLuint index, GLdouble x, GLdouble y);
		typedef void (* PFNGLVERTEXATTRIBL3DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLVERTEXATTRIBL4DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLVERTEXATTRIBL1DVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBL2DVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBL3DVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBL4DVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBLPOINTERPROC) (GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLGETVERTEXATTRIBLDVPROC) (GLuint index, GLenum pname, GLdouble *params);
		typedef void (* PFNGLVIEWPORTARRAYVPROC) (GLuint first, GLsizei count, const GLfloat *v);
		typedef void (* PFNGLVIEWPORTINDEXEDFPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat w, GLfloat h);
		typedef void (* PFNGLVIEWPORTINDEXEDFVPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLSCISSORARRAYVPROC) (GLuint first, GLsizei count, const GLint *v);
		typedef void (* PFNGLSCISSORINDEXEDPROC) (GLuint index, GLint left, GLint bottom, GLsizei width, GLsizei height);
		typedef void (* PFNGLSCISSORINDEXEDVPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLDEPTHRANGEARRAYVPROC) (GLuint first, GLsizei count, const GLdouble *v);
		typedef void (* PFNGLDEPTHRANGEINDEXEDPROC) (GLuint index, GLdouble n, GLdouble f);
		typedef void (* PFNGLGETFLOATI_VPROC) (GLenum target, GLuint index, GLfloat *data);
		typedef void (* PFNGLGETDOUBLEI_VPROC) (GLenum target, GLuint index, GLdouble *data);
		typedef GLsync (* PFNGLCREATESYNCFROMCLEVENTARBPROC) (struct _cl_context * context, struct _cl_event * event, GLbitfield flags);
		typedef void (* PFNGLDEBUGMESSAGECONTROLARBPROC) (GLenum source, GLenum type, GLenum severity, GLsizei count, const GLuint *ids, GLboolean enabled);
		typedef void (* PFNGLDEBUGMESSAGEINSERTARBPROC) (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *buf);
		typedef void (* PFNGLDEBUGMESSAGECALLBACKARBPROC) (GLDEBUGPROCARB callback, const GLvoid *userParam);
		typedef GLuint (* PFNGLGETDEBUGMESSAGELOGARBPROC) (GLuint count, GLsizei bufsize, GLenum *sources, GLenum *types, GLuint *ids, GLenum *severities, GLsizei *lengths, GLchar *messageLog);
		typedef GLenum (* PFNGLGETGRAPHICSRESETSTATUSARBPROC) (void);
		typedef void (* PFNGLGETNMAPDVARBPROC) (GLenum target, GLenum query, GLsizei bufSize, GLdouble *v);
		typedef void (* PFNGLGETNMAPFVARBPROC) (GLenum target, GLenum query, GLsizei bufSize, GLfloat *v);
		typedef void (* PFNGLGETNMAPIVARBPROC) (GLenum target, GLenum query, GLsizei bufSize, GLint *v);
		typedef void (* PFNGLGETNPIXELMAPFVARBPROC) (GLenum map, GLsizei bufSize, GLfloat *values);
		typedef void (* PFNGLGETNPIXELMAPUIVARBPROC) (GLenum map, GLsizei bufSize, GLuint *values);
		typedef void (* PFNGLGETNPIXELMAPUSVARBPROC) (GLenum map, GLsizei bufSize, GLushort *values);
		typedef void (* PFNGLGETNPOLYGONSTIPPLEARBPROC) (GLsizei bufSize, GLubyte *pattern);
		typedef void (* PFNGLGETNCOLORTABLEARBPROC) (GLenum target, GLenum format, GLenum type, GLsizei bufSize, GLvoid *table);
		typedef void (* PFNGLGETNCONVOLUTIONFILTERARBPROC) (GLenum target, GLenum format, GLenum type, GLsizei bufSize, GLvoid *image);
		typedef void (* PFNGLGETNSEPARABLEFILTERARBPROC) (GLenum target, GLenum format, GLenum type, GLsizei rowBufSize, GLvoid *row, GLsizei columnBufSize, GLvoid *column, GLvoid *span);
		typedef void (* PFNGLGETNHISTOGRAMARBPROC) (GLenum target, GLboolean reset, GLenum format, GLenum type, GLsizei bufSize, GLvoid *values);
		typedef void (* PFNGLGETNMINMAXARBPROC) (GLenum target, GLboolean reset, GLenum format, GLenum type, GLsizei bufSize, GLvoid *values);
		typedef void (* PFNGLGETNTEXIMAGEARBPROC) (GLenum target, GLint level, GLenum format, GLenum type, GLsizei bufSize, GLvoid *img);
		typedef void (* PFNGLREADNPIXELSARBPROC) (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLsizei bufSize, GLvoid *data);
		typedef void (* PFNGLGETNCOMPRESSEDTEXIMAGEARBPROC) (GLenum target, GLint lod, GLsizei bufSize, GLvoid *img);
		typedef void (* PFNGLGETNUNIFORMFVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLfloat *params);
		typedef void (* PFNGLGETNUNIFORMIVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLint *params);
		typedef void (* PFNGLGETNUNIFORMUIVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLuint *params);
		typedef void (* PFNGLGETNUNIFORMDVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLdouble *params);
		typedef void (* PFNGLDRAWARRAYSINSTANCEDBASEINSTANCEPROC) (GLenum mode, GLint first, GLsizei count, GLsizei instancecount, GLuint baseinstance);
		typedef void (* PFNGLDRAWELEMENTSINSTANCEDBASEINSTANCEPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLuint baseinstance);
		typedef void (* PFNGLDRAWELEMENTSINSTANCEDBASEVERTEXBASEINSTANCEPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLint basevertex, GLuint baseinstance);
		typedef void (* PFNGLDRAWTRANSFORMFEEDBACKINSTANCEDPROC) (GLenum mode, GLuint id, GLsizei instancecount);
		typedef void (* PFNGLDRAWTRANSFORMFEEDBACKSTREAMINSTANCEDPROC) (GLenum mode, GLuint id, GLuint stream, GLsizei instancecount);
		typedef void (* PFNGLGETINTERNALFORMATIVPROC) (GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint *params);
		typedef void (* PFNGLGETACTIVEATOMICCOUNTERBUFFERIVPROC) (GLuint program, GLuint bufferIndex, GLenum pname, GLint *params);
		typedef void (* PFNGLBINDIMAGETEXTUREPROC) (GLuint unit, GLuint texture, GLint level, GLboolean layered, GLint layer, GLenum access, GLenum format);
		typedef void (* PFNGLMEMORYBARRIERPROC) (GLbitfield barriers);
		typedef void (* PFNGLTEXSTORAGE1DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width);
		typedef void (* PFNGLTEXSTORAGE2DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLTEXSTORAGE3DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);
		typedef void (* PFNGLTEXTURESTORAGE1DEXTPROC) (GLuint texture, GLenum target, GLsizei levels, GLenum internalformat, GLsizei width);
		typedef void (* PFNGLTEXTURESTORAGE2DEXTPROC) (GLuint texture, GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLTEXTURESTORAGE3DEXTPROC) (GLuint texture, GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);
		typedef void (* PFNGLDEBUGMESSAGECONTROLPROC) (GLenum source, GLenum type, GLenum severity, GLsizei count, const GLuint *ids, GLboolean enabled);
		typedef void (* PFNGLDEBUGMESSAGEINSERTPROC) (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *buf);
		typedef void (* PFNGLDEBUGMESSAGECALLBACKPROC) (GLDEBUGPROC callback, const void *userParam);
		typedef GLuint (* PFNGLGETDEBUGMESSAGELOGPROC) (GLuint count, GLsizei bufsize, GLenum *sources, GLenum *types, GLuint *ids, GLenum *severities, GLsizei *lengths, GLchar *messageLog);
		typedef void (* PFNGLPUSHDEBUGGROUPPROC) (GLenum source, GLuint id, GLsizei length, const GLchar *message);
		typedef void (* PFNGLPOPDEBUGGROUPPROC) (void);
		typedef void (* PFNGLOBJECTLABELPROC) (GLenum identifier, GLuint name, GLsizei length, const GLchar *label);
		typedef void (* PFNGLGETOBJECTLABELPROC) (GLenum identifier, GLuint name, GLsizei bufSize, GLsizei *length, GLchar *label);
		typedef void (* PFNGLOBJECTPTRLABELPROC) (const void *ptr, GLsizei length, const GLchar *label);
		typedef void (* PFNGLGETOBJECTPTRLABELPROC) (const void *ptr, GLsizei bufSize, GLsizei *length, GLchar *label);
		typedef void (* PFNGLCLEARBUFFERDATAPROC) (GLenum target, GLenum internalformat, GLenum format, GLenum type, const void *data);
		typedef void (* PFNGLCLEARBUFFERSUBDATAPROC) (GLenum target, GLenum internalformat, GLintptr offset, GLsizeiptr size, GLenum format, GLenum type, const void *data);
		typedef void (* PFNGLCLEARNAMEDBUFFERDATAEXTPROC) (GLuint buffer, GLenum internalformat, GLenum format, GLenum type, const void *data);
		typedef void (* PFNGLCLEARNAMEDBUFFERSUBDATAEXTPROC) (GLuint buffer, GLenum internalformat, GLenum format, GLenum type, GLsizeiptr offset, GLsizeiptr size, const void *data);
		typedef void (* PFNGLDISPATCHCOMPUTEPROC) (GLuint num_groups_x, GLuint num_groups_y, GLuint num_groups_z);
		typedef void (* PFNGLDISPATCHCOMPUTEINDIRECTPROC) (GLintptr indirect);
		typedef void (* PFNGLCOPYIMAGESUBDATAPROC) (GLuint srcName, GLenum srcTarget, GLint srcLevel, GLint srcX, GLint srcY, GLint srcZ, GLuint dstName, GLenum dstTarget, GLint dstLevel, GLint dstX, GLint dstY, GLint dstZ, GLsizei srcWidth, GLsizei srcHeight, GLsizei srcDepth);
		typedef void (* PFNGLTEXTUREVIEWPROC) (GLuint texture, GLenum target, GLuint origtexture, GLenum internalformat, GLuint minlevel, GLuint numlevels, GLuint minlayer, GLuint numlayers);
		typedef void (* PFNGLBINDVERTEXBUFFERPROC) (GLuint bindingindex, GLuint buffer, GLintptr offset, GLsizei stride);
		typedef void (* PFNGLVERTEXATTRIBFORMATPROC) (GLuint attribindex, GLint size, GLenum type, GLboolean normalized, GLuint relativeoffset);
		typedef void (* PFNGLVERTEXATTRIBIFORMATPROC) (GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
		typedef void (* PFNGLVERTEXATTRIBLFORMATPROC) (GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
		typedef void (* PFNGLVERTEXATTRIBBINDINGPROC) (GLuint attribindex, GLuint bindingindex);
		typedef void (* PFNGLVERTEXBINDINGDIVISORPROC) (GLuint bindingindex, GLuint divisor);
		typedef void (* PFNGLVERTEXARRAYBINDVERTEXBUFFEREXTPROC) (GLuint vaobj, GLuint bindingindex, GLuint buffer, GLintptr offset, GLsizei stride);
		typedef void (* PFNGLVERTEXARRAYVERTEXATTRIBFORMATEXTPROC) (GLuint vaobj, GLuint attribindex, GLint size, GLenum type, GLboolean normalized, GLuint relativeoffset);
		typedef void (* PFNGLVERTEXARRAYVERTEXATTRIBIFORMATEXTPROC) (GLuint vaobj, GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
		typedef void (* PFNGLVERTEXARRAYVERTEXATTRIBLFORMATEXTPROC) (GLuint vaobj, GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
		typedef void (* PFNGLVERTEXARRAYVERTEXATTRIBBINDINGEXTPROC) (GLuint vaobj, GLuint attribindex, GLuint bindingindex);
		typedef void (* PFNGLVERTEXARRAYVERTEXBINDINGDIVISOREXTPROC) (GLuint vaobj, GLuint bindingindex, GLuint divisor);
		typedef void (* PFNGLFRAMEBUFFERPARAMETERIPROC) (GLenum target, GLenum pname, GLint param);
		typedef void (* PFNGLGETFRAMEBUFFERPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLNAMEDFRAMEBUFFERPARAMETERIEXTPROC) (GLuint framebuffer, GLenum pname, GLint param);
		typedef void (* PFNGLGETNAMEDFRAMEBUFFERPARAMETERIVEXTPROC) (GLuint framebuffer, GLenum pname, GLint *params);
		typedef void (* PFNGLGETINTERNALFORMATI64VPROC) (GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint64 *params);
		typedef void (* PFNGLINVALIDATETEXSUBIMAGEPROC) (GLuint texture, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth);
		typedef void (* PFNGLINVALIDATETEXIMAGEPROC) (GLuint texture, GLint level);
		typedef void (* PFNGLINVALIDATEBUFFERSUBDATAPROC) (GLuint buffer, GLintptr offset, GLsizeiptr length);
		typedef void (* PFNGLINVALIDATEBUFFERDATAPROC) (GLuint buffer);
		typedef void (* PFNGLINVALIDATEFRAMEBUFFERPROC) (GLenum target, GLsizei numAttachments, const GLenum *attachments);
		typedef void (* PFNGLINVALIDATESUBFRAMEBUFFERPROC) (GLenum target, GLsizei numAttachments, const GLenum *attachments, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLMULTIDRAWARRAYSINDIRECTPROC) (GLenum mode, const void *indirect, GLsizei drawcount, GLsizei stride);
		typedef void (* PFNGLMULTIDRAWELEMENTSINDIRECTPROC) (GLenum mode, GLenum type, const void *indirect, GLsizei drawcount, GLsizei stride);
		typedef void (* PFNGLGETPROGRAMINTERFACEIVPROC) (GLuint program, GLenum programInterface, GLenum pname, GLint *params);
		typedef GLuint (* PFNGLGETPROGRAMRESOURCEINDEXPROC) (GLuint program, GLenum programInterface, const GLchar *name);
		typedef void (* PFNGLGETPROGRAMRESOURCENAMEPROC) (GLuint program, GLenum programInterface, GLuint index, GLsizei bufSize, GLsizei *length, GLchar *name);
		typedef void (* PFNGLGETPROGRAMRESOURCEIVPROC) (GLuint program, GLenum programInterface, GLuint index, GLsizei propCount, const GLenum *props, GLsizei bufSize, GLsizei *length, GLint *params);
		typedef GLint (* PFNGLGETPROGRAMRESOURCELOCATIONPROC) (GLuint program, GLenum programInterface, const GLchar *name);
		typedef GLint (* PFNGLGETPROGRAMRESOURCELOCATIONINDEXPROC) (GLuint program, GLenum programInterface, const GLchar *name);
		typedef void (* PFNGLSHADERSTORAGEBLOCKBINDINGPROC) (GLuint program, GLuint storageBlockIndex, GLuint storageBlockBinding);
		typedef void (* PFNGLTEXBUFFERRANGEPROC) (GLenum target, GLenum internalformat, GLuint buffer, GLintptr offset, GLsizeiptr size);
		typedef void (* PFNGLTEXTUREBUFFERRANGEEXTPROC) (GLuint texture, GLenum target, GLenum internalformat, GLuint buffer, GLintptr offset, GLsizeiptr size);
		typedef void (* PFNGLTEXSTORAGE2DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
		typedef void (* PFNGLTEXSTORAGE3DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);
		typedef void (* PFNGLTEXTURESTORAGE2DMULTISAMPLEEXTPROC) (GLuint texture, GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
		typedef void (* PFNGLTEXTURESTORAGE3DMULTISAMPLEEXTPROC) (GLuint texture, GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);
		typedef void (* PFNGLBLENDCOLOREXTPROC) (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
		typedef void (* PFNGLPOLYGONOFFSETEXTPROC) (GLfloat factor, GLfloat bias);
		typedef void (* PFNGLTEXIMAGE3DEXTPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLTEXSUBIMAGE3DEXTPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLGETTEXFILTERFUNCSGISPROC) (GLenum target, GLenum filter, GLfloat *weights);
		typedef void (* PFNGLTEXFILTERFUNCSGISPROC) (GLenum target, GLenum filter, GLsizei n, const GLfloat *weights);
		typedef void (* PFNGLTEXSUBIMAGE1DEXTPROC) (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLTEXSUBIMAGE2DEXTPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLCOPYTEXIMAGE1DEXTPROC) (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLint border);
		typedef void (* PFNGLCOPYTEXIMAGE2DEXTPROC) (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
		typedef void (* PFNGLCOPYTEXSUBIMAGE1DEXTPROC) (GLenum target, GLint level, GLint xoffset, GLint x, GLint y, GLsizei width);
		typedef void (* PFNGLCOPYTEXSUBIMAGE2DEXTPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLCOPYTEXSUBIMAGE3DEXTPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLGETHISTOGRAMEXTPROC) (GLenum target, GLboolean reset, GLenum format, GLenum type, GLvoid *values);
		typedef void (* PFNGLGETHISTOGRAMPARAMETERFVEXTPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETHISTOGRAMPARAMETERIVEXTPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETMINMAXEXTPROC) (GLenum target, GLboolean reset, GLenum format, GLenum type, GLvoid *values);
		typedef void (* PFNGLGETMINMAXPARAMETERFVEXTPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETMINMAXPARAMETERIVEXTPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLHISTOGRAMEXTPROC) (GLenum target, GLsizei width, GLenum internalformat, GLboolean sink);
		typedef void (* PFNGLMINMAXEXTPROC) (GLenum target, GLenum internalformat, GLboolean sink);
		typedef void (* PFNGLRESETHISTOGRAMEXTPROC) (GLenum target);
		typedef void (* PFNGLRESETMINMAXEXTPROC) (GLenum target);
		typedef void (* PFNGLCONVOLUTIONFILTER1DEXTPROC) (GLenum target, GLenum internalformat, GLsizei width, GLenum format, GLenum type, const GLvoid *image);
		typedef void (* PFNGLCONVOLUTIONFILTER2DEXTPROC) (GLenum target, GLenum internalformat, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *image);
		typedef void (* PFNGLCONVOLUTIONPARAMETERFEXTPROC) (GLenum target, GLenum pname, GLfloat params);
		typedef void (* PFNGLCONVOLUTIONPARAMETERFVEXTPROC) (GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLCONVOLUTIONPARAMETERIEXTPROC) (GLenum target, GLenum pname, GLint params);
		typedef void (* PFNGLCONVOLUTIONPARAMETERIVEXTPROC) (GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLCOPYCONVOLUTIONFILTER1DEXTPROC) (GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width);
		typedef void (* PFNGLCOPYCONVOLUTIONFILTER2DEXTPROC) (GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLGETCONVOLUTIONFILTEREXTPROC) (GLenum target, GLenum format, GLenum type, GLvoid *image);
		typedef void (* PFNGLGETCONVOLUTIONPARAMETERFVEXTPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETCONVOLUTIONPARAMETERIVEXTPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETSEPARABLEFILTEREXTPROC) (GLenum target, GLenum format, GLenum type, GLvoid *row, GLvoid *column, GLvoid *span);
		typedef void (* PFNGLSEPARABLEFILTER2DEXTPROC) (GLenum target, GLenum internalformat, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *row, const GLvoid *column);
		typedef void (* PFNGLCOLORTABLESGIPROC) (GLenum target, GLenum internalformat, GLsizei width, GLenum format, GLenum type, const GLvoid *table);
		typedef void (* PFNGLCOLORTABLEPARAMETERFVSGIPROC) (GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLCOLORTABLEPARAMETERIVSGIPROC) (GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLCOPYCOLORTABLESGIPROC) (GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width);
		typedef void (* PFNGLGETCOLORTABLESGIPROC) (GLenum target, GLenum format, GLenum type, GLvoid *table);
		typedef void (* PFNGLGETCOLORTABLEPARAMETERFVSGIPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETCOLORTABLEPARAMETERIVSGIPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLPIXELTEXGENSGIXPROC) (GLenum mode);
		typedef void (* PFNGLPIXELTEXGENPARAMETERISGISPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLPIXELTEXGENPARAMETERIVSGISPROC) (GLenum pname, const GLint *params);
		typedef void (* PFNGLPIXELTEXGENPARAMETERFSGISPROC) (GLenum pname, GLfloat param);
		typedef void (* PFNGLPIXELTEXGENPARAMETERFVSGISPROC) (GLenum pname, const GLfloat *params);
		typedef void (* PFNGLGETPIXELTEXGENPARAMETERIVSGISPROC) (GLenum pname, GLint *params);
		typedef void (* PFNGLGETPIXELTEXGENPARAMETERFVSGISPROC) (GLenum pname, GLfloat *params);
		typedef void (* PFNGLTEXIMAGE4DSGISPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLsizei size4d, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLTEXSUBIMAGE4DSGISPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint woffset, GLsizei width, GLsizei height, GLsizei depth, GLsizei size4d, GLenum format, GLenum type, const GLvoid *pixels);
		typedef GLboolean (* PFNGLARETEXTURESRESIDENTEXTPROC) (GLsizei n, const GLuint *textures, GLboolean *residences);
		typedef void (* PFNGLBINDTEXTUREEXTPROC) (GLenum target, GLuint texture);
		typedef void (* PFNGLDELETETEXTURESEXTPROC) (GLsizei n, const GLuint *textures);
		typedef void (* PFNGLGENTEXTURESEXTPROC) (GLsizei n, GLuint *textures);
		typedef GLboolean (* PFNGLISTEXTUREEXTPROC) (GLuint texture);
		typedef void (* PFNGLPRIORITIZETEXTURESEXTPROC) (GLsizei n, const GLuint *textures, const GLclampf *priorities);
		typedef void (* PFNGLDETAILTEXFUNCSGISPROC) (GLenum target, GLsizei n, const GLfloat *points);
		typedef void (* PFNGLGETDETAILTEXFUNCSGISPROC) (GLenum target, GLfloat *points);
		typedef void (* PFNGLSHARPENTEXFUNCSGISPROC) (GLenum target, GLsizei n, const GLfloat *points);
		typedef void (* PFNGLGETSHARPENTEXFUNCSGISPROC) (GLenum target, GLfloat *points);
		typedef void (* PFNGLSAMPLEMASKSGISPROC) (GLclampf value, GLboolean invert);
		typedef void (* PFNGLSAMPLEPATTERNSGISPROC) (GLenum pattern);
		typedef void (* PFNGLARRAYELEMENTEXTPROC) (GLint i);
		typedef void (* PFNGLCOLORPOINTEREXTPROC) (GLint size, GLenum type, GLsizei stride, GLsizei count, const GLvoid *pointer);
		typedef void (* PFNGLDRAWARRAYSEXTPROC) (GLenum mode, GLint first, GLsizei count);
		typedef void (* PFNGLEDGEFLAGPOINTEREXTPROC) (GLsizei stride, GLsizei count, const GLboolean *pointer);
		typedef void (* PFNGLGETPOINTERVEXTPROC) (GLenum pname, GLvoid* *params);
		typedef void (* PFNGLINDEXPOINTEREXTPROC) (GLenum type, GLsizei stride, GLsizei count, const GLvoid *pointer);
		typedef void (* PFNGLNORMALPOINTEREXTPROC) (GLenum type, GLsizei stride, GLsizei count, const GLvoid *pointer);
		typedef void (* PFNGLTEXCOORDPOINTEREXTPROC) (GLint size, GLenum type, GLsizei stride, GLsizei count, const GLvoid *pointer);
		typedef void (* PFNGLVERTEXPOINTEREXTPROC) (GLint size, GLenum type, GLsizei stride, GLsizei count, const GLvoid *pointer);
		typedef void (* PFNGLBLENDEQUATIONEXTPROC) (GLenum mode);
		typedef void (* PFNGLSPRITEPARAMETERFSGIXPROC) (GLenum pname, GLfloat param);
		typedef void (* PFNGLSPRITEPARAMETERFVSGIXPROC) (GLenum pname, const GLfloat *params);
		typedef void (* PFNGLSPRITEPARAMETERISGIXPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLSPRITEPARAMETERIVSGIXPROC) (GLenum pname, const GLint *params);
		typedef void (* PFNGLPOINTPARAMETERFEXTPROC) (GLenum pname, GLfloat param);
		typedef void (* PFNGLPOINTPARAMETERFVEXTPROC) (GLenum pname, const GLfloat *params);
		typedef void (* PFNGLPOINTPARAMETERFSGISPROC) (GLenum pname, GLfloat param);
		typedef void (* PFNGLPOINTPARAMETERFVSGISPROC) (GLenum pname, const GLfloat *params);
		typedef GLint (* PFNGLGETINSTRUMENTSSGIXPROC) (void);
		typedef void (* PFNGLINSTRUMENTSBUFFERSGIXPROC) (GLsizei size, GLint *buffer);
		typedef GLint (* PFNGLPOLLINSTRUMENTSSGIXPROC) (GLint *marker_p);
		typedef void (* PFNGLREADINSTRUMENTSSGIXPROC) (GLint marker);
		typedef void (* PFNGLSTARTINSTRUMENTSSGIXPROC) (void);
		typedef void (* PFNGLSTOPINSTRUMENTSSGIXPROC) (GLint marker);
		typedef void (* PFNGLFRAMEZOOMSGIXPROC) (GLint factor);
		typedef void (* PFNGLTAGSAMPLEBUFFERSGIXPROC) (void);
		typedef void (* PFNGLDEFORMATIONMAP3DSGIXPROC) (GLenum target, GLdouble u1, GLdouble u2, GLint ustride, GLint uorder, GLdouble v1, GLdouble v2, GLint vstride, GLint vorder, GLdouble w1, GLdouble w2, GLint wstride, GLint worder, const GLdouble *points);
		typedef void (* PFNGLDEFORMATIONMAP3FSGIXPROC) (GLenum target, GLfloat u1, GLfloat u2, GLint ustride, GLint uorder, GLfloat v1, GLfloat v2, GLint vstride, GLint vorder, GLfloat w1, GLfloat w2, GLint wstride, GLint worder, const GLfloat *points);
		typedef void (* PFNGLDEFORMSGIXPROC) (GLbitfield mask);
		typedef void (* PFNGLLOADIDENTITYDEFORMATIONMAPSGIXPROC) (GLbitfield mask);
		typedef void (* PFNGLREFERENCEPLANESGIXPROC) (const GLdouble *equation);
		typedef void (* PFNGLFLUSHRASTERSGIXPROC) (void);
		typedef void (* PFNGLFOGFUNCSGISPROC) (GLsizei n, const GLfloat *points);
		typedef void (* PFNGLGETFOGFUNCSGISPROC) (GLfloat *points);
		typedef void (* PFNGLIMAGETRANSFORMPARAMETERIHPPROC) (GLenum target, GLenum pname, GLint param);
		typedef void (* PFNGLIMAGETRANSFORMPARAMETERFHPPROC) (GLenum target, GLenum pname, GLfloat param);
		typedef void (* PFNGLIMAGETRANSFORMPARAMETERIVHPPROC) (GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLIMAGETRANSFORMPARAMETERFVHPPROC) (GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLGETIMAGETRANSFORMPARAMETERIVHPPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETIMAGETRANSFORMPARAMETERFVHPPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLCOLORSUBTABLEEXTPROC) (GLenum target, GLsizei start, GLsizei count, GLenum format, GLenum type, const GLvoid *data);
		typedef void (* PFNGLCOPYCOLORSUBTABLEEXTPROC) (GLenum target, GLsizei start, GLint x, GLint y, GLsizei width);
		typedef void (* PFNGLHINTPGIPROC) (GLenum target, GLint mode);
		typedef void (* PFNGLCOLORTABLEEXTPROC) (GLenum target, GLenum internalFormat, GLsizei width, GLenum format, GLenum type, const GLvoid *table);
		typedef void (* PFNGLGETCOLORTABLEEXTPROC) (GLenum target, GLenum format, GLenum type, GLvoid *data);
		typedef void (* PFNGLGETCOLORTABLEPARAMETERIVEXTPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETCOLORTABLEPARAMETERFVEXTPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETLISTPARAMETERFVSGIXPROC) (GLuint list, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETLISTPARAMETERIVSGIXPROC) (GLuint list, GLenum pname, GLint *params);
		typedef void (* PFNGLLISTPARAMETERFSGIXPROC) (GLuint list, GLenum pname, GLfloat param);
		typedef void (* PFNGLLISTPARAMETERFVSGIXPROC) (GLuint list, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLLISTPARAMETERISGIXPROC) (GLuint list, GLenum pname, GLint param);
		typedef void (* PFNGLLISTPARAMETERIVSGIXPROC) (GLuint list, GLenum pname, const GLint *params);
		typedef void (* PFNGLINDEXMATERIALEXTPROC) (GLenum face, GLenum mode);
		typedef void (* PFNGLINDEXFUNCEXTPROC) (GLenum func, GLclampf ref);
		typedef void (* PFNGLLOCKARRAYSEXTPROC) (GLint first, GLsizei count);
		typedef void (* PFNGLUNLOCKARRAYSEXTPROC) (void);
		typedef void (* PFNGLCULLPARAMETERDVEXTPROC) (GLenum pname, GLdouble *params);
		typedef void (* PFNGLCULLPARAMETERFVEXTPROC) (GLenum pname, GLfloat *params);
		typedef void (* PFNGLFRAGMENTCOLORMATERIALSGIXPROC) (GLenum face, GLenum mode);
		typedef void (* PFNGLFRAGMENTLIGHTFSGIXPROC) (GLenum light, GLenum pname, GLfloat param);
		typedef void (* PFNGLFRAGMENTLIGHTFVSGIXPROC) (GLenum light, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLFRAGMENTLIGHTISGIXPROC) (GLenum light, GLenum pname, GLint param);
		typedef void (* PFNGLFRAGMENTLIGHTIVSGIXPROC) (GLenum light, GLenum pname, const GLint *params);
		typedef void (* PFNGLFRAGMENTLIGHTMODELFSGIXPROC) (GLenum pname, GLfloat param);
		typedef void (* PFNGLFRAGMENTLIGHTMODELFVSGIXPROC) (GLenum pname, const GLfloat *params);
		typedef void (* PFNGLFRAGMENTLIGHTMODELISGIXPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLFRAGMENTLIGHTMODELIVSGIXPROC) (GLenum pname, const GLint *params);
		typedef void (* PFNGLFRAGMENTMATERIALFSGIXPROC) (GLenum face, GLenum pname, GLfloat param);
		typedef void (* PFNGLFRAGMENTMATERIALFVSGIXPROC) (GLenum face, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLFRAGMENTMATERIALISGIXPROC) (GLenum face, GLenum pname, GLint param);
		typedef void (* PFNGLFRAGMENTMATERIALIVSGIXPROC) (GLenum face, GLenum pname, const GLint *params);
		typedef void (* PFNGLGETFRAGMENTLIGHTFVSGIXPROC) (GLenum light, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETFRAGMENTLIGHTIVSGIXPROC) (GLenum light, GLenum pname, GLint *params);
		typedef void (* PFNGLGETFRAGMENTMATERIALFVSGIXPROC) (GLenum face, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETFRAGMENTMATERIALIVSGIXPROC) (GLenum face, GLenum pname, GLint *params);
		typedef void (* PFNGLLIGHTENVISGIXPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLDRAWRANGEELEMENTSEXTPROC) (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indices);
		typedef void (* PFNGLAPPLYTEXTUREEXTPROC) (GLenum mode);
		typedef void (* PFNGLTEXTURELIGHTEXTPROC) (GLenum pname);
		typedef void (* PFNGLTEXTUREMATERIALEXTPROC) (GLenum face, GLenum mode);
		typedef void (* PFNGLASYNCMARKERSGIXPROC) (GLuint marker);
		typedef GLint (* PFNGLFINISHASYNCSGIXPROC) (GLuint *markerp);
		typedef GLint (* PFNGLPOLLASYNCSGIXPROC) (GLuint *markerp);
		typedef GLuint (* PFNGLGENASYNCMARKERSSGIXPROC) (GLsizei range);
		typedef void (* PFNGLDELETEASYNCMARKERSSGIXPROC) (GLuint marker, GLsizei range);
		typedef GLboolean (* PFNGLISASYNCMARKERSGIXPROC) (GLuint marker);
		typedef void (* PFNGLVERTEXPOINTERVINTELPROC) (GLint size, GLenum type, const GLvoid* *pointer);
		typedef void (* PFNGLNORMALPOINTERVINTELPROC) (GLenum type, const GLvoid* *pointer);
		typedef void (* PFNGLCOLORPOINTERVINTELPROC) (GLint size, GLenum type, const GLvoid* *pointer);
		typedef void (* PFNGLTEXCOORDPOINTERVINTELPROC) (GLint size, GLenum type, const GLvoid* *pointer);
		typedef void (* PFNGLPIXELTRANSFORMPARAMETERIEXTPROC) (GLenum target, GLenum pname, GLint param);
		typedef void (* PFNGLPIXELTRANSFORMPARAMETERFEXTPROC) (GLenum target, GLenum pname, GLfloat param);
		typedef void (* PFNGLPIXELTRANSFORMPARAMETERIVEXTPROC) (GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLPIXELTRANSFORMPARAMETERFVEXTPROC) (GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLGETPIXELTRANSFORMPARAMETERIVEXTPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETPIXELTRANSFORMPARAMETERFVEXTPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLSECONDARYCOLOR3BEXTPROC) (GLbyte red, GLbyte green, GLbyte blue);
		typedef void (* PFNGLSECONDARYCOLOR3BVEXTPROC) (const GLbyte *v);
		typedef void (* PFNGLSECONDARYCOLOR3DEXTPROC) (GLdouble red, GLdouble green, GLdouble blue);
		typedef void (* PFNGLSECONDARYCOLOR3DVEXTPROC) (const GLdouble *v);
		typedef void (* PFNGLSECONDARYCOLOR3FEXTPROC) (GLfloat red, GLfloat green, GLfloat blue);
		typedef void (* PFNGLSECONDARYCOLOR3FVEXTPROC) (const GLfloat *v);
		typedef void (* PFNGLSECONDARYCOLOR3IEXTPROC) (GLint red, GLint green, GLint blue);
		typedef void (* PFNGLSECONDARYCOLOR3IVEXTPROC) (const GLint *v);
		typedef void (* PFNGLSECONDARYCOLOR3SEXTPROC) (GLshort red, GLshort green, GLshort blue);
		typedef void (* PFNGLSECONDARYCOLOR3SVEXTPROC) (const GLshort *v);
		typedef void (* PFNGLSECONDARYCOLOR3UBEXTPROC) (GLubyte red, GLubyte green, GLubyte blue);
		typedef void (* PFNGLSECONDARYCOLOR3UBVEXTPROC) (const GLubyte *v);
		typedef void (* PFNGLSECONDARYCOLOR3UIEXTPROC) (GLuint red, GLuint green, GLuint blue);
		typedef void (* PFNGLSECONDARYCOLOR3UIVEXTPROC) (const GLuint *v);
		typedef void (* PFNGLSECONDARYCOLOR3USEXTPROC) (GLushort red, GLushort green, GLushort blue);
		typedef void (* PFNGLSECONDARYCOLOR3USVEXTPROC) (const GLushort *v);
		typedef void (* PFNGLSECONDARYCOLORPOINTEREXTPROC) (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLTEXTURENORMALEXTPROC) (GLenum mode);
		typedef void (* PFNGLMULTIDRAWARRAYSEXTPROC) (GLenum mode, const GLint *first, const GLsizei *count, GLsizei primcount);
		typedef void (* PFNGLMULTIDRAWELEMENTSEXTPROC) (GLenum mode, const GLsizei *count, GLenum type, const GLvoid* *indices, GLsizei primcount);
		typedef void (* PFNGLFOGCOORDFEXTPROC) (GLfloat coord);
		typedef void (* PFNGLFOGCOORDFVEXTPROC) (const GLfloat *coord);
		typedef void (* PFNGLFOGCOORDDEXTPROC) (GLdouble coord);
		typedef void (* PFNGLFOGCOORDDVEXTPROC) (const GLdouble *coord);
		typedef void (* PFNGLFOGCOORDPOINTEREXTPROC) (GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLTANGENT3BEXTPROC) (GLbyte tx, GLbyte ty, GLbyte tz);
		typedef void (* PFNGLTANGENT3BVEXTPROC) (const GLbyte *v);
		typedef void (* PFNGLTANGENT3DEXTPROC) (GLdouble tx, GLdouble ty, GLdouble tz);
		typedef void (* PFNGLTANGENT3DVEXTPROC) (const GLdouble *v);
		typedef void (* PFNGLTANGENT3FEXTPROC) (GLfloat tx, GLfloat ty, GLfloat tz);
		typedef void (* PFNGLTANGENT3FVEXTPROC) (const GLfloat *v);
		typedef void (* PFNGLTANGENT3IEXTPROC) (GLint tx, GLint ty, GLint tz);
		typedef void (* PFNGLTANGENT3IVEXTPROC) (const GLint *v);
		typedef void (* PFNGLTANGENT3SEXTPROC) (GLshort tx, GLshort ty, GLshort tz);
		typedef void (* PFNGLTANGENT3SVEXTPROC) (const GLshort *v);
		typedef void (* PFNGLBINORMAL3BEXTPROC) (GLbyte bx, GLbyte by, GLbyte bz);
		typedef void (* PFNGLBINORMAL3BVEXTPROC) (const GLbyte *v);
		typedef void (* PFNGLBINORMAL3DEXTPROC) (GLdouble bx, GLdouble by, GLdouble bz);
		typedef void (* PFNGLBINORMAL3DVEXTPROC) (const GLdouble *v);
		typedef void (* PFNGLBINORMAL3FEXTPROC) (GLfloat bx, GLfloat by, GLfloat bz);
		typedef void (* PFNGLBINORMAL3FVEXTPROC) (const GLfloat *v);
		typedef void (* PFNGLBINORMAL3IEXTPROC) (GLint bx, GLint by, GLint bz);
		typedef void (* PFNGLBINORMAL3IVEXTPROC) (const GLint *v);
		typedef void (* PFNGLBINORMAL3SEXTPROC) (GLshort bx, GLshort by, GLshort bz);
		typedef void (* PFNGLBINORMAL3SVEXTPROC) (const GLshort *v);
		typedef void (* PFNGLTANGENTPOINTEREXTPROC) (GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLBINORMALPOINTEREXTPROC) (GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLFINISHTEXTURESUNXPROC) (void);
		typedef void (* PFNGLGLOBALALPHAFACTORBSUNPROC) (GLbyte factor);
		typedef void (* PFNGLGLOBALALPHAFACTORSSUNPROC) (GLshort factor);
		typedef void (* PFNGLGLOBALALPHAFACTORISUNPROC) (GLint factor);
		typedef void (* PFNGLGLOBALALPHAFACTORFSUNPROC) (GLfloat factor);
		typedef void (* PFNGLGLOBALALPHAFACTORDSUNPROC) (GLdouble factor);
		typedef void (* PFNGLGLOBALALPHAFACTORUBSUNPROC) (GLubyte factor);
		typedef void (* PFNGLGLOBALALPHAFACTORUSSUNPROC) (GLushort factor);
		typedef void (* PFNGLGLOBALALPHAFACTORUISUNPROC) (GLuint factor);
		typedef void (* PFNGLREPLACEMENTCODEUISUNPROC) (GLuint code);
		typedef void (* PFNGLREPLACEMENTCODEUSSUNPROC) (GLushort code);
		typedef void (* PFNGLREPLACEMENTCODEUBSUNPROC) (GLubyte code);
		typedef void (* PFNGLREPLACEMENTCODEUIVSUNPROC) (const GLuint *code);
		typedef void (* PFNGLREPLACEMENTCODEUSVSUNPROC) (const GLushort *code);
		typedef void (* PFNGLREPLACEMENTCODEUBVSUNPROC) (const GLubyte *code);
		typedef void (* PFNGLREPLACEMENTCODEPOINTERSUNPROC) (GLenum type, GLsizei stride, const GLvoid* *pointer);
		typedef void (* PFNGLCOLOR4UBVERTEX2FSUNPROC) (GLubyte r, GLubyte g, GLubyte b, GLubyte a, GLfloat x, GLfloat y);
		typedef void (* PFNGLCOLOR4UBVERTEX2FVSUNPROC) (const GLubyte *c, const GLfloat *v);
		typedef void (* PFNGLCOLOR4UBVERTEX3FSUNPROC) (GLubyte r, GLubyte g, GLubyte b, GLubyte a, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLCOLOR4UBVERTEX3FVSUNPROC) (const GLubyte *c, const GLfloat *v);
		typedef void (* PFNGLCOLOR3FVERTEX3FSUNPROC) (GLfloat r, GLfloat g, GLfloat b, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLCOLOR3FVERTEX3FVSUNPROC) (const GLfloat *c, const GLfloat *v);
		typedef void (* PFNGLNORMAL3FVERTEX3FSUNPROC) (GLfloat nx, GLfloat ny, GLfloat nz, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLNORMAL3FVERTEX3FVSUNPROC) (const GLfloat *n, const GLfloat *v);
		typedef void (* PFNGLCOLOR4FNORMAL3FVERTEX3FSUNPROC) (GLfloat r, GLfloat g, GLfloat b, GLfloat a, GLfloat nx, GLfloat ny, GLfloat nz, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLCOLOR4FNORMAL3FVERTEX3FVSUNPROC) (const GLfloat *c, const GLfloat *n, const GLfloat *v);
		typedef void (* PFNGLTEXCOORD2FVERTEX3FSUNPROC) (GLfloat s, GLfloat t, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLTEXCOORD2FVERTEX3FVSUNPROC) (const GLfloat *tc, const GLfloat *v);
		typedef void (* PFNGLTEXCOORD4FVERTEX4FSUNPROC) (GLfloat s, GLfloat t, GLfloat p, GLfloat q, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLTEXCOORD4FVERTEX4FVSUNPROC) (const GLfloat *tc, const GLfloat *v);
		typedef void (* PFNGLTEXCOORD2FCOLOR4UBVERTEX3FSUNPROC) (GLfloat s, GLfloat t, GLubyte r, GLubyte g, GLubyte b, GLubyte a, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLTEXCOORD2FCOLOR4UBVERTEX3FVSUNPROC) (const GLfloat *tc, const GLubyte *c, const GLfloat *v);
		typedef void (* PFNGLTEXCOORD2FCOLOR3FVERTEX3FSUNPROC) (GLfloat s, GLfloat t, GLfloat r, GLfloat g, GLfloat b, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLTEXCOORD2FCOLOR3FVERTEX3FVSUNPROC) (const GLfloat *tc, const GLfloat *c, const GLfloat *v);
		typedef void (* PFNGLTEXCOORD2FNORMAL3FVERTEX3FSUNPROC) (GLfloat s, GLfloat t, GLfloat nx, GLfloat ny, GLfloat nz, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLTEXCOORD2FNORMAL3FVERTEX3FVSUNPROC) (const GLfloat *tc, const GLfloat *n, const GLfloat *v);
		typedef void (* PFNGLTEXCOORD2FCOLOR4FNORMAL3FVERTEX3FSUNPROC) (GLfloat s, GLfloat t, GLfloat r, GLfloat g, GLfloat b, GLfloat a, GLfloat nx, GLfloat ny, GLfloat nz, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLTEXCOORD2FCOLOR4FNORMAL3FVERTEX3FVSUNPROC) (const GLfloat *tc, const GLfloat *c, const GLfloat *n, const GLfloat *v);
		typedef void (* PFNGLTEXCOORD4FCOLOR4FNORMAL3FVERTEX4FSUNPROC) (GLfloat s, GLfloat t, GLfloat p, GLfloat q, GLfloat r, GLfloat g, GLfloat b, GLfloat a, GLfloat nx, GLfloat ny, GLfloat nz, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLTEXCOORD4FCOLOR4FNORMAL3FVERTEX4FVSUNPROC) (const GLfloat *tc, const GLfloat *c, const GLfloat *n, const GLfloat *v);
		typedef void (* PFNGLREPLACEMENTCODEUIVERTEX3FSUNPROC) (GLuint rc, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLREPLACEMENTCODEUIVERTEX3FVSUNPROC) (const GLuint *rc, const GLfloat *v);
		typedef void (* PFNGLREPLACEMENTCODEUICOLOR4UBVERTEX3FSUNPROC) (GLuint rc, GLubyte r, GLubyte g, GLubyte b, GLubyte a, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLREPLACEMENTCODEUICOLOR4UBVERTEX3FVSUNPROC) (const GLuint *rc, const GLubyte *c, const GLfloat *v);
		typedef void (* PFNGLREPLACEMENTCODEUICOLOR3FVERTEX3FSUNPROC) (GLuint rc, GLfloat r, GLfloat g, GLfloat b, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLREPLACEMENTCODEUICOLOR3FVERTEX3FVSUNPROC) (const GLuint *rc, const GLfloat *c, const GLfloat *v);
		typedef void (* PFNGLREPLACEMENTCODEUINORMAL3FVERTEX3FSUNPROC) (GLuint rc, GLfloat nx, GLfloat ny, GLfloat nz, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLREPLACEMENTCODEUINORMAL3FVERTEX3FVSUNPROC) (const GLuint *rc, const GLfloat *n, const GLfloat *v);
		typedef void (* PFNGLREPLACEMENTCODEUICOLOR4FNORMAL3FVERTEX3FSUNPROC) (GLuint rc, GLfloat r, GLfloat g, GLfloat b, GLfloat a, GLfloat nx, GLfloat ny, GLfloat nz, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLREPLACEMENTCODEUICOLOR4FNORMAL3FVERTEX3FVSUNPROC) (const GLuint *rc, const GLfloat *c, const GLfloat *n, const GLfloat *v);
		typedef void (* PFNGLREPLACEMENTCODEUITEXCOORD2FVERTEX3FSUNPROC) (GLuint rc, GLfloat s, GLfloat t, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLREPLACEMENTCODEUITEXCOORD2FVERTEX3FVSUNPROC) (const GLuint *rc, const GLfloat *tc, const GLfloat *v);
		typedef void (* PFNGLREPLACEMENTCODEUITEXCOORD2FNORMAL3FVERTEX3FSUNPROC) (GLuint rc, GLfloat s, GLfloat t, GLfloat nx, GLfloat ny, GLfloat nz, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLREPLACEMENTCODEUITEXCOORD2FNORMAL3FVERTEX3FVSUNPROC) (const GLuint *rc, const GLfloat *tc, const GLfloat *n, const GLfloat *v);
		typedef void (* PFNGLREPLACEMENTCODEUITEXCOORD2FCOLOR4FNORMAL3FVERTEX3FSUNPROC) (GLuint rc, GLfloat s, GLfloat t, GLfloat r, GLfloat g, GLfloat b, GLfloat a, GLfloat nx, GLfloat ny, GLfloat nz, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLREPLACEMENTCODEUITEXCOORD2FCOLOR4FNORMAL3FVERTEX3FVSUNPROC) (const GLuint *rc, const GLfloat *tc, const GLfloat *c, const GLfloat *n, const GLfloat *v);
		typedef void (* PFNGLBLENDFUNCSEPARATEEXTPROC) (GLenum sfactorRGB, GLenum dfactorRGB, GLenum sfactorAlpha, GLenum dfactorAlpha);
		typedef void (* PFNGLBLENDFUNCSEPARATEINGRPROC) (GLenum sfactorRGB, GLenum dfactorRGB, GLenum sfactorAlpha, GLenum dfactorAlpha);
		typedef void (* PFNGLVERTEXWEIGHTFEXTPROC) (GLfloat weight);
		typedef void (* PFNGLVERTEXWEIGHTFVEXTPROC) (const GLfloat *weight);
		typedef void (* PFNGLVERTEXWEIGHTPOINTEREXTPROC) (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLFLUSHVERTEXARRAYRANGENVPROC) (void);
		typedef void (* PFNGLVERTEXARRAYRANGENVPROC) (GLsizei length, const GLvoid *pointer);
		typedef void (* PFNGLCOMBINERPARAMETERFVNVPROC) (GLenum pname, const GLfloat *params);
		typedef void (* PFNGLCOMBINERPARAMETERFNVPROC) (GLenum pname, GLfloat param);
		typedef void (* PFNGLCOMBINERPARAMETERIVNVPROC) (GLenum pname, const GLint *params);
		typedef void (* PFNGLCOMBINERPARAMETERINVPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLCOMBINERINPUTNVPROC) (GLenum stage, GLenum portion, GLenum variable, GLenum input, GLenum mapping, GLenum componentUsage);
		typedef void (* PFNGLCOMBINEROUTPUTNVPROC) (GLenum stage, GLenum portion, GLenum abOutput, GLenum cdOutput, GLenum sumOutput, GLenum scale, GLenum bias, GLboolean abDotProduct, GLboolean cdDotProduct, GLboolean muxSum);
		typedef void (* PFNGLFINALCOMBINERINPUTNVPROC) (GLenum variable, GLenum input, GLenum mapping, GLenum componentUsage);
		typedef void (* PFNGLGETCOMBINERINPUTPARAMETERFVNVPROC) (GLenum stage, GLenum portion, GLenum variable, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETCOMBINERINPUTPARAMETERIVNVPROC) (GLenum stage, GLenum portion, GLenum variable, GLenum pname, GLint *params);
		typedef void (* PFNGLGETCOMBINEROUTPUTPARAMETERFVNVPROC) (GLenum stage, GLenum portion, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETCOMBINEROUTPUTPARAMETERIVNVPROC) (GLenum stage, GLenum portion, GLenum pname, GLint *params);
		typedef void (* PFNGLGETFINALCOMBINERINPUTPARAMETERFVNVPROC) (GLenum variable, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETFINALCOMBINERINPUTPARAMETERIVNVPROC) (GLenum variable, GLenum pname, GLint *params);
		typedef void (* PFNGLRESIZEBUFFERSMESAPROC) (void);
		typedef void (* PFNGLWINDOWPOS2DMESAPROC) (GLdouble x, GLdouble y);
		typedef void (* PFNGLWINDOWPOS2DVMESAPROC) (const GLdouble *v);
		typedef void (* PFNGLWINDOWPOS2FMESAPROC) (GLfloat x, GLfloat y);
		typedef void (* PFNGLWINDOWPOS2FVMESAPROC) (const GLfloat *v);
		typedef void (* PFNGLWINDOWPOS2IMESAPROC) (GLint x, GLint y);
		typedef void (* PFNGLWINDOWPOS2IVMESAPROC) (const GLint *v);
		typedef void (* PFNGLWINDOWPOS2SMESAPROC) (GLshort x, GLshort y);
		typedef void (* PFNGLWINDOWPOS2SVMESAPROC) (const GLshort *v);
		typedef void (* PFNGLWINDOWPOS3DMESAPROC) (GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLWINDOWPOS3DVMESAPROC) (const GLdouble *v);
		typedef void (* PFNGLWINDOWPOS3FMESAPROC) (GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLWINDOWPOS3FVMESAPROC) (const GLfloat *v);
		typedef void (* PFNGLWINDOWPOS3IMESAPROC) (GLint x, GLint y, GLint z);
		typedef void (* PFNGLWINDOWPOS3IVMESAPROC) (const GLint *v);
		typedef void (* PFNGLWINDOWPOS3SMESAPROC) (GLshort x, GLshort y, GLshort z);
		typedef void (* PFNGLWINDOWPOS3SVMESAPROC) (const GLshort *v);
		typedef void (* PFNGLWINDOWPOS4DMESAPROC) (GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLWINDOWPOS4DVMESAPROC) (const GLdouble *v);
		typedef void (* PFNGLWINDOWPOS4FMESAPROC) (GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLWINDOWPOS4FVMESAPROC) (const GLfloat *v);
		typedef void (* PFNGLWINDOWPOS4IMESAPROC) (GLint x, GLint y, GLint z, GLint w);
		typedef void (* PFNGLWINDOWPOS4IVMESAPROC) (const GLint *v);
		typedef void (* PFNGLWINDOWPOS4SMESAPROC) (GLshort x, GLshort y, GLshort z, GLshort w);
		typedef void (* PFNGLWINDOWPOS4SVMESAPROC) (const GLshort *v);
		typedef void (* PFNGLMULTIMODEDRAWARRAYSIBMPROC) (const GLenum *mode, const GLint *first, const GLsizei *count, GLsizei primcount, GLint modestride);
		typedef void (* PFNGLMULTIMODEDRAWELEMENTSIBMPROC) (const GLenum *mode, const GLsizei *count, GLenum type, const GLvoid* const *indices, GLsizei primcount, GLint modestride);
		typedef void (* PFNGLCOLORPOINTERLISTIBMPROC) (GLint size, GLenum type, GLint stride, const GLvoid* *pointer, GLint ptrstride);
		typedef void (* PFNGLSECONDARYCOLORPOINTERLISTIBMPROC) (GLint size, GLenum type, GLint stride, const GLvoid* *pointer, GLint ptrstride);
		typedef void (* PFNGLEDGEFLAGPOINTERLISTIBMPROC) (GLint stride, const GLboolean* *pointer, GLint ptrstride);
		typedef void (* PFNGLFOGCOORDPOINTERLISTIBMPROC) (GLenum type, GLint stride, const GLvoid* *pointer, GLint ptrstride);
		typedef void (* PFNGLINDEXPOINTERLISTIBMPROC) (GLenum type, GLint stride, const GLvoid* *pointer, GLint ptrstride);
		typedef void (* PFNGLNORMALPOINTERLISTIBMPROC) (GLenum type, GLint stride, const GLvoid* *pointer, GLint ptrstride);
		typedef void (* PFNGLTEXCOORDPOINTERLISTIBMPROC) (GLint size, GLenum type, GLint stride, const GLvoid* *pointer, GLint ptrstride);
		typedef void (* PFNGLVERTEXPOINTERLISTIBMPROC) (GLint size, GLenum type, GLint stride, const GLvoid* *pointer, GLint ptrstride);
		typedef void (* PFNGLTBUFFERMASK3DFXPROC) (GLuint mask);
		typedef void (* PFNGLSAMPLEMASKEXTPROC) (GLclampf value, GLboolean invert);
		typedef void (* PFNGLSAMPLEPATTERNEXTPROC) (GLenum pattern);
		typedef void (* PFNGLTEXTURECOLORMASKSGISPROC) (GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
		typedef void (* PFNGLIGLOOINTERFACESGIXPROC) (GLenum pname, const GLvoid *params);
		typedef void (* PFNGLDELETEFENCESNVPROC) (GLsizei n, const GLuint *fences);
		typedef void (* PFNGLGENFENCESNVPROC) (GLsizei n, GLuint *fences);
		typedef GLboolean (* PFNGLISFENCENVPROC) (GLuint fence);
		typedef GLboolean (* PFNGLTESTFENCENVPROC) (GLuint fence);
		typedef void (* PFNGLGETFENCEIVNVPROC) (GLuint fence, GLenum pname, GLint *params);
		typedef void (* PFNGLFINISHFENCENVPROC) (GLuint fence);
		typedef void (* PFNGLSETFENCENVPROC) (GLuint fence, GLenum condition);
		typedef void (* PFNGLMAPCONTROLPOINTSNVPROC) (GLenum target, GLuint index, GLenum type, GLsizei ustride, GLsizei vstride, GLint uorder, GLint vorder, GLboolean packed, const GLvoid *points);
		typedef void (* PFNGLMAPPARAMETERIVNVPROC) (GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLMAPPARAMETERFVNVPROC) (GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLGETMAPCONTROLPOINTSNVPROC) (GLenum target, GLuint index, GLenum type, GLsizei ustride, GLsizei vstride, GLboolean packed, GLvoid *points);
		typedef void (* PFNGLGETMAPPARAMETERIVNVPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETMAPPARAMETERFVNVPROC) (GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETMAPATTRIBPARAMETERIVNVPROC) (GLenum target, GLuint index, GLenum pname, GLint *params);
		typedef void (* PFNGLGETMAPATTRIBPARAMETERFVNVPROC) (GLenum target, GLuint index, GLenum pname, GLfloat *params);
		typedef void (* PFNGLEVALMAPSNVPROC) (GLenum target, GLenum mode);
		typedef void (* PFNGLCOMBINERSTAGEPARAMETERFVNVPROC) (GLenum stage, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLGETCOMBINERSTAGEPARAMETERFVNVPROC) (GLenum stage, GLenum pname, GLfloat *params);
		typedef GLboolean (* PFNGLAREPROGRAMSRESIDENTNVPROC) (GLsizei n, const GLuint *programs, GLboolean *residences);
		typedef void (* PFNGLBINDPROGRAMNVPROC) (GLenum target, GLuint id);
		typedef void (* PFNGLDELETEPROGRAMSNVPROC) (GLsizei n, const GLuint *programs);
		typedef void (* PFNGLEXECUTEPROGRAMNVPROC) (GLenum target, GLuint id, const GLfloat *params);
		typedef void (* PFNGLGENPROGRAMSNVPROC) (GLsizei n, GLuint *programs);
		typedef void (* PFNGLGETPROGRAMPARAMETERDVNVPROC) (GLenum target, GLuint index, GLenum pname, GLdouble *params);
		typedef void (* PFNGLGETPROGRAMPARAMETERFVNVPROC) (GLenum target, GLuint index, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETPROGRAMIVNVPROC) (GLuint id, GLenum pname, GLint *params);
		typedef void (* PFNGLGETPROGRAMSTRINGNVPROC) (GLuint id, GLenum pname, GLubyte *program);
		typedef void (* PFNGLGETTRACKMATRIXIVNVPROC) (GLenum target, GLuint address, GLenum pname, GLint *params);
		typedef void (* PFNGLGETVERTEXATTRIBDVNVPROC) (GLuint index, GLenum pname, GLdouble *params);
		typedef void (* PFNGLGETVERTEXATTRIBFVNVPROC) (GLuint index, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETVERTEXATTRIBIVNVPROC) (GLuint index, GLenum pname, GLint *params);
		typedef void (* PFNGLGETVERTEXATTRIBPOINTERVNVPROC) (GLuint index, GLenum pname, GLvoid* *pointer);
		typedef GLboolean (* PFNGLISPROGRAMNVPROC) (GLuint id);
		typedef void (* PFNGLLOADPROGRAMNVPROC) (GLenum target, GLuint id, GLsizei len, const GLubyte *program);
		typedef void (* PFNGLPROGRAMPARAMETER4DNVPROC) (GLenum target, GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLPROGRAMPARAMETER4DVNVPROC) (GLenum target, GLuint index, const GLdouble *v);
		typedef void (* PFNGLPROGRAMPARAMETER4FNVPROC) (GLenum target, GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLPROGRAMPARAMETER4FVNVPROC) (GLenum target, GLuint index, const GLfloat *v);
		typedef void (* PFNGLPROGRAMPARAMETERS4DVNVPROC) (GLenum target, GLuint index, GLsizei count, const GLdouble *v);
		typedef void (* PFNGLPROGRAMPARAMETERS4FVNVPROC) (GLenum target, GLuint index, GLsizei count, const GLfloat *v);
		typedef void (* PFNGLREQUESTRESIDENTPROGRAMSNVPROC) (GLsizei n, const GLuint *programs);
		typedef void (* PFNGLTRACKMATRIXNVPROC) (GLenum target, GLuint address, GLenum matrix, GLenum transform);
		typedef void (* PFNGLVERTEXATTRIBPOINTERNVPROC) (GLuint index, GLint fsize, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLVERTEXATTRIB1DNVPROC) (GLuint index, GLdouble x);
		typedef void (* PFNGLVERTEXATTRIB1DVNVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB1FNVPROC) (GLuint index, GLfloat x);
		typedef void (* PFNGLVERTEXATTRIB1FVNVPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB1SNVPROC) (GLuint index, GLshort x);
		typedef void (* PFNGLVERTEXATTRIB1SVNVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB2DNVPROC) (GLuint index, GLdouble x, GLdouble y);
		typedef void (* PFNGLVERTEXATTRIB2DVNVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB2FNVPROC) (GLuint index, GLfloat x, GLfloat y);
		typedef void (* PFNGLVERTEXATTRIB2FVNVPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB2SNVPROC) (GLuint index, GLshort x, GLshort y);
		typedef void (* PFNGLVERTEXATTRIB2SVNVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB3DNVPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLVERTEXATTRIB3DVNVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB3FNVPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLVERTEXATTRIB3FVNVPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB3SNVPROC) (GLuint index, GLshort x, GLshort y, GLshort z);
		typedef void (* PFNGLVERTEXATTRIB3SVNVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB4DNVPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLVERTEXATTRIB4DVNVPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIB4FNVPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLVERTEXATTRIB4FVNVPROC) (GLuint index, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIB4SNVPROC) (GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
		typedef void (* PFNGLVERTEXATTRIB4SVNVPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIB4UBNVPROC) (GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
		typedef void (* PFNGLVERTEXATTRIB4UBVNVPROC) (GLuint index, const GLubyte *v);
		typedef void (* PFNGLVERTEXATTRIBS1DVNVPROC) (GLuint index, GLsizei count, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBS1FVNVPROC) (GLuint index, GLsizei count, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIBS1SVNVPROC) (GLuint index, GLsizei count, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIBS2DVNVPROC) (GLuint index, GLsizei count, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBS2FVNVPROC) (GLuint index, GLsizei count, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIBS2SVNVPROC) (GLuint index, GLsizei count, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIBS3DVNVPROC) (GLuint index, GLsizei count, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBS3FVNVPROC) (GLuint index, GLsizei count, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIBS3SVNVPROC) (GLuint index, GLsizei count, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIBS4DVNVPROC) (GLuint index, GLsizei count, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBS4FVNVPROC) (GLuint index, GLsizei count, const GLfloat *v);
		typedef void (* PFNGLVERTEXATTRIBS4SVNVPROC) (GLuint index, GLsizei count, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIBS4UBVNVPROC) (GLuint index, GLsizei count, const GLubyte *v);
		typedef void (* PFNGLTEXBUMPPARAMETERIVATIPROC) (GLenum pname, const GLint *param);
		typedef void (* PFNGLTEXBUMPPARAMETERFVATIPROC) (GLenum pname, const GLfloat *param);
		typedef void (* PFNGLGETTEXBUMPPARAMETERIVATIPROC) (GLenum pname, GLint *param);
		typedef void (* PFNGLGETTEXBUMPPARAMETERFVATIPROC) (GLenum pname, GLfloat *param);
		typedef GLuint (* PFNGLGENFRAGMENTSHADERSATIPROC) (GLuint range);
		typedef void (* PFNGLBINDFRAGMENTSHADERATIPROC) (GLuint id);
		typedef void (* PFNGLDELETEFRAGMENTSHADERATIPROC) (GLuint id);
		typedef void (* PFNGLBEGINFRAGMENTSHADERATIPROC) (void);
		typedef void (* PFNGLENDFRAGMENTSHADERATIPROC) (void);
		typedef void (* PFNGLPASSTEXCOORDATIPROC) (GLuint dst, GLuint coord, GLenum swizzle);
		typedef void (* PFNGLSAMPLEMAPATIPROC) (GLuint dst, GLuint interp, GLenum swizzle);
		typedef void (* PFNGLCOLORFRAGMENTOP1ATIPROC) (GLenum op, GLuint dst, GLuint dstMask, GLuint dstMod, GLuint arg1, GLuint arg1Rep, GLuint arg1Mod);
		typedef void (* PFNGLCOLORFRAGMENTOP2ATIPROC) (GLenum op, GLuint dst, GLuint dstMask, GLuint dstMod, GLuint arg1, GLuint arg1Rep, GLuint arg1Mod, GLuint arg2, GLuint arg2Rep, GLuint arg2Mod);
		typedef void (* PFNGLCOLORFRAGMENTOP3ATIPROC) (GLenum op, GLuint dst, GLuint dstMask, GLuint dstMod, GLuint arg1, GLuint arg1Rep, GLuint arg1Mod, GLuint arg2, GLuint arg2Rep, GLuint arg2Mod, GLuint arg3, GLuint arg3Rep, GLuint arg3Mod);
		typedef void (* PFNGLALPHAFRAGMENTOP1ATIPROC) (GLenum op, GLuint dst, GLuint dstMod, GLuint arg1, GLuint arg1Rep, GLuint arg1Mod);
		typedef void (* PFNGLALPHAFRAGMENTOP2ATIPROC) (GLenum op, GLuint dst, GLuint dstMod, GLuint arg1, GLuint arg1Rep, GLuint arg1Mod, GLuint arg2, GLuint arg2Rep, GLuint arg2Mod);
		typedef void (* PFNGLALPHAFRAGMENTOP3ATIPROC) (GLenum op, GLuint dst, GLuint dstMod, GLuint arg1, GLuint arg1Rep, GLuint arg1Mod, GLuint arg2, GLuint arg2Rep, GLuint arg2Mod, GLuint arg3, GLuint arg3Rep, GLuint arg3Mod);
		typedef void (* PFNGLSETFRAGMENTSHADERCONSTANTATIPROC) (GLuint dst, const GLfloat *value);
		typedef void (* PFNGLPNTRIANGLESIATIPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLPNTRIANGLESFATIPROC) (GLenum pname, GLfloat param);
		typedef GLuint (* PFNGLNEWOBJECTBUFFERATIPROC) (GLsizei size, const GLvoid *pointer, GLenum usage);
		typedef GLboolean (* PFNGLISOBJECTBUFFERATIPROC) (GLuint buffer);
		typedef void (* PFNGLUPDATEOBJECTBUFFERATIPROC) (GLuint buffer, GLuint offset, GLsizei size, const GLvoid *pointer, GLenum preserve);
		typedef void (* PFNGLGETOBJECTBUFFERFVATIPROC) (GLuint buffer, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETOBJECTBUFFERIVATIPROC) (GLuint buffer, GLenum pname, GLint *params);
		typedef void (* PFNGLFREEOBJECTBUFFERATIPROC) (GLuint buffer);
		typedef void (* PFNGLARRAYOBJECTATIPROC) (GLenum array, GLint size, GLenum type, GLsizei stride, GLuint buffer, GLuint offset);
		typedef void (* PFNGLGETARRAYOBJECTFVATIPROC) (GLenum array, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETARRAYOBJECTIVATIPROC) (GLenum array, GLenum pname, GLint *params);
		typedef void (* PFNGLVARIANTARRAYOBJECTATIPROC) (GLuint id, GLenum type, GLsizei stride, GLuint buffer, GLuint offset);
		typedef void (* PFNGLGETVARIANTARRAYOBJECTFVATIPROC) (GLuint id, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETVARIANTARRAYOBJECTIVATIPROC) (GLuint id, GLenum pname, GLint *params);
		typedef void (* PFNGLBEGINVERTEXSHADEREXTPROC) (void);
		typedef void (* PFNGLENDVERTEXSHADEREXTPROC) (void);
		typedef void (* PFNGLBINDVERTEXSHADEREXTPROC) (GLuint id);
		typedef GLuint (* PFNGLGENVERTEXSHADERSEXTPROC) (GLuint range);
		typedef void (* PFNGLDELETEVERTEXSHADEREXTPROC) (GLuint id);
		typedef void (* PFNGLSHADEROP1EXTPROC) (GLenum op, GLuint res, GLuint arg1);
		typedef void (* PFNGLSHADEROP2EXTPROC) (GLenum op, GLuint res, GLuint arg1, GLuint arg2);
		typedef void (* PFNGLSHADEROP3EXTPROC) (GLenum op, GLuint res, GLuint arg1, GLuint arg2, GLuint arg3);
		typedef void (* PFNGLSWIZZLEEXTPROC) (GLuint res, GLuint in, GLenum outX, GLenum outY, GLenum outZ, GLenum outW);
		typedef void (* PFNGLWRITEMASKEXTPROC) (GLuint res, GLuint in, GLenum outX, GLenum outY, GLenum outZ, GLenum outW);
		typedef void (* PFNGLINSERTCOMPONENTEXTPROC) (GLuint res, GLuint src, GLuint num);
		typedef void (* PFNGLEXTRACTCOMPONENTEXTPROC) (GLuint res, GLuint src, GLuint num);
		typedef GLuint (* PFNGLGENSYMBOLSEXTPROC) (GLenum datatype, GLenum storagetype, GLenum range, GLuint components);
		typedef void (* PFNGLSETINVARIANTEXTPROC) (GLuint id, GLenum type, const GLvoid *addr);
		typedef void (* PFNGLSETLOCALCONSTANTEXTPROC) (GLuint id, GLenum type, const GLvoid *addr);
		typedef void (* PFNGLVARIANTBVEXTPROC) (GLuint id, const GLbyte *addr);
		typedef void (* PFNGLVARIANTSVEXTPROC) (GLuint id, const GLshort *addr);
		typedef void (* PFNGLVARIANTIVEXTPROC) (GLuint id, const GLint *addr);
		typedef void (* PFNGLVARIANTFVEXTPROC) (GLuint id, const GLfloat *addr);
		typedef void (* PFNGLVARIANTDVEXTPROC) (GLuint id, const GLdouble *addr);
		typedef void (* PFNGLVARIANTUBVEXTPROC) (GLuint id, const GLubyte *addr);
		typedef void (* PFNGLVARIANTUSVEXTPROC) (GLuint id, const GLushort *addr);
		typedef void (* PFNGLVARIANTUIVEXTPROC) (GLuint id, const GLuint *addr);
		typedef void (* PFNGLVARIANTPOINTEREXTPROC) (GLuint id, GLenum type, GLuint stride, const GLvoid *addr);
		typedef void (* PFNGLENABLEVARIANTCLIENTSTATEEXTPROC) (GLuint id);
		typedef void (* PFNGLDISABLEVARIANTCLIENTSTATEEXTPROC) (GLuint id);
		typedef GLuint (* PFNGLBINDLIGHTPARAMETEREXTPROC) (GLenum light, GLenum value);
		typedef GLuint (* PFNGLBINDMATERIALPARAMETEREXTPROC) (GLenum face, GLenum value);
		typedef GLuint (* PFNGLBINDTEXGENPARAMETEREXTPROC) (GLenum unit, GLenum coord, GLenum value);
		typedef GLuint (* PFNGLBINDTEXTUREUNITPARAMETEREXTPROC) (GLenum unit, GLenum value);
		typedef GLuint (* PFNGLBINDPARAMETEREXTPROC) (GLenum value);
		typedef GLboolean (* PFNGLISVARIANTENABLEDEXTPROC) (GLuint id, GLenum cap);
		typedef void (* PFNGLGETVARIANTBOOLEANVEXTPROC) (GLuint id, GLenum value, GLboolean *data);
		typedef void (* PFNGLGETVARIANTINTEGERVEXTPROC) (GLuint id, GLenum value, GLint *data);
		typedef void (* PFNGLGETVARIANTFLOATVEXTPROC) (GLuint id, GLenum value, GLfloat *data);
		typedef void (* PFNGLGETVARIANTPOINTERVEXTPROC) (GLuint id, GLenum value, GLvoid* *data);
		typedef void (* PFNGLGETINVARIANTBOOLEANVEXTPROC) (GLuint id, GLenum value, GLboolean *data);
		typedef void (* PFNGLGETINVARIANTINTEGERVEXTPROC) (GLuint id, GLenum value, GLint *data);
		typedef void (* PFNGLGETINVARIANTFLOATVEXTPROC) (GLuint id, GLenum value, GLfloat *data);
		typedef void (* PFNGLGETLOCALCONSTANTBOOLEANVEXTPROC) (GLuint id, GLenum value, GLboolean *data);
		typedef void (* PFNGLGETLOCALCONSTANTINTEGERVEXTPROC) (GLuint id, GLenum value, GLint *data);
		typedef void (* PFNGLGETLOCALCONSTANTFLOATVEXTPROC) (GLuint id, GLenum value, GLfloat *data);
		typedef void (* PFNGLVERTEXSTREAM1SATIPROC) (GLenum stream, GLshort x);
		typedef void (* PFNGLVERTEXSTREAM1SVATIPROC) (GLenum stream, const GLshort *coords);
		typedef void (* PFNGLVERTEXSTREAM1IATIPROC) (GLenum stream, GLint x);
		typedef void (* PFNGLVERTEXSTREAM1IVATIPROC) (GLenum stream, const GLint *coords);
		typedef void (* PFNGLVERTEXSTREAM1FATIPROC) (GLenum stream, GLfloat x);
		typedef void (* PFNGLVERTEXSTREAM1FVATIPROC) (GLenum stream, const GLfloat *coords);
		typedef void (* PFNGLVERTEXSTREAM1DATIPROC) (GLenum stream, GLdouble x);
		typedef void (* PFNGLVERTEXSTREAM1DVATIPROC) (GLenum stream, const GLdouble *coords);
		typedef void (* PFNGLVERTEXSTREAM2SATIPROC) (GLenum stream, GLshort x, GLshort y);
		typedef void (* PFNGLVERTEXSTREAM2SVATIPROC) (GLenum stream, const GLshort *coords);
		typedef void (* PFNGLVERTEXSTREAM2IATIPROC) (GLenum stream, GLint x, GLint y);
		typedef void (* PFNGLVERTEXSTREAM2IVATIPROC) (GLenum stream, const GLint *coords);
		typedef void (* PFNGLVERTEXSTREAM2FATIPROC) (GLenum stream, GLfloat x, GLfloat y);
		typedef void (* PFNGLVERTEXSTREAM2FVATIPROC) (GLenum stream, const GLfloat *coords);
		typedef void (* PFNGLVERTEXSTREAM2DATIPROC) (GLenum stream, GLdouble x, GLdouble y);
		typedef void (* PFNGLVERTEXSTREAM2DVATIPROC) (GLenum stream, const GLdouble *coords);
		typedef void (* PFNGLVERTEXSTREAM3SATIPROC) (GLenum stream, GLshort x, GLshort y, GLshort z);
		typedef void (* PFNGLVERTEXSTREAM3SVATIPROC) (GLenum stream, const GLshort *coords);
		typedef void (* PFNGLVERTEXSTREAM3IATIPROC) (GLenum stream, GLint x, GLint y, GLint z);
		typedef void (* PFNGLVERTEXSTREAM3IVATIPROC) (GLenum stream, const GLint *coords);
		typedef void (* PFNGLVERTEXSTREAM3FATIPROC) (GLenum stream, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLVERTEXSTREAM3FVATIPROC) (GLenum stream, const GLfloat *coords);
		typedef void (* PFNGLVERTEXSTREAM3DATIPROC) (GLenum stream, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLVERTEXSTREAM3DVATIPROC) (GLenum stream, const GLdouble *coords);
		typedef void (* PFNGLVERTEXSTREAM4SATIPROC) (GLenum stream, GLshort x, GLshort y, GLshort z, GLshort w);
		typedef void (* PFNGLVERTEXSTREAM4SVATIPROC) (GLenum stream, const GLshort *coords);
		typedef void (* PFNGLVERTEXSTREAM4IATIPROC) (GLenum stream, GLint x, GLint y, GLint z, GLint w);
		typedef void (* PFNGLVERTEXSTREAM4IVATIPROC) (GLenum stream, const GLint *coords);
		typedef void (* PFNGLVERTEXSTREAM4FATIPROC) (GLenum stream, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLVERTEXSTREAM4FVATIPROC) (GLenum stream, const GLfloat *coords);
		typedef void (* PFNGLVERTEXSTREAM4DATIPROC) (GLenum stream, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLVERTEXSTREAM4DVATIPROC) (GLenum stream, const GLdouble *coords);
		typedef void (* PFNGLNORMALSTREAM3BATIPROC) (GLenum stream, GLbyte nx, GLbyte ny, GLbyte nz);
		typedef void (* PFNGLNORMALSTREAM3BVATIPROC) (GLenum stream, const GLbyte *coords);
		typedef void (* PFNGLNORMALSTREAM3SATIPROC) (GLenum stream, GLshort nx, GLshort ny, GLshort nz);
		typedef void (* PFNGLNORMALSTREAM3SVATIPROC) (GLenum stream, const GLshort *coords);
		typedef void (* PFNGLNORMALSTREAM3IATIPROC) (GLenum stream, GLint nx, GLint ny, GLint nz);
		typedef void (* PFNGLNORMALSTREAM3IVATIPROC) (GLenum stream, const GLint *coords);
		typedef void (* PFNGLNORMALSTREAM3FATIPROC) (GLenum stream, GLfloat nx, GLfloat ny, GLfloat nz);
		typedef void (* PFNGLNORMALSTREAM3FVATIPROC) (GLenum stream, const GLfloat *coords);
		typedef void (* PFNGLNORMALSTREAM3DATIPROC) (GLenum stream, GLdouble nx, GLdouble ny, GLdouble nz);
		typedef void (* PFNGLNORMALSTREAM3DVATIPROC) (GLenum stream, const GLdouble *coords);
		typedef void (* PFNGLCLIENTACTIVEVERTEXSTREAMATIPROC) (GLenum stream);
		typedef void (* PFNGLVERTEXBLENDENVIATIPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLVERTEXBLENDENVFATIPROC) (GLenum pname, GLfloat param);
		typedef void (* PFNGLELEMENTPOINTERATIPROC) (GLenum type, const GLvoid *pointer);
		typedef void (* PFNGLDRAWELEMENTARRAYATIPROC) (GLenum mode, GLsizei count);
		typedef void (* PFNGLDRAWRANGEELEMENTARRAYATIPROC) (GLenum mode, GLuint start, GLuint end, GLsizei count);
		typedef void (* PFNGLDRAWMESHARRAYSSUNPROC) (GLenum mode, GLint first, GLsizei count, GLsizei width);
		typedef void (* PFNGLGENOCCLUSIONQUERIESNVPROC) (GLsizei n, GLuint *ids);
		typedef void (* PFNGLDELETEOCCLUSIONQUERIESNVPROC) (GLsizei n, const GLuint *ids);
		typedef GLboolean (* PFNGLISOCCLUSIONQUERYNVPROC) (GLuint id);
		typedef void (* PFNGLBEGINOCCLUSIONQUERYNVPROC) (GLuint id);
		typedef void (* PFNGLENDOCCLUSIONQUERYNVPROC) (void);
		typedef void (* PFNGLGETOCCLUSIONQUERYIVNVPROC) (GLuint id, GLenum pname, GLint *params);
		typedef void (* PFNGLGETOCCLUSIONQUERYUIVNVPROC) (GLuint id, GLenum pname, GLuint *params);
		typedef void (* PFNGLPOINTPARAMETERINVPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLPOINTPARAMETERIVNVPROC) (GLenum pname, const GLint *params);
		typedef void (* PFNGLACTIVESTENCILFACEEXTPROC) (GLenum face);
		typedef void (* PFNGLELEMENTPOINTERAPPLEPROC) (GLenum type, const GLvoid *pointer);
		typedef void (* PFNGLDRAWELEMENTARRAYAPPLEPROC) (GLenum mode, GLint first, GLsizei count);
		typedef void (* PFNGLDRAWRANGEELEMENTARRAYAPPLEPROC) (GLenum mode, GLuint start, GLuint end, GLint first, GLsizei count);
		typedef void (* PFNGLMULTIDRAWELEMENTARRAYAPPLEPROC) (GLenum mode, const GLint *first, const GLsizei *count, GLsizei primcount);
		typedef void (* PFNGLMULTIDRAWRANGEELEMENTARRAYAPPLEPROC) (GLenum mode, GLuint start, GLuint end, const GLint *first, const GLsizei *count, GLsizei primcount);
		typedef void (* PFNGLGENFENCESAPPLEPROC) (GLsizei n, GLuint *fences);
		typedef void (* PFNGLDELETEFENCESAPPLEPROC) (GLsizei n, const GLuint *fences);
		typedef void (* PFNGLSETFENCEAPPLEPROC) (GLuint fence);
		typedef GLboolean (* PFNGLISFENCEAPPLEPROC) (GLuint fence);
		typedef GLboolean (* PFNGLTESTFENCEAPPLEPROC) (GLuint fence);
		typedef void (* PFNGLFINISHFENCEAPPLEPROC) (GLuint fence);
		typedef GLboolean (* PFNGLTESTOBJECTAPPLEPROC) (GLenum object, GLuint name);
		typedef void (* PFNGLFINISHOBJECTAPPLEPROC) (GLenum object, GLint name);
		typedef void (* PFNGLBINDVERTEXARRAYAPPLEPROC) (GLuint array);
		typedef void (* PFNGLDELETEVERTEXARRAYSAPPLEPROC) (GLsizei n, const GLuint *arrays);
		typedef void (* PFNGLGENVERTEXARRAYSAPPLEPROC) (GLsizei n, GLuint *arrays);
		typedef GLboolean (* PFNGLISVERTEXARRAYAPPLEPROC) (GLuint array);
		typedef void (* PFNGLVERTEXARRAYRANGEAPPLEPROC) (GLsizei length, GLvoid *pointer);
		typedef void (* PFNGLFLUSHVERTEXARRAYRANGEAPPLEPROC) (GLsizei length, GLvoid *pointer);
		typedef void (* PFNGLVERTEXARRAYPARAMETERIAPPLEPROC) (GLenum pname, GLint param);
		typedef void (* PFNGLDRAWBUFFERSATIPROC) (GLsizei n, const GLenum *bufs);
		typedef void (* PFNGLPROGRAMNAMEDPARAMETER4FNVPROC) (GLuint id, GLsizei len, const GLubyte *name, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLPROGRAMNAMEDPARAMETER4FVNVPROC) (GLuint id, GLsizei len, const GLubyte *name, const GLfloat *v);
		typedef void (* PFNGLPROGRAMNAMEDPARAMETER4DNVPROC) (GLuint id, GLsizei len, const GLubyte *name, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLPROGRAMNAMEDPARAMETER4DVNVPROC) (GLuint id, GLsizei len, const GLubyte *name, const GLdouble *v);
		typedef void (* PFNGLGETPROGRAMNAMEDPARAMETERFVNVPROC) (GLuint id, GLsizei len, const GLubyte *name, GLfloat *params);
		typedef void (* PFNGLGETPROGRAMNAMEDPARAMETERDVNVPROC) (GLuint id, GLsizei len, const GLubyte *name, GLdouble *params);
		typedef void (* PFNGLVERTEX2HNVPROC) (GLhalfNV x, GLhalfNV y);
		typedef void (* PFNGLVERTEX2HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLVERTEX3HNVPROC) (GLhalfNV x, GLhalfNV y, GLhalfNV z);
		typedef void (* PFNGLVERTEX3HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLVERTEX4HNVPROC) (GLhalfNV x, GLhalfNV y, GLhalfNV z, GLhalfNV w);
		typedef void (* PFNGLVERTEX4HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLNORMAL3HNVPROC) (GLhalfNV nx, GLhalfNV ny, GLhalfNV nz);
		typedef void (* PFNGLNORMAL3HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLCOLOR3HNVPROC) (GLhalfNV red, GLhalfNV green, GLhalfNV blue);
		typedef void (* PFNGLCOLOR3HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLCOLOR4HNVPROC) (GLhalfNV red, GLhalfNV green, GLhalfNV blue, GLhalfNV alpha);
		typedef void (* PFNGLCOLOR4HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLTEXCOORD1HNVPROC) (GLhalfNV s);
		typedef void (* PFNGLTEXCOORD1HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLTEXCOORD2HNVPROC) (GLhalfNV s, GLhalfNV t);
		typedef void (* PFNGLTEXCOORD2HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLTEXCOORD3HNVPROC) (GLhalfNV s, GLhalfNV t, GLhalfNV r);
		typedef void (* PFNGLTEXCOORD3HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLTEXCOORD4HNVPROC) (GLhalfNV s, GLhalfNV t, GLhalfNV r, GLhalfNV q);
		typedef void (* PFNGLTEXCOORD4HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLMULTITEXCOORD1HNVPROC) (GLenum target, GLhalfNV s);
		typedef void (* PFNGLMULTITEXCOORD1HVNVPROC) (GLenum target, const GLhalfNV *v);
		typedef void (* PFNGLMULTITEXCOORD2HNVPROC) (GLenum target, GLhalfNV s, GLhalfNV t);
		typedef void (* PFNGLMULTITEXCOORD2HVNVPROC) (GLenum target, const GLhalfNV *v);
		typedef void (* PFNGLMULTITEXCOORD3HNVPROC) (GLenum target, GLhalfNV s, GLhalfNV t, GLhalfNV r);
		typedef void (* PFNGLMULTITEXCOORD3HVNVPROC) (GLenum target, const GLhalfNV *v);
		typedef void (* PFNGLMULTITEXCOORD4HNVPROC) (GLenum target, GLhalfNV s, GLhalfNV t, GLhalfNV r, GLhalfNV q);
		typedef void (* PFNGLMULTITEXCOORD4HVNVPROC) (GLenum target, const GLhalfNV *v);
		typedef void (* PFNGLFOGCOORDHNVPROC) (GLhalfNV fog);
		typedef void (* PFNGLFOGCOORDHVNVPROC) (const GLhalfNV *fog);
		typedef void (* PFNGLSECONDARYCOLOR3HNVPROC) (GLhalfNV red, GLhalfNV green, GLhalfNV blue);
		typedef void (* PFNGLSECONDARYCOLOR3HVNVPROC) (const GLhalfNV *v);
		typedef void (* PFNGLVERTEXWEIGHTHNVPROC) (GLhalfNV weight);
		typedef void (* PFNGLVERTEXWEIGHTHVNVPROC) (const GLhalfNV *weight);
		typedef void (* PFNGLVERTEXATTRIB1HNVPROC) (GLuint index, GLhalfNV x);
		typedef void (* PFNGLVERTEXATTRIB1HVNVPROC) (GLuint index, const GLhalfNV *v);
		typedef void (* PFNGLVERTEXATTRIB2HNVPROC) (GLuint index, GLhalfNV x, GLhalfNV y);
		typedef void (* PFNGLVERTEXATTRIB2HVNVPROC) (GLuint index, const GLhalfNV *v);
		typedef void (* PFNGLVERTEXATTRIB3HNVPROC) (GLuint index, GLhalfNV x, GLhalfNV y, GLhalfNV z);
		typedef void (* PFNGLVERTEXATTRIB3HVNVPROC) (GLuint index, const GLhalfNV *v);
		typedef void (* PFNGLVERTEXATTRIB4HNVPROC) (GLuint index, GLhalfNV x, GLhalfNV y, GLhalfNV z, GLhalfNV w);
		typedef void (* PFNGLVERTEXATTRIB4HVNVPROC) (GLuint index, const GLhalfNV *v);
		typedef void (* PFNGLVERTEXATTRIBS1HVNVPROC) (GLuint index, GLsizei n, const GLhalfNV *v);
		typedef void (* PFNGLVERTEXATTRIBS2HVNVPROC) (GLuint index, GLsizei n, const GLhalfNV *v);
		typedef void (* PFNGLVERTEXATTRIBS3HVNVPROC) (GLuint index, GLsizei n, const GLhalfNV *v);
		typedef void (* PFNGLVERTEXATTRIBS4HVNVPROC) (GLuint index, GLsizei n, const GLhalfNV *v);
		typedef void (* PFNGLPIXELDATARANGENVPROC) (GLenum target, GLsizei length, const GLvoid *pointer);
		typedef void (* PFNGLFLUSHPIXELDATARANGENVPROC) (GLenum target);
		typedef void (* PFNGLPRIMITIVERESTARTNVPROC) (void);
		typedef void (* PFNGLPRIMITIVERESTARTINDEXNVPROC) (GLuint index);
		typedef GLvoid* (* PFNGLMAPOBJECTBUFFERATIPROC) (GLuint buffer);
		typedef void (* PFNGLUNMAPOBJECTBUFFERATIPROC) (GLuint buffer);
		typedef void (* PFNGLSTENCILOPSEPARATEATIPROC) (GLenum face, GLenum sfail, GLenum dpfail, GLenum dppass);
		typedef void (* PFNGLSTENCILFUNCSEPARATEATIPROC) (GLenum frontfunc, GLenum backfunc, GLint ref, GLuint mask);
		typedef void (* PFNGLVERTEXATTRIBARRAYOBJECTATIPROC) (GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, GLuint buffer, GLuint offset);
		typedef void (* PFNGLGETVERTEXATTRIBARRAYOBJECTFVATIPROC) (GLuint index, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETVERTEXATTRIBARRAYOBJECTIVATIPROC) (GLuint index, GLenum pname, GLint *params);
		typedef void (* PFNGLMULTITEXCOORD1BOESPROC) (GLenum texture, GLbyte s);
		typedef void (* PFNGLMULTITEXCOORD1BVOESPROC) (GLenum texture, const GLbyte *coords);
		typedef void (* PFNGLMULTITEXCOORD2BOESPROC) (GLenum texture, GLbyte s, GLbyte t);
		typedef void (* PFNGLMULTITEXCOORD2BVOESPROC) (GLenum texture, const GLbyte *coords);
		typedef void (* PFNGLMULTITEXCOORD3BOESPROC) (GLenum texture, GLbyte s, GLbyte t, GLbyte r);
		typedef void (* PFNGLMULTITEXCOORD3BVOESPROC) (GLenum texture, const GLbyte *coords);
		typedef void (* PFNGLMULTITEXCOORD4BOESPROC) (GLenum texture, GLbyte s, GLbyte t, GLbyte r, GLbyte q);
		typedef void (* PFNGLMULTITEXCOORD4BVOESPROC) (GLenum texture, const GLbyte *coords);
		typedef void (* PFNGLTEXCOORD1BOESPROC) (GLbyte s);
		typedef void (* PFNGLTEXCOORD1BVOESPROC) (const GLbyte *coords);
		typedef void (* PFNGLTEXCOORD2BOESPROC) (GLbyte s, GLbyte t);
		typedef void (* PFNGLTEXCOORD2BVOESPROC) (const GLbyte *coords);
		typedef void (* PFNGLTEXCOORD3BOESPROC) (GLbyte s, GLbyte t, GLbyte r);
		typedef void (* PFNGLTEXCOORD3BVOESPROC) (const GLbyte *coords);
		typedef void (* PFNGLTEXCOORD4BOESPROC) (GLbyte s, GLbyte t, GLbyte r, GLbyte q);
		typedef void (* PFNGLTEXCOORD4BVOESPROC) (const GLbyte *coords);
		typedef void (* PFNGLVERTEX2BOESPROC) (GLbyte x);
		typedef void (* PFNGLVERTEX2BVOESPROC) (const GLbyte *coords);
		typedef void (* PFNGLVERTEX3BOESPROC) (GLbyte x, GLbyte y);
		typedef void (* PFNGLVERTEX3BVOESPROC) (const GLbyte *coords);
		typedef void (* PFNGLVERTEX4BOESPROC) (GLbyte x, GLbyte y, GLbyte z);
		typedef void (* PFNGLVERTEX4BVOESPROC) (const GLbyte *coords);
		typedef void (* PFNGLACCUMXOESPROC) (GLenum op, GLfixed value);
		typedef void (* PFNGLALPHAFUNCXOESPROC) (GLenum func, GLfixed ref);
		typedef void (* PFNGLBITMAPXOESPROC) (GLsizei width, GLsizei height, GLfixed xorig, GLfixed yorig, GLfixed xmove, GLfixed ymove, const GLubyte *bitmap);
		typedef void (* PFNGLBLENDCOLORXOESPROC) (GLfixed red, GLfixed green, GLfixed blue, GLfixed alpha);
		typedef void (* PFNGLCLEARACCUMXOESPROC) (GLfixed red, GLfixed green, GLfixed blue, GLfixed alpha);
		typedef void (* PFNGLCLEARCOLORXOESPROC) (GLfixed red, GLfixed green, GLfixed blue, GLfixed alpha);
		typedef void (* PFNGLCLEARDEPTHXOESPROC) (GLfixed depth);
		typedef void (* PFNGLCLIPPLANEXOESPROC) (GLenum plane, const GLfixed *equation);
		typedef void (* PFNGLCOLOR3XOESPROC) (GLfixed red, GLfixed green, GLfixed blue);
		typedef void (* PFNGLCOLOR4XOESPROC) (GLfixed red, GLfixed green, GLfixed blue, GLfixed alpha);
		typedef void (* PFNGLCOLOR3XVOESPROC) (const GLfixed *components);
		typedef void (* PFNGLCOLOR4XVOESPROC) (const GLfixed *components);
		typedef void (* PFNGLCONVOLUTIONPARAMETERXOESPROC) (GLenum target, GLenum pname, GLfixed param);
		typedef void (* PFNGLCONVOLUTIONPARAMETERXVOESPROC) (GLenum target, GLenum pname, const GLfixed *params);
		typedef void (* PFNGLDEPTHRANGEXOESPROC) (GLfixed n, GLfixed f);
		typedef void (* PFNGLEVALCOORD1XOESPROC) (GLfixed u);
		typedef void (* PFNGLEVALCOORD2XOESPROC) (GLfixed u, GLfixed v);
		typedef void (* PFNGLEVALCOORD1XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLEVALCOORD2XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLFEEDBACKBUFFERXOESPROC) (GLsizei n, GLenum type, const GLfixed *buffer);
		typedef void (* PFNGLFOGXOESPROC) (GLenum pname, GLfixed param);
		typedef void (* PFNGLFOGXVOESPROC) (GLenum pname, const GLfixed *param);
		typedef void (* PFNGLFRUSTUMXOESPROC) (GLfixed l, GLfixed r, GLfixed b, GLfixed t, GLfixed n, GLfixed f);
		typedef void (* PFNGLGETCLIPPLANEXOESPROC) (GLenum plane, GLfixed *equation);
		typedef void (* PFNGLGETCONVOLUTIONPARAMETERXVOESPROC) (GLenum target, GLenum pname, GLfixed *params);
		typedef void (* PFNGLGETFIXEDVOESPROC) (GLenum pname, GLfixed *params);
		typedef void (* PFNGLGETHISTOGRAMPARAMETERXVOESPROC) (GLenum target, GLenum pname, GLfixed *params);
		typedef void (* PFNGLGETLIGHTXOESPROC) (GLenum light, GLenum pname, GLfixed *params);
		typedef void (* PFNGLGETMAPXVOESPROC) (GLenum target, GLenum query, GLfixed *v);
		typedef void (* PFNGLGETMATERIALXOESPROC) (GLenum face, GLenum pname, GLfixed param);
		typedef void (* PFNGLGETPIXELMAPXVPROC) (GLenum map, GLint size, GLfixed *values);
		typedef void (* PFNGLGETTEXENVXVOESPROC) (GLenum target, GLenum pname, GLfixed *params);
		typedef void (* PFNGLGETTEXGENXVOESPROC) (GLenum coord, GLenum pname, GLfixed *params);
		typedef void (* PFNGLGETTEXLEVELPARAMETERXVOESPROC) (GLenum target, GLint level, GLenum pname, GLfixed *params);
		typedef void (* PFNGLGETTEXPARAMETERXVOESPROC) (GLenum target, GLenum pname, GLfixed *params);
		typedef void (* PFNGLINDEXXOESPROC) (GLfixed component);
		typedef void (* PFNGLINDEXXVOESPROC) (const GLfixed *component);
		typedef void (* PFNGLLIGHTMODELXOESPROC) (GLenum pname, GLfixed param);
		typedef void (* PFNGLLIGHTMODELXVOESPROC) (GLenum pname, const GLfixed *param);
		typedef void (* PFNGLLIGHTXOESPROC) (GLenum light, GLenum pname, GLfixed param);
		typedef void (* PFNGLLIGHTXVOESPROC) (GLenum light, GLenum pname, const GLfixed *params);
		typedef void (* PFNGLLINEWIDTHXOESPROC) (GLfixed width);
		typedef void (* PFNGLLOADMATRIXXOESPROC) (const GLfixed *m);
		typedef void (* PFNGLLOADTRANSPOSEMATRIXXOESPROC) (const GLfixed *m);
		typedef void (* PFNGLMAP1XOESPROC) (GLenum target, GLfixed u1, GLfixed u2, GLint stride, GLint order, GLfixed points);
		typedef void (* PFNGLMAP2XOESPROC) (GLenum target, GLfixed u1, GLfixed u2, GLint ustride, GLint uorder, GLfixed v1, GLfixed v2, GLint vstride, GLint vorder, GLfixed points);
		typedef void (* PFNGLMAPGRID1XOESPROC) (GLint n, GLfixed u1, GLfixed u2);
		typedef void (* PFNGLMAPGRID2XOESPROC) (GLint n, GLfixed u1, GLfixed u2, GLfixed v1, GLfixed v2);
		typedef void (* PFNGLMATERIALXOESPROC) (GLenum face, GLenum pname, GLfixed param);
		typedef void (* PFNGLMATERIALXVOESPROC) (GLenum face, GLenum pname, const GLfixed *param);
		typedef void (* PFNGLMULTMATRIXXOESPROC) (const GLfixed *m);
		typedef void (* PFNGLMULTTRANSPOSEMATRIXXOESPROC) (const GLfixed *m);
		typedef void (* PFNGLMULTITEXCOORD1XOESPROC) (GLenum texture, GLfixed s);
		typedef void (* PFNGLMULTITEXCOORD2XOESPROC) (GLenum texture, GLfixed s, GLfixed t);
		typedef void (* PFNGLMULTITEXCOORD3XOESPROC) (GLenum texture, GLfixed s, GLfixed t, GLfixed r);
		typedef void (* PFNGLMULTITEXCOORD4XOESPROC) (GLenum texture, GLfixed s, GLfixed t, GLfixed r, GLfixed q);
		typedef void (* PFNGLMULTITEXCOORD1XVOESPROC) (GLenum texture, const GLfixed *coords);
		typedef void (* PFNGLMULTITEXCOORD2XVOESPROC) (GLenum texture, const GLfixed *coords);
		typedef void (* PFNGLMULTITEXCOORD3XVOESPROC) (GLenum texture, const GLfixed *coords);
		typedef void (* PFNGLMULTITEXCOORD4XVOESPROC) (GLenum texture, const GLfixed *coords);
		typedef void (* PFNGLNORMAL3XOESPROC) (GLfixed nx, GLfixed ny, GLfixed nz);
		typedef void (* PFNGLNORMAL3XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLORTHOXOESPROC) (GLfixed l, GLfixed r, GLfixed b, GLfixed t, GLfixed n, GLfixed f);
		typedef void (* PFNGLPASSTHROUGHXOESPROC) (GLfixed token);
		typedef void (* PFNGLPIXELMAPXPROC) (GLenum map, GLint size, const GLfixed *values);
		typedef void (* PFNGLPIXELSTOREXPROC) (GLenum pname, GLfixed param);
		typedef void (* PFNGLPIXELTRANSFERXOESPROC) (GLenum pname, GLfixed param);
		typedef void (* PFNGLPIXELZOOMXOESPROC) (GLfixed xfactor, GLfixed yfactor);
		typedef void (* PFNGLPOINTPARAMETERXVOESPROC) (GLenum pname, const GLfixed *params);
		typedef void (* PFNGLPOINTSIZEXOESPROC) (GLfixed size);
		typedef void (* PFNGLPOLYGONOFFSETXOESPROC) (GLfixed factor, GLfixed units);
		typedef void (* PFNGLPRIORITIZETEXTURESXOESPROC) (GLsizei n, const GLuint *textures, const GLfixed *priorities);
		typedef void (* PFNGLRASTERPOS2XOESPROC) (GLfixed x, GLfixed y);
		typedef void (* PFNGLRASTERPOS3XOESPROC) (GLfixed x, GLfixed y, GLfixed z);
		typedef void (* PFNGLRASTERPOS4XOESPROC) (GLfixed x, GLfixed y, GLfixed z, GLfixed w);
		typedef void (* PFNGLRASTERPOS2XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLRASTERPOS3XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLRASTERPOS4XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLRECTXOESPROC) (GLfixed x1, GLfixed y1, GLfixed x2, GLfixed y2);
		typedef void (* PFNGLRECTXVOESPROC) (const GLfixed *v1, const GLfixed *v2);
		typedef void (* PFNGLROTATEXOESPROC) (GLfixed angle, GLfixed x, GLfixed y, GLfixed z);
		typedef void (* PFNGLSAMPLECOVERAGEOESPROC) (GLfixed value, GLboolean invert);
		typedef void (* PFNGLSCALEXOESPROC) (GLfixed x, GLfixed y, GLfixed z);
		typedef void (* PFNGLTEXCOORD1XOESPROC) (GLfixed s);
		typedef void (* PFNGLTEXCOORD2XOESPROC) (GLfixed s, GLfixed t);
		typedef void (* PFNGLTEXCOORD3XOESPROC) (GLfixed s, GLfixed t, GLfixed r);
		typedef void (* PFNGLTEXCOORD4XOESPROC) (GLfixed s, GLfixed t, GLfixed r, GLfixed q);
		typedef void (* PFNGLTEXCOORD1XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLTEXCOORD2XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLTEXCOORD3XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLTEXCOORD4XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLTEXENVXOESPROC) (GLenum target, GLenum pname, GLfixed param);
		typedef void (* PFNGLTEXENVXVOESPROC) (GLenum target, GLenum pname, const GLfixed *params);
		typedef void (* PFNGLTEXGENXOESPROC) (GLenum coord, GLenum pname, GLfixed param);
		typedef void (* PFNGLTEXGENXVOESPROC) (GLenum coord, GLenum pname, const GLfixed *params);
		typedef void (* PFNGLTEXPARAMETERXOESPROC) (GLenum target, GLenum pname, GLfixed param);
		typedef void (* PFNGLTEXPARAMETERXVOESPROC) (GLenum target, GLenum pname, const GLfixed *params);
		typedef void (* PFNGLTRANSLATEXOESPROC) (GLfixed x, GLfixed y, GLfixed z);
		typedef void (* PFNGLVERTEX2XOESPROC) (GLfixed x);
		typedef void (* PFNGLVERTEX3XOESPROC) (GLfixed x, GLfixed y);
		typedef void (* PFNGLVERTEX4XOESPROC) (GLfixed x, GLfixed y, GLfixed z);
		typedef void (* PFNGLVERTEX2XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLVERTEX3XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLVERTEX4XVOESPROC) (const GLfixed *coords);
		typedef void (* PFNGLDEPTHRANGEFOESPROC) (GLclampf n, GLclampf f);
		typedef void (* PFNGLFRUSTUMFOESPROC) (GLfloat l, GLfloat r, GLfloat b, GLfloat t, GLfloat n, GLfloat f);
		typedef void (* PFNGLORTHOFOESPROC) (GLfloat l, GLfloat r, GLfloat b, GLfloat t, GLfloat n, GLfloat f);
		typedef void (* PFNGLCLIPPLANEFOESPROC) (GLenum plane, const GLfloat *equation);
		typedef void (* PFNGLCLEARDEPTHFOESPROC) (GLclampd depth);
		typedef void (* PFNGLGETCLIPPLANEFOESPROC) (GLenum plane, GLfloat *equation);
		typedef GLbitfield (* PFNGLQUERYMATRIXXOESPROC) (const GLfixed *mantissa, const GLint *exponent);
		typedef void (* PFNGLDEPTHBOUNDSEXTPROC) (GLclampd zmin, GLclampd zmax);
		typedef void (* PFNGLBLENDEQUATIONSEPARATEEXTPROC) (GLenum modeRGB, GLenum modeAlpha);
		typedef GLboolean (* PFNGLISRENDERBUFFEREXTPROC) (GLuint renderbuffer);
		typedef void (* PFNGLBINDRENDERBUFFEREXTPROC) (GLenum target, GLuint renderbuffer);
		typedef void (* PFNGLDELETERENDERBUFFERSEXTPROC) (GLsizei n, const GLuint *renderbuffers);
		typedef void (* PFNGLGENRENDERBUFFERSEXTPROC) (GLsizei n, GLuint *renderbuffers);
		typedef void (* PFNGLRENDERBUFFERSTORAGEEXTPROC) (GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLGETRENDERBUFFERPARAMETERIVEXTPROC) (GLenum target, GLenum pname, GLint *params);
		typedef GLboolean (* PFNGLISFRAMEBUFFEREXTPROC) (GLuint framebuffer);
		typedef void (* PFNGLBINDFRAMEBUFFEREXTPROC) (GLenum target, GLuint framebuffer);
		typedef void (* PFNGLDELETEFRAMEBUFFERSEXTPROC) (GLsizei n, const GLuint *framebuffers);
		typedef void (* PFNGLGENFRAMEBUFFERSEXTPROC) (GLsizei n, GLuint *framebuffers);
		typedef GLenum (* PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC) (GLenum target);
		typedef void (* PFNGLFRAMEBUFFERTEXTURE1DEXTPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
		typedef void (* PFNGLFRAMEBUFFERTEXTURE2DEXTPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
		typedef void (* PFNGLFRAMEBUFFERTEXTURE3DEXTPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset);
		typedef void (* PFNGLFRAMEBUFFERRENDERBUFFEREXTPROC) (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
		typedef void (* PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVEXTPROC) (GLenum target, GLenum attachment, GLenum pname, GLint *params);
		typedef void (* PFNGLGENERATEMIPMAPEXTPROC) (GLenum target);
		typedef void (* PFNGLSTRINGMARKERGREMEDYPROC) (GLsizei len, const GLvoid *string);
		typedef void (* PFNGLSTENCILCLEARTAGEXTPROC) (GLsizei stencilTagBits, GLuint stencilClearTag);
		typedef void (* PFNGLBLITFRAMEBUFFEREXTPROC) (GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
		typedef void (* PFNGLRENDERBUFFERSTORAGEMULTISAMPLEEXTPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLGETQUERYOBJECTI64VEXTPROC) (GLuint id, GLenum pname, GLint64EXT *params);
		typedef void (* PFNGLGETQUERYOBJECTUI64VEXTPROC) (GLuint id, GLenum pname, GLuint64EXT *params);
		typedef void (* PFNGLPROGRAMENVPARAMETERS4FVEXTPROC) (GLenum target, GLuint index, GLsizei count, const GLfloat *params);
		typedef void (* PFNGLPROGRAMLOCALPARAMETERS4FVEXTPROC) (GLenum target, GLuint index, GLsizei count, const GLfloat *params);
		typedef void (* PFNGLBUFFERPARAMETERIAPPLEPROC) (GLenum target, GLenum pname, GLint param);
		typedef void (* PFNGLFLUSHMAPPEDBUFFERRANGEAPPLEPROC) (GLenum target, GLintptr offset, GLsizeiptr size);
		typedef void (* PFNGLPROGRAMLOCALPARAMETERI4INVPROC) (GLenum target, GLuint index, GLint x, GLint y, GLint z, GLint w);
		typedef void (* PFNGLPROGRAMLOCALPARAMETERI4IVNVPROC) (GLenum target, GLuint index, const GLint *params);
		typedef void (* PFNGLPROGRAMLOCALPARAMETERSI4IVNVPROC) (GLenum target, GLuint index, GLsizei count, const GLint *params);
		typedef void (* PFNGLPROGRAMLOCALPARAMETERI4UINVPROC) (GLenum target, GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
		typedef void (* PFNGLPROGRAMLOCALPARAMETERI4UIVNVPROC) (GLenum target, GLuint index, const GLuint *params);
		typedef void (* PFNGLPROGRAMLOCALPARAMETERSI4UIVNVPROC) (GLenum target, GLuint index, GLsizei count, const GLuint *params);
		typedef void (* PFNGLPROGRAMENVPARAMETERI4INVPROC) (GLenum target, GLuint index, GLint x, GLint y, GLint z, GLint w);
		typedef void (* PFNGLPROGRAMENVPARAMETERI4IVNVPROC) (GLenum target, GLuint index, const GLint *params);
		typedef void (* PFNGLPROGRAMENVPARAMETERSI4IVNVPROC) (GLenum target, GLuint index, GLsizei count, const GLint *params);
		typedef void (* PFNGLPROGRAMENVPARAMETERI4UINVPROC) (GLenum target, GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
		typedef void (* PFNGLPROGRAMENVPARAMETERI4UIVNVPROC) (GLenum target, GLuint index, const GLuint *params);
		typedef void (* PFNGLPROGRAMENVPARAMETERSI4UIVNVPROC) (GLenum target, GLuint index, GLsizei count, const GLuint *params);
		typedef void (* PFNGLGETPROGRAMLOCALPARAMETERIIVNVPROC) (GLenum target, GLuint index, GLint *params);
		typedef void (* PFNGLGETPROGRAMLOCALPARAMETERIUIVNVPROC) (GLenum target, GLuint index, GLuint *params);
		typedef void (* PFNGLGETPROGRAMENVPARAMETERIIVNVPROC) (GLenum target, GLuint index, GLint *params);
		typedef void (* PFNGLGETPROGRAMENVPARAMETERIUIVNVPROC) (GLenum target, GLuint index, GLuint *params);
		typedef void (* PFNGLPROGRAMVERTEXLIMITNVPROC) (GLenum target, GLint limit);
		typedef void (* PFNGLFRAMEBUFFERTEXTUREEXTPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level);
		typedef void (* PFNGLFRAMEBUFFERTEXTURELAYEREXTPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);
		typedef void (* PFNGLFRAMEBUFFERTEXTUREFACEEXTPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level, GLenum face);
		typedef void (* PFNGLPROGRAMPARAMETERIEXTPROC) (GLuint program, GLenum pname, GLint value);
		typedef void (* PFNGLVERTEXATTRIBI1IEXTPROC) (GLuint index, GLint x);
		typedef void (* PFNGLVERTEXATTRIBI2IEXTPROC) (GLuint index, GLint x, GLint y);
		typedef void (* PFNGLVERTEXATTRIBI3IEXTPROC) (GLuint index, GLint x, GLint y, GLint z);
		typedef void (* PFNGLVERTEXATTRIBI4IEXTPROC) (GLuint index, GLint x, GLint y, GLint z, GLint w);
		typedef void (* PFNGLVERTEXATTRIBI1UIEXTPROC) (GLuint index, GLuint x);
		typedef void (* PFNGLVERTEXATTRIBI2UIEXTPROC) (GLuint index, GLuint x, GLuint y);
		typedef void (* PFNGLVERTEXATTRIBI3UIEXTPROC) (GLuint index, GLuint x, GLuint y, GLuint z);
		typedef void (* PFNGLVERTEXATTRIBI4UIEXTPROC) (GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
		typedef void (* PFNGLVERTEXATTRIBI1IVEXTPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIBI2IVEXTPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIBI3IVEXTPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIBI4IVEXTPROC) (GLuint index, const GLint *v);
		typedef void (* PFNGLVERTEXATTRIBI1UIVEXTPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIBI2UIVEXTPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIBI3UIVEXTPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIBI4UIVEXTPROC) (GLuint index, const GLuint *v);
		typedef void (* PFNGLVERTEXATTRIBI4BVEXTPROC) (GLuint index, const GLbyte *v);
		typedef void (* PFNGLVERTEXATTRIBI4SVEXTPROC) (GLuint index, const GLshort *v);
		typedef void (* PFNGLVERTEXATTRIBI4UBVEXTPROC) (GLuint index, const GLubyte *v);
		typedef void (* PFNGLVERTEXATTRIBI4USVEXTPROC) (GLuint index, const GLushort *v);
		typedef void (* PFNGLVERTEXATTRIBIPOINTEREXTPROC) (GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLGETVERTEXATTRIBIIVEXTPROC) (GLuint index, GLenum pname, GLint *params);
		typedef void (* PFNGLGETVERTEXATTRIBIUIVEXTPROC) (GLuint index, GLenum pname, GLuint *params);
		typedef void (* PFNGLGETUNIFORMUIVEXTPROC) (GLuint program, GLint location, GLuint *params);
		typedef void (* PFNGLBINDFRAGDATALOCATIONEXTPROC) (GLuint program, GLuint color, const GLchar *name);
		typedef GLint (* PFNGLGETFRAGDATALOCATIONEXTPROC) (GLuint program, const GLchar *name);
		typedef void (* PFNGLUNIFORM1UIEXTPROC) (GLint location, GLuint v0);
		typedef void (* PFNGLUNIFORM2UIEXTPROC) (GLint location, GLuint v0, GLuint v1);
		typedef void (* PFNGLUNIFORM3UIEXTPROC) (GLint location, GLuint v0, GLuint v1, GLuint v2);
		typedef void (* PFNGLUNIFORM4UIEXTPROC) (GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
		typedef void (* PFNGLUNIFORM1UIVEXTPROC) (GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLUNIFORM2UIVEXTPROC) (GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLUNIFORM3UIVEXTPROC) (GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLUNIFORM4UIVEXTPROC) (GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLDRAWARRAYSINSTANCEDEXTPROC) (GLenum mode, GLint start, GLsizei count, GLsizei primcount);
		typedef void (* PFNGLDRAWELEMENTSINSTANCEDEXTPROC) (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLsizei primcount);
		typedef void (* PFNGLTEXBUFFEREXTPROC) (GLenum target, GLenum internalformat, GLuint buffer);
		typedef void (* PFNGLDEPTHRANGEDNVPROC) (GLdouble zNear, GLdouble zFar);
		typedef void (* PFNGLCLEARDEPTHDNVPROC) (GLdouble depth);
		typedef void (* PFNGLDEPTHBOUNDSDNVPROC) (GLdouble zmin, GLdouble zmax);
		typedef void (* PFNGLRENDERBUFFERSTORAGEMULTISAMPLECOVERAGENVPROC) (GLenum target, GLsizei coverageSamples, GLsizei colorSamples, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLPROGRAMBUFFERPARAMETERSFVNVPROC) (GLenum target, GLuint bindingIndex, GLuint wordIndex, GLsizei count, const GLfloat *params);
		typedef void (* PFNGLPROGRAMBUFFERPARAMETERSIIVNVPROC) (GLenum target, GLuint bindingIndex, GLuint wordIndex, GLsizei count, const GLint *params);
		typedef void (* PFNGLPROGRAMBUFFERPARAMETERSIUIVNVPROC) (GLenum target, GLuint bindingIndex, GLuint wordIndex, GLsizei count, const GLuint *params);
		typedef void (* PFNGLCOLORMASKINDEXEDEXTPROC) (GLuint index, GLboolean r, GLboolean g, GLboolean b, GLboolean a);
		typedef void (* PFNGLGETBOOLEANINDEXEDVEXTPROC) (GLenum target, GLuint index, GLboolean *data);
		typedef void (* PFNGLGETINTEGERINDEXEDVEXTPROC) (GLenum target, GLuint index, GLint *data);
		typedef void (* PFNGLENABLEINDEXEDEXTPROC) (GLenum target, GLuint index);
		typedef void (* PFNGLDISABLEINDEXEDEXTPROC) (GLenum target, GLuint index);
		typedef GLboolean (* PFNGLISENABLEDINDEXEDEXTPROC) (GLenum target, GLuint index);
		typedef void (* PFNGLBEGINTRANSFORMFEEDBACKNVPROC) (GLenum primitiveMode);
		typedef void (* PFNGLENDTRANSFORMFEEDBACKNVPROC) (void);
		typedef void (* PFNGLTRANSFORMFEEDBACKATTRIBSNVPROC) (GLuint count, const GLint *attribs, GLenum bufferMode);
		typedef void (* PFNGLBINDBUFFERRANGENVPROC) (GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
		typedef void (* PFNGLBINDBUFFEROFFSETNVPROC) (GLenum target, GLuint index, GLuint buffer, GLintptr offset);
		typedef void (* PFNGLBINDBUFFERBASENVPROC) (GLenum target, GLuint index, GLuint buffer);
		typedef void (* PFNGLTRANSFORMFEEDBACKVARYINGSNVPROC) (GLuint program, GLsizei count, const GLint *locations, GLenum bufferMode);
		typedef void (* PFNGLACTIVEVARYINGNVPROC) (GLuint program, const GLchar *name);
		typedef GLint (* PFNGLGETVARYINGLOCATIONNVPROC) (GLuint program, const GLchar *name);
		typedef void (* PFNGLGETACTIVEVARYINGNVPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLsizei *size, GLenum *type, GLchar *name);
		typedef void (* PFNGLGETTRANSFORMFEEDBACKVARYINGNVPROC) (GLuint program, GLuint index, GLint *location);
		typedef void (* PFNGLTRANSFORMFEEDBACKSTREAMATTRIBSNVPROC) (GLsizei count, const GLint *attribs, GLsizei nbuffers, const GLint *bufstreams, GLenum bufferMode);
		typedef void (* PFNGLUNIFORMBUFFEREXTPROC) (GLuint program, GLint location, GLuint buffer);
		typedef GLint (* PFNGLGETUNIFORMBUFFERSIZEEXTPROC) (GLuint program, GLint location);
		typedef GLintptr (* PFNGLGETUNIFORMOFFSETEXTPROC) (GLuint program, GLint location);
		typedef void (* PFNGLTEXPARAMETERIIVEXTPROC) (GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLTEXPARAMETERIUIVEXTPROC) (GLenum target, GLenum pname, const GLuint *params);
		typedef void (* PFNGLGETTEXPARAMETERIIVEXTPROC) (GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETTEXPARAMETERIUIVEXTPROC) (GLenum target, GLenum pname, GLuint *params);
		typedef void (* PFNGLCLEARCOLORIIEXTPROC) (GLint red, GLint green, GLint blue, GLint alpha);
		typedef void (* PFNGLCLEARCOLORIUIEXTPROC) (GLuint red, GLuint green, GLuint blue, GLuint alpha);
		typedef void (* PFNGLFRAMETERMINATORGREMEDYPROC) (void);
		typedef void (* PFNGLBEGINCONDITIONALRENDERNVPROC) (GLuint id, GLenum mode);
		typedef void (* PFNGLENDCONDITIONALRENDERNVPROC) (void);
		typedef void (* PFNGLPRESENTFRAMEKEYEDNVPROC) (GLuint video_slot, GLuint64EXT minPresentTime, GLuint beginPresentTimeId, GLuint presentDurationId, GLenum type, GLenum target0, GLuint fill0, GLuint key0, GLenum target1, GLuint fill1, GLuint key1);
		typedef void (* PFNGLPRESENTFRAMEDUALFILLNVPROC) (GLuint video_slot, GLuint64EXT minPresentTime, GLuint beginPresentTimeId, GLuint presentDurationId, GLenum type, GLenum target0, GLuint fill0, GLenum target1, GLuint fill1, GLenum target2, GLuint fill2, GLenum target3, GLuint fill3);
		typedef void (* PFNGLGETVIDEOIVNVPROC) (GLuint video_slot, GLenum pname, GLint *params);
		typedef void (* PFNGLGETVIDEOUIVNVPROC) (GLuint video_slot, GLenum pname, GLuint *params);
		typedef void (* PFNGLGETVIDEOI64VNVPROC) (GLuint video_slot, GLenum pname, GLint64EXT *params);
		typedef void (* PFNGLGETVIDEOUI64VNVPROC) (GLuint video_slot, GLenum pname, GLuint64EXT *params);
		typedef void (* PFNGLBEGINTRANSFORMFEEDBACKEXTPROC) (GLenum primitiveMode);
		typedef void (* PFNGLENDTRANSFORMFEEDBACKEXTPROC) (void);
		typedef void (* PFNGLBINDBUFFERRANGEEXTPROC) (GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
		typedef void (* PFNGLBINDBUFFEROFFSETEXTPROC) (GLenum target, GLuint index, GLuint buffer, GLintptr offset);
		typedef void (* PFNGLBINDBUFFERBASEEXTPROC) (GLenum target, GLuint index, GLuint buffer);
		typedef void (* PFNGLTRANSFORMFEEDBACKVARYINGSEXTPROC) (GLuint program, GLsizei count, const GLchar* *varyings, GLenum bufferMode);
		typedef void (* PFNGLGETTRANSFORMFEEDBACKVARYINGEXTPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLsizei *size, GLenum *type, GLchar *name);
		typedef void (* PFNGLCLIENTATTRIBDEFAULTEXTPROC) (GLbitfield mask);
		typedef void (* PFNGLPUSHCLIENTATTRIBDEFAULTEXTPROC) (GLbitfield mask);
		typedef void (* PFNGLMATRIXLOADFEXTPROC) (GLenum mode, const GLfloat *m);
		typedef void (* PFNGLMATRIXLOADDEXTPROC) (GLenum mode, const GLdouble *m);
		typedef void (* PFNGLMATRIXMULTFEXTPROC) (GLenum mode, const GLfloat *m);
		typedef void (* PFNGLMATRIXMULTDEXTPROC) (GLenum mode, const GLdouble *m);
		typedef void (* PFNGLMATRIXLOADIDENTITYEXTPROC) (GLenum mode);
		typedef void (* PFNGLMATRIXROTATEFEXTPROC) (GLenum mode, GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLMATRIXROTATEDEXTPROC) (GLenum mode, GLdouble angle, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLMATRIXSCALEFEXTPROC) (GLenum mode, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLMATRIXSCALEDEXTPROC) (GLenum mode, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLMATRIXTRANSLATEFEXTPROC) (GLenum mode, GLfloat x, GLfloat y, GLfloat z);
		typedef void (* PFNGLMATRIXTRANSLATEDEXTPROC) (GLenum mode, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLMATRIXFRUSTUMEXTPROC) (GLenum mode, GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble zNear, GLdouble zFar);
		typedef void (* PFNGLMATRIXORTHOEXTPROC) (GLenum mode, GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble zNear, GLdouble zFar);
		typedef void (* PFNGLMATRIXPOPEXTPROC) (GLenum mode);
		typedef void (* PFNGLMATRIXPUSHEXTPROC) (GLenum mode);
		typedef void (* PFNGLMATRIXLOADTRANSPOSEFEXTPROC) (GLenum mode, const GLfloat *m);
		typedef void (* PFNGLMATRIXLOADTRANSPOSEDEXTPROC) (GLenum mode, const GLdouble *m);
		typedef void (* PFNGLMATRIXMULTTRANSPOSEFEXTPROC) (GLenum mode, const GLfloat *m);
		typedef void (* PFNGLMATRIXMULTTRANSPOSEDEXTPROC) (GLenum mode, const GLdouble *m);
		typedef void (* PFNGLTEXTUREPARAMETERFEXTPROC) (GLuint texture, GLenum target, GLenum pname, GLfloat param);
		typedef void (* PFNGLTEXTUREPARAMETERFVEXTPROC) (GLuint texture, GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLTEXTUREPARAMETERIEXTPROC) (GLuint texture, GLenum target, GLenum pname, GLint param);
		typedef void (* PFNGLTEXTUREPARAMETERIVEXTPROC) (GLuint texture, GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLTEXTUREIMAGE1DEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLTEXTUREIMAGE2DEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLTEXTURESUBIMAGE1DEXTPROC) (GLuint texture, GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLTEXTURESUBIMAGE2DEXTPROC) (GLuint texture, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLCOPYTEXTUREIMAGE1DEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLint border);
		typedef void (* PFNGLCOPYTEXTUREIMAGE2DEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
		typedef void (* PFNGLCOPYTEXTURESUBIMAGE1DEXTPROC) (GLuint texture, GLenum target, GLint level, GLint xoffset, GLint x, GLint y, GLsizei width);
		typedef void (* PFNGLCOPYTEXTURESUBIMAGE2DEXTPROC) (GLuint texture, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLGETTEXTUREIMAGEEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum format, GLenum type, GLvoid *pixels);
		typedef void (* PFNGLGETTEXTUREPARAMETERFVEXTPROC) (GLuint texture, GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETTEXTUREPARAMETERIVEXTPROC) (GLuint texture, GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETTEXTURELEVELPARAMETERFVEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETTEXTURELEVELPARAMETERIVEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum pname, GLint *params);
		typedef void (* PFNGLTEXTUREIMAGE3DEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLTEXTURESUBIMAGE3DEXTPROC) (GLuint texture, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLCOPYTEXTURESUBIMAGE3DEXTPROC) (GLuint texture, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLMULTITEXPARAMETERFEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLfloat param);
		typedef void (* PFNGLMULTITEXPARAMETERFVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLMULTITEXPARAMETERIEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLint param);
		typedef void (* PFNGLMULTITEXPARAMETERIVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLMULTITEXIMAGE1DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLMULTITEXIMAGE2DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLMULTITEXSUBIMAGE1DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLMULTITEXSUBIMAGE2DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLCOPYMULTITEXIMAGE1DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLint border);
		typedef void (* PFNGLCOPYMULTITEXIMAGE2DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
		typedef void (* PFNGLCOPYMULTITEXSUBIMAGE1DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLint xoffset, GLint x, GLint y, GLsizei width);
		typedef void (* PFNGLCOPYMULTITEXSUBIMAGE2DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLGETMULTITEXIMAGEEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum format, GLenum type, GLvoid *pixels);
		typedef void (* PFNGLGETMULTITEXPARAMETERFVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETMULTITEXPARAMETERIVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETMULTITEXLEVELPARAMETERFVEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETMULTITEXLEVELPARAMETERIVEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum pname, GLint *params);
		typedef void (* PFNGLMULTITEXIMAGE3DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLMULTITEXSUBIMAGE3DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid *pixels);
		typedef void (* PFNGLCOPYMULTITEXSUBIMAGE3DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);
		typedef void (* PFNGLBINDMULTITEXTUREEXTPROC) (GLenum texunit, GLenum target, GLuint texture);
		typedef void (* PFNGLENABLECLIENTSTATEINDEXEDEXTPROC) (GLenum array, GLuint index);
		typedef void (* PFNGLDISABLECLIENTSTATEINDEXEDEXTPROC) (GLenum array, GLuint index);
		typedef void (* PFNGLMULTITEXCOORDPOINTEREXTPROC) (GLenum texunit, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLMULTITEXENVFEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLfloat param);
		typedef void (* PFNGLMULTITEXENVFVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLMULTITEXENVIEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLint param);
		typedef void (* PFNGLMULTITEXENVIVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLMULTITEXGENDEXTPROC) (GLenum texunit, GLenum coord, GLenum pname, GLdouble param);
		typedef void (* PFNGLMULTITEXGENDVEXTPROC) (GLenum texunit, GLenum coord, GLenum pname, const GLdouble *params);
		typedef void (* PFNGLMULTITEXGENFEXTPROC) (GLenum texunit, GLenum coord, GLenum pname, GLfloat param);
		typedef void (* PFNGLMULTITEXGENFVEXTPROC) (GLenum texunit, GLenum coord, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLMULTITEXGENIEXTPROC) (GLenum texunit, GLenum coord, GLenum pname, GLint param);
		typedef void (* PFNGLMULTITEXGENIVEXTPROC) (GLenum texunit, GLenum coord, GLenum pname, const GLint *params);
		typedef void (* PFNGLGETMULTITEXENVFVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETMULTITEXENVIVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETMULTITEXGENDVEXTPROC) (GLenum texunit, GLenum coord, GLenum pname, GLdouble *params);
		typedef void (* PFNGLGETMULTITEXGENFVEXTPROC) (GLenum texunit, GLenum coord, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETMULTITEXGENIVEXTPROC) (GLenum texunit, GLenum coord, GLenum pname, GLint *params);
		typedef void (* PFNGLGETFLOATINDEXEDVEXTPROC) (GLenum target, GLuint index, GLfloat *data);
		typedef void (* PFNGLGETDOUBLEINDEXEDVEXTPROC) (GLenum target, GLuint index, GLdouble *data);
		typedef void (* PFNGLGETPOINTERINDEXEDVEXTPROC) (GLenum target, GLuint index, GLvoid* *data);
		typedef void (* PFNGLCOMPRESSEDTEXTUREIMAGE3DEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDTEXTUREIMAGE2DEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDTEXTUREIMAGE1DEXTPROC) (GLuint texture, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDTEXTURESUBIMAGE3DEXTPROC) (GLuint texture, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDTEXTURESUBIMAGE2DEXTPROC) (GLuint texture, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDTEXTURESUBIMAGE1DEXTPROC) (GLuint texture, GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLGETCOMPRESSEDTEXTUREIMAGEEXTPROC) (GLuint texture, GLenum target, GLint lod, GLvoid *img);
		typedef void (* PFNGLCOMPRESSEDMULTITEXIMAGE3DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDMULTITEXIMAGE2DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDMULTITEXIMAGE1DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDMULTITEXSUBIMAGE3DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDMULTITEXSUBIMAGE2DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLCOMPRESSEDMULTITEXSUBIMAGE1DEXTPROC) (GLenum texunit, GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, const GLvoid *bits);
		typedef void (* PFNGLGETCOMPRESSEDMULTITEXIMAGEEXTPROC) (GLenum texunit, GLenum target, GLint lod, GLvoid *img);
		typedef void (* PFNGLNAMEDPROGRAMSTRINGEXTPROC) (GLuint program, GLenum target, GLenum format, GLsizei len, const GLvoid *string);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETER4DEXTPROC) (GLuint program, GLenum target, GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETER4DVEXTPROC) (GLuint program, GLenum target, GLuint index, const GLdouble *params);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETER4FEXTPROC) (GLuint program, GLenum target, GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETER4FVEXTPROC) (GLuint program, GLenum target, GLuint index, const GLfloat *params);
		typedef void (* PFNGLGETNAMEDPROGRAMLOCALPARAMETERDVEXTPROC) (GLuint program, GLenum target, GLuint index, GLdouble *params);
		typedef void (* PFNGLGETNAMEDPROGRAMLOCALPARAMETERFVEXTPROC) (GLuint program, GLenum target, GLuint index, GLfloat *params);
		typedef void (* PFNGLGETNAMEDPROGRAMIVEXTPROC) (GLuint program, GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETNAMEDPROGRAMSTRINGEXTPROC) (GLuint program, GLenum target, GLenum pname, GLvoid *string);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETERS4FVEXTPROC) (GLuint program, GLenum target, GLuint index, GLsizei count, const GLfloat *params);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETERI4IEXTPROC) (GLuint program, GLenum target, GLuint index, GLint x, GLint y, GLint z, GLint w);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETERI4IVEXTPROC) (GLuint program, GLenum target, GLuint index, const GLint *params);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETERSI4IVEXTPROC) (GLuint program, GLenum target, GLuint index, GLsizei count, const GLint *params);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETERI4UIEXTPROC) (GLuint program, GLenum target, GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETERI4UIVEXTPROC) (GLuint program, GLenum target, GLuint index, const GLuint *params);
		typedef void (* PFNGLNAMEDPROGRAMLOCALPARAMETERSI4UIVEXTPROC) (GLuint program, GLenum target, GLuint index, GLsizei count, const GLuint *params);
		typedef void (* PFNGLGETNAMEDPROGRAMLOCALPARAMETERIIVEXTPROC) (GLuint program, GLenum target, GLuint index, GLint *params);
		typedef void (* PFNGLGETNAMEDPROGRAMLOCALPARAMETERIUIVEXTPROC) (GLuint program, GLenum target, GLuint index, GLuint *params);
		typedef void (* PFNGLTEXTUREPARAMETERIIVEXTPROC) (GLuint texture, GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLTEXTUREPARAMETERIUIVEXTPROC) (GLuint texture, GLenum target, GLenum pname, const GLuint *params);
		typedef void (* PFNGLGETTEXTUREPARAMETERIIVEXTPROC) (GLuint texture, GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETTEXTUREPARAMETERIUIVEXTPROC) (GLuint texture, GLenum target, GLenum pname, GLuint *params);
		typedef void (* PFNGLMULTITEXPARAMETERIIVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, const GLint *params);
		typedef void (* PFNGLMULTITEXPARAMETERIUIVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, const GLuint *params);
		typedef void (* PFNGLGETMULTITEXPARAMETERIIVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLint *params);
		typedef void (* PFNGLGETMULTITEXPARAMETERIUIVEXTPROC) (GLenum texunit, GLenum target, GLenum pname, GLuint *params);
		typedef void (* PFNGLPROGRAMUNIFORM1FEXTPROC) (GLuint program, GLint location, GLfloat v0);
		typedef void (* PFNGLPROGRAMUNIFORM2FEXTPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1);
		typedef void (* PFNGLPROGRAMUNIFORM3FEXTPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
		typedef void (* PFNGLPROGRAMUNIFORM4FEXTPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
		typedef void (* PFNGLPROGRAMUNIFORM1IEXTPROC) (GLuint program, GLint location, GLint v0);
		typedef void (* PFNGLPROGRAMUNIFORM2IEXTPROC) (GLuint program, GLint location, GLint v0, GLint v1);
		typedef void (* PFNGLPROGRAMUNIFORM3IEXTPROC) (GLuint program, GLint location, GLint v0, GLint v1, GLint v2);
		typedef void (* PFNGLPROGRAMUNIFORM4IEXTPROC) (GLuint program, GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
		typedef void (* PFNGLPROGRAMUNIFORM1FVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORM2FVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORM3FVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORM4FVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORM1IVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLPROGRAMUNIFORM2IVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLPROGRAMUNIFORM3IVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLPROGRAMUNIFORM4IVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2FVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3FVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4FVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2X3FVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3X2FVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2X4FVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4X2FVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3X4FVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4X3FVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
		typedef void (* PFNGLPROGRAMUNIFORM1UIEXTPROC) (GLuint program, GLint location, GLuint v0);
		typedef void (* PFNGLPROGRAMUNIFORM2UIEXTPROC) (GLuint program, GLint location, GLuint v0, GLuint v1);
		typedef void (* PFNGLPROGRAMUNIFORM3UIEXTPROC) (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2);
		typedef void (* PFNGLPROGRAMUNIFORM4UIEXTPROC) (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
		typedef void (* PFNGLPROGRAMUNIFORM1UIVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLPROGRAMUNIFORM2UIVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLPROGRAMUNIFORM3UIVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLPROGRAMUNIFORM4UIVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
		typedef void (* PFNGLNAMEDBUFFERDATAEXTPROC) (GLuint buffer, GLsizeiptr size, const GLvoid *data, GLenum usage);
		typedef void (* PFNGLNAMEDBUFFERSUBDATAEXTPROC) (GLuint buffer, GLintptr offset, GLsizeiptr size, const GLvoid *data);
		typedef GLvoid* (* PFNGLMAPNAMEDBUFFEREXTPROC) (GLuint buffer, GLenum access);
		typedef GLboolean (* PFNGLUNMAPNAMEDBUFFEREXTPROC) (GLuint buffer);
		typedef GLvoid* (* PFNGLMAPNAMEDBUFFERRANGEEXTPROC) (GLuint buffer, GLintptr offset, GLsizeiptr length, GLbitfield access);
		typedef void (* PFNGLFLUSHMAPPEDNAMEDBUFFERRANGEEXTPROC) (GLuint buffer, GLintptr offset, GLsizeiptr length);
		typedef void (* PFNGLNAMEDCOPYBUFFERSUBDATAEXTPROC) (GLuint readBuffer, GLuint writeBuffer, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size);
		typedef void (* PFNGLGETNAMEDBUFFERPARAMETERIVEXTPROC) (GLuint buffer, GLenum pname, GLint *params);
		typedef void (* PFNGLGETNAMEDBUFFERPOINTERVEXTPROC) (GLuint buffer, GLenum pname, GLvoid* *params);
		typedef void (* PFNGLGETNAMEDBUFFERSUBDATAEXTPROC) (GLuint buffer, GLintptr offset, GLsizeiptr size, GLvoid *data);
		typedef void (* PFNGLTEXTUREBUFFEREXTPROC) (GLuint texture, GLenum target, GLenum internalformat, GLuint buffer);
		typedef void (* PFNGLMULTITEXBUFFEREXTPROC) (GLenum texunit, GLenum target, GLenum internalformat, GLuint buffer);
		typedef void (* PFNGLNAMEDRENDERBUFFERSTORAGEEXTPROC) (GLuint renderbuffer, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLGETNAMEDRENDERBUFFERPARAMETERIVEXTPROC) (GLuint renderbuffer, GLenum pname, GLint *params);
		typedef GLenum (* PFNGLCHECKNAMEDFRAMEBUFFERSTATUSEXTPROC) (GLuint framebuffer, GLenum target);
		typedef void (* PFNGLNAMEDFRAMEBUFFERTEXTURE1DEXTPROC) (GLuint framebuffer, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
		typedef void (* PFNGLNAMEDFRAMEBUFFERTEXTURE2DEXTPROC) (GLuint framebuffer, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
		typedef void (* PFNGLNAMEDFRAMEBUFFERTEXTURE3DEXTPROC) (GLuint framebuffer, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset);
		typedef void (* PFNGLNAMEDFRAMEBUFFERRENDERBUFFEREXTPROC) (GLuint framebuffer, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
		typedef void (* PFNGLGETNAMEDFRAMEBUFFERATTACHMENTPARAMETERIVEXTPROC) (GLuint framebuffer, GLenum attachment, GLenum pname, GLint *params);
		typedef void (* PFNGLGENERATETEXTUREMIPMAPEXTPROC) (GLuint texture, GLenum target);
		typedef void (* PFNGLGENERATEMULTITEXMIPMAPEXTPROC) (GLenum texunit, GLenum target);
		typedef void (* PFNGLFRAMEBUFFERDRAWBUFFEREXTPROC) (GLuint framebuffer, GLenum mode);
		typedef void (* PFNGLFRAMEBUFFERDRAWBUFFERSEXTPROC) (GLuint framebuffer, GLsizei n, const GLenum *bufs);
		typedef void (* PFNGLFRAMEBUFFERREADBUFFEREXTPROC) (GLuint framebuffer, GLenum mode);
		typedef void (* PFNGLGETFRAMEBUFFERPARAMETERIVEXTPROC) (GLuint framebuffer, GLenum pname, GLint *params);
		typedef void (* PFNGLNAMEDRENDERBUFFERSTORAGEMULTISAMPLEEXTPROC) (GLuint renderbuffer, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLNAMEDRENDERBUFFERSTORAGEMULTISAMPLECOVERAGEEXTPROC) (GLuint renderbuffer, GLsizei coverageSamples, GLsizei colorSamples, GLenum internalformat, GLsizei width, GLsizei height);
		typedef void (* PFNGLNAMEDFRAMEBUFFERTEXTUREEXTPROC) (GLuint framebuffer, GLenum attachment, GLuint texture, GLint level);
		typedef void (* PFNGLNAMEDFRAMEBUFFERTEXTURELAYEREXTPROC) (GLuint framebuffer, GLenum attachment, GLuint texture, GLint level, GLint layer);
		typedef void (* PFNGLNAMEDFRAMEBUFFERTEXTUREFACEEXTPROC) (GLuint framebuffer, GLenum attachment, GLuint texture, GLint level, GLenum face);
		typedef void (* PFNGLTEXTURERENDERBUFFEREXTPROC) (GLuint texture, GLenum target, GLuint renderbuffer);
		typedef void (* PFNGLMULTITEXRENDERBUFFEREXTPROC) (GLenum texunit, GLenum target, GLuint renderbuffer);
		typedef void (* PFNGLPROGRAMUNIFORM1DEXTPROC) (GLuint program, GLint location, GLdouble x);
		typedef void (* PFNGLPROGRAMUNIFORM2DEXTPROC) (GLuint program, GLint location, GLdouble x, GLdouble y);
		typedef void (* PFNGLPROGRAMUNIFORM3DEXTPROC) (GLuint program, GLint location, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLPROGRAMUNIFORM4DEXTPROC) (GLuint program, GLint location, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLPROGRAMUNIFORM1DVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORM2DVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORM3DVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORM4DVEXTPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2DVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3DVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4DVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2X3DVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX2X4DVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3X2DVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX3X4DVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4X2DVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLPROGRAMUNIFORMMATRIX4X3DVEXTPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
		typedef void (* PFNGLGETMULTISAMPLEFVNVPROC) (GLenum pname, GLuint index, GLfloat *val);
		typedef void (* PFNGLSAMPLEMASKINDEXEDNVPROC) (GLuint index, GLbitfield mask);
		typedef void (* PFNGLTEXRENDERBUFFERNVPROC) (GLenum target, GLuint renderbuffer);
		typedef void (* PFNGLBINDTRANSFORMFEEDBACKNVPROC) (GLenum target, GLuint id);
		typedef void (* PFNGLDELETETRANSFORMFEEDBACKSNVPROC) (GLsizei n, const GLuint *ids);
		typedef void (* PFNGLGENTRANSFORMFEEDBACKSNVPROC) (GLsizei n, GLuint *ids);
		typedef GLboolean (* PFNGLISTRANSFORMFEEDBACKNVPROC) (GLuint id);
		typedef void (* PFNGLPAUSETRANSFORMFEEDBACKNVPROC) (void);
		typedef void (* PFNGLRESUMETRANSFORMFEEDBACKNVPROC) (void);
		typedef void (* PFNGLDRAWTRANSFORMFEEDBACKNVPROC) (GLenum mode, GLuint id);
		typedef void (* PFNGLGETPERFMONITORGROUPSAMDPROC) (GLint *numGroups, GLsizei groupsSize, GLuint *groups);
		typedef void (* PFNGLGETPERFMONITORCOUNTERSAMDPROC) (GLuint group, GLint *numCounters, GLint *maxActiveCounters, GLsizei counterSize, GLuint *counters);
		typedef void (* PFNGLGETPERFMONITORGROUPSTRINGAMDPROC) (GLuint group, GLsizei bufSize, GLsizei *length, GLchar *groupString);
		typedef void (* PFNGLGETPERFMONITORCOUNTERSTRINGAMDPROC) (GLuint group, GLuint counter, GLsizei bufSize, GLsizei *length, GLchar *counterString);
		typedef void (* PFNGLGETPERFMONITORCOUNTERINFOAMDPROC) (GLuint group, GLuint counter, GLenum pname, GLvoid *data);
		typedef void (* PFNGLGENPERFMONITORSAMDPROC) (GLsizei n, GLuint *monitors);
		typedef void (* PFNGLDELETEPERFMONITORSAMDPROC) (GLsizei n, GLuint *monitors);
		typedef void (* PFNGLSELECTPERFMONITORCOUNTERSAMDPROC) (GLuint monitor, GLboolean enable, GLuint group, GLint numCounters, GLuint *counterList);
		typedef void (* PFNGLBEGINPERFMONITORAMDPROC) (GLuint monitor);
		typedef void (* PFNGLENDPERFMONITORAMDPROC) (GLuint monitor);
		typedef void (* PFNGLGETPERFMONITORCOUNTERDATAAMDPROC) (GLuint monitor, GLenum pname, GLsizei dataSize, GLuint *data, GLint *bytesWritten);
		typedef void (* PFNGLTESSELLATIONFACTORAMDPROC) (GLfloat factor);
		typedef void (* PFNGLTESSELLATIONMODEAMDPROC) (GLenum mode);
		typedef void (* PFNGLPROVOKINGVERTEXEXTPROC) (GLenum mode);
		typedef void (* PFNGLBLENDFUNCINDEXEDAMDPROC) (GLuint buf, GLenum src, GLenum dst);
		typedef void (* PFNGLBLENDFUNCSEPARATEINDEXEDAMDPROC) (GLuint buf, GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);
		typedef void (* PFNGLBLENDEQUATIONINDEXEDAMDPROC) (GLuint buf, GLenum mode);
		typedef void (* PFNGLBLENDEQUATIONSEPARATEINDEXEDAMDPROC) (GLuint buf, GLenum modeRGB, GLenum modeAlpha);
		typedef void (* PFNGLTEXTURERANGEAPPLEPROC) (GLenum target, GLsizei length, const GLvoid *pointer);
		typedef void (* PFNGLGETTEXPARAMETERPOINTERVAPPLEPROC) (GLenum target, GLenum pname, GLvoid* *params);
		typedef void (* PFNGLENABLEVERTEXATTRIBAPPLEPROC) (GLuint index, GLenum pname);
		typedef void (* PFNGLDISABLEVERTEXATTRIBAPPLEPROC) (GLuint index, GLenum pname);
		typedef GLboolean (* PFNGLISVERTEXATTRIBENABLEDAPPLEPROC) (GLuint index, GLenum pname);
		typedef void (* PFNGLMAPVERTEXATTRIB1DAPPLEPROC) (GLuint index, GLuint size, GLdouble u1, GLdouble u2, GLint stride, GLint order, const GLdouble *points);
		typedef void (* PFNGLMAPVERTEXATTRIB1FAPPLEPROC) (GLuint index, GLuint size, GLfloat u1, GLfloat u2, GLint stride, GLint order, const GLfloat *points);
		typedef void (* PFNGLMAPVERTEXATTRIB2DAPPLEPROC) (GLuint index, GLuint size, GLdouble u1, GLdouble u2, GLint ustride, GLint uorder, GLdouble v1, GLdouble v2, GLint vstride, GLint vorder, const GLdouble *points);
		typedef void (* PFNGLMAPVERTEXATTRIB2FAPPLEPROC) (GLuint index, GLuint size, GLfloat u1, GLfloat u2, GLint ustride, GLint uorder, GLfloat v1, GLfloat v2, GLint vstride, GLint vorder, const GLfloat *points);
		typedef GLenum (* PFNGLOBJECTPURGEABLEAPPLEPROC) (GLenum objectType, GLuint name, GLenum option);
		typedef GLenum (* PFNGLOBJECTUNPURGEABLEAPPLEPROC) (GLenum objectType, GLuint name, GLenum option);
		typedef void (* PFNGLGETOBJECTPARAMETERIVAPPLEPROC) (GLenum objectType, GLuint name, GLenum pname, GLint *params);
		typedef void (* PFNGLBEGINVIDEOCAPTURENVPROC) (GLuint video_capture_slot);
		typedef void (* PFNGLBINDVIDEOCAPTURESTREAMBUFFERNVPROC) (GLuint video_capture_slot, GLuint stream, GLenum frame_region, GLintptrARB offset);
		typedef void (* PFNGLBINDVIDEOCAPTURESTREAMTEXTURENVPROC) (GLuint video_capture_slot, GLuint stream, GLenum frame_region, GLenum target, GLuint texture);
		typedef void (* PFNGLENDVIDEOCAPTURENVPROC) (GLuint video_capture_slot);
		typedef void (* PFNGLGETVIDEOCAPTUREIVNVPROC) (GLuint video_capture_slot, GLenum pname, GLint *params);
		typedef void (* PFNGLGETVIDEOCAPTURESTREAMIVNVPROC) (GLuint video_capture_slot, GLuint stream, GLenum pname, GLint *params);
		typedef void (* PFNGLGETVIDEOCAPTURESTREAMFVNVPROC) (GLuint video_capture_slot, GLuint stream, GLenum pname, GLfloat *params);
		typedef void (* PFNGLGETVIDEOCAPTURESTREAMDVNVPROC) (GLuint video_capture_slot, GLuint stream, GLenum pname, GLdouble *params);
		typedef GLenum (* PFNGLVIDEOCAPTURENVPROC) (GLuint video_capture_slot, GLuint *sequence_num, GLuint64EXT *capture_time);
		typedef void (* PFNGLVIDEOCAPTURESTREAMPARAMETERIVNVPROC) (GLuint video_capture_slot, GLuint stream, GLenum pname, const GLint *params);
		typedef void (* PFNGLVIDEOCAPTURESTREAMPARAMETERFVNVPROC) (GLuint video_capture_slot, GLuint stream, GLenum pname, const GLfloat *params);
		typedef void (* PFNGLVIDEOCAPTURESTREAMPARAMETERDVNVPROC) (GLuint video_capture_slot, GLuint stream, GLenum pname, const GLdouble *params);
		typedef void (* PFNGLCOPYIMAGESUBDATANVPROC) (GLuint srcName, GLenum srcTarget, GLint srcLevel, GLint srcX, GLint srcY, GLint srcZ, GLuint dstName, GLenum dstTarget, GLint dstLevel, GLint dstX, GLint dstY, GLint dstZ, GLsizei width, GLsizei height, GLsizei depth);
		typedef void (* PFNGLUSESHADERPROGRAMEXTPROC) (GLenum type, GLuint program);
		typedef void (* PFNGLACTIVEPROGRAMEXTPROC) (GLuint program);
		typedef GLuint (* PFNGLCREATESHADERPROGRAMEXTPROC) (GLenum type, const GLchar *string);
		typedef void (* PFNGLMAKEBUFFERRESIDENTNVPROC) (GLenum target, GLenum access);
		typedef void (* PFNGLMAKEBUFFERNONRESIDENTNVPROC) (GLenum target);
		typedef GLboolean (* PFNGLISBUFFERRESIDENTNVPROC) (GLenum target);
		typedef void (* PFNGLMAKENAMEDBUFFERRESIDENTNVPROC) (GLuint buffer, GLenum access);
		typedef void (* PFNGLMAKENAMEDBUFFERNONRESIDENTNVPROC) (GLuint buffer);
		typedef GLboolean (* PFNGLISNAMEDBUFFERRESIDENTNVPROC) (GLuint buffer);
		typedef void (* PFNGLGETBUFFERPARAMETERUI64VNVPROC) (GLenum target, GLenum pname, GLuint64EXT *params);
		typedef void (* PFNGLGETNAMEDBUFFERPARAMETERUI64VNVPROC) (GLuint buffer, GLenum pname, GLuint64EXT *params);
		typedef void (* PFNGLGETINTEGERUI64VNVPROC) (GLenum value, GLuint64EXT *result);
		typedef void (* PFNGLUNIFORMUI64NVPROC) (GLint location, GLuint64EXT value);
		typedef void (* PFNGLUNIFORMUI64VNVPROC) (GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLGETUNIFORMUI64VNVPROC) (GLuint program, GLint location, GLuint64EXT *params);
		typedef void (* PFNGLPROGRAMUNIFORMUI64NVPROC) (GLuint program, GLint location, GLuint64EXT value);
		typedef void (* PFNGLPROGRAMUNIFORMUI64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLBUFFERADDRESSRANGENVPROC) (GLenum pname, GLuint index, GLuint64EXT address, GLsizeiptr length);
		typedef void (* PFNGLVERTEXFORMATNVPROC) (GLint size, GLenum type, GLsizei stride);
		typedef void (* PFNGLNORMALFORMATNVPROC) (GLenum type, GLsizei stride);
		typedef void (* PFNGLCOLORFORMATNVPROC) (GLint size, GLenum type, GLsizei stride);
		typedef void (* PFNGLINDEXFORMATNVPROC) (GLenum type, GLsizei stride);
		typedef void (* PFNGLTEXCOORDFORMATNVPROC) (GLint size, GLenum type, GLsizei stride);
		typedef void (* PFNGLEDGEFLAGFORMATNVPROC) (GLsizei stride);
		typedef void (* PFNGLSECONDARYCOLORFORMATNVPROC) (GLint size, GLenum type, GLsizei stride);
		typedef void (* PFNGLFOGCOORDFORMATNVPROC) (GLenum type, GLsizei stride);
		typedef void (* PFNGLVERTEXATTRIBFORMATNVPROC) (GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride);
		typedef void (* PFNGLVERTEXATTRIBIFORMATNVPROC) (GLuint index, GLint size, GLenum type, GLsizei stride);
		typedef void (* PFNGLGETINTEGERUI64I_VNVPROC) (GLenum value, GLuint index, GLuint64EXT *result);
		typedef void (* PFNGLTEXTUREBARRIERNVPROC) (void);
		typedef void (* PFNGLBINDIMAGETEXTUREEXTPROC) (GLuint index, GLuint texture, GLint level, GLboolean layered, GLint layer, GLenum access, GLint format);
		typedef void (* PFNGLMEMORYBARRIEREXTPROC) (GLbitfield barriers);
		typedef void (* PFNGLVERTEXATTRIBL1DEXTPROC) (GLuint index, GLdouble x);
		typedef void (* PFNGLVERTEXATTRIBL2DEXTPROC) (GLuint index, GLdouble x, GLdouble y);
		typedef void (* PFNGLVERTEXATTRIBL3DEXTPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z);
		typedef void (* PFNGLVERTEXATTRIBL4DEXTPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
		typedef void (* PFNGLVERTEXATTRIBL1DVEXTPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBL2DVEXTPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBL3DVEXTPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBL4DVEXTPROC) (GLuint index, const GLdouble *v);
		typedef void (* PFNGLVERTEXATTRIBLPOINTEREXTPROC) (GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
		typedef void (* PFNGLGETVERTEXATTRIBLDVEXTPROC) (GLuint index, GLenum pname, GLdouble *params);
		typedef void (* PFNGLVERTEXARRAYVERTEXATTRIBLOFFSETEXTPROC) (GLuint vaobj, GLuint buffer, GLuint index, GLint size, GLenum type, GLsizei stride, GLintptr offset);
		typedef void (* PFNGLPROGRAMSUBROUTINEPARAMETERSUIVNVPROC) (GLenum target, GLsizei count, const GLuint *params);
		typedef void (* PFNGLGETPROGRAMSUBROUTINEPARAMETERUIVNVPROC) (GLenum target, GLuint index, GLuint *param);
		typedef void (* PFNGLUNIFORM1I64NVPROC) (GLint location, GLint64EXT x);
		typedef void (* PFNGLUNIFORM2I64NVPROC) (GLint location, GLint64EXT x, GLint64EXT y);
		typedef void (* PFNGLUNIFORM3I64NVPROC) (GLint location, GLint64EXT x, GLint64EXT y, GLint64EXT z);
		typedef void (* PFNGLUNIFORM4I64NVPROC) (GLint location, GLint64EXT x, GLint64EXT y, GLint64EXT z, GLint64EXT w);
		typedef void (* PFNGLUNIFORM1I64VNVPROC) (GLint location, GLsizei count, const GLint64EXT *value);
		typedef void (* PFNGLUNIFORM2I64VNVPROC) (GLint location, GLsizei count, const GLint64EXT *value);
		typedef void (* PFNGLUNIFORM3I64VNVPROC) (GLint location, GLsizei count, const GLint64EXT *value);
		typedef void (* PFNGLUNIFORM4I64VNVPROC) (GLint location, GLsizei count, const GLint64EXT *value);
		typedef void (* PFNGLUNIFORM1UI64NVPROC) (GLint location, GLuint64EXT x);
		typedef void (* PFNGLUNIFORM2UI64NVPROC) (GLint location, GLuint64EXT x, GLuint64EXT y);
		typedef void (* PFNGLUNIFORM3UI64NVPROC) (GLint location, GLuint64EXT x, GLuint64EXT y, GLuint64EXT z);
		typedef void (* PFNGLUNIFORM4UI64NVPROC) (GLint location, GLuint64EXT x, GLuint64EXT y, GLuint64EXT z, GLuint64EXT w);
		typedef void (* PFNGLUNIFORM1UI64VNVPROC) (GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLUNIFORM2UI64VNVPROC) (GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLUNIFORM3UI64VNVPROC) (GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLUNIFORM4UI64VNVPROC) (GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLGETUNIFORMI64VNVPROC) (GLuint program, GLint location, GLint64EXT *params);
		typedef void (* PFNGLPROGRAMUNIFORM1I64NVPROC) (GLuint program, GLint location, GLint64EXT x);
		typedef void (* PFNGLPROGRAMUNIFORM2I64NVPROC) (GLuint program, GLint location, GLint64EXT x, GLint64EXT y);
		typedef void (* PFNGLPROGRAMUNIFORM3I64NVPROC) (GLuint program, GLint location, GLint64EXT x, GLint64EXT y, GLint64EXT z);
		typedef void (* PFNGLPROGRAMUNIFORM4I64NVPROC) (GLuint program, GLint location, GLint64EXT x, GLint64EXT y, GLint64EXT z, GLint64EXT w);
		typedef void (* PFNGLPROGRAMUNIFORM1I64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLint64EXT *value);
		typedef void (* PFNGLPROGRAMUNIFORM2I64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLint64EXT *value);
		typedef void (* PFNGLPROGRAMUNIFORM3I64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLint64EXT *value);
		typedef void (* PFNGLPROGRAMUNIFORM4I64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLint64EXT *value);
		typedef void (* PFNGLPROGRAMUNIFORM1UI64NVPROC) (GLuint program, GLint location, GLuint64EXT x);
		typedef void (* PFNGLPROGRAMUNIFORM2UI64NVPROC) (GLuint program, GLint location, GLuint64EXT x, GLuint64EXT y);
		typedef void (* PFNGLPROGRAMUNIFORM3UI64NVPROC) (GLuint program, GLint location, GLuint64EXT x, GLuint64EXT y, GLuint64EXT z);
		typedef void (* PFNGLPROGRAMUNIFORM4UI64NVPROC) (GLuint program, GLint location, GLuint64EXT x, GLuint64EXT y, GLuint64EXT z, GLuint64EXT w);
		typedef void (* PFNGLPROGRAMUNIFORM1UI64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLPROGRAMUNIFORM2UI64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLPROGRAMUNIFORM3UI64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLPROGRAMUNIFORM4UI64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLuint64EXT *value);
		typedef void (* PFNGLVERTEXATTRIBL1I64NVPROC) (GLuint index, GLint64EXT x);
		typedef void (* PFNGLVERTEXATTRIBL2I64NVPROC) (GLuint index, GLint64EXT x, GLint64EXT y);
		typedef void (* PFNGLVERTEXATTRIBL3I64NVPROC) (GLuint index, GLint64EXT x, GLint64EXT y, GLint64EXT z);
		typedef void (* PFNGLVERTEXATTRIBL4I64NVPROC) (GLuint index, GLint64EXT x, GLint64EXT y, GLint64EXT z, GLint64EXT w);
		typedef void (* PFNGLVERTEXATTRIBL1I64VNVPROC) (GLuint index, const GLint64EXT *v);
		typedef void (* PFNGLVERTEXATTRIBL2I64VNVPROC) (GLuint index, const GLint64EXT *v);
		typedef void (* PFNGLVERTEXATTRIBL3I64VNVPROC) (GLuint index, const GLint64EXT *v);
		typedef void (* PFNGLVERTEXATTRIBL4I64VNVPROC) (GLuint index, const GLint64EXT *v);
		typedef void (* PFNGLVERTEXATTRIBL1UI64NVPROC) (GLuint index, GLuint64EXT x);
		typedef void (* PFNGLVERTEXATTRIBL2UI64NVPROC) (GLuint index, GLuint64EXT x, GLuint64EXT y);
		typedef void (* PFNGLVERTEXATTRIBL3UI64NVPROC) (GLuint index, GLuint64EXT x, GLuint64EXT y, GLuint64EXT z);
		typedef void (* PFNGLVERTEXATTRIBL4UI64NVPROC) (GLuint index, GLuint64EXT x, GLuint64EXT y, GLuint64EXT z, GLuint64EXT w);
		typedef void (* PFNGLVERTEXATTRIBL1UI64VNVPROC) (GLuint index, const GLuint64EXT *v);
		typedef void (* PFNGLVERTEXATTRIBL2UI64VNVPROC) (GLuint index, const GLuint64EXT *v);
		typedef void (* PFNGLVERTEXATTRIBL3UI64VNVPROC) (GLuint index, const GLuint64EXT *v);
		typedef void (* PFNGLVERTEXATTRIBL4UI64VNVPROC) (GLuint index, const GLuint64EXT *v);
		typedef void (* PFNGLGETVERTEXATTRIBLI64VNVPROC) (GLuint index, GLenum pname, GLint64EXT *params);
		typedef void (* PFNGLGETVERTEXATTRIBLUI64VNVPROC) (GLuint index, GLenum pname, GLuint64EXT *params);
		typedef void (* PFNGLVERTEXATTRIBLFORMATNVPROC) (GLuint index, GLint size, GLenum type, GLsizei stride);
		typedef void (* PFNGLGENNAMESAMDPROC) (GLenum identifier, GLuint num, GLuint *names);
		typedef void (* PFNGLDELETENAMESAMDPROC) (GLenum identifier, GLuint num, const GLuint *names);
		typedef GLboolean (* PFNGLISNAMEAMDPROC) (GLenum identifier, GLuint name);
		typedef void (* PFNGLDEBUGMESSAGEENABLEAMDPROC) (GLenum category, GLenum severity, GLsizei count, const GLuint *ids, GLboolean enabled);
		typedef void (* PFNGLDEBUGMESSAGEINSERTAMDPROC) (GLenum category, GLenum severity, GLuint id, GLsizei length, const GLchar *buf);
		typedef void (* PFNGLDEBUGMESSAGECALLBACKAMDPROC) (GLDEBUGPROCAMD callback, GLvoid *userParam);
		typedef GLuint (* PFNGLGETDEBUGMESSAGELOGAMDPROC) (GLuint count, GLsizei bufsize, GLenum *categories, GLuint *severities, GLuint *ids, GLsizei *lengths, GLchar *message);
		typedef void (* PFNGLVDPAUINITNVPROC) (const GLvoid *vdpDevice, const GLvoid *getProcAddress);
		typedef void (* PFNGLVDPAUFININVPROC) (void);
		typedef GLvdpauSurfaceNV (* PFNGLVDPAUREGISTERVIDEOSURFACENVPROC) (const GLvoid *vdpSurface, GLenum target, GLsizei numTextureNames, const GLuint *textureNames);
		typedef GLvdpauSurfaceNV (* PFNGLVDPAUREGISTEROUTPUTSURFACENVPROC) (GLvoid *vdpSurface, GLenum target, GLsizei numTextureNames, const GLuint *textureNames);
		typedef void (* PFNGLVDPAUISSURFACENVPROC) (GLvdpauSurfaceNV surface);
		typedef void (* PFNGLVDPAUUNREGISTERSURFACENVPROC) (GLvdpauSurfaceNV surface);
		typedef void (* PFNGLVDPAUGETSURFACEIVNVPROC) (GLvdpauSurfaceNV surface, GLenum pname, GLsizei bufSize, GLsizei *length, GLint *values);
		typedef void (* PFNGLVDPAUSURFACEACCESSNVPROC) (GLvdpauSurfaceNV surface, GLenum access);
		typedef void (* PFNGLVDPAUMAPSURFACESNVPROC) (GLsizei numSurfaces, const GLvdpauSurfaceNV *surfaces);
		typedef void (* PFNGLVDPAUUNMAPSURFACESNVPROC) (GLsizei numSurface, const GLvdpauSurfaceNV *surfaces);
		typedef void (* PFNGLTEXIMAGE2DMULTISAMPLECOVERAGENVPROC) (GLenum target, GLsizei coverageSamples, GLsizei colorSamples, GLint internalFormat, GLsizei width, GLsizei height, GLboolean fixedSampleLocations);
		typedef void (* PFNGLTEXIMAGE3DMULTISAMPLECOVERAGENVPROC) (GLenum target, GLsizei coverageSamples, GLsizei colorSamples, GLint internalFormat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedSampleLocations);
		typedef void (* PFNGLTEXTUREIMAGE2DMULTISAMPLENVPROC) (GLuint texture, GLenum target, GLsizei samples, GLint internalFormat, GLsizei width, GLsizei height, GLboolean fixedSampleLocations);
		typedef void (* PFNGLTEXTUREIMAGE3DMULTISAMPLENVPROC) (GLuint texture, GLenum target, GLsizei samples, GLint internalFormat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedSampleLocations);
		typedef void (* PFNGLTEXTUREIMAGE2DMULTISAMPLECOVERAGENVPROC) (GLuint texture, GLenum target, GLsizei coverageSamples, GLsizei colorSamples, GLint internalFormat, GLsizei width, GLsizei height, GLboolean fixedSampleLocations);
		typedef void (* PFNGLTEXTUREIMAGE3DMULTISAMPLECOVERAGENVPROC) (GLuint texture, GLenum target, GLsizei coverageSamples, GLsizei colorSamples, GLint internalFormat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedSampleLocations);
		typedef void (* PFNGLSETMULTISAMPLEFVAMDPROC) (GLenum pname, GLuint index, const GLfloat *val);
		typedef GLsync (* PFNGLIMPORTSYNCEXTPROC) (GLenum external_sync_type, GLintptr external_sync, GLbitfield flags);
		typedef void (* PFNGLMULTIDRAWARRAYSINDIRECTAMDPROC) (GLenum mode, const GLvoid *indirect, GLsizei primcount, GLsizei stride);
		typedef void (* PFNGLMULTIDRAWELEMENTSINDIRECTAMDPROC) (GLenum mode, GLenum type, const GLvoid *indirect, GLsizei primcount, GLsizei stride);
		typedef GLuint (* PFNGLGENPATHSNVPROC) (GLsizei range);
		typedef void (* PFNGLDELETEPATHSNVPROC) (GLuint path, GLsizei range);
		typedef GLboolean (* PFNGLISPATHNVPROC) (GLuint path);
		typedef void (* PFNGLPATHCOMMANDSNVPROC) (GLuint path, GLsizei numCommands, const GLubyte *commands, GLsizei numCoords, GLenum coordType, const GLvoid *coords);
		typedef void (* PFNGLPATHCOORDSNVPROC) (GLuint path, GLsizei numCoords, GLenum coordType, const GLvoid *coords);
		typedef void (* PFNGLPATHSUBCOMMANDSNVPROC) (GLuint path, GLsizei commandStart, GLsizei commandsToDelete, GLsizei numCommands, const GLubyte *commands, GLsizei numCoords, GLenum coordType, const GLvoid *coords);
		typedef void (* PFNGLPATHSUBCOORDSNVPROC) (GLuint path, GLsizei coordStart, GLsizei numCoords, GLenum coordType, const GLvoid *coords);
		typedef void (* PFNGLPATHSTRINGNVPROC) (GLuint path, GLenum format, GLsizei length, const GLvoid *pathString);
		typedef void (* PFNGLPATHGLYPHSNVPROC) (GLuint firstPathName, GLenum fontTarget, const GLvoid *fontName, GLbitfield fontStyle, GLsizei numGlyphs, GLenum type, const GLvoid *charcodes, GLenum handleMissingGlyphs, GLuint pathParameterTemplate, GLfloat emScale);
		typedef void (* PFNGLPATHGLYPHRANGENVPROC) (GLuint firstPathName, GLenum fontTarget, const GLvoid *fontName, GLbitfield fontStyle, GLuint firstGlyph, GLsizei numGlyphs, GLenum handleMissingGlyphs, GLuint pathParameterTemplate, GLfloat emScale);
		typedef void (* PFNGLWEIGHTPATHSNVPROC) (GLuint resultPath, GLsizei numPaths, const GLuint *paths, const GLfloat *weights);
		typedef void (* PFNGLCOPYPATHNVPROC) (GLuint resultPath, GLuint srcPath);
		typedef void (* PFNGLINTERPOLATEPATHSNVPROC) (GLuint resultPath, GLuint pathA, GLuint pathB, GLfloat weight);
		typedef void (* PFNGLTRANSFORMPATHNVPROC) (GLuint resultPath, GLuint srcPath, GLenum transformType, const GLfloat *transformValues);
		typedef void (* PFNGLPATHPARAMETERIVNVPROC) (GLuint path, GLenum pname, const GLint *value);
		typedef void (* PFNGLPATHPARAMETERINVPROC) (GLuint path, GLenum pname, GLint value);
		typedef void (* PFNGLPATHPARAMETERFVNVPROC) (GLuint path, GLenum pname, const GLfloat *value);
		typedef void (* PFNGLPATHPARAMETERFNVPROC) (GLuint path, GLenum pname, GLfloat value);
		typedef void (* PFNGLPATHDASHARRAYNVPROC) (GLuint path, GLsizei dashCount, const GLfloat *dashArray);
		typedef void (* PFNGLPATHSTENCILFUNCNVPROC) (GLenum func, GLint ref, GLuint mask);
		typedef void (* PFNGLPATHSTENCILDEPTHOFFSETNVPROC) (GLfloat factor, GLfloat units);
		typedef void (* PFNGLSTENCILFILLPATHNVPROC) (GLuint path, GLenum fillMode, GLuint mask);
		typedef void (* PFNGLSTENCILSTROKEPATHNVPROC) (GLuint path, GLint reference, GLuint mask);
		typedef void (* PFNGLSTENCILFILLPATHINSTANCEDNVPROC) (GLsizei numPaths, GLenum pathNameType, const GLvoid *paths, GLuint pathBase, GLenum fillMode, GLuint mask, GLenum transformType, const GLfloat *transformValues);
		typedef void (* PFNGLSTENCILSTROKEPATHINSTANCEDNVPROC) (GLsizei numPaths, GLenum pathNameType, const GLvoid *paths, GLuint pathBase, GLint reference, GLuint mask, GLenum transformType, const GLfloat *transformValues);
		typedef void (* PFNGLPATHCOVERDEPTHFUNCNVPROC) (GLenum func);
		typedef void (* PFNGLPATHCOLORGENNVPROC) (GLenum color, GLenum genMode, GLenum colorFormat, const GLfloat *coeffs);
		typedef void (* PFNGLPATHTEXGENNVPROC) (GLenum texCoordSet, GLenum genMode, GLint components, const GLfloat *coeffs);
		typedef void (* PFNGLPATHFOGGENNVPROC) (GLenum genMode);
		typedef void (* PFNGLCOVERFILLPATHNVPROC) (GLuint path, GLenum coverMode);
		typedef void (* PFNGLCOVERSTROKEPATHNVPROC) (GLuint path, GLenum coverMode);
		typedef void (* PFNGLCOVERFILLPATHINSTANCEDNVPROC) (GLsizei numPaths, GLenum pathNameType, const GLvoid *paths, GLuint pathBase, GLenum coverMode, GLenum transformType, const GLfloat *transformValues);
		typedef void (* PFNGLCOVERSTROKEPATHINSTANCEDNVPROC) (GLsizei numPaths, GLenum pathNameType, const GLvoid *paths, GLuint pathBase, GLenum coverMode, GLenum transformType, const GLfloat *transformValues);
		typedef void (* PFNGLGETPATHPARAMETERIVNVPROC) (GLuint path, GLenum pname, GLint *value);
		typedef void (* PFNGLGETPATHPARAMETERFVNVPROC) (GLuint path, GLenum pname, GLfloat *value);
		typedef void (* PFNGLGETPATHCOMMANDSNVPROC) (GLuint path, GLubyte *commands);
		typedef void (* PFNGLGETPATHCOORDSNVPROC) (GLuint path, GLfloat *coords);
		typedef void (* PFNGLGETPATHDASHARRAYNVPROC) (GLuint path, GLfloat *dashArray);
		typedef void (* PFNGLGETPATHMETRICSNVPROC) (GLbitfield metricQueryMask, GLsizei numPaths, GLenum pathNameType, const GLvoid *paths, GLuint pathBase, GLsizei stride, GLfloat *metrics);
		typedef void (* PFNGLGETPATHMETRICRANGENVPROC) (GLbitfield metricQueryMask, GLuint firstPathName, GLsizei numPaths, GLsizei stride, GLfloat *metrics);
		typedef void (* PFNGLGETPATHSPACINGNVPROC) (GLenum pathListMode, GLsizei numPaths, GLenum pathNameType, const GLvoid *paths, GLuint pathBase, GLfloat advanceScale, GLfloat kerningScale, GLenum transformType, GLfloat *returnedSpacing);
		typedef void (* PFNGLGETPATHCOLORGENIVNVPROC) (GLenum color, GLenum pname, GLint *value);
		typedef void (* PFNGLGETPATHCOLORGENFVNVPROC) (GLenum color, GLenum pname, GLfloat *value);
		typedef void (* PFNGLGETPATHTEXGENIVNVPROC) (GLenum texCoordSet, GLenum pname, GLint *value);
		typedef void (* PFNGLGETPATHTEXGENFVNVPROC) (GLenum texCoordSet, GLenum pname, GLfloat *value);
		typedef GLboolean (* PFNGLISPOINTINFILLPATHNVPROC) (GLuint path, GLuint mask, GLfloat x, GLfloat y);
		typedef GLboolean (* PFNGLISPOINTINSTROKEPATHNVPROC) (GLuint path, GLfloat x, GLfloat y);
		typedef GLfloat (* PFNGLGETPATHLENGTHNVPROC) (GLuint path, GLsizei startSegment, GLsizei numSegments);
		typedef GLboolean (* PFNGLPOINTALONGPATHNVPROC) (GLuint path, GLsizei startSegment, GLsizei numSegments, GLfloat distance, GLfloat *x, GLfloat *y, GLfloat *tangentX, GLfloat *tangentY);
		typedef void (* PFNGLSTENCILOPVALUEAMDPROC) (GLenum face, GLuint value);
		typedef GLuint64 (* PFNGLGETTEXTUREHANDLENVPROC) (GLuint texture);
		typedef GLuint64 (* PFNGLGETTEXTURESAMPLERHANDLENVPROC) (GLuint texture, GLuint sampler);
		typedef void (* PFNGLMAKETEXTUREHANDLERESIDENTNVPROC) (GLuint64 handle);
		typedef void (* PFNGLMAKETEXTUREHANDLENONRESIDENTNVPROC) (GLuint64 handle);
		typedef GLuint64 (* PFNGLGETIMAGEHANDLENVPROC) (GLuint texture, GLint level, GLboolean layered, GLint layer, GLenum format);
		typedef void (* PFNGLMAKEIMAGEHANDLERESIDENTNVPROC) (GLuint64 handle, GLenum access);
		typedef void (* PFNGLMAKEIMAGEHANDLENONRESIDENTNVPROC) (GLuint64 handle);
		typedef void (* PFNGLUNIFORMHANDLEUI64NVPROC) (GLint location, GLuint64 value);
		typedef void (* PFNGLUNIFORMHANDLEUI64VNVPROC) (GLint location, GLsizei count, const GLuint64 *value);
		typedef void (* PFNGLPROGRAMUNIFORMHANDLEUI64NVPROC) (GLuint program, GLint location, GLuint64 value);
		typedef void (* PFNGLPROGRAMUNIFORMHANDLEUI64VNVPROC) (GLuint program, GLint location, GLsizei count, const GLuint64 *values);
		typedef GLboolean (* PFNGLISTEXTUREHANDLERESIDENTNVPROC) (GLuint64 handle);
		typedef GLboolean (* PFNGLISIMAGEHANDLERESIDENTNVPROC) (GLuint64 handle);
		typedef void (* PFNGLBEGINCONDITIONALRENDERNVXPROC) (GLuint id);
		typedef void (* PFNGLENDCONDITIONALRENDERNVXPROC) (void);
		typedef void (* PFNGLTEXSTORAGESPARSEAMDPROC) (GLenum target, GLenum internalFormat, GLsizei width, GLsizei height, GLsizei depth, GLsizei layers, GLbitfield flags);
		typedef void (* PFNGLTEXTURESTORAGESPARSEAMDPROC) (GLuint texture, GLenum target, GLenum internalFormat, GLsizei width, GLsizei height, GLsizei depth, GLsizei layers, GLbitfield flags);
		typedef void (* PFNGLSYNCTEXTUREINTELPROC) (GLuint texture);
		typedef void (* PFNGLUNMAPTEXTURE2DINTELPROC) (GLuint texture, GLint level);
		typedef GLvoid* (* PFNGLMAPTEXTURE2DINTELPROC) (GLuint texture, GLint level, GLbitfield access, const GLint *stride, const GLenum *layout);
		typedef void (* PFNGLDRAWTEXTURENVPROC) (GLuint texture, GLuint sampler, GLfloat x0, GLfloat y0, GLfloat x1, GLfloat y1, GLfloat z, GLfloat s0, GLfloat t0, GLfloat s1, GLfloat t1);
	]]
end


local function glfun(k) return lib["gl"..k] end

if ffi.os == "Windows" then
	local function wglfun(k)
		local name = "gl"..k
		local funcptr = lib.wglGetProcAddress(name)
		assert(funcptr ~= nil)
		local protoname = string.format("PFN%sPROC", name:upper())
		local castfunc = ffi.cast(protoname, funcptr)
		return castfunc
	end
	
	-- use wgl:
	glfun = function(k)
		local ok, fun = pcall(wglfun, k)
		if not ok then 
			fun = lib["gl"..k]
		end
		return fun
	end
end
 

local function glenum(k) return lib["GL_"..k] end
local function glindex(t, k)
	-- check functions first
	local ok, fun = pcall(glfun, k)
	if ok then
		t[k] = fun
	else
		local ok, enum = pcall(glenum, k)
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
setmetatable(gl, { __index = glindex, })

local glGetString = gl.GetString
function gl.GetString(p) 
	local s = glGetString(p) 
	if s == nil then error("failed to load gl (no current context)")
	else return ffi.string(s) end
end

--print("using OpenGL", gl.GetString(gl.VERSION))

local glClear = gl.Clear
function gl.Clear(...)
	if select('#', ...) > 0 then
		glClear(bit.bor(...))
	else
		glClear(bit.bor(gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT))
	end
end

local glClearAccum = gl.ClearAccum
function gl.ClearAccum(r, g, b, a)
	if type(r) == "table" then r, g, b, a = unpack(r) end
	glClearAccum(r or 0, g or 0, b or 0, a or 1)
end

local glClearColor = gl.ClearColor
function gl.ClearColor(r, g, b, a)
	if type(r) == "table" then r, g, b, a = unpack(r) end
	glClearColor(r or 0, g or 0, b or 0, a or 1)
end

function gl.Color(r, g, b, a)
	if type(r) == "table" then r, g, b, a = unpack(r) end
	gl.Color4f(r or 0, g or 0, b or 0, a or 1)
end

local glColorMask = gl.ColorMask
function gl.ColorMask(r, g, b, a)
	if type(r) == "table" then r, g, b, a = unpack(r) end
	glColorMask(r or 0, g or 0, b or 0, a or 1)
end

-- Why is this necessary? FFI bug? Clash with "End" and "end" ?
local glEnd = gl.End
function gl.End() glEnd() end


function gl.Get(p) error("TODO for the array returns.") end

function gl.LoadMatrix(t) 
	if type(t) == "table" then
		gl.LoadMatrixd(ffi.new("GLdouble[?]", 16, unpack(t)))
	else
		-- hope t is a double *
		gl.LoadMatrixd(t)
	end
end

function gl.MultMatrix(t) 
	if type(t) == "table" then
		gl.MultMatrixd(ffi.new("GLdouble[?]", 16, unpack(t)))
	else
		-- hope t is a double *
		gl.MultMatrixd(t)
	end
end

function gl.Normal(x, y, z)
	if type(x) == "userdata" or type(x) == "cdata" then
		x, y, z = x:unpack()
	elseif type(x) == "table" then 
		x, y, z = unpack(x) 
	end
	gl.Normal3d(x, y, z or 0)
end

function gl.PixelStore(p, v) gl.PixelStoref(p, v) end

function gl.Rotate(a, x, y, z)
	if type(a) == "table" then a, x, y, z = unpack(a) end
	gl.Rotated(a, x, y, z)
end

function gl.Scale(x, y, z)
	if type(x) == "table" then 
		x, y, z = unpack(x) 
	end
	if not y then y, z = x, x end
	gl.Scaled(x, y, z)
end

function gl.TexCoord(x, y, z, w)
	if type(x) == "table" then x, y, z, w = unpack(x) end
	if w then
		gl.TexCoord4d(x, y, z, w)
	elseif z then
		gl.TexCoord3d(x, y, z)
	elseif y then
		gl.TexCoord2d(x, y)
	else
		error("gl.Vertex: invalid arguments")
	end
end

function gl.Translate(x, y, z)
	if type(x) == "table" then x, y, z = unpack(x) end
	gl.Translated(x, y, z)
end

function gl.Vertex(x, y, z, w)
	if type(x) == "userdata" or type(x) == "cdata" then
		x, y, z, w = x:unpack()
	elseif type(x) == "table" then 
		x, y, z, w = unpack(x) 
	end
	if w then
		gl.Vertex4d(x, y, z, w)
	elseif z then
		gl.Vertex3d(x, y, z)
	elseif y then
		gl.Vertex2d(x, y)
	else
		error("gl.Vertex: invalid arguments")
	end
end

function gl.TexParameter(target, pname)
	if pname == gl.TEXTURE_MAG_FILTER
		or pname == gl.TEXTURE_MIN_FILTER
		or pname == gl.TEXTURE_WRAP_S
		or pname == gl.TEXTURE_WRAP_T
		or pname == gl.TEXTURE_WRAP_R
		or pname == gl.TEXTURE_PRIORITY
		or pname == gl.TEXTURE_RESIDENT
		or pname == gl.TEXTURE_COMPARE_MODE
		or pname == gl.TEXTURE_COMPARE_FUNC
		or pname == gl.DEPTH_TEXTURE_MODE
		or pname == gl.GENERATE_MIPMAP then
		local params = ffi.new("GLuint[?]", 1)
		gl.GetTexParameteriv(target, pname, params)
		return params[0]
	elseif pname == gl.TEXTURE_MIN_LOD
		or pname == gl.TEXTURE_MAX_LOD
		or pname == gl.TEXTURE_BASE_LEVEL
		or pname == gl.TEXTURE_MAX_LEVEL then
		local params = ffi.new("GLfloat[?]", 1)
		gl.GetTexParameterfv(target, pname, params)
		return params[0]
	elseif pname == gl.TEXTURE_BORDER_COLOR then
		local params = ffi.new("GLfloat[?]", 4)
		gl.GetTexParameterfv(target, pname, params)
		return params[0], params[1], params[2], params[3]
	else
		error("gl.GetTexParameter: invalid arguments")
	end
end

local glGenFramebuffers = gl.GenFramebuffers
function gl.GenFramebuffers(n) 
	n = n or 1
	local arr = ffi.new("GLuint[?]", n)
	glGenFramebuffers(n, arr)
	local res = {}
	for i = 1, n do res[i] = arr[i-1] end
	return unpack(res)
end

local glDeleteFramebuffers = gl.DeleteFramebuffers 
function gl.DeleteFramebuffers(...)
	local t = {...}
	local n = #t
	local arr = ffi.new("GLuint[?]", n)
	for i = 1, n do arr[i-1] = t[i] end
	glDeleteFramebuffers(n, arr)
end

local glGenRenderbuffers = gl.GenRenderbuffers
function gl.GenRenderbuffers(n) 
	n = n or 1
	local arr = ffi.new("GLuint[?]", n)
	glGenRenderbuffers(n, arr)
	local res = {}
	for i = 1, n do res[i] = arr[i-1] end
	return unpack(res)
end

local glDeleteRenderbuffers = gl.DeleteRenderbuffers
function gl.DeleteRenderbuffers(...)
	local t = {...}
	local n = #t
	local arr = ffi.new("GLuint[?]", n)
	for i = 1, n do arr[i-1] = t[i] end
	glDeleteRenderbuffers(n, arr)
end

local glGenBuffers = gl.GenBuffers
function gl.GenBuffers(n) 
	n = n or 1
	local arr = ffi.new("GLuint[?]", n)
	glGenBuffers(n, arr)
	local res = {}
	for i = 1, n do res[i] = arr[i-1] end
	return unpack(res)
end

local glGenTextures = gl.GenTextures
function gl.GenTextures(n) 
	n = n or 1
	local arr = ffi.new("GLuint[?]", n)
	glGenTextures(n, arr)
	local res = {}
	for i = 1, n do res[i] = arr[i-1] end
	return unpack(res)
end

local glDeleteTextures = gl.DeleteTextures
function gl.DeleteTextures(...)
	local t = {...}
	local n = #t
	local arr = ffi.new("GLuint[?]", n)
	for i = 1, n do arr[i-1] = t[i] end
	glDeleteTextures(n, arr)
end

function gl.Shader(kind, code)
	local shader = gl.CreateShader(kind)
	assert(shader ~= 0, "Failed to allocate shader; is the GL context ready?")
	--print("shader", shader)
	if code then
		local numshaders = 1
		local codestr = ffi.new("const GLchar*[?]", numshaders)
		local len = ffi.new("int[?]", numshaders)
		local codeconstcharstar = ffi.cast("const char *", code)
		codestr[0] = codeconstcharstar
		local status = ffi.new("GLint[1]")
		len[0] = #code
		gl.ShaderSource(shader, 1, codestr, len)
		gl.GetShaderiv(shader, gl.SHADER_SOURCE_LENGTH, status)
		gl.CompileShader(shader)
		gl.GetShaderiv(shader, gl.COMPILE_STATUS, status)
		if status[0] == gl.FALSE then
			local infoLogLength = ffi.new("GLint[1]")
			gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, infoLogLength)
			local strInfoLog = ffi.new("GLchar[?]", infoLogLength[0] + 1)
			gl.GetShaderInfoLog(shader, infoLogLength[0], nil, strInfoLog)
			local ln = 1
			for line in string.gmatch(code, "[^\n]+") do
				print(ln, line)
				ln = ln + 1
			end
			error("gl.CompileShader: " .. ffi.string(strInfoLog))
		end
	end
	return shader
end

function gl.CreateVertexShader(code)
	return gl.Shader(gl.VERTEX_SHADER, code)
end

function gl.CreateFragmentShader(code)
	return gl.Shader(gl.FRAGMENT_SHADER, code)
end

function gl.Program(...)
	local program = gl.CreateProgram()
	assert(program ~= 0, "Failed to allocate shader program; is the GL context ready?")
	local args = {...}
	if #args > 0 then
		for s in ipairs(args) do
			gl.AttachShader(program, s)
		end
		gl.LinkProgram(program)
		
		local status = ffi.new("GLint[1]")
		gl.GetProgramiv(program, gl.LINK_STATUS, status)
		if status[0] == gl.FALSE then
			local infoLogLength = ffi.new("GLint[1]")
			gl.GetProgramiv(program, gl.INFO_LOG_LENGTH, infoLogLength)
			local strInfoLog = ffi.new("GLchar[?]", infoLogLength[0] + 1)
			gl.GetProgramInfoLog(program, infoLogLength[0], nil, strInfoLog)
			error("gl.LinkProgram " .. ffi.string(strInfoLog))
		end
		
		for s in ipairs(args) do
			gl.DetachShader(program, s)
		end
	end
	return program
end

function gl.Uniformf(loc, a, b, c, d)
	if d 	 then gl.Uniform4fARB(loc, a, b, c, d)
	elseif c then gl.Uniform3fARB(loc, a, b, c)
	elseif b then gl.Uniform2fARB(loc, a, b)
	elseif a then gl.Uniform1fARB(loc, a) 
	end
end
function gl.Uniformi(loc, a, b, c, d)
	if d 	 then gl.Uniform4iARB(loc, a, b, c, d)
	elseif c then gl.Uniform3iARB(loc, a, b, c)
	elseif b then gl.Uniform2iARB(loc, a, b)
	elseif a then gl.Uniform1iARB(loc, a) 
	end
end

-- TODO: metatables for Texture, RBO, FBO etc.

-- TODO: sketch submodule
local sketch = {}
gl.sketch = sketch

 -- no arguments, uses the default (-1, -1, 2, 2) normalized mode
 -- glOrtho(-1, 1, -1, 1, -100, 100)
 -- 2 arguments, sets up a pixel mode (0, 0, w, h)
 -- glOrtho(0, w, h, 0, -100, 100); 
 -- 4 arguments, sets an arbitrary mode (x, y, w, h)
 -- glOrtho(x, x+w, y, y+h, -100, 100)
function sketch.enter_ortho(x, y, w, h)
	if w then
		gl.MatrixMode(gl.PROJECTION)
		gl.PushMatrix()
		gl.LoadIdentity()
		gl.Ortho(x, x+w, y, y+h, -100, 100)

		gl.MatrixMode(gl.MODELVIEW);
		gl.PushMatrix()
		gl.LoadIdentity()
	elseif x then
		gl.MatrixMode(gl.PROJECTION)
		gl.PushMatrix()
		gl.LoadIdentity()
		gl.Ortho(0, x, y, 0, -100, 100)
		print("ortho", x, y)

		gl.MatrixMode(gl.MODELVIEW);
		gl.PushMatrix()
		gl.LoadIdentity()
	else
		gl.MatrixMode(gl.PROJECTION)
		gl.PushMatrix()
		gl.LoadIdentity()
		gl.Ortho(-1, 1, -1, 1, -100, 100)

		gl.MatrixMode(gl.MODELVIEW);
		gl.PushMatrix()
		gl.LoadIdentity()
	end
end

function sketch.leave_ortho()	
	gl.MatrixMode(gl.PROJECTION);
	gl.PopMatrix();

	gl.MatrixMode(gl.MODELVIEW);
	gl.PopMatrix();
end

function sketch.quad(x, y, w, h)
	gl.Begin(gl.QUADS)
	if not h then
		if not y then
			-- default quad
			x, y, w, h = -1, -1, 2, 2
		else
			-- scaled quad
			x, y, w, h = -w/2, -h/2, w, h
		end
	end
	gl.TexCoord2f(0, 0)
	gl.Vertex3f(x, y, 0)
	gl.TexCoord2f(1, 0)
	gl.Vertex3f(x+w, y, 0)
	gl.TexCoord2f(1, 1)
	gl.Vertex3f(x+w, y+h, 0)
	gl.TexCoord2f(0, 1)
	gl.Vertex3f(x, y+h, 0)
	gl.End()
end

gl.extensions_table = false
function gl.extensions()
	if not gl.extensions_table then
		print("VERSION", gl.GetString(gl.VERSION))
		print("VENDOR", gl.GetString(gl.VENDOR))
		print("RENDERER", gl.GetString(gl.RENDERER))
		print("SHADING_LANGUAGE_VERSION", gl.GetString(gl.SHADING_LANGUAGE_VERSION))
	
		gl.extensions_table = {}
		local extensions = tostring(gl.GetString(gl.EXTENSIONS))
		for w in extensions:gmatch("[^%s]+") do
			--print("EXTENSION", w)
			gl.extensions_table[w] = true
			table.insert(gl.extensions_table, w)
		end
	end
	return gl.extensions_table
end

--]]

return gl
