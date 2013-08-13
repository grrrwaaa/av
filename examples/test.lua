
local audio = require "audio"

audio.driver.outdevice = 4
audio.start()
print(audio.driver.outchannels)