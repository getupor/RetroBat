@echo off
setlocal EnableDelayedExpansion

goto:rem
---------------------------------------
build.bat
---------------------------------------
This batch script is made to help download all the required software for RetroBat,
to set the default configuration and to build the setup from sources.
---------------------------------------
:rem

set script_type=builder
set retrobat_branch=master

:: ---- BUILDER OPTION ----

set retroarch_version=1.10.3
set zip_loglevel=0

set get_batgui=0
set get_batocera_ports=1
set get_bios=1
set get_decorations=1
set get_default_theme=1
set get_emulationstation=1
set get_lrcores=1
set get_mega_bezels=0
set get_retroarch=1
set get_retrobat_binaries=1
set get_roms=0
set get_wiimotegun=1

set deps_list=(git makensis 7za strip wget)
set clone_list=(bios decorations default_theme)
set download_list=(retrobat_binaries batgui emulationstation batocera_ports mega_bezels retroarch roms wiimotegun)

:: ---- GET STARTED ----

call :set_root
call :set_install
call :set_builder

:: ---- UI ----

call :banner

echo  This script can help you to download all the required 
echo  softwares and build the RetroBat Setup with the NullSoft 
echo  Scriptable Install System.
echo +===========================================================+
echo  - (D)ownload required softwares and build Setup
echo  - (B)uild Setup only
echo  - (Q)uit
echo +===========================================================+
choice /C DBQ /N /T 10 /D D /M "Please type your choice here: "
echo +===========================================================+

set user_choice=%ERRORLEVEL%

if %user_choice% EQU 1 (

	call :get_packages
	call :set_config
	call :build_setup
	call :exit_door
	goto :eof
)

if %user_choice% EQU 2 (

	call :set_config
	call :build_setup
	call :exit_door
	goto :eof
)

if %user_choice% EQU 3 (

	(set exit_code=0)
	call :exit_door
	goto :eof
)

:: ---- LABELS ----

:: ---- SET ROOT PATH ----

:set_root

set current_file=%~nx0
set current_drive="%cd:~0,2%"
set current_dir="%cd:~3%"
set current_drive=%current_drive:"=%
set current_dir=%current_dir:"=%
set current_path=!current_drive!\!current_dir!
set root_path=!current_path!

goto :eof

:: ---- SET INSTALL INFOS ----

:set_install

:: ---- SET TMP FILE ----

set tmp_infos_file=!root_path!\rb_infos.tmp
if exist "!tmp_infos_file!" del/Q "!tmp_infos_file!"

:: ---- CALL SHARED VARIABLES SCRIPT ----

if exist "!root_path!\system\scripts\shared-variables.cmd" (

	cd "!root_path!\system\scripts"
	call shared-variables.cmd	
	
) else (

	(set exit_code=2)
	call :exit_door
	goto :eof
)

:: ---- GET INFOS STORED IN TMP FILE ----

if exist "!tmp_infos_file!" (

	for /f "delims=" %%x in ('type "!tmp_infos_file!"') do (set "%%x") 
	del/Q "!tmp_infos_file!"
	
) else (

	(set/A exit_code=2)
	call :exit_door
	goto :eof
)

:: ---- WINDOW TITLE ----

title !name! Builder Script

goto :eof

:: ---- DEPENDENCIES CHECKING ----

:set_builder

call :banner

echo :: CHECKING BUILD DEPENDENCIES...

(set/A found_total=0)

if "%archx%"=="x86_64" (set "git_path=%ProgramFiles%\Git\cmd") else (set "git_path=%ProgramFiles(x86)%\Git\cmd")

for %%i in %deps_list% do (

	(set/A found_%%i=0)
	(set/A found_total=!found_total!+1)
	(set package_name=%%i)
	(set buildtools_path=!root_path!\buildtools\msys)
	
	if "!package_name!"=="git" (set buildtools_path=!git_path!)
	if "!package_name!"=="makensis" (set buildtools_path=!root_path!\buildtools\nsis)
	
	if exist "!buildtools_path!\!package_name!.exe" (
	
		(set/A found_%%i=!found_%%i!+1)
		echo %%i: found
		
	) else (
	
		echo %%i: not found
	)
	
	(set/A found_total=!found_total!-!found_%%i!)		
)

if !found_total! NEQ 0 (
	
	(set/A exit_code=2)
	call :exit_door
	goto :eof
)
	
timeout /t 3 >nul

goto :eof

:: ---- GET PACKAGES ----

:get_packages

echo :: GETTING REQUIRED PACKAGES...

cd !root_path!
git submodule update --init

if %ERRORLEVEL% NEQ 0 (

	(set/A exit_code=%ERRORLEVEL%)
	call :exit_door
	goto :eof
)

for %%i in %download_list% do (

	if "!get_%%i!"=="1" (
		
		(set package_name=%%i)
		(set package_file=%%i.7z)
		(set download_url=!%%i_url!)
		(set destination_path=!%%i_path!)		

		if "!package_name!"=="retrobat_binaries" (set package_file=%%i_%retrobat_branch%.7z)
		if "!package_name!"=="emulationstation" (set package_file=EmulationStation-Win32.zip)
		if "!package_name!"=="batocera_ports" (set package_file=batocera-ports.zip)
		if "!package_name!"=="retroarch" (set package_file=RetroArch.7z)
		if "!package_name!"=="wiimotegun" (set package_file=WiimoteGun.zip)
		
		call :download
		call :extract		
	)
)

if "%get_lrcores%"=="1" (

	for /f "usebackq delims=" %%x in ("%system_path%\configgen\lrcores_names.list") do (

		(set package_name=%%x)
		(set package_file=%%x_libretro.dll.zip)
		(set download_url=%lrcores_url%/!package_file!)
		(set destination_path=%lrcores_path%)

		call :download
		call :extract	
	)
)

goto :eof

:: ---- DOWNLOAD PACKAGES ----

:download

echo *************************************************************

if "!package_name!"=="4do" (

	set download_url=https://www.retrobat.ovh/repo/%arch%/legacy/lrcores
)

if "!package_name!"=="mame2016" (

	set download_url=https://www.retrobat.ovh/repo/%arch%/legacy/lrcores
)

if "!package_name!"=="px68k" (

	set download_url=https://www.retrobat.ovh/repo/%arch%/legacy/lrcores
)

"%buildtools_path%\wget" --continue --no-check-certificate --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 3 -P "%download_path%" !download_url!/!package_file! -q --show-progress

if %ERRORLEVEL% NEQ 0 (

	(set/A exit_code=%ERRORLEVEL%)
	call :exit_door
	goto :eof
)

if not exist "%download_path%\%package_file%" (

	(set/A exit_code=2)
	call :exit_door
	goto :eof
	
)
goto :eof

:: ---- EXTRACT PACKAGES ----

:extract

echo *************************************************************

if not exist "%extraction_path%\." md "%extraction_path%"
"%buildtools_path%\7za.exe" -y x "%download_path%\%package_file%" -aoa -o"%extraction_path%"

set true=1

if "!package_name!"=="retroarch" (

	set true=0
	
	if "%archx%"=="x86_64" (
				
		xcopy "%extraction_path%\RetroArch-Win64" "%destination_path%\" /s /e /v /y
		rmdir /s /q "%download_path%\extract\RetroArch-Win64"
	)
	
	if "%archx%"=="x86" (
	
		xcopy "%extraction_path%\RetroArch" "%destination_path%\" /s /e /v /y
		rmdir /s /q "%download_path%\extract\RetroArch"
	)
	
) 

if "%true%"=="1" (

	xcopy "%extraction_path%" "%destination_path%\" /e /v /y
)
 
rmdir /s /q "%download_path%\extract"
del/Q "%download_path%\%package_file%"

goto :eof

:: ---- SET RETROBAT CONFIG ----

:set_config

echo :: COPYING FILES IN BUILD DIRECTORY...

cd "!root_path!"

if not exist "!build_path!\." md "!build_path!"

for %%i in (bios emulationstation emulators roms system) do (xcopy "!root_path!\%%i" "!build_path!\%%i" /i /s /e /v /y)

for %%i in (exe dat txt) do (xcopy "!root_path!\*.%%i" "!build_path!" /v /y)

echo :: SETTING CONFIG FILES...

for /f "usebackq delims=" %%x in ("%system_path%\configgen\retrobat_tree.list") do (if not exist "!build_path!\%%x\." md "!build_path!\%%x")
for /f "usebackq delims=" %%x in ("%system_path%\configgen\emulators_names.list") do (if not exist "!build_path!\emulators\%%x\." md "!build_path!\emulators\%%x")
for /f "usebackq delims=" %%x in ("%system_path%\configgen\systems_names.list") do (if not exist "!build_path!\roms\%%x\." md "!build_path!\roms\%%x")
for /f "usebackq delims=" %%x in ("%system_path%\configgen\systems_names.list") do (if not exist "!build_path!\saves\%%x\." md "!build_path!\saves\%%x")

if exist "!build_path!\retrobat.exe" (

rem	"!build_path!\retrobat.exe" /NOF #MakeTree
rem	"!build_path!\retrobat.exe" /NOF #GetConfigFiles
	"!build_path!\retrobat.exe" /NOF #SetEmulationStationSettings
	"!build_path!\retrobat.exe" /NOF #SetEmulatorsSettings
	
	if %ERRORLEVEL% NEQ 0 (
		(set/A exit_code=%ERRORLEVEL%)
		call :exit_door
		goto :eof
	)

) else (

	(set/A exit_code=2)
	call :exit_door
	goto :eof
	
)

if exist "!system_path!\templates\emulationstation\*.mp4" xcopy /v /y "!system_path!\templates\emulationstation\*.mp4" "!build_path!\emulationstation\.emulationstation\video"
if exist "!system_path!\templates\emulationstation\*.ogg" xcopy /v /y "!system_path!\templates\emulationstation\*.ogg" "!build_path!\emulationstation\.emulationstation\music"

goto :eof

:: ---- BUILD RETROBAT SETUP ----

:build_setup

echo :: BUILDING RETROBAT SETUP...

!buildtools_path!\..\nsis\makensis.exe /V4 "!root_path!\installer.nsi"

if %ERRORLEVEL% NEQ 0 (
		(set/A exit_code=%ERRORLEVEL%)
		call :exit_door
		goto :eof
	)

goto :eof

:: ---- BANNER ----

:banner

cls
echo +===========================================================+
echo  !name! Builder Script
echo +===========================================================+
goto :eof

:: ---- EXIT ----

:exit_door

echo :: EXITING...

if exist "!tmp_infos_file!" del/Q "!tmp_infos_file!"

(echo %date% %time% [INFO] exit_code=!exit_code!)>> "!root_path!\build.log"
pause
rem timeout /t 15>nul
exit !exit_code!