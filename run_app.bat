@echo off
title MARIO Pizza App Launcher
echo ========================================================
echo        MARIO Pizza - Starting Backend and Flutter
echo ========================================================
echo.

set PROJECT_DIR=%~dp0
cd /d "%PROJECT_DIR%"

:: Locate Go executable
set "GO_CMD=go"
where go >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if exist "C:\Program Files (x86)\Go\bin\go.exe" (
        set "GO_CMD=C:\Program Files (x86)\Go\bin\go.exe"
    ) else if exist "C:\Program Files\Go\bin\go.exe" (
        set "GO_CMD=C:\Program Files\Go\bin\go.exe"
    ) else if exist "C:\Go\bin\go.exe" (
        set "GO_CMD=C:\Go\bin\go.exe"
    )
)

:: Free port 8080 if an old server instance is still running
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080') do (
    taskkill /F /PID %%a >nul 2>&1
)

echo [1/2] Starting Go Backend Server on http://localhost:8080...
start "MARIO Go Backend API" cmd /k "cd /d ""%PROJECT_DIR%backend"" && ""%GO_CMD%"" run main.go"
echo Waiting 2 seconds for backend to initialize...
timeout /t 2 /nobreak >nul

echo.
echo [2/2] Launching Flutter Web App in Google Chrome...
echo Running: flutter run -d chrome
echo.

flutter run -d chrome

pause
