@echo off
setlocal

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

if %errorlevel% neq 0 (
    echo [31mPlease run this script as administrator[0m
    pause
    exit /b
)

set REPO_OWNER="glnklein"
set REPO_NAME="Lightn1ng0_AI_Aimbot"

curl --insecure -s https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest > latest_release.json

for /f "tokens=2 delims=:," %%a in ('findstr /r /c:"\"tag_name\"" latest_release.json') do set TAG_NAME=%%~a
set TAG_NAME=%TAG_NAME:~1%

del latest_release.json

set "INSTALL_LOCATION=%appdata%\Lightn1ng0_AI_Aimbot"
set "RELEASE_ZIP=%INSTALL_LOCATION%\Lightn1ng0_AI_Aimbot_Release-%TAG_NAME%.zip"
set "CUDA_INSTALLER=%INSTALL_LOCATION%\Dependencies\cuda_12.5.0_555.85_windows.exe"
set "PYTHON_INSTALLER=%INSTALL_LOCATION%\Dependencies\python-3.11.9-amd64.exe"
set "CUDNN_INSTALLER=%INSTALL_LOCATION%\Dependencies\cudnn_9.2_windows.exe"
set "TENSORRT_ZIP=%INSTALL_LOCATION%\Dependencies\TensorRT-10.0.1.6.Windows10.win10.cuda-12.4.zip"

if not exist "%INSTALL_LOCATION%" (
    mkdir "%INSTALL_LOCATION%"
)

set PREFIX="Lightn1ng0_AI_Aimbot_Release-"

for %%F in (%INSTALL_LOCATION%\%PREFIX%*.zip) do (
    if exist "%%F" (
        del "%%F"
    )
)

echo Downloading latest release (%TAG_NAME%)...
curl --insecure -o %RELEASE_ZIP% -L -# https://github.com/glnklein/Lightn1ng0_AI_Aimbot/releases/download/%TAG_NAME%/Lightn1ng0_AI_Aimbot_Release-%TAG_NAME%.zip

if exist "%INSTALL_LOCATION%\Lightn1ng0_AI_Aimbot" (
    rmdir %INSTALL_LOCATION%\Lightn1ng0_AI_Aimbot /s /q
    del %INSTALL_LOCATION%\Dependencies\requirements.txt
    del %INSTALL_LOCATION%\update.bat
)

powershell -Command "$ProgressPreference = 'SilentlyContinue'; Expand-Archive -Path "%RELEASE_ZIP%" -DestinationPath "%INSTALL_LOCATION%"" > nul

echo [92mChecking if your system has an NVIDIA graphics card...[0m
set "GPU_OUTPUT="
for /f "delims=" %%i in ('powershell -Command "Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -like '*NVIDIA*' }"') do set "GPU_OUTPUT=%%i"

nvcc --version >nul 2>&1
if defined GPU_OUTPUT (
    echo [32mNVIDIA graphics card detected.[0m
    if %errorlevel% neq 0 (
        if exist "%CUDA_INSTALLER%" (
            echo [92mCUDA installer already exists. Skipping download.[0m
        ) else (
            echo [92mDownloading CUDA Toolkit 12.5...[0m
            curl --insecure -o "%CUDA_INSTALLER%" -# https://developer.download.nvidia.com/compute/cuda/12.5.0/local_installers/cuda_12.5.0_555.85_windows.exe
        )
    ) else (
        echo [92mCUDA is already installed. Skipping install...[0m
    )
) else (
    echo [32mNo NVIDIA graphics card detected.[0m
)

nvcc --version >nul 2>&1
if defined GPU_OUTPUT (
    if %errorlevel% neq 0 (
        echo [32mInstalling CUDA Toolkit 12.5...[0m
        "%CUDA_INSTALLER%" -s
    )
)

set PYTHON_INSTALL_PATH=%localappdata%\Programs\Python\Python311
set PATH=%PYTHON_INSTALL_PATH%;%PYTHON_INSTALL_PATH%\Scripts;%PATH%

python --version >nul 2>&1

if %errorlevel% neq 0 (
    if exist "%PYTHON_INSTALLER%" (
        echo [94mPython installer already exists. Skipping download.[0m
    ) else (
        echo [94mDownloading Python...[0m
        curl --insecure -o "%PYTHON_INSTALLER%" -# https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
    )
)

python --version >nul 2>&1

if %errorlevel% neq 0 (
    echo [34mInstalling Python...[0m
    "%PYTHON_INSTALLER%" /quiet PrependPath=1
) else (
    echo [94mPython is already installed. Skipping install...[0m
)

python -m pip install --upgrade pip
pip install --upgrade setuptools

set "VENV_DIR=%INSTALL_LOCATION%\venv"

echo [35mCreating a Python virtual environment in the directory: %VENV_DIR%[0m
python -m venv %VENV_DIR%

if exist %VENV_DIR%\Scripts\activate.bat (
    echo [95mVirtual environment created successfully.[0m
    echo [35mActivating the virtual environment...[0m
    call "%VENV_DIR%\Scripts\activate.bat"

    if %errorlevel% neq 0 (
        echo [31mFailed to activate the virtual environment.[0m
        pause
        exit /b 1
    ) else (
        echo [95mVirtual environment activated successfully.[0m
    )
) else (
    echo [31mFailed to create the virtual environment.[0m
    pause
    exit /b 1
)

echo [34mInstalling Python Pip Packages%...[0m
python -m pip install --upgrade pip
pip install --upgrade setuptools
pip install -r "%INSTALL_LOCATION%\Dependencies\requirements.txt"

if defined GPU_OUTPUT (
    pip install cupy-cuda12x
    pip install onnxruntime-gpu --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/
    pip uninstall torch torchvision torchaudio -y
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
) else (
    pip install onnxruntime-directml
)

if defined GPU_OUTPUT (
    if exist "%CUDNN_INSTALLER%" (
        echo [92mCUDNN installer already exists. Skipping download.[0m
    ) else (
        echo [92mDownloading CUDNN 9.2...[0m
        curl --insecure -o "%CUDNN_INSTALLER%" -# https://developer.download.nvidia.com/compute/cudnn/9.2.1/local_installers/cudnn_9.2.1_windows.exe
    )
)

if defined GPU_OUTPUT (
    echo [32mInstalling CUDNN 9.2...[0m
    "%CUDNN_INSTALLER%" -s
)

if defined GPU_OUTPUT (
    if exist "%TENSORRT_ZIP%" (
        echo [92mTensorRT installer already exists. Skipping download.[0m
    ) else (
        echo [92mDownloading TensorRT 10.0.1.6...[0m
        curl --insecure -o "%TENSORRT_ZIP%" -L -# https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.0.1/zip/TensorRT-10.0.1.6.Windows10.win10.cuda-12.4.zip
    )
)

if defined GPU_OUTPUT (
    echo [32mInstalling TensorRT 10.0.1.6...[0m
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; Expand-Archive -Path "%TENSORRT_ZIP%" -DestinationPath "%INSTALL_LOCATION%\Dependencies"" > nul
    python "%INSTALL_LOCATION%\Dependencies\copy.py"
    pip install "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.5\python\tensorrt-10.0.1-cp311-none-win_amd64.whl"
)

copy "%INSTALL_LOCATION%\Lightn1ng0 AI Aimbot.lnk" "%userprofile%\Desktop" /Y > nul
copy "%INSTALL_LOCATION%\Lightn1ng0 AI Aimbot.lnk" "%APPDATA%\Microsoft\Windows\Start Menu\Programs" /Y > nul
copy "%INSTALL_LOCATION%\Lightn1ng0 AI Aimbot Updater.lnk" "%userprofile%\Desktop" /Y > nul
copy "%INSTALL_LOCATION%\Lightn1ng0 AI Aimbot Updater.lnk" "%APPDATA%\Microsoft\Windows\Start Menu\Programs" /Y > nul
echo [95mLightn1ng0 AI Aimbot is installed!...[0m
endlocal
pause
