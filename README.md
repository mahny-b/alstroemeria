# alstroemeria
Qiita用のネタで作った痒い所に手が届いて欲しいバッチコマンド集です。
ユーティリティセットとか十徳ナイフとか孫の手とか山椒は小粒でもぴりりと辛いとか、無くても困らないけどあると便利なものを入れていくつもりです。
アルストロメリアと名付けていますが桃色のアルストロメリアのイメージを込めています。
アイマスは好きですが残念ながらここでは関係ありません。

# 何が出来るのか？
- ahelp
    - このパッケージに含まれるコマンド一覧が確認できる。困ったらこれを実行してみよう
- dl
    - 引数で指定した連番URLのリソースを一括ダウンロードする
- clean-zip-files（別途 7z が必要）
    - カレントディレクトリ内のzipと7zに含まれるメタファイルやディレクトリを削除する
- convjpg（別途 ffmpeg が必要）
    - カレントディレクトリ内のpngとjpgのサイズと品質を良い感じに落とした軽量jpgに変換する
- get-resolution（別途 ffprobe が必要）
    - 引数で指定したメディアファイル（ffmpeg対応するものなら多分分かる）の解像度を調べる

# 使い方
- 困ったら`ahelp`でコマンド一覧をみて下さい。
- 各コマンドの実装ポリシーとして、オプション無しの起動はヘルプを表示するようにしています。気になるコマンドをオプション無しでバシバシ叩いてください。

# インストール
1. zipでダウンロードします。
2. ダウンロードしたzipを任意のフォルダに展開します。
3. 展開したフォルダ（`(zip)\alstroemeria\bin`）にwindowsのパスを通して下さい。
4. いくつかのコマンドはffmpegを使用します。別途ダウンロードをして、ffmpegもwindowsのパスを通した状態にして下さい。
5. コマンドプロンプトで `ahelp` と入れて応答が返ってくればOKです。

# アンインストール
1. 通したWindowsパスの設定を消します。
2. 本コマンド群を展開したフォルダを削除します。

以上
