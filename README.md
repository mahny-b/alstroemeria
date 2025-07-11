# alstroemeria
Qiita用のネタで作った痒い所に手が届いて欲しいバッチコマンド集です。

ユーティリティセットとか十徳ナイフとか孫の手とか山椒は小粒でもピリリと辛いとか、無くても困らないけどあると便利なものを入れます。

アルストロメリアと名付けていますが桃色のアルストロメリアのイメージを込めています。
アイマスは好きですが残念ながらここでは関係ありません。

# 動作確認環境
```
> $PSVersionTable

Name                           Value
----                           -----
PSVersion                      7.5.2
PSEdition                      Core
GitCommitId                    7.5.2
OS                             Microsoft Windows 10.0.19045
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0


> ffmpeg -version
ffmpeg version 7.1.1-full_build-www.gyan.dev Copyright (c) 2000-2025 the FFmpeg developers
built with gcc 14.2.0 (Rev1, Built by MSYS2 project)
configuration: --enable-gpl --enable-version3 --enable-static --disable-w32threads --disable-autodetect --enable-fontconfig --enable-iconv --enable-gnutls --enable-lcms2 --enable-libxml2 --enable-gmp --enable-bzlib --enable-lzma --enable-libsnappy --enable-zlib --enable-librist --enable-libsrt --enable-libssh --enable-libzmq --enable-avisynth --enable-libbluray --enable-libcaca --enable-libdvdnav --enable-libdvdread --enable-sdl2 --enable-libaribb24 --enable-libaribcaption --enable-libdav1d --enable-libdavs2 --enable-libopenjpeg --enable-libquirc --enable-libuavs3d --enable-libxevd --enable-libzvbi --enable-libqrencode --enable-librav1e --enable-libsvtav1 --enable-libvvenc --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxavs2 --enable-libxeve --enable-libxvid --enable-libaom --enable-libjxl --enable-libvpx --enable-mediafoundation --enable-libass --enable-frei0r --enable-libfreetype --enable-libfribidi --enable-libharfbuzz --enable-liblensfun --enable-libvidstab --enable-libvmaf --enable-libzimg --enable-amf --enable-cuda-llvm --enable-cuvid --enable-dxva2 --enable-d3d11va --enable-d3d12va --enable-ffnvcodec --enable-libvpl --enable-nvdec --enable-nvenc --enable-vaapi --enable-libshaderc --enable-vulkan --enable-libplacebo --enable-opencl --enable-libcdio --enable-libgme --enable-libmodplug --enable-libopenmpt --enable-libopencore-amrwb --enable-libmp3lame --enable-libshine --enable-libtheora --enable-libtwolame --enable-libvo-amrwbenc --enable-libcodec2 --enable-libilbc --enable-libgsm --enable-liblc3 --enable-libopencore-amrnb --enable-libopus --enable-libspeex --enable-libvorbis --enable-ladspa --enable-libbs2b --enable-libflite --enable-libmysofa --enable-librubberband --enable-libsoxr --enable-chromaprint
libavutil      59. 39.100 / 59. 39.100
libavcodec     61. 19.101 / 61. 19.101
libavformat    61.  7.100 / 61.  7.100
libavdevice    61.  3.100 / 61.  3.100
libavfilter    10.  4.100 / 10.  4.100
libswscale      8.  3.100 /  8.  3.100
libswresample   5.  3.100 /  5.  3.100
libpostproc    58.  3.100 / 58.  3.100
```


# インストール
1. zipでダウンロードします。
2. ダウンロードしたzipを任意のフォルダに展開します。
3. 展開したフォルダ（`(zip)\alstroemeria\bat` や `(zip)\alstroemeria\ps1` 等）にwindowsのパスを適宜通して下さい。
4. いくつかのコマンドはffmpegを使用します。別途ダウンロードをして、ffmpegもwindowsのパスを通した状態にして下さい。
5. いくつかのコマンドは7zを使用します。別途ダウンロードをして、7zもwindowsのパスを通した状態にして下さい。


# 使い方
- 各コマンドの実装ポリシーとして、オプション無しの起動はヘルプを表示するようにしています。気になるコマンドをオプション無しでバシバシ叩いてください。


# アンインストール
1. 通したWindowsパスの設定を消します。
2. 本コマンド群を展開したフォルダを削除します。


# ps1フォルダについて
PowerShellのツールが入っています。  
どのスクリプトも引数無しで起動するとヘルプが見られるので、確認して下さい。  
もしくはソースを直接覗いて下さい。

## convert-to-lite-mp4.ps1
指定したフォルダに入っている動画ファイルを、程々の品質に落として軽量化するスクリプトです。  
※2025/07時点で使用している私のグラボ（RTX 2070 SUPER）でAV1の処理が出来ない為、CPU処理に切り替えるようにしてます。

## check-appdata.ps1
任意のユーザのAppDataの中から、容量をバカ食いしているフォルダを探します。


以上
