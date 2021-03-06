@echo off
SetLocal EnableExtensions EnableDelayedExpansion

where lzmw.exe 2>nul >nul || if not exist %~dp0\lzmw.exe powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/lzmw/blob/master/tools/lzmw.exe?raw=true -OutFile %~dp0\lzmw.exe"
where lzmw.exe 2>nul >nul || set "PATH=%PATH%;%~dp0"

where nin.exe 2>nul >nul || if not exist %~dp0\nin.exe powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/msr/blob/master/tools/nin.exe?raw=true -OutFile %~dp0\nin.exe"
where nin.exe 2>nul >nul || set "PATH=%PATH%;%~dp0"

for /f "tokens=*" %%a in ('lzmw -hC ^| lzmw -t ".*Now time = (\d+\S+) (\d+[:\d]+)\.(\d{3})(\d*)\s+(\w+)?.*" -o "$1 $2" -PAC') do set "TimeNow=%%a"

set ThisFolder=%~dp0
set ThisScriptName=%~nx0

:: Find all directories which contains html
for /f "tokens=*" %%a in ('lzmw -rp %~dp0 --nd "^\.git" -f "\.html" -l -PAC ^| nin nul "^(.+)\\[^\\\\/]+$" -ui -PAC') do (
    call :Check_Generate_README_in_Directory %%a
)

lzmw -rp %~dp0 --nd "^\.git" -f "README.md" -x ".github.io" --w1 "%TimeNow%" -l --wt --sz

if !ERRORLEVEL! EQU 0 lzmw -rp %~dp0 --nd "^\.git" -f "README.md" -x ".github.io" -l --wt --sz

exit /b 0


:Check_Generate_README_in_Directory
    set directory=%1
    set readmeFile=%1\README.md
    if exist %readmeFile% (
        for /f "tokens=*" %%p in ('lzmw -p %readmeFile% -ix ".github.io/" ^| lzmw -it "^Matched \d+ lines\s*\((\d+\.?\d*\s*.*?)\).*" -o "$1" -PAC') do set "htmlPercentage=%%p"
        lzmw -z "!htmlPercentage!" -t "^([5-9]\d|100)" -c Check if htmlPercentage=!htmlPercentage! ^>= 50% -H 0
        if !ERRORLEVEL! NEQ 1 (
            lzmw -p %readmeFile% -ix ".github.io/" -H 3
            echo Existed %readmeFile% has just !htmlPercentage! percent of html files, ignore to avoid editing maunal file.
            exit /b 0
        )
        
        echo Will overwrite existed %readmeFile% as htmlPercentage=!htmlPercentage! | lzmw -aPA -t "\w+" -x %readmeFile%
        del /f %readmeFile%
    )
    
    echo **Zoom out** following screenshots to **90%% or smaller** if it's not tidy or comfortable. Auto generated by `%ThisScriptName%` .> %readmeFile%
    :: lzmw -z "Zoom out following screenshots to 90%% or smaller if it is not tidy or comfortable." -it "(Zoom out|\d+%% or \w+)" -o "**$1**" -PAC > %readmeFile%
    for /f "tokens=*" %%a in ('dir /b %directory%\*.html') do (
        lzmw -z "* [%%a](https://qualiu.github.io/lzmw/%directory%/%%a)" -ix %ThisFolder% -o "" -aPAC | lzmw -x \ -o / -aPAC >> %readmeFile%
    )
