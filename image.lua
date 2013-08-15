
local ffi = require "ffi"
local C = ffi.C

local freeimage = require "freeimage"
local texture = require "texture"
local glu = require "glu"

function load(name)
	local filetype = freeimage.GetFileType(name,0)
	assert(freeimage.FIFSupportsReading(filetype), "cannot parse image type")
	local flags = 0
	local img = freeimage.Load(filetype, name, flags)
	if img == nil then error("failed to load "..name) end
	local res = freeimage.ConvertTo32Bits(img)
	freeimage.Unload(img)
	img = res
	
	local colortype = freeimage.GetColorType(img)
	if colortype == C.FIC_MINISWHITE or colortype == C.FIC_MINISBLACK then
		print("greyscale")
		local res = freeimage.ConvertToGreyscale(img)
		freeimage.Unload(img)
		img = res
	end
	
	local w = freeimage.GetWidth(img)
	local h = freeimage.GetHeight(img)
	local datatype = freeimage.GetImageType(img)
	assert(datatype == C.FIT_BITMAP, "only 8-bit unsigned image types yet")
	local hdr = freeimage.GetInfoHeader(img)
	--print(hdr.biBitCount)
	local pixels = freeimage.GetBits(img)
	--print(w, h, pixels)
	
	local tex = texture(w, h)
	tex.data = pixels
	
	-- format depends on the file... 
	--tex.format = gl.BGRA
	
	-- segfault.. probably need to copy the pixels... 
	--freeimage.Unload(img)
	
	glu.assert("image loaded")
	
	return tex
end

return load
