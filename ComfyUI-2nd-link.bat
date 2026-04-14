@echo off
setlocal enabledelayedexpansion

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  ComfyUI シンボリックリンク一括設定ツール
::
::  機能:
::  このバッチファイルがある場所（例: C:\AI）から、"ComfyUI_*" という
::  名前のサブフォルダをすべて検索し、それぞれの環境に対して、
::  外部の共有フォルダへのシンボリックリンクを一括で作成・更新します。
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

rem --- ここを環境に合わせて変更 ---

rem ComfyUIがインストールされる親ディレクトリ
set "INSTALL_PARENT_DIR=C:\AI"

rem 各種（input/outputなど）データやTempを保存、利用する外部親ディレクトリ
set "EXTERNAL_DATA_PARENT_DIR=D:\AI_Assets\data"

rem モデルを保存する外部の共有ディレクトリ
set "SHARED_MODELS_DIR=D:\AI_Assets\models"

rem ワークフローの共有directory


rem --- --------------------------------------------------- ---

rem --- リンクするフォルダのリスト (ここを編集して追加・削除)  ---
set "MODEL_FOLDERS=animatediff_models animatediff_motion_lora audio_encoders checkpoints clip clip_vision configs controlnet diffusers diffusion_models embeddings gligen hypernetworks latent_upscale_models loras model_patches onnx openunmix photomaker sams style_models text_encoders unet upscale_models vae vae_approx"
set "DATA_FOLDERS=input output temp"
set "WORKFLOWS_FOLDER=workflows"
rem --- --------------------------------------------------- ---

cls
echo ======================================================
echo  ComfyUI シンボリックリンク一括設定ツール
echo ======================================================
echo.
echo  検索対象: %INSTALL_PARENT_DIR%\ComfyUI_*
echo  共有モデル: %SHARED_MODELS_DIR%
echo  専用データ: %EXTERNAL_DATA_PARENT_DIR%
echo.
echo ======================================================
pause

rem --- 外部フォルダの事前作成 ---
echo --- 外部フォルダを準備しています... ---
for %%F in (%MODEL_FOLDERS%) do ( mkdir "%SHARED_MODELS_DIR%\%%F" > nul 2>&1 )
echo.

rem === メイン処理: "ComfyUI_*" フォルダをループ ===
echo --- サブフォルダを検索してリンクを作成します... ---
for /d %%D in ("%INSTALL_PARENT_DIR%\ComfyUI_*") do (
    set "COMFYUI_DIR=%%D"
    set "ENV_TYPE_FULL=%%~nD"
    set "ENV_TYPE=!ENV_TYPE_FULL:ComfyUI_=!"

    echo.
    echo =================================================
    echo  ■ 処理中の環境: !ENV_TYPE!
    echo =================================================

    rem --- modelsフォルダの存在チェック ---
    if not exist "!COMFYUI_DIR!\models" (
        echo   [警告] !COMFYUI_DIR!\models が見つかりません。スキップします。
    ) else (
        echo   --- モデルフォルダのリンクを作成中... ---
        cd /d "!COMFYUI_DIR!\models"
        for %%F in (%MODEL_FOLDERS%) do (
            echo     - %%F
            rmdir /s /q "%%F" > nul 2>&1
            mklink /D "%%F" "%SHARED_MODELS_DIR%\%%F"
        )
    )

    rem --- ワークフローフォルダのリンク作成 ---
    echo   --- ワークフローフォルダのリンクを作成中... ---
    set "USER_DEFAULT_DIR=!COMFYUI_DIR!\user\default"
    set "EXTERNAL_WORKFLOW_DIR=%EXTERNAL_DATA_PARENT_DIR%\!ENV_TYPE!_data"
    mkdir "!COMFYUI_DIR!\user" > nul 2>&1
    mkdir "!USER_DEFAULT_DIR!" > nul 2>&1
    mkdir "!EXTERNAL_WORKFLOW_DIR!\!WORKFLOWS_FOLDER!" > nul 2>&1
    cd /d "!USER_DEFAULT_DIR!"
    echo     - !WORKFLOWS_FOLDER!
    rmdir /s /q "!WORKFLOWS_FOLDER!" > nul 2>&1
    mklink /D "!WORKFLOWS_FOLDER!" "!EXTERNAL_WORKFLOW_DIR!\!WORKFLOWS_FOLDER!"


    rem --- データフォルダのリンク作成 ---
    echo   --- データフォルダのリンクを作成中... ---
    set "EXTERNAL_DATA_DIR=%EXTERNAL_DATA_PARENT_DIR%\!ENV_TYPE!_data"
    mkdir "!EXTERNAL_DATA_DIR!" > nul 2>&1
    for %%F in (%DATA_FOLDERS%) do ( mkdir "!EXTERNAL_DATA_DIR!\%%F" > nul 2>&1 )

    cd /d "!COMFYUI_DIR!"
    for %%F in (%DATA_FOLDERS%) do (
        echo     - %%F
        rmdir /s /q "%%F" > nul 2>&1
        mklink /D "%%F" "!EXTERNAL_DATA_DIR!\%%F"
    )
)





echo.
echo ======================================================
echo  すべての処理が完了しました！
echo ======================================================
pause
exit
