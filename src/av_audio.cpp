#include "av.hpp"
//#include "portaudio.h"
#include "RtAudio.h"

#define AV_AUDIO_MSGBUFFER_SIZE_DEFAULT (1024 * 1024)

// the FFI exposed object:
static av_Audio audio;

// the internal object:
static RtAudio rta;

// the audio-thread Lua state:
static lua_State * AL = 0;

int av_rtaudio_callback(void *outputBuffer, 
						void *inputBuffer, 
						unsigned int frames,
						double streamTime, 
						RtAudioStreamStatus status, 
						void *data) {
	
	audio.input = (float *)inputBuffer;
	audio.output = (float *)outputBuffer;
	audio.frames = frames;
	
	double newtime = audio.time + frames / audio.samplerate;
	
	// zero outbuffers:
	memset(outputBuffer, 0, sizeof(float) * frames);
	
	// this calls back into Lua via FFI:
	if (audio.onframes) {
		(audio.onframes)(&audio, newtime, audio.input, audio.output, frames);
	}
	
	audio.time = newtime;
	
	return 0;
}

void av_audio_start() {
	if (!rta.isStreamRunning()) {
		if (rta.isStreamOpen()) {
			// close it:
			rta.closeStream();
		}	
		
		unsigned int devices = rta.getDeviceCount();
		if (devices < 1) {
			printf("no audio devices found\n");
			return;
		}
		
		RtAudio::DeviceInfo info;
		
		info = rta.getDeviceInfo(audio.indevice);
		printf("Using audio input %d: %dx%d (%d) %s\n", audio.indevice, info.inputChannels, info.outputChannels, info.duplexChannels, info.name.c_str());
		
		info = rta.getDeviceInfo(audio.outdevice);
		printf("Using audio output %d: %dx%d (%d) %s\n", audio.outdevice, info.inputChannels, info.outputChannels, info.duplexChannels, info.name.c_str());
		
		RtAudio::StreamParameters iParams, oParams;
		
		iParams.deviceId = audio.indevice;
		iParams.nChannels = audio.inchannels;
		iParams.firstChannel = 0;
		
		oParams.deviceId = audio.outdevice;
		oParams.nChannels = audio.outchannels;
		oParams.firstChannel = 0;

		RtAudio::StreamOptions options;
		options.flags |= RTAUDIO_NONINTERLEAVED;
		options.streamName = "av";
		
		try {
			rta.openStream( &oParams, &iParams, RTAUDIO_FLOAT32, audio.samplerate, &audio.blocksize, &av_rtaudio_callback, NULL, &options );
			rta.startStream();
			printf("Audio started\n");
		}
		catch ( RtError& e ) {
			fprintf(stderr, "%s\n", e.getMessage().c_str());
		}
	}
}

av_Audio * av_audio_get() {
	static bool initialized = false;
	if (!initialized) {
		initialized = true;
		
		rta.showWarnings( true );		
		
		// defaults:
		audio.samplerate = 44100;
		audio.blocksize = 256;
		audio.inchannels = 2;
		audio.outchannels = 2;
		audio.time = 0;
		audio.lag = 0.04;
		audio.indevice = rta.getDefaultInputDevice();
		audio.outdevice = rta.getDefaultOutputDevice();
		audio.msgbuffer.size = AV_AUDIO_MSGBUFFER_SIZE_DEFAULT;
		audio.msgbuffer.read = 0;
		audio.msgbuffer.write = 0;
		audio.msgbuffer.data = (unsigned char *)malloc(audio.msgbuffer.size);
		
		audio.onframes = 0;
		
		AL = av_init_lua();
		
		// unique to audio thread:
		if (luaL_dostring(AL, "require 'audioprocess'")) {
			printf("error: %s\n", lua_tostring(AL, -1));
			initialized = false;
		} 
	}
	return &audio;
}

