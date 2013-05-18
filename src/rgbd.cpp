#include "rgbd.h"
#include "av.hpp"

#include "libfreenect-registration.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>

#include <pthread.h>

typedef glm::highp_vec2 vec2;
typedef glm::highp_vec3 vec3;
typedef glm::highp_vec4 vec4;
typedef glm::detail::tquat<double> quat;

typedef glm::mediump_vec2 vec2f;
typedef glm::mediump_vec3 vec3f;
typedef glm::mediump_vec4 vec4f;
typedef glm::detail::tquat<float> quatf;

static av_RGBD rgbd;

static freenect_context * f_ctx = 0;
static struct freenect_device_attributes * attrs;

static pthread_t freenect_thread;
static volatile int die = 0;

static uint16_t t_gamma[10000];

static GLuint gl_depth_tex = 0;
static GLuint gl_rgb_tex = 0;

static vec2f texcoords[RGBD_POINTS_SIZE];

void av_rgbd_draw(int dev, int x, int y, int w, int h) {
	glViewport(x,y,w,h);
	glEnable(GL_SCISSOR_TEST);
	glScissor(x,y,w,h);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho (0, 1, 1, 0, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClearDepth(1.0);
//	glDepthFunc(GL_LESS);
    glDepthMask(GL_FALSE);
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_TEXTURE_2D);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//	glShadeModel(GL_FLAT);
	
	if (gl_depth_tex == 0) {
		printf("creating textures\n");
		glGenTextures(1, &gl_depth_tex);
		glBindTexture(GL_TEXTURE_2D, gl_depth_tex);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		glGenTextures(1, &gl_rgb_tex);
		glBindTexture(GL_TEXTURE_2D, gl_rgb_tex);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}

	glBindTexture(GL_TEXTURE_2D, gl_rgb_tex);
	glTexImage2D(GL_TEXTURE_2D, 0, 3, 640, 480, 0, GL_RGB, GL_UNSIGNED_BYTE, rgbd.sensors[dev].rgb_back);

	glBegin(GL_TRIANGLE_FAN);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glTexCoord2f(0, 0); glVertex3f(0,0,0);
	glTexCoord2f(1, 0); glVertex3f(1,0,0);
	glTexCoord2f(1, 1); glVertex3f(1,1,0);
	glTexCoord2f(0, 1); glVertex3f(0,1,0);
	glEnd();

	glBindTexture(GL_TEXTURE_2D, gl_depth_tex);
	glTexImage2D(GL_TEXTURE_2D, 0, 4, 640, 480, 0, GL_RGBA, GL_UNSIGNED_BYTE, rgbd.sensors[dev].depth_back);

	glBegin(GL_TRIANGLE_FAN);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glTexCoord2f(0, 0); glVertex3f(0,0,0);
	glTexCoord2f(1, 0); glVertex3f(1,0,0);
	glTexCoord2f(1, 1); glVertex3f(1,1,0);
	glTexCoord2f(0, 1); glVertex3f(0,1,0);
	glEnd();
	
	glBindTexture(GL_TEXTURE_2D, 0);
	glDisable(GL_SCISSOR_TEST);
}	

void av_rgbd_transform_rawpoints(av_RGBDSensor& sensor) {
	
	// create transform matrix:
	glm::mat4 transform;
	transform = glm::scale(transform, sensor.scale);
	transform = glm::rotate(transform, sensor.rotate.x, vec3f(1, 0, 0));
	transform = glm::rotate(transform, sensor.rotate.y, vec3f(0, 1, 0));
	transform = glm::rotate(transform, sensor.rotate.z, vec3f(0, 0, 1));
	transform = glm::translate(transform, sensor.translate);

	int idx = 0;
	for (int i=0; i<640*480; i++) {
		vec4f raw(sensor.rawpoints[i], 1.f);
		
		if (raw.z > 0) {
		
			// transform into world space:
			vec4f t = transform * raw;
			
			// clip to bounding box:
			if (t.x > sensor.minbound.x && t.x < sensor.maxbound.x &&
				t.y > sensor.minbound.y && t.y < sensor.maxbound.y &&
				t.z > sensor.minbound.z && t.z < sensor.maxbound.z) {
					
				sensor.points[idx].x = t.x;
				sensor.points[idx].y = t.y;
				sensor.points[idx].z = t.z;
				
				idx++;
			}
		}
	}
	sensor.numpoints = idx;
}

void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp) {
	av_RGBDSensor& sensor = *(av_RGBDSensor *)freenect_get_user(dev);	
	uint16_t *depth = (uint16_t*)v_depth;
	
//	float ymin = 0;
//	float ymax = 0;
//	float xmin = 0;
//	float xmax = 0;
	
	int i = 0;
	for (int y=0; y<480; y++) {
		for (int x=0; x<640; x++, i++) {
			//if (depth[i] >= 2048) continue;
			
			uint8_t * out = sensor.depth_back;
			
			// theoretically this is in mm:
			int mmz = depth[i];			
			
			int pval = t_gamma[depth[i]] / 32;
			int lb = pval & 0xff;
			out[4*i+3] = 128; // default alpha value
			if (depth[i] ==  0) {
				out[4*i+3] = 0; // remove anything without depth value
				
				// not an interesting point:
				sensor.rawpoints[i].x = 0;
				sensor.rawpoints[i].y = 0;
				sensor.rawpoints[i].z = 0;
				
			} else {
				
				// convert to meters:
				double mmx, mmy;
				freenect_camera_to_world(dev, x, y, mmz, &mmx, &mmy);
				vec4f raw(mmx * 0.001, mmy * 0.001, mmz * 0.001, 1.);
				
				// store:
				sensor.rawpoints[i].x = raw.x;
				sensor.rawpoints[i].y = raw.y;
				sensor.rawpoints[i].z = raw.z;
				
//				xmax = (mmx*0.001 > xmax) ? mmx*0.001 : xmax;
//				xmin = (mmx*0.001 < xmin) ? mmx*0.001 : xmin;
//				
//				ymax = (mmy*0.001 > ymax) ? mmy*0.001 : ymax;
//				ymin = (mmy*0.001 < ymin) ? mmy*0.001 : ymin;
			}

			switch (pval>>8) {
				case 0:
					out[4*i+0] = 255;
					out[4*i+1] = 255-lb;
					out[4*i+2] = 255-lb;
					break;
				case 1:
					out[4*i+0] = 255;
					out[4*i+1] = lb;
					out[4*i+2] = 0;
					break;
				case 2:
					out[4*i+0] = 255-lb;
					out[4*i+1] = 255;
					out[4*i+2] = 0;
					break;
				case 3:
					out[4*i+0] = 0;
					out[4*i+1] = 255;
					out[4*i+2] = lb;
					break;
				case 4:
					out[4*i+0] = 0;
					out[4*i+1] = 255-lb;
					out[4*i+2] = 255;
					break;
				case 5:
					out[4*i+0] = 0;
					out[4*i+1] = 0;
					out[4*i+2] = 255-lb;
					break;
				default:
					out[4*i+0] = 0;
					out[4*i+1] = 0;
					out[4*i+2] = 0;
					out[4*i+3] = 0;
					break;
			}
		}
	}
	
	// derive the world-space points:
	av_rgbd_transform_rawpoints(sensor);
	
	//printf("x <%03.1f %03.1f> y <%03.1f %03.1f>\n", xmin, xmax, ymin, ymax);

}

void av_rgbd_write_obj(int dev, const char * path) {
	
	av_RGBDSensor& sensor = rgbd.sensors[dev];
	
	FILE * ofile = fopen(path, "w");
	fprintf(ofile, "g depth");
	
	int i = 0;
	for (int y=0; y<480; y++) {
		for (int x=0; x<640; x++, i++) {
			vec3f& p = sensor.rawpoints[i];
			if (p.z > 0) {
				fprintf(ofile, "v %06.3f %06.3f %06.3f\n", p.x, p.y, p.z);
				fprintf(ofile, "vt %06.3f %06.3f\n", texcoords[i].x, texcoords[i].y);
			}
		}
	}
	
	fclose(ofile);	
}

void rgb_cb(freenect_device *dev, void *rgb, uint32_t timestamp) {
	av_RGBDSensor& sensor = *(av_RGBDSensor *)freenect_get_user(dev);
}

void *freenect_threadfunc(void *arg) {
	
	printf("RGBD starting with %d devices\n", rgbd.numdevices);
	
	for (int i=0; i<rgbd.numdevices; i++) {
		
		av_RGBDSensor& sensor = rgbd.sensors[i];
		
		freenect_set_depth_callback(sensor.dev, depth_cb);
		freenect_set_video_callback(sensor.dev, rgb_cb);
		freenect_set_video_mode(sensor.dev, freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB));
		freenect_set_depth_mode(sensor.dev, freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_REGISTERED));
		freenect_set_video_buffer(sensor.dev, sensor.rgb_back);
		
		freenect_set_user(sensor.dev, &sensor);

		freenect_start_depth(sensor.dev);
		freenect_start_video(sensor.dev);
		
	}
	
	while (!die) {
		int res = freenect_process_events(f_ctx);
		if (res < 0 && res != -10) {
			printf("\nError %d received from libusb - aborting.\n",res);
			break;
		}
	}
	
	printf("\nshutting down streams...\n");
	for (int i=0; i<rgbd.numdevices; i++) {
		av_RGBDSensor& sensor = rgbd.sensors[i];
		
		freenect_stop_depth(sensor.dev);
		freenect_stop_video(sensor.dev);
		freenect_close_device(sensor.dev);
	}
	
	printf("-- done!\n");
	return 0;
}

av_RGBD * av_rgbd_init() {
	static bool initialized = 0;
	if (initialized) return &rgbd;
	int i;
	
	if (freenect_init(&f_ctx, NULL) < 0) {
		printf("freenect_init() failed\n");
		return 0;
	}
	
	for (i=0; i<10000; i++) {
		float v = i/2048.0;
		v = powf(v, 3) * 6;
		t_gamma[i] = v*6*256;
	}
	
	for (int y=0, i=0; y<480; y++) {
		for (int x=0; x<640; x++, i++) {
			texcoords[i].x = x/640.;
			texcoords[i].y = y/480.;
		}
	}
	
	for (i=0; i<RGBD_MAX_SENSORS; i++) {
		av_RGBDSensor& sensor = rgbd.sensors[i];
		
		sensor.translate = vec3f(0);
		sensor.rotate = vec3f(0);
		sensor.scale = vec3f(1);
		sensor.minbound = vec3f(-10);
		sensor.maxbound = vec3f(10);
		sensor.numpoints = 0;
		
	}
	
	freenect_set_log_level(f_ctx, FREENECT_LOG_ERROR);
	freenect_select_subdevices(f_ctx, (freenect_device_flags)(FREENECT_DEVICE_CAMERA));

	int nr_devices = freenect_num_devices (f_ctx);
	printf ("Number of RGBD devices found: %d\n", nr_devices);
	
	// list connected devices (and check serial numbers)
	struct freenect_device_attributes * attrs;
	int numdevs = freenect_list_device_attributes(f_ctx, &attrs);
	rgbd.numdevices = numdevs;
	
	printf ("Number of RGBD devices attributed: %d\n", numdevs);
	
	i=0;
	for (; i<numdevs; i++) {
		if (attrs) {
			printf("RGBD device %d: %s\n", i, attrs->camera_serial);
			//rgbd.sensors[i].serial = attrs->camera_serial;
			sprintf(rgbd.sensors[i].serial, "%s", attrs->camera_serial);
			attrs = attrs->next;
		}
		
		if (freenect_open_device(f_ctx, &rgbd.sensors[i].dev, i) < 0) {
			printf("Could not open device\n");
		}
	}
	for (; i<RGBD_MAX_SENSORS; i++) {
		rgbd.sensors[i].serial[0] = 0;
		rgbd.sensors[i].dev = 0;
	}
	
	initialized = 1;
	return &rgbd;
}

void av_rgbd_start() {
	
	if (av_rgbd_init() == 0) 
	return;
	
	static bool started = 0;
	if (started) return;
	
	int res = pthread_create(&freenect_thread, NULL, freenect_threadfunc, NULL);
	if (res) {
		printf("pthread_create failed\n");
		return;
	}
	started = 1;
}

av_RGBDSensor * av_rgbd_open(int user_device_number) {
	av_RGBDSensor * sensor = new av_RGBDSensor;

	if (freenect_num_devices(f_ctx) < 1) {
		printf("no Kinect devices found\n");
		delete sensor;
		return 0;
	} else if (freenect_open_device(f_ctx, &sensor->dev, user_device_number) < 0) {
		printf("Could not open device\n");
		delete sensor;
		return 0;
	}
	
	return sensor;
}

int av_rgbd_quit() {
	freenect_free_device_attributes(attrs);
	return 0;
}
