:: Purpose:       Tron's pre-run checks. Various things to check before continuing on.
:: Requirements:  Called by tron.bat during script initialization
:: Author:        vocatus on reddit.com/r/TronScript ( vocatus.gate at gmail ) // PGP key: 0x07d1490f82a211a2
:: Version:       1.0.4 ! Fix syntax error in IF statement: Wrap paths in quotes to handle special characters and spaces
::                1.0.3 * Don't download drivedb.h definitions file if in either autorun mode
::                1.0.2 * Don't download drivedb.h definitions file if doing a dry run
::                1.0.1 + Add automatic update of drivedb.h prior to scanning hard drives. This ensures we're always on the latest definitions file
::                        Silently fails if no network connection
::                1.0.0 . Initial write, forked out of v9.9.0 of tron.bat


:: Script version
set PRERUN_CHECKS_SCRIPT_VERSION=1.0.4
set PRERUN_CHECKS_SCRIPT_DATE=2017-12-11



::::::::::::
:: CHECKS ::
::::::::::::

:: CHECK: Admin rights
:: Skip this check if we're in Safe Mode because Safe Mode command prompts always start with Admin rights
SETLOCAL ENABLEDELAYEDEXPANSION
if /i not "%SAFE_MODE%"=="yes" (
	fsutil dirty query %systemdrive% >NUL 2>&1
	if /i not !ERRORLEVEL!==0 (
		color cf
		cls
		echo.
		echo  ERROR
		echo.
		echo  Look you fucking moron, Tron needs to be run as Admin
		echo  Re-Run Tron as Administrator so you won't see this 
		echo  obvious warning. 
		echo.
		echo  Close this window and re-run Tron as an Administrator.
		echo  ^(right-click tron.bat and click "Run as Administrator"^)
		echo  ^(obviously, do you even know what windows is?^)
		echo.
		pause
		exit 1
	)
)
ENDLOCAL DISABLEDELAYEDEXPANSION


:: CHECK: Detect unsupported OS. If we are, complain to the user and bail out
if "%WIN_VER:~0,19%"=="Windows Server 2016" (
	if /i %DEV_MODE%==no (
		color 0c
		echo.
		echo  ^! ERROR
		echo.
		echo    Did you even RTFM you Clown?  "%WIN_VER%"
		echo	isn't supported ^(yet^)
		echo.
		echo    Look I realize you might want to override this
		echo    and run it anyways, so fuck you ignore me
		echo	add -dev to the command flag
		echo.
		echo    I still won't fucking support you anyways so fuck
		echo    me right? Not like it matters.
		echo.
		pause
		exit 3
	)
)



:: CHECK: Prohibited directory execution
:: YALL FUCKING DUMB STOP RUNNING IT IN THE WRONG DIRECTORY!
:: Why? because people have some bizarre obsession with running from the System temp folder
:: or some other random location instead of from the desktop as instructed
set RUNDIR=%~dp0
if "%RUNDIR:~0,7%"=="%SystemDrive%\tron" set BAD_RUNPATH=yes
if "%RUNDIR:~0,7%"=="%SystemDrive%\temp" set BAD_RUNPATH=yes
if "%RUNDIR%"=="%TEMP%\tron\tron\resources\functions\" set BAD_RUNPATH=yes
if "%RUNDIR%"=="%TEMP%\tron\resources\functions\" set BAD_RUNPATH=yes
if "%RUNDIR%"=="%TEMP%\resources\functions\" set BAD_RUNPATH=yes
if %BAD_RUNPATH%==yes (
	color 0c
	cls
	echo.
	echo  ERROR
	echo  YO YOU DIDNT FUCKING READ THE MANUAL MORON, WE'VE BEEN OVER THIS
	echo  DON'T FUCKING RUN TRON FROM ANYWHERE BUT THE DESKTOP FFS.
	echo.
	echo  READ THE FUCKING MANUAL!
	echo. 
	echo  Tron is running from a temp location or the root of %SystemDrive%.
	echo  Obviously Tron can't run from these sections because it would
	echo  fucking delete itself you clown. 
	echo  Run Tron directly from the Desktop. Example of a correct path:
	echo.
	echo   "%USERPROFILE%\Desktop\tron\tron.bat"
	echo.
	echo  Look you're reading this alert now that means you fucked up and 
	echo  didn't read the actual instructions so gtfo out of here and go
	echo  read that shit. Sick and tired of answering these easy questions
	echo  because you fucks can't RTFM properly 
	echo.
	echo  go read the file appropriately named 
	echo  "INSTRUCTIONS -- YES ACTUALLY READ THEM.txt"
	echo.
	echo  Goodbye(clown).
	echo.
	pause
	exit 5
)




:::::::::::
:: TASKS ::
:::::::::::

:: TASK: Detect Solid State hard drives or Virtual Machine installation (determines if post-run defrag executes or not)
pushd stage_6_optimize\defrag\

	:: Check for an updated drivedb.h, but only if we're not in autorun OR doing a dry run
	if /i %DRY_RUN%==no ( if /i %AUTORUN%==no ( if /i %AUTORUN_IN_SAFE_MODE%==no ( update-smart-drivedb.exe /S ) ) )
	
	:: Do the scan
	for /f %%i in ('smartctl.exe --scan') do smartctl.exe %%i -a | %FINDSTR% /i "Solid SSD RAID SandForce" >NUL && set SKIP_DEFRAG=yes_ssd
	for /f %%i in ('smartctl.exe --scan') do smartctl.exe %%i -a | %FINDSTR% /i "VMware VBOX XENSRC PVDISK" >NUL && set SKIP_DEFRAG=yes_vm
	for /f %%i in ('smartctl.exe --scan') do smartctl.exe %%i -a | %FIND% /i "Read Device Identity Failed" >NUL && set SKIP_DEFRAG=yes_error
popd


:: TASK: Get free space on the system drive and stash it for comparison later
for /F "tokens=2 delims=:" %%a in ('fsutil volume diskfree %SystemDrive% ^| %FIND% /i "avail free"') do set bytes=%%a
:: GB version
::set /A FREE_SPACE_BEFORE=%bytes:~0,-3%/1024*1000/1024/1024
:: MB version
set /A FREE_SPACE_BEFORE=%bytes:~0,-3%/1024*1000/1024


:: TASK: Re-enable the standard "F8" key functionality for choosing bootup options (Microsoft started disabling it by default in Windows 8 and up)
if %WIN_VER_NUM% geq 6.3 bcdedit /set {default} bootmenupolicy legacy
