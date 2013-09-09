@rem Script to build AV with MSVC.
@rem Run ins a "Visual Studio Command Prompt"

@rem build luajit:
cd luajit-2.0\src
msvcbuild
cd ..\..

@rem this won't work because it relies on gcc -E
@rem luajit-2.0\src\luajit.exe h2ffi.lua av.h av_ffi_header