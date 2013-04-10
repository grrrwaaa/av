#ifndef AV_RGBD_H
#define AV_RGBD_H

#include "av.h"

#ifdef __cplusplus

#include <stdint.h>

#include "glm/glm.hpp"
#include "glm/gtc/quaternion.hpp"
#include "glm/gtc/matrix_transform.hpp"

typedef glm::highp_vec2 vec2;
typedef glm::highp_vec3 vec3;
typedef glm::highp_vec4 vec4;
typedef glm::detail::tquat<double> quat;

typedef glm::mediump_vec2 vec2f;
typedef glm::mediump_vec3 vec3f;
typedef glm::mediump_vec4 vec4f;
typedef glm::detail::tquat<float> quatf;

#else

typedef struct vec1 { double x, y; } vec1;
typedef struct vec3 { double x, y, z; } vec3;
typedef struct vec4 { double x, y, z, w; } vec4;
typedef struct quat { double x, y, z, w; } quat;

typedef struct vec2f { float x, y; } vec2f;
typedef struct vec3f { float x, y, z; } vec3f;
typedef struct vec4f { float x, y, z, w; } vec4f;
typedef struct quatf { float x, y, z, w; } quatf;

#endif

#ifdef __cplusplus
#include <stdint.h>
#include "libfreenect.h"

typedef freenect_device rgbd_device;
extern "C" {
#else
typedef struct rgbd_device rgbd_device;
#endif

#define RGBD_MAX_SENSORS 4
#define RGBD_DEPTH_SIZE 640*480*4
#define RGBD_RGB_SIZE 640*480*3
#define RGBD_POINTS_SIZE 640*480

typedef struct av_RGBDSensor {

	rgbd_device * dev;
	const char * serial;
	
	void (*onframe)(struct av_RGBDSensor * self);
	
	uint8_t rgb_back[RGBD_RGB_SIZE];
	//uint8_t rgb_front[RGBD_RGB_SIZE];
	
	uint8_t depth_back[RGBD_DEPTH_SIZE];
	//uint8_t depth_front[RGBD_DEPTH_SIZE];
	
	vec3f rawpoints[RGBD_POINTS_SIZE];
	
	vec3f points[RGBD_POINTS_SIZE];
	int numpoints;
	
	// 3D transformation into world space:
	vec3f translate, rotate, scale;
	vec3f minbound, maxbound;
	
} av_RGBDSensor;

typedef struct av_RGBD {

	int numdevices;
	av_RGBDSensor sensors[RGBD_MAX_SENSORS];
	
} av_RGBD;


// only use from main thread:
AV_EXPORT av_RGBD * av_rgbd_init();
AV_EXPORT void av_rgbd_start();
AV_EXPORT void av_rgbd_transform_rawpoints(av_RGBDSensor& sensor);
AV_EXPORT void av_rgbd_draw(int dev, int w, int h);
AV_EXPORT void av_rgbd_write_obj(int dev, const char * path);

#ifdef __cplusplus
}
#endif

#endif