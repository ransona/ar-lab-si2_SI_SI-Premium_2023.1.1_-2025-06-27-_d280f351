@echo off
Setlocal

set dllPath=%~dp0
set regasm64=%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe

REM --> reset error level
type nul>nul

REM --> Check for permissions
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
    >nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if "%errorlevel%" NEQ "0" (goto UACPrompt) else (goto gotAdmin)

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set _command=%~f0
    set _command=""%_command:"=%""
    echo UAC.ShellExecute "cmd", "/c ""%_command%""", "", "runas", 1 >> "%temp%\getadmin.vbs"

    cscript /nologo "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

    %regasm64% /codebase "%dllPath%\QlmLicenseLib.dll"

:END

