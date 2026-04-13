@echo off
setlocal enabledelayedexpansion

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  ComfyUI 目的別・自動インストールスクリプト 
::
::  機能:
::  1. "image", "video", "music" 他からインストールする環境を選択
::  2. 古い環境があれば自分でリネームなどしてバックアップ
::  3. ComfyUI本体を新規クリーンインストール
::  4. Python仮想環境(venv)とPyTorchをセットアップ
::  5. ComfyUI-Managerを自動でインストール
::  6. 外部の共有モデルフォルダやデータフォルダへのシンボリックリンクを一括作成
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

rem --- ここを環境に合わせて変更 ---

rem ComfyUIがインストールされる親ディレクトリ
set "INSTALL_PARENT_DIR=C:\AI"

rem 各種（input/outputなど）データやTempを保存、利用する外部親ディレクトリ
set "EXTERNAL_DATA_PARENT_DIR=D:\AI_Assets\data"

rem モデルを保存する外部の共有ディレクトリ
set "SHARED_MODELS_DIR=D:\AI_Assets\models"

rem ComfyUI-ManagerのGitリポジトリURL
set "MANAGER_URL=https://github.com/ltdrdata/ComfyUI-Manager.git"

rem --- --------------------------------------------------- ---


:CHOOSE_ENVIRONMENT
cls
echo ======================================================
echo  どの環境構築をしますか？
echo ======================================================
echo.
echo  1. Image (画像生成 環境 )
echo  2. Video (動画生成 環境)
echo  3. Music (音楽生成 環境)
echo. 4. Test (テスト 環境)
echo.
set /p "CHOICE=番号を入力してください (1～4): "

if "%CHOICE%"=="1" ( set "ENV_TYPE=image" )
if "%CHOICE%"=="2" ( set "ENV_TYPE=video" )
if "%CHOICE%"=="3" ( set "ENV_TYPE=music" )
if "%CHOICE%"=="4" ( set "ENV_TYPE=test" )

if not defined ENV_TYPE (
    echo.
    echo 無効な選択です。1～4のいずれかを入力してください。
    pause
    goto CHOOSE_ENVIRONMENT
)

rem --- パスの設定 ---
set "COMFYUI_DIR=%INSTALL_PARENT_DIR%\ComfyUI_%ENV_TYPE%"
set "EXTERNAL_DATA_DIR=%EXTERNAL_DATA_PARENT_DIR%\%ENV_TYPE%_data"

cls
echo ======================================================
echo  環境構築を開始します
echo ======================================================
echo.
echo    インストール先: %COMFYUI_DIR%
echo    共有モデルフォルダ: %SHARED_MODELS_DIR%
echo    専用データフォルダ: %EXTERNAL_DATA_DIR%
echo.
echo ======================================================
pause


rem === ComfyUIのインストール ===

echo --- ComfyUIをクローンしています ---
git clone https://github.com/Comfy-Org/ComfyUI.git "%COMFYUI_DIR%"
if %errorlevel% neq 0 ( echo ComfyUIのクローンに失敗しました 。 & goto error_exit )
echo.


rem === Python仮想環境のセットアップ ===

echo --- Python仮想環境(venv)を構築 ---
cd /d "%COMFYUI_DIR%"
python -m venv venv
if %errorlevel% neq 0 ( echo venvの作成に失敗しました。 & goto error_exit )


echo --- 仮想環境を有効化し、PyTorchとライブラリをインストール ---
echo --- CUDA13 python3.12 pytorch2.10 の場合 ---
call venv\Scripts\activate
python.exe -m pip install --upgrade pip
pip install torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 --index-url https://download.pytorch.org/whl/cu130
pip install -r requirements.txt
echo.


rem === ComfyUI-Managerのインストール ===

echo --- ComfyUI-Managerをインストール ---
rem set "CUSTOM_NODES_DIR=%COMFYUI_DIR%\custom_nodes"
rem cd /d "%CUSTOM_NODES_DIR%"
rem git clone %MANAGER_URL%
rem if %errorlevel% neq 0 ( echo ComfyUI-Managerのクローンに失敗しました 。 & goto error_exit )
echo --- ComfyUI-Managerのライブラリをインストールしています ---
cd /d "%COMFYUI_DIR%"
pip install -r manager_requirements.txt

rem === 起動用バッチファイルの自動生成 ===

echo --- 起動用バッチファイルを生成します ---
set "LAUNCHER_FILENAME=start_comfyui_%ENV_TYPE%.bat"
set "LAUNCHER_FILEPATH=%INSTALL_PARENT_DIR%\%LAUNCHER_FILENAME%"

(
    echo @echo off
    echo set COMFYUI_DIR=%%~dp0ComfyUI_%ENV_TYPE%
    echo.
    echo echo %ENV_TYPE% 環境用のComfyUIを起動します...
    echo cd /d "!COMFYUI_DIR!"
    echo call venv\Scripts\activate
    echo.
    echo start "" "http://127.0.0.1:8188"
    echo python main.py --enable-manager
    echo.
    echo pause
) > "!LAUNCHER_FILEPATH!"

echo %LAUNCHER_FILENAME% を %INSTALL_PARENT_DIR% に作成しました。

rem === ComfyUI起動 ===
python main.py --enable-manager
echo.
pause