@echo off
REM Load keys from .env and run Flutter
REM Usage: run_dev.bat

for /f "tokens=1,2 delims==" %%a in (.env) do (
    if "%%a"=="STRIPE_PK" set STRIPE_PK=%%b
    if "%%a"=="STRIPE_SK" set STRIPE_SK=%%b
)

flutter run --dart-define=STRIPE_PK=%STRIPE_PK% --dart-define=STRIPE_SK=%STRIPE_SK%
