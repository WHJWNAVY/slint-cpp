@echo off

set cur_path=%cd%
set cmake_exe=cmake.exe
set upx_exe=upx.exe

rem gcc or llvm
set cc_type=llvm

if "%cc_type%" == "gcc" (
	rem gcc:WinLibs
	set cc_dir=C:\WinLibs\ucrt\bin
	set strip_name=strip.exe
	set cxx_name=g++.exe
	set cc_name=gcc.exe
	set make_name=mingw32-make.exe
) else (
	rem llvm:WinLibs
	set cc_dir=C:\WinLibs\ucrt\bin
	set strip_name=llvm-strip.exe
	set cxx_name=clang++.exe
	set cc_name=clang.exe
	set make_name=mingw32-make.exe
)
set strip_exe=%cc_dir%/%strip_name%
set cxx_compiler=%cc_dir%/%cxx_name%
set cc_compiler=%cc_dir%/%cc_name%
set make_program=%cc_dir%/%make_name%
echo "cc_dir = [%cc_dir%]"
echo "cc_compiler = [%cc_compiler%]"

set build_dir=my_build
set install_dir=my_install

set cflags=-Os -flto -DNDEBUG -ffunction-sections -fdata-sections
set ldlibrary=-lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32 -lcomctl32 -liphlpapi -lws2_32 -lntoskrnl -lbcrypt -lopengl32 -luiautomationcore -lpropsys -ldwmapi -limm32 -luxtheme -luserenv

echo "cflags = [%cflags%]"
echo "ldlibrary = [%ldlibrary%]"

set ldflags=-Os -DNDEBUG -Wl,-subsystem,windows -Wl,--gc-sections

echo "Del build cache"
rmdir /s /q %build_dir%
rmdir /s /q %install_dir%
mkdir %build_dir%
mkdir %install_dir%
call :my_sleep

echo "Run cmake generator"
%cmake_exe% -G "MinGW Makefiles" -B "%build_dir%" ^
	-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON ^
	-DCMAKE_BUILD_TYPE:STRING=MinSizeRel ^
	-DBUILD_SHARED_LIBS:BOOL=OFF ^
	-DSLINT_STYLE=native ^
	-DSLINT_FEATURE_RENDERER_FEMTOVG:BOOL=OFF ^
	-DSLINT_FEATURE_RENDERER_SOFTWARE:BOOL=ON ^
	-DRust_CARGO_TARGET=x86_64-pc-windows-gnu ^
	-DDEFAULT_SLINT_EMBED_RESOURCES:STRING=embed-for-software-renderer ^
	-DCMAKE_CXX_COMPILER:STRING="%cxx_compiler%" ^
	-DCMAKE_MAKE_PROGRAM:FILEPATH="%make_program%" ^
	-DCMAKE_C_COMPILER:STRING="%cc_compiler%" ^
	-DCMAKE_CXX_FLAGS:STRING="%cflags%" ^
	-DCMAKE_C_FLAGS:STRING="%cflags%" ^
	-DCMAKE_CXX_STANDARD_LIBRARIES:STRING="%ldlibrary%" ^
	-DCMAKE_C_STANDARD_LIBRARIES:STRING="%ldlibrary%" ^
	-DCMAKE_STATIC_LINKER_FLAGS:STRING="%ldflags%" ^
	-DCMAKE_EXE_LINKER_FLAGS:STRING="%ldflags%" ^
	-DCMAKE_INSTALL_PREFIX:PATH="%install_dir%"
if %errorlevel% neq 0 goto my_error
call :my_sleep

echo "Run cmake build [%cmake_exe% --build %build_dir%]"
%cmake_exe% --build %build_dir%
if %errorlevel% neq 0 goto my_error
call :my_sleep

echo "Run install [%cmake_exe% --install %build_dir%]"
%cmake_exe% --install %build_dir%
if %errorlevel% neq 0 goto my_error
goto my_success

:my_sleep
rem echo "wait 1s ..."
ping 127.0.0.1 -n 2 > nul
goto :eof

:my_success
echo "Build success!"
goto :eof

:my_error
echo "Build failed!"
goto :eof