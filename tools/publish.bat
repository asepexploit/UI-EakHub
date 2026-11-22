@echo off
REM ------------------------------------------------------------------
REM  EakUI - publish to GitHub (asepexploit/UI-EakHub)
REM
REM  Double-click to run. It will:
REM    1. install Git / GitHub CLI with winget if they are missing
REM    2. sign in to GitHub in your browser (first run only)
REM    3. fix the "dubious ownership" Git error for this folder
REM    4. commit any changes and push them to GitHub
REM    5. create the repo if it does not exist yet
REM ------------------------------------------------------------------
setlocal EnableExtensions
title EakUI - Publish to GitHub
cd /d "%~dp0.."
set "REPO_DIR=%CD%"
set "REPO_NAME=UI-EakHub"

echo.
echo  EakUI publisher
echo  Folder: %REPO_DIR%
echo.

REM ---------- 1. Tools ----------------------------------------------
set "NEED_RESTART="
where git >nul 2>nul
if errorlevel 1 (
    echo [..] Git not found, installing with winget...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    set "NEED_RESTART=1"
)
where gh >nul 2>nul
if errorlevel 1 (
    echo [..] GitHub CLI not found, installing with winget...
    winget install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements
    set "NEED_RESTART=1"
)
if defined NEED_RESTART (
    echo.
    echo [OK] Tools installed. Close this window and run publish.bat again
    echo      so Windows picks up the new programs.
    pause
    exit /b 0
)

REM ---------- 2. Sign in --------------------------------------------
gh auth status >nul 2>nul
if errorlevel 1 (
    echo [..] Signing in to GitHub - a browser window will open.
    gh auth login --hostname github.com --git-protocol https --web
    if errorlevel 1 goto :fail
)
gh auth setup-git >nul 2>nul

REM ---------- 3. Trust this folder (fixes "dubious ownership") -------
set "SAFE_DIR=%REPO_DIR:\=/%"
git config --global --get-all safe.directory 2>nul | findstr /i /x /c:"%SAFE_DIR%" >nul
if errorlevel 1 git config --global --add safe.directory "%SAFE_DIR%"

REM ---------- 4. Repo + commit --------------------------------------
if not exist ".git" (
    echo [..] Initialising git repository...
    git init -b main
    if errorlevel 1 goto :fail
)

for /f "delims=" %%U in ('git config user.name 2^>nul') do set "GIT_USER=%%U"
if not defined GIT_USER (
    for /f "delims=" %%L in ('gh api user --jq .login') do (
        git config user.name "%%L"
        git config user.email "%%L@users.noreply.github.com"
    )
)

git add -A
git diff --cached --quiet
if errorlevel 1 (
    for /f "delims=" %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH:mm"') do set "STAMP=%%D"
    git commit -m "EakUI update %STAMP%"
    if errorlevel 1 goto :fail
) else (
    echo [OK] No new local changes to commit.
)

REM ---------- 5. Push ------------------------------------------------
git remote get-url origin >nul 2>nul
if errorlevel 1 (
    echo [..] Creating GitHub repo %REPO_NAME%...
    gh repo create %REPO_NAME% --public --description "Custom Roblox UI library for script hubs - 100%% Instance.new()" --source . --remote origin --push
    if errorlevel 1 goto :fail
    goto :done
)

git branch -M main
echo [..] Pushing to GitHub...
git push -u origin main
if errorlevel 1 (
    echo [..] Push rejected, pulling remote changes first...
    git pull --rebase origin main
    if errorlevel 1 goto :fail
    git push -u origin main
    if errorlevel 1 goto :fail
)

:done
for /f "delims=" %%L in ('gh api user --jq .login') do set "LOGIN=%%L"
echo.
echo  ============================================================
echo  [OK] Published!
echo  Repo:       https://github.com/%LOGIN%/%REPO_NAME%
echo  Loadstring: https://raw.githubusercontent.com/%LOGIN%/%REPO_NAME%/main/dist/EakUI.lua
echo  (raw links can take 1-5 minutes to update)
echo  ============================================================
echo.
pause
exit /b 0

:fail
echo.
echo [!!] Something went wrong - read the message above.
echo      Screenshot this window and send it if you need help.
pause
exit /b 1
