local ffi = require 'ffi'

local lib
if ffi.os == "Linux" then
	lib = ffi.load("freeimage")
elseif ffi.os == "OSX" then
	--local exepath = exepath or ""
	--lib = ffi.load(exepath .. "/modules/lib/OSX/freeimage.dylib")
	lib = ffi.load("freeimage")
else
	lib = ffi.C
end	

local m = {}
m["FREEIMAGE_H"] = 1
m["FREEIMAGE_MAJOR_VERSION"] = 3
m["FREEIMAGE_MINOR_VERSION"] = 15
m["FREEIMAGE_RELEASE_SERIAL"] = 1
m["FREEIMAGE_BIGENDIAN"] = 1
m["FREEIMAGE_COLORORDER_BGR"] = 1
m["FREEIMAGE_COLORORDER_RGB"] = 1
m["FREEIMAGE_COLORORDER"] = m["FREEIMAGE_COLORORDER_RGB"]
m["FREEIMAGE_COLORORDER"] = m["FREEIMAGE_COLORORDER_BGR"]
m["FI_DEFAULT"] = 1
m["FI_ENUM"] = m["enum"]
m["FI_STRUCT"] = 1
m["FI_DEFAULT"] = 1
m["FI_ENUM"] = m["typedef"]
m["FI_STRUCT"] = 1
m["FALSE"] = 0
m["TRUE"] = 1
m["NULL"] = 0
m["SEEK_SET"] = 0
m["SEEK_CUR"] = 1
m["SEEK_END"] = 2
m["FI_RGBA_RED"] = 1
m["FI_RGBA_GREEN"] = 1
m["FI_RGBA_BLUE"] = 1
m["FI_RGBA_ALPHA"] = 1
m["FI_RGBA_RED_MASK"] = 1
m["FI_RGBA_GREEN_MASK"] = 1
m["FI_RGBA_BLUE_MASK"] = 1
m["FI_RGBA_ALPHA_MASK"] = 1
m["FI_RGBA_RED_SHIFT"] = 1
m["FI_RGBA_GREEN_SHIFT"] = 1
m["FI_RGBA_BLUE_SHIFT"] = 1
m["FI_RGBA_ALPHA_SHIFT"] = 1
m["FI_RGBA_RED"] = 1
m["FI_RGBA_GREEN"] = 1
m["FI_RGBA_BLUE"] = 1
m["FI_RGBA_ALPHA"] = 1
m["FI_RGBA_RED_MASK"] = 1
m["FI_RGBA_GREEN_MASK"] = 1
m["FI_RGBA_BLUE_MASK"] = 1
m["FI_RGBA_ALPHA_MASK"] = 1
m["FI_RGBA_RED_SHIFT"] = 1
m["FI_RGBA_GREEN_SHIFT"] = 1
m["FI_RGBA_BLUE_SHIFT"] = 1
m["FI_RGBA_ALPHA_SHIFT"] = 1
m["FI_RGBA_RED"] = 1
m["FI_RGBA_GREEN"] = 1
m["FI_RGBA_BLUE"] = 1
m["FI_RGBA_ALPHA"] = 1
m["FI_RGBA_RED_MASK"] = 1
m["FI_RGBA_GREEN_MASK"] = 1
m["FI_RGBA_BLUE_MASK"] = 1
m["FI_RGBA_ALPHA_MASK"] = 1
m["FI_RGBA_RED_SHIFT"] = 1
m["FI_RGBA_GREEN_SHIFT"] = 1
m["FI_RGBA_BLUE_SHIFT"] = 1
m["FI_RGBA_ALPHA_SHIFT"] = 1
m["FI_RGBA_RED"] = 1
m["FI_RGBA_GREEN"] = 1
m["FI_RGBA_BLUE"] = 1
m["FI_RGBA_ALPHA"] = 1
m["FI_RGBA_RED_MASK"] = 1
m["FI_RGBA_GREEN_MASK"] = 1
m["FI_RGBA_BLUE_MASK"] = 1
m["FI_RGBA_ALPHA_MASK"] = 1
m["FI_RGBA_RED_SHIFT"] = 1
m["FI_RGBA_GREEN_SHIFT"] = 1
m["FI_RGBA_BLUE_SHIFT"] = 1
m["FI_RGBA_ALPHA_SHIFT"] = 1
m["FI_RGBA_RGB_MASK"] = 1
m["FI16_555_RED_MASK"] = 1
m["FI16_555_GREEN_MASK"] = 1
m["FI16_555_BLUE_MASK"] = 1
m["FI16_555_RED_SHIFT"] = 1
m["FI16_555_GREEN_SHIFT"] = 1
m["FI16_555_BLUE_SHIFT"] = 1
m["FI16_565_RED_MASK"] = 1
m["FI16_565_GREEN_MASK"] = 1
m["FI16_565_BLUE_MASK"] = 1
m["FI16_565_RED_SHIFT"] = 1
m["FI16_565_GREEN_SHIFT"] = 1
m["FI16_565_BLUE_SHIFT"] = 1
m["FIICC_DEFAULT"] = 1
m["FIICC_COLOR_IS_CMYK"] = 1
m["FREEIMAGE_IO"] = 1
m["PLUGINS"] = 1
m["FIF_LOAD_NOPIXELS"] = 0x8000
m["BMP_DEFAULT"] = 0
m["BMP_SAVE_RLE"] = 1
m["CUT_DEFAULT"] = 0
m["DDS_DEFAULT"] = 1
m["EXR_DEFAULT"] = 1
m["EXR_FLOAT"] = 1
m["EXR_NONE"] = 1
m["EXR_ZIP"] = 1
m["EXR_PIZ"] = 1
m["EXR_PXR24"] = 1
m["EXR_B44"] = 1
m["EXR_LC"] = 1
m["FAXG3_DEFAULT"] = 1
m["GIF_DEFAULT"] = 1
m["GIF_LOAD256"] = 1
m["GIF_PLAYBACK"] = 1
m["HDR_DEFAULT"] = 1
m["ICO_DEFAULT"] = 0
m["ICO_MAKEALPHA"] = 1
m["IFF_DEFAULT"] = 0
m["J2K_DEFAULT"] = 1
m["JP2_DEFAULT"] = 1
m["JPEG_DEFAULT"] = 0
m["JPEG_FAST"] = 0x0001
m["JPEG_ACCURATE"] = 0x0002
m["JPEG_CMYK"] = 1
m["JPEG_EXIFROTATE"] = 1
m["JPEG_QUALITYSUPERB"] = 0x80
m["JPEG_QUALITYGOOD"] = 0x0100
m["JPEG_QUALITYNORMAL"] = 0x0200
m["JPEG_QUALITYAVERAGE"] = 0x0400
m["JPEG_QUALITYBAD"] = 0x0800
m["JPEG_PROGRESSIVE"] = 1
m["JPEG_SUBSAMPLING_411"] = 0x1000
m["JPEG_SUBSAMPLING_420"] = 0x4000
m["JPEG_SUBSAMPLING_422"] = 0x8000
m["JPEG_SUBSAMPLING_444"] = 0x10000
m["JPEG_OPTIMIZE"] = 1
m["JPEG_BASELINE"] = 1
m["KOALA_DEFAULT"] = 0
m["LBM_DEFAULT"] = 0
m["MNG_DEFAULT"] = 0
m["PCD_DEFAULT"] = 0
m["PCD_BASE"] = 1
m["PCD_BASEDIV4"] = 2
m["PCD_BASEDIV16"] = 3
m["PCX_DEFAULT"] = 0
m["PFM_DEFAULT"] = 0
m["PICT_DEFAULT"] = 0
m["PNG_DEFAULT"] = 0
m["PNG_IGNOREGAMMA"] = 1
m["PNG_Z_BEST_SPEED"] = 1
m["PNG_Z_DEFAULT_COMPRESSION"] = 1
m["PNG_Z_BEST_COMPRESSION"] = 1
m["PNG_Z_NO_COMPRESSION"] = 1
m["PNG_INTERLACED"] = 1
m["PNM_DEFAULT"] = 0
m["PNM_SAVE_RAW"] = 0
m["PNM_SAVE_ASCII"] = 1
m["PSD_DEFAULT"] = 0
m["PSD_CMYK"] = 1
m["PSD_LAB"] = 1
m["RAS_DEFAULT"] = 0
m["RAW_DEFAULT"] = 0
m["RAW_PREVIEW"] = 1
m["RAW_DISPLAY"] = 1
m["RAW_HALFSIZE"] = 1
m["SGI_DEFAULT"] = 1
m["TARGA_DEFAULT"] = 0
m["TARGA_LOAD_RGB888"] = 1
m["TARGA_SAVE_RLE"] = 1
m["TIFF_DEFAULT"] = 0
m["TIFF_CMYK"] = 1
m["TIFF_PACKBITS"] = 0x0100
m["TIFF_DEFLATE"] = 0x0200
m["TIFF_ADOBE_DEFLATE"] = 0x0400
m["TIFF_NONE"] = 0x0800
m["TIFF_CCITTFAX3"] = 1
m["TIFF_CCITTFAX4"] = 1
m["TIFF_LZW"] = 1
m["TIFF_JPEG"] = 1
m["TIFF_LOGLUV"] = 1
m["WBMP_DEFAULT"] = 0
m["XBM_DEFAULT"] = 1
m["XPM_DEFAULT"] = 1
m["FI_COLOR_IS_RGB_COLOR"] = 1
m["FI_COLOR_IS_RGBA_COLOR"] = 1
m["FI_COLOR_FIND_EQUAL_COLOR"] = 1
m["FI_COLOR_ALPHA_IS_INDEX"] = 1
m["FI_COLOR_PALETTE_SEARCH_MASK"] = 1
m.header = [[

typedef struct FIBITMAP FIBITMAP; struct FIBITMAP { void *data; };
typedef struct FIMULTIBITMAP FIMULTIBITMAP; struct FIMULTIBITMAP { void *data; };
typedef int32_t BOOL;
typedef uint8_t BYTE;
typedef uint16_t WORD;
typedef uint32_t DWORD;
typedef int32_t LONG;
typedef struct tagRGBQUAD {
  BYTE rgbBlue;
  BYTE rgbGreen;
  BYTE rgbRed;
  BYTE rgbReserved;
} RGBQUAD;
typedef struct tagRGBTRIPLE {
  BYTE rgbtBlue;
  BYTE rgbtGreen;
  BYTE rgbtRed;
} RGBTRIPLE;
typedef struct tagBITMAPINFOHEADER{
  DWORD biSize;
  LONG biWidth;
  LONG biHeight;
  WORD biPlanes;
  WORD biBitCount;
  DWORD biCompression;
  DWORD biSizeImage;
  LONG biXPelsPerMeter;
  LONG biYPelsPerMeter;
  DWORD biClrUsed;
  DWORD biClrImportant;
} BITMAPINFOHEADER, *PBITMAPINFOHEADER;
typedef struct tagBITMAPINFO {
  BITMAPINFOHEADER bmiHeader;
  RGBQUAD bmiColors[1];
} BITMAPINFO, *PBITMAPINFO;
typedef struct tagFIRGB16 {
 WORD red;
 WORD green;
 WORD blue;
} FIRGB16;
typedef struct tagFIRGBA16 {
 WORD red;
 WORD green;
 WORD blue;
 WORD alpha;
} FIRGBA16;
typedef struct tagFIRGBF {
 float red;
 float green;
 float blue;
} FIRGBF;
typedef struct tagFIRGBAF {
 float red;
 float green;
 float blue;
 float alpha;
} FIRGBAF;
typedef struct tagFICOMPLEX {
 double r;
    double i;
} FICOMPLEX;
typedef struct FIICCPROFILE FIICCPROFILE; struct FIICCPROFILE {
 WORD flags;
 DWORD size;
 void *data;
};
typedef int FREE_IMAGE_FORMAT; enum FREE_IMAGE_FORMAT {
 FIF_UNKNOWN = -1,
 FIF_BMP = 0,
 FIF_ICO = 1,
 FIF_JPEG = 2,
 FIF_JNG = 3,
 FIF_KOALA = 4,
 FIF_LBM = 5,
 FIF_IFF = FIF_LBM,
 FIF_MNG = 6,
 FIF_PBM = 7,
 FIF_PBMRAW = 8,
 FIF_PCD = 9,
 FIF_PCX = 10,
 FIF_PGM = 11,
 FIF_PGMRAW = 12,
 FIF_PNG = 13,
 FIF_PPM = 14,
 FIF_PPMRAW = 15,
 FIF_RAS = 16,
 FIF_TARGA = 17,
 FIF_TIFF = 18,
 FIF_WBMP = 19,
 FIF_PSD = 20,
 FIF_CUT = 21,
 FIF_XBM = 22,
 FIF_XPM = 23,
 FIF_DDS = 24,
 FIF_GIF = 25,
 FIF_HDR = 26,
 FIF_FAXG3 = 27,
 FIF_SGI = 28,
 FIF_EXR = 29,
 FIF_J2K = 30,
 FIF_JP2 = 31,
 FIF_PFM = 32,
 FIF_PICT = 33,
 FIF_RAW = 34
};
typedef int FREE_IMAGE_TYPE; enum FREE_IMAGE_TYPE {
 FIT_UNKNOWN = 0,
 FIT_BITMAP = 1,
 FIT_UINT16 = 2,
 FIT_INT16 = 3,
 FIT_UINT32 = 4,
 FIT_INT32 = 5,
 FIT_FLOAT = 6,
 FIT_DOUBLE = 7,
 FIT_COMPLEX = 8,
 FIT_RGB16 = 9,
 FIT_RGBA16 = 10,
 FIT_RGBF = 11,
 FIT_RGBAF = 12
};
typedef int FREE_IMAGE_COLOR_TYPE; enum FREE_IMAGE_COLOR_TYPE {
 FIC_MINISWHITE = 0,
    FIC_MINISBLACK = 1,
    FIC_RGB = 2,
    FIC_PALETTE = 3,
 FIC_RGBALPHA = 4,
 FIC_CMYK = 5
};
typedef int FREE_IMAGE_QUANTIZE; enum FREE_IMAGE_QUANTIZE {
    FIQ_WUQUANT = 0,
    FIQ_NNQUANT = 1
};
typedef int FREE_IMAGE_DITHER; enum FREE_IMAGE_DITHER {
    FID_FS = 0,
 FID_BAYER4x4 = 1,
 FID_BAYER8x8 = 2,
 FID_CLUSTER6x6 = 3,
 FID_CLUSTER8x8 = 4,
 FID_CLUSTER16x16= 5,
 FID_BAYER16x16 = 6
};
typedef int FREE_IMAGE_JPEG_OPERATION; enum FREE_IMAGE_JPEG_OPERATION {
 FIJPEG_OP_NONE = 0,
 FIJPEG_OP_FLIP_H = 1,
 FIJPEG_OP_FLIP_V = 2,
 FIJPEG_OP_TRANSPOSE = 3,
 FIJPEG_OP_TRANSVERSE = 4,
 FIJPEG_OP_ROTATE_90 = 5,
 FIJPEG_OP_ROTATE_180 = 6,
 FIJPEG_OP_ROTATE_270 = 7
};
typedef int FREE_IMAGE_TMO; enum FREE_IMAGE_TMO {
    FITMO_DRAGO03 = 0,
 FITMO_REINHARD05 = 1,
 FITMO_FATTAL02 = 2
};
typedef int FREE_IMAGE_FILTER; enum FREE_IMAGE_FILTER {
 FILTER_BOX = 0,
 FILTER_BICUBIC = 1,
 FILTER_BILINEAR = 2,
 FILTER_BSPLINE = 3,
 FILTER_CATMULLROM = 4,
 FILTER_LANCZOS3 = 5
};
typedef int FREE_IMAGE_COLOR_CHANNEL; enum FREE_IMAGE_COLOR_CHANNEL {
 FICC_RGB = 0,
 FICC_RED = 1,
 FICC_GREEN = 2,
 FICC_BLUE = 3,
 FICC_ALPHA = 4,
 FICC_BLACK = 5,
 FICC_REAL = 6,
 FICC_IMAG = 7,
 FICC_MAG = 8,
 FICC_PHASE = 9
};
typedef int FREE_IMAGE_MDTYPE; enum FREE_IMAGE_MDTYPE {
 FIDT_NOTYPE = 0,
 FIDT_BYTE = 1,
 FIDT_ASCII = 2,
 FIDT_SHORT = 3,
 FIDT_LONG = 4,
 FIDT_RATIONAL = 5,
 FIDT_SBYTE = 6,
 FIDT_UNDEFINED = 7,
 FIDT_SSHORT = 8,
 FIDT_SLONG = 9,
 FIDT_SRATIONAL = 10,
 FIDT_FLOAT = 11,
 FIDT_DOUBLE = 12,
 FIDT_IFD = 13,
 FIDT_PALETTE = 14
};
typedef int FREE_IMAGE_MDMODEL; enum FREE_IMAGE_MDMODEL {
 FIMD_NODATA = -1,
 FIMD_COMMENTS = 0,
 FIMD_EXIF_MAIN = 1,
 FIMD_EXIF_EXIF = 2,
 FIMD_EXIF_GPS = 3,
 FIMD_EXIF_MAKERNOTE = 4,
 FIMD_EXIF_INTEROP = 5,
 FIMD_IPTC = 6,
 FIMD_XMP = 7,
 FIMD_GEOTIFF = 8,
 FIMD_ANIMATION = 9,
 FIMD_CUSTOM = 10,
 FIMD_EXIF_RAW = 11
};
typedef struct FIMETADATA FIMETADATA; struct FIMETADATA { void *data; };
typedef struct FITAG FITAG; struct FITAG { void *data; };
typedef void* fi_handle;
typedef unsigned ( *FI_ReadProc) (void *buffer, unsigned size, unsigned count, fi_handle handle);
typedef unsigned ( *FI_WriteProc) (void *buffer, unsigned size, unsigned count, fi_handle handle);
typedef int ( *FI_SeekProc) (fi_handle handle, long offset, int origin);
typedef long ( *FI_TellProc) (fi_handle handle);
typedef struct FreeImageIO FreeImageIO; struct FreeImageIO {
 FI_ReadProc read_proc;
    FI_WriteProc write_proc;
    FI_SeekProc seek_proc;
    FI_TellProc tell_proc;
};
typedef struct FIMEMORY FIMEMORY; struct FIMEMORY { void *data; };
typedef const char *( *FI_FormatProc)(void);
typedef const char *( *FI_DescriptionProc)(void);
typedef const char *( *FI_ExtensionListProc)(void);
typedef const char *( *FI_RegExprProc)(void);
typedef void *( *FI_OpenProc)(FreeImageIO *io, fi_handle handle, BOOL read);
typedef void ( *FI_CloseProc)(FreeImageIO *io, fi_handle handle, void *data);
typedef int ( *FI_PageCountProc)(FreeImageIO *io, fi_handle handle, void *data);
typedef int ( *FI_PageCapabilityProc)(FreeImageIO *io, fi_handle handle, void *data);
typedef FIBITMAP *( *FI_LoadProc)(FreeImageIO *io, fi_handle handle, int page, int flags, void *data);
typedef BOOL ( *FI_SaveProc)(FreeImageIO *io, FIBITMAP *dib, fi_handle handle, int page, int flags, void *data);
typedef BOOL ( *FI_ValidateProc)(FreeImageIO *io, fi_handle handle);
typedef const char *( *FI_MimeProc)(void);
typedef BOOL ( *FI_SupportsExportBPPProc)(int bpp);
typedef BOOL ( *FI_SupportsExportTypeProc)(FREE_IMAGE_TYPE type);
typedef BOOL ( *FI_SupportsICCProfilesProc)(void);
typedef BOOL ( *FI_SupportsNoPixelsProc)(void);
typedef struct Plugin Plugin; struct Plugin {
 FI_FormatProc format_proc;
 FI_DescriptionProc description_proc;
 FI_ExtensionListProc extension_proc;
 FI_RegExprProc regexpr_proc;
 FI_OpenProc open_proc;
 FI_CloseProc close_proc;
 FI_PageCountProc pagecount_proc;
 FI_PageCapabilityProc pagecapability_proc;
 FI_LoadProc load_proc;
 FI_SaveProc save_proc;
 FI_ValidateProc validate_proc;
 FI_MimeProc mime_proc;
 FI_SupportsExportBPPProc supports_export_bpp_proc;
 FI_SupportsExportTypeProc supports_export_type_proc;
 FI_SupportsICCProfilesProc supports_icc_profiles_proc;
 FI_SupportsNoPixelsProc supports_no_pixels_proc;
};
typedef void ( *FI_InitProc)(Plugin *plugin, int format_id);
void FreeImage_Initialise(BOOL load_local_plugins_only );
void FreeImage_DeInitialise(void);
const char * FreeImage_GetVersion(void);
const char * FreeImage_GetCopyrightMessage(void);
typedef void (*FreeImage_OutputMessageFunction)(FREE_IMAGE_FORMAT fif, const char *msg);
typedef void ( *FreeImage_OutputMessageFunctionStdCall)(FREE_IMAGE_FORMAT fif, const char *msg);
void FreeImage_SetOutputMessageStdCall(FreeImage_OutputMessageFunctionStdCall omf);
void FreeImage_SetOutputMessage(FreeImage_OutputMessageFunction omf);
void FreeImage_OutputMessageProc(int fif, const char *fmt, ...);
FIBITMAP * FreeImage_Allocate(int width, int height, int bpp, unsigned red_mask , unsigned green_mask , unsigned blue_mask );
FIBITMAP * FreeImage_AllocateT(FREE_IMAGE_TYPE type, int width, int height, int bpp , unsigned red_mask , unsigned green_mask , unsigned blue_mask );
FIBITMAP * FreeImage_Clone(FIBITMAP *dib);
void FreeImage_Unload(FIBITMAP *dib);
BOOL FreeImage_HasPixels(FIBITMAP *dib);
FIBITMAP * FreeImage_Load(FREE_IMAGE_FORMAT fif, const char *filename, int flags );
FIBITMAP * FreeImage_LoadU(FREE_IMAGE_FORMAT fif, const wchar_t *filename, int flags );
FIBITMAP * FreeImage_LoadFromHandle(FREE_IMAGE_FORMAT fif, FreeImageIO *io, fi_handle handle, int flags );
BOOL FreeImage_Save(FREE_IMAGE_FORMAT fif, FIBITMAP *dib, const char *filename, int flags );
BOOL FreeImage_SaveU(FREE_IMAGE_FORMAT fif, FIBITMAP *dib, const wchar_t *filename, int flags );
BOOL FreeImage_SaveToHandle(FREE_IMAGE_FORMAT fif, FIBITMAP *dib, FreeImageIO *io, fi_handle handle, int flags );
FIMEMORY * FreeImage_OpenMemory(BYTE *data , DWORD size_in_bytes );
void FreeImage_CloseMemory(FIMEMORY *stream);
FIBITMAP * FreeImage_LoadFromMemory(FREE_IMAGE_FORMAT fif, FIMEMORY *stream, int flags );
BOOL FreeImage_SaveToMemory(FREE_IMAGE_FORMAT fif, FIBITMAP *dib, FIMEMORY *stream, int flags );
long FreeImage_TellMemory(FIMEMORY *stream);
BOOL FreeImage_SeekMemory(FIMEMORY *stream, long offset, int origin);
BOOL FreeImage_AcquireMemory(FIMEMORY *stream, BYTE **data, DWORD *size_in_bytes);
unsigned FreeImage_ReadMemory(void *buffer, unsigned size, unsigned count, FIMEMORY *stream);
unsigned FreeImage_WriteMemory(const void *buffer, unsigned size, unsigned count, FIMEMORY *stream);
FIMULTIBITMAP * FreeImage_LoadMultiBitmapFromMemory(FREE_IMAGE_FORMAT fif, FIMEMORY *stream, int flags );
BOOL FreeImage_SaveMultiBitmapToMemory(FREE_IMAGE_FORMAT fif, FIMULTIBITMAP *bitmap, FIMEMORY *stream, int flags);
FREE_IMAGE_FORMAT FreeImage_RegisterLocalPlugin(FI_InitProc proc_address, const char *format , const char *description , const char *extension , const char *regexpr );
FREE_IMAGE_FORMAT FreeImage_RegisterExternalPlugin(const char *path, const char *format , const char *description , const char *extension , const char *regexpr );
int FreeImage_GetFIFCount(void);
int FreeImage_SetPluginEnabled(FREE_IMAGE_FORMAT fif, BOOL enable);
int FreeImage_IsPluginEnabled(FREE_IMAGE_FORMAT fif);
FREE_IMAGE_FORMAT FreeImage_GetFIFFromFormat(const char *format);
FREE_IMAGE_FORMAT FreeImage_GetFIFFromMime(const char *mime);
const char * FreeImage_GetFormatFromFIF(FREE_IMAGE_FORMAT fif);
const char * FreeImage_GetFIFExtensionList(FREE_IMAGE_FORMAT fif);
const char * FreeImage_GetFIFDescription(FREE_IMAGE_FORMAT fif);
const char * FreeImage_GetFIFRegExpr(FREE_IMAGE_FORMAT fif);
const char * FreeImage_GetFIFMimeType(FREE_IMAGE_FORMAT fif);
FREE_IMAGE_FORMAT FreeImage_GetFIFFromFilename(const char *filename);
FREE_IMAGE_FORMAT FreeImage_GetFIFFromFilenameU(const wchar_t *filename);
BOOL FreeImage_FIFSupportsReading(FREE_IMAGE_FORMAT fif);
BOOL FreeImage_FIFSupportsWriting(FREE_IMAGE_FORMAT fif);
BOOL FreeImage_FIFSupportsExportBPP(FREE_IMAGE_FORMAT fif, int bpp);
BOOL FreeImage_FIFSupportsExportType(FREE_IMAGE_FORMAT fif, FREE_IMAGE_TYPE type);
BOOL FreeImage_FIFSupportsICCProfiles(FREE_IMAGE_FORMAT fif);
BOOL FreeImage_FIFSupportsNoPixels(FREE_IMAGE_FORMAT fif);
FIMULTIBITMAP * FreeImage_OpenMultiBitmap(FREE_IMAGE_FORMAT fif, const char *filename, BOOL create_new, BOOL read_only, BOOL keep_cache_in_memory , int flags );
FIMULTIBITMAP * FreeImage_OpenMultiBitmapFromHandle(FREE_IMAGE_FORMAT fif, FreeImageIO *io, fi_handle handle, int flags );
BOOL FreeImage_SaveMultiBitmapToHandle(FREE_IMAGE_FORMAT fif, FIMULTIBITMAP *bitmap, FreeImageIO *io, fi_handle handle, int flags );
BOOL FreeImage_CloseMultiBitmap(FIMULTIBITMAP *bitmap, int flags );
int FreeImage_GetPageCount(FIMULTIBITMAP *bitmap);
void FreeImage_AppendPage(FIMULTIBITMAP *bitmap, FIBITMAP *data);
void FreeImage_InsertPage(FIMULTIBITMAP *bitmap, int page, FIBITMAP *data);
void FreeImage_DeletePage(FIMULTIBITMAP *bitmap, int page);
FIBITMAP * FreeImage_LockPage(FIMULTIBITMAP *bitmap, int page);
void FreeImage_UnlockPage(FIMULTIBITMAP *bitmap, FIBITMAP *data, BOOL changed);
BOOL FreeImage_MovePage(FIMULTIBITMAP *bitmap, int target, int source);
BOOL FreeImage_GetLockedPageNumbers(FIMULTIBITMAP *bitmap, int *pages, int *count);
FREE_IMAGE_FORMAT FreeImage_GetFileType(const char *filename, int size );
FREE_IMAGE_FORMAT FreeImage_GetFileTypeU(const wchar_t *filename, int size );
FREE_IMAGE_FORMAT FreeImage_GetFileTypeFromHandle(FreeImageIO *io, fi_handle handle, int size );
FREE_IMAGE_FORMAT FreeImage_GetFileTypeFromMemory(FIMEMORY *stream, int size );
FREE_IMAGE_TYPE FreeImage_GetImageType(FIBITMAP *dib);
BOOL FreeImage_IsLittleEndian(void);
BOOL FreeImage_LookupX11Color(const char *szColor, BYTE *nRed, BYTE *nGreen, BYTE *nBlue);
BOOL FreeImage_LookupSVGColor(const char *szColor, BYTE *nRed, BYTE *nGreen, BYTE *nBlue);
BYTE * FreeImage_GetBits(FIBITMAP *dib);
BYTE * FreeImage_GetScanLine(FIBITMAP *dib, int scanline);
BOOL FreeImage_GetPixelIndex(FIBITMAP *dib, unsigned x, unsigned y, BYTE *value);
BOOL FreeImage_GetPixelColor(FIBITMAP *dib, unsigned x, unsigned y, RGBQUAD *value);
BOOL FreeImage_SetPixelIndex(FIBITMAP *dib, unsigned x, unsigned y, BYTE *value);
BOOL FreeImage_SetPixelColor(FIBITMAP *dib, unsigned x, unsigned y, RGBQUAD *value);
unsigned FreeImage_GetColorsUsed(FIBITMAP *dib);
unsigned FreeImage_GetBPP(FIBITMAP *dib);
unsigned FreeImage_GetWidth(FIBITMAP *dib);
unsigned FreeImage_GetHeight(FIBITMAP *dib);
unsigned FreeImage_GetLine(FIBITMAP *dib);
unsigned FreeImage_GetPitch(FIBITMAP *dib);
unsigned FreeImage_GetDIBSize(FIBITMAP *dib);
RGBQUAD * FreeImage_GetPalette(FIBITMAP *dib);
unsigned FreeImage_GetDotsPerMeterX(FIBITMAP *dib);
unsigned FreeImage_GetDotsPerMeterY(FIBITMAP *dib);
void FreeImage_SetDotsPerMeterX(FIBITMAP *dib, unsigned res);
void FreeImage_SetDotsPerMeterY(FIBITMAP *dib, unsigned res);
BITMAPINFOHEADER * FreeImage_GetInfoHeader(FIBITMAP *dib);
BITMAPINFO * FreeImage_GetInfo(FIBITMAP *dib);
FREE_IMAGE_COLOR_TYPE FreeImage_GetColorType(FIBITMAP *dib);
unsigned FreeImage_GetRedMask(FIBITMAP *dib);
unsigned FreeImage_GetGreenMask(FIBITMAP *dib);
unsigned FreeImage_GetBlueMask(FIBITMAP *dib);
unsigned FreeImage_GetTransparencyCount(FIBITMAP *dib);
BYTE * FreeImage_GetTransparencyTable(FIBITMAP *dib);
void FreeImage_SetTransparent(FIBITMAP *dib, BOOL enabled);
void FreeImage_SetTransparencyTable(FIBITMAP *dib, BYTE *table, int count);
BOOL FreeImage_IsTransparent(FIBITMAP *dib);
void FreeImage_SetTransparentIndex(FIBITMAP *dib, int index);
int FreeImage_GetTransparentIndex(FIBITMAP *dib);
BOOL FreeImage_HasBackgroundColor(FIBITMAP *dib);
BOOL FreeImage_GetBackgroundColor(FIBITMAP *dib, RGBQUAD *bkcolor);
BOOL FreeImage_SetBackgroundColor(FIBITMAP *dib, RGBQUAD *bkcolor);
FIBITMAP * FreeImage_GetThumbnail(FIBITMAP *dib);
BOOL FreeImage_SetThumbnail(FIBITMAP *dib, FIBITMAP *thumbnail);
FIICCPROFILE * FreeImage_GetICCProfile(FIBITMAP *dib);
FIICCPROFILE * FreeImage_CreateICCProfile(FIBITMAP *dib, void *data, long size);
void FreeImage_DestroyICCProfile(FIBITMAP *dib);
void FreeImage_ConvertLine1To4(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine8To4(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine16To4_555(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine16To4_565(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine24To4(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine32To4(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine1To8(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine4To8(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine16To8_555(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine16To8_565(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine24To8(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine32To8(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine1To16_555(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine4To16_555(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine8To16_555(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine16_565_To16_555(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine24To16_555(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine32To16_555(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine1To16_565(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine4To16_565(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine8To16_565(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine16_555_To16_565(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine24To16_565(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine32To16_565(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine1To24(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine4To24(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine8To24(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine16To24_555(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine16To24_565(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine32To24(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine1To32(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine4To32(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine8To32(BYTE *target, BYTE *source, int width_in_pixels, RGBQUAD *palette);
void FreeImage_ConvertLine16To32_555(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine16To32_565(BYTE *target, BYTE *source, int width_in_pixels);
void FreeImage_ConvertLine24To32(BYTE *target, BYTE *source, int width_in_pixels);
FIBITMAP * FreeImage_ConvertTo4Bits(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertTo8Bits(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertToGreyscale(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertTo16Bits555(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertTo16Bits565(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertTo24Bits(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertTo32Bits(FIBITMAP *dib);
FIBITMAP * FreeImage_ColorQuantize(FIBITMAP *dib, FREE_IMAGE_QUANTIZE quantize);
FIBITMAP * FreeImage_ColorQuantizeEx(FIBITMAP *dib, FREE_IMAGE_QUANTIZE quantize , int PaletteSize , int ReserveSize , RGBQUAD *ReservePalette );
FIBITMAP * FreeImage_Threshold(FIBITMAP *dib, BYTE T);
FIBITMAP * FreeImage_Dither(FIBITMAP *dib, FREE_IMAGE_DITHER algorithm);
FIBITMAP * FreeImage_ConvertFromRawBits(BYTE *bits, int width, int height, int pitch, unsigned bpp, unsigned red_mask, unsigned green_mask, unsigned blue_mask, BOOL topdown );
void FreeImage_ConvertToRawBits(BYTE *bits, FIBITMAP *dib, int pitch, unsigned bpp, unsigned red_mask, unsigned green_mask, unsigned blue_mask, BOOL topdown );
FIBITMAP * FreeImage_ConvertToFloat(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertToRGBF(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertToUINT16(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertToRGB16(FIBITMAP *dib);
FIBITMAP * FreeImage_ConvertToStandardType(FIBITMAP *src, BOOL scale_linear );
FIBITMAP * FreeImage_ConvertToType(FIBITMAP *src, FREE_IMAGE_TYPE dst_type, BOOL scale_linear );
FIBITMAP * FreeImage_ToneMapping(FIBITMAP *dib, FREE_IMAGE_TMO tmo, double first_param , double second_param );
FIBITMAP * FreeImage_TmoDrago03(FIBITMAP *src, double gamma , double exposure );
FIBITMAP * FreeImage_TmoReinhard05(FIBITMAP *src, double intensity , double contrast );
FIBITMAP * FreeImage_TmoReinhard05Ex(FIBITMAP *src, double intensity , double contrast , double adaptation , double color_correction );
FIBITMAP * FreeImage_TmoFattal02(FIBITMAP *src, double color_saturation , double attenuation );
DWORD FreeImage_ZLibCompress(BYTE *target, DWORD target_size, BYTE *source, DWORD source_size);
DWORD FreeImage_ZLibUncompress(BYTE *target, DWORD target_size, BYTE *source, DWORD source_size);
DWORD FreeImage_ZLibGZip(BYTE *target, DWORD target_size, BYTE *source, DWORD source_size);
DWORD FreeImage_ZLibGUnzip(BYTE *target, DWORD target_size, BYTE *source, DWORD source_size);
DWORD FreeImage_ZLibCRC32(DWORD crc, BYTE *source, DWORD source_size);
FITAG * FreeImage_CreateTag(void);
void FreeImage_DeleteTag(FITAG *tag);
FITAG * FreeImage_CloneTag(FITAG *tag);
const char * FreeImage_GetTagKey(FITAG *tag);
const char * FreeImage_GetTagDescription(FITAG *tag);
WORD FreeImage_GetTagID(FITAG *tag);
FREE_IMAGE_MDTYPE FreeImage_GetTagType(FITAG *tag);
DWORD FreeImage_GetTagCount(FITAG *tag);
DWORD FreeImage_GetTagLength(FITAG *tag);
const void * FreeImage_GetTagValue(FITAG *tag);
BOOL FreeImage_SetTagKey(FITAG *tag, const char *key);
BOOL FreeImage_SetTagDescription(FITAG *tag, const char *description);
BOOL FreeImage_SetTagID(FITAG *tag, WORD id);
BOOL FreeImage_SetTagType(FITAG *tag, FREE_IMAGE_MDTYPE type);
BOOL FreeImage_SetTagCount(FITAG *tag, DWORD count);
BOOL FreeImage_SetTagLength(FITAG *tag, DWORD length);
BOOL FreeImage_SetTagValue(FITAG *tag, const void *value);
FIMETADATA * FreeImage_FindFirstMetadata(FREE_IMAGE_MDMODEL model, FIBITMAP *dib, FITAG **tag);
BOOL FreeImage_FindNextMetadata(FIMETADATA *mdhandle, FITAG **tag);
void FreeImage_FindCloseMetadata(FIMETADATA *mdhandle);
BOOL FreeImage_SetMetadata(FREE_IMAGE_MDMODEL model, FIBITMAP *dib, const char *key, FITAG *tag);
BOOL FreeImage_GetMetadata(FREE_IMAGE_MDMODEL model, FIBITMAP *dib, const char *key, FITAG **tag);
unsigned FreeImage_GetMetadataCount(FREE_IMAGE_MDMODEL model, FIBITMAP *dib);
BOOL FreeImage_CloneMetadata(FIBITMAP *dst, FIBITMAP *src);
const char* FreeImage_TagToString(FREE_IMAGE_MDMODEL model, FITAG *tag, char *Make );
FIBITMAP * FreeImage_RotateClassic(FIBITMAP *dib, double angle);
FIBITMAP * FreeImage_Rotate(FIBITMAP *dib, double angle, const void *bkcolor );
FIBITMAP * FreeImage_RotateEx(FIBITMAP *dib, double angle, double x_shift, double y_shift, double x_origin, double y_origin, BOOL use_mask);
BOOL FreeImage_FlipHorizontal(FIBITMAP *dib);
BOOL FreeImage_FlipVertical(FIBITMAP *dib);
BOOL FreeImage_JPEGTransform(const char *src_file, const char *dst_file, FREE_IMAGE_JPEG_OPERATION operation, BOOL perfect );
BOOL FreeImage_JPEGTransformU(const wchar_t *src_file, const wchar_t *dst_file, FREE_IMAGE_JPEG_OPERATION operation, BOOL perfect );
FIBITMAP * FreeImage_Rescale(FIBITMAP *dib, int dst_width, int dst_height, FREE_IMAGE_FILTER filter);
FIBITMAP * FreeImage_MakeThumbnail(FIBITMAP *dib, int max_pixel_size, BOOL convert );
BOOL FreeImage_AdjustCurve(FIBITMAP *dib, BYTE *LUT, FREE_IMAGE_COLOR_CHANNEL channel);
BOOL FreeImage_AdjustGamma(FIBITMAP *dib, double gamma);
BOOL FreeImage_AdjustBrightness(FIBITMAP *dib, double percentage);
BOOL FreeImage_AdjustContrast(FIBITMAP *dib, double percentage);
BOOL FreeImage_Invert(FIBITMAP *dib);
BOOL FreeImage_GetHistogram(FIBITMAP *dib, DWORD *histo, FREE_IMAGE_COLOR_CHANNEL channel );
int FreeImage_GetAdjustColorsLookupTable(BYTE *LUT, double brightness, double contrast, double gamma, BOOL invert);
BOOL FreeImage_AdjustColors(FIBITMAP *dib, double brightness, double contrast, double gamma, BOOL invert );
unsigned FreeImage_ApplyColorMapping(FIBITMAP *dib, RGBQUAD *srccolors, RGBQUAD *dstcolors, unsigned count, BOOL ignore_alpha, BOOL swap);
unsigned FreeImage_SwapColors(FIBITMAP *dib, RGBQUAD *color_a, RGBQUAD *color_b, BOOL ignore_alpha);
unsigned FreeImage_ApplyPaletteIndexMapping(FIBITMAP *dib, BYTE *srcindices, BYTE *dstindices, unsigned count, BOOL swap);
unsigned FreeImage_SwapPaletteIndices(FIBITMAP *dib, BYTE *index_a, BYTE *index_b);
FIBITMAP * FreeImage_GetChannel(FIBITMAP *dib, FREE_IMAGE_COLOR_CHANNEL channel);
BOOL FreeImage_SetChannel(FIBITMAP *dst, FIBITMAP *src, FREE_IMAGE_COLOR_CHANNEL channel);
FIBITMAP * FreeImage_GetComplexChannel(FIBITMAP *src, FREE_IMAGE_COLOR_CHANNEL channel);
BOOL FreeImage_SetComplexChannel(FIBITMAP *dst, FIBITMAP *src, FREE_IMAGE_COLOR_CHANNEL channel);
FIBITMAP * FreeImage_Copy(FIBITMAP *dib, int left, int top, int right, int bottom);
BOOL FreeImage_Paste(FIBITMAP *dst, FIBITMAP *src, int left, int top, int alpha);
FIBITMAP * FreeImage_Composite(FIBITMAP *fg, BOOL useFileBkg , RGBQUAD *appBkColor , FIBITMAP *bg );
BOOL FreeImage_JPEGCrop(const char *src_file, const char *dst_file, int left, int top, int right, int bottom);
BOOL FreeImage_JPEGCropU(const wchar_t *src_file, const wchar_t *dst_file, int left, int top, int right, int bottom);
BOOL FreeImage_PreMultiplyWithAlpha(FIBITMAP *dib);
BOOL FreeImage_FillBackground(FIBITMAP *dib, const void *color, int options );
FIBITMAP * FreeImage_EnlargeCanvas(FIBITMAP *src, int left, int top, int right, int bottom, const void *color, int options );
FIBITMAP * FreeImage_AllocateEx(int width, int height, int bpp, const RGBQUAD *color, int options , const RGBQUAD *palette , unsigned red_mask , unsigned green_mask , unsigned blue_mask );
FIBITMAP * FreeImage_AllocateExT(FREE_IMAGE_TYPE type, int width, int height, int bpp, const void *color, int options , const RGBQUAD *palette , unsigned red_mask , unsigned green_mask , unsigned blue_mask );
FIBITMAP * FreeImage_MultigridPoissonSolver(FIBITMAP *Laplacian, int ncycle );
]]
ffi.cdef(m.header)

setmetatable(m, {
	__index = function(s, k)
		local v = lib["FreeImage_" .. k]
		s[k] = v
		return v
	end,
})

m.Initialise(0)
print("using FreeImage", ffi.string(m.GetVersion()))
print(ffi.string(m.GetCopyrightMessage()))

return m

