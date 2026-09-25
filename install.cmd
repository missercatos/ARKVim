@echo off
rem ARKVim Windows installer wrapper
rem
rem   - 双击本文件即可安装
rem   - 或在 cmd 里用参数运行：install.cmd -Minimal
rem
rem 参数会原样传给 install.ps1

setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set RC=%ERRORLEVEL%

rem 双击运行时（父进程就是本脚本）结束后停一下，方便看结果
echo %cmdcmdline% | find /i "%~f0" >nul
if not errorlevel 1 (
  echo.
  if %RC%==0 (
    echo 安装完成。按任意键关闭...
  ) else (
    echo 安装失败（退出码 %RC%）^，按任意键关闭...
  )
  pause >nul
)

endlocal & exit /b %RC%
