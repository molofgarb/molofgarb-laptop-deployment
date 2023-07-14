@echo off
Dism /Online /Cleanup-Image /RestoreHealth
sfc /scannow
pause