@echo off
REM ------------------------------------------------------------------
REM  Publish EakUI to GitHub as asepexploit/UI-EakHub (public repo).
REM  Needs: Git (https://git-scm.com) and GitHub CLI (https://cli.github.com)
REM  Login happens in your browser - no token needed.
REM  First run creates the repo; later runs push new commits.
REM ------------------------------------------------------------------
setlocal
cd /d "%~dp0.."

where git >nul 2>nul || (echo [!] Git is not installed: https://git-scm.com/download/win & pause & exit /b 1)
where gh  >nul 2>nul || (echo [!] GitHub CLI is not installed: https://cli.github.com & pause & exit /b 1)

gh auth status >nul 2>nul || gh auth login --web --git-protocol https
gh auth setup-git >nul 2>nul

if exist "EakUI.lua" echo [!] Old file EakUI.lua found in the root folder - delete it first (replaced by dist\EakUI.lua). & pause & exit /b 1
if exist "Example.lua" echo [!] Old file Example.lua found in the root folder - delete it first (replaced by examples\). & pause & exit /b 1

if not exist ".git" (
    git init -b main
)

git add -A
git commit -m "EakUI update" || echo Nothing new to commit.

git remote get-url origin >nul 2>nul
if errorlevel 1 (
    gh repo create UI-EakHub --public --description "Custom Roblox UI library for script hubs - 100%% Instance.new()" --source . --remote origin --push
) else (
    git push -u origin main
)

echo.
echo Done: https://github.com/asepexploit/UI-EakHub
echo Loadstring: https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/dist/EakUI.lua
pause
