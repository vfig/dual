@echo off
REM bsp gantry.e gantry.bin -l3 -V
REM bsp gantryx.e gantryx.bin -ep1.0 -l0 -V -o -M-0.5
copy /y gantry.bin ..\obj\
copy /y gantryx.bin ..\obj\
copy /y gantry.png ..\obj\txt16\
copy /y gantry.mtl ..\obj\txt16\
