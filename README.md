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
PSVersion                      7.4.4
PSEdition                      Core
GitCommitId                    7.4.4
OS                             Microsoft Windows 10.0.19045
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0

> ffmpeg -version
ffmpeg version 4.3.1-2020-11-19-full_build-www.gyan.dev Copyright (c) 2000-2020 the FFmpeg developers
built with gcc 10.2.0 (Rev5, Built by MSYS2 project)
configuration: --enable-gpl --enable-version3 --enable-static --disable-w32threads --disable-autodetect --enable-fontconfig --enable-iconv --enable-gnutls --enable-libxml2 --enable-gmp --enable-lzma --enable-libsnappy --enable-zlib --enable-libsrt --enable-libssh --enable-libzmq --enable-avisynth --enable-libbluray --enable-libcaca --enable-sdl2 --enable-libdav1d --enable-libzvbi --enable-librav1e --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxvid --enable-libaom --enable-libopenjpeg --enable-libvpx --enable-libass --enable-frei0r --enable-libfreetype --enable-libfribidi --enable-libvidstab --enable-libvmaf --enable-libzimg --enable-amf --enable-cuda-llvm --enable-cuvid --enable-ffnvcodec --enable-nvdec --enable-nvenc --enable-d3d11va --enable-dxva2 --enable-libmfx --enable-libcdio --enable-libgme --enable-libmodplug --enable-libopenmpt --enable-libopencore-amrwb --enable-libmp3lame --enable-libshine --enable-libtheora --enable-libtwolame --enable-libvo-amrwbenc --enable-libilbc --enable-libgsm --enable-libopencore-amrnb --enable-libopus --enable-libspeex --enable-libvorbis --enable-ladspa --enable-libbs2b --enable-libflite --enable-libmysofa --enable-librubberband --enable-libsoxr --enable-chromaprint
libavutil      56. 51.100 / 56. 51.100
libavcodec     58. 91.100 / 58. 91.100
libavformat    58. 45.100 / 58. 45.100
libavdevice    58. 10.100 / 58. 10.100
libavfilter     7. 85.100 /  7. 85.100
libswscale      5.  7.100 /  5.  7.100
libswresample   3.  7.100 /  3.  7.100
libpostproc    55.  7.100 / 55.  7.100
```


# インストール
1. zipでダウンロードします。
2. ダウンロードしたzipを任意のフォルダに展開します。
3. 展開したフォルダ（`(zip)\alstroemeria\bat`）にwindowsのパスを通して下さい。
    - 以前使ってた人は、フォルダが `bin` から `bat` に変わっていますのでご注意を！ 
5. いくつかのコマンドはffmpegを使用します。別途ダウンロードをして、ffmpegもwindowsのパスを通した状態にして下さい。
6. いくつかのコマンドは7zを使用します。別途ダウンロードをして、7zもwindowsのパスを通した状態にして下さい。
7. コマンドプロンプトで `ahelp` と入れて応答が返ってくればOKです。


# 使い方
- 困ったら`ahelp`でコマンド一覧をみて下さい。
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

## check-appdata.ps1
任意のユーザのAppDataの中から、容量をバカ食いしているフォルダを探します。


以上
