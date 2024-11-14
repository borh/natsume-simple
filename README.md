# natsume-simple

[![CI](https://github.com/borh/natsume-simple/actions/workflows/ci.yaml/badge.svg)](https://github.com/borh/natsume-simple/actions/workflows/ci.yaml)

## 概要

natsume-simpleは日本語の係り受け関係を検索できるシステム

## 開発環境のセットアップ

本プロジェクトには以下の3つの開発環境のセットアップ方法があります：

### Dev Container を使用する場合

[VS Code](https://code.visualstudio.com/)と[Dev Containers拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)をインストールした後：

1. このリポジトリをクローン：
```bash
git clone https://github.com/borh/natsume-simple.git
```

2. VS Codeでフォルダを開く
3. 右下に表示される通知から、もしくはコマンドパレット（F1）から「Dev Containers: Reopen in Container」を選択
4. コンテナのビルドが完了すると、必要な開発環境が自動的に設定されます

### Nixを使用する場合

1. [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)でNixをインストール：
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```

2. プロジェクトのセットアップ：
```bash
git clone https://github.com/borh/natsume-simple.git
cd natsume-simple
nix develop
```

### 手動セットアップの場合

以下のツールを個別にインストールする必要があります：

- git
- Python 3.12以上
- [uv](https://github.com/astral/uv)
- Node.js
- pandoc

その後：

```bash
git clone https://github.com/borh/natsume-simple.git
cd natsume-simple
uv sync --extra backend
cd natsume-frontend && npm install && npm run build && cd ..
```

## Nixフレークの使用方法

このプロジェクトはNixフレークを使用して開発環境とビルドを管理しています。以下のコマンドが利用可能です：

### 開発環境

```bash
# 開発環境に入る
nix develop

# または direnvを使用している場合（推奨）
direnv allow
```

### ビルドとテスト

```bash
# テストを実行
nix run .#test

# リンター実行
nix run .#lint

# 開発サーバー起動（ホットリロード有効）
nix run .#dev-server

# プロダクションサーバー起動
nix run .#server
```

### その他の便利なコマンド

```bash
# フォーマット
nix fmt

# ビルド
nix build

# 開発環境のシェル情報を表示
nix develop --print-build-logs
```
<!-- TODO
### process-composeによるサービス管理

複数のサービスを同時に実行する場合：

```bash
nix run .#process-compose-natsume-simple-services
```
-->

注意：
- 各コマンドは自動的に必要な依存関係をインストールします
- `nix develop`で入る開発環境には以下が含まれています：
  - Python 3.12
  - Node.js
  - uv（Pythonパッケージマネージャー）
  - pandoc
  - その他開発に必要なツール


## CLI使用方法

### 処理の順序

データの準備から検索システムの利用まで、以下の順序で処理を行う必要があります：

1. データの準備（JNLPコーパスとTEDコーパスのダウンロードと前処理）
2. パターン抽出（各コーパスからのNPVパターンの抽出）
3. サーバーの起動（検索インターフェースの提供）

### 1. データの準備

```bash
python src/natsume_simple/data.py --prepare
```

オプション：
- `--data-dir PATH` - データを保存するディレクトリ（デフォルト: ./data）
- `--seed INT` - 乱数シードの設定（デフォルト: 42）

この処理で以下が実行されます：
- JNLPコーパスのダウンロードと変換
- TEDコーパスのダウンロードと前処理
- 前処理済みデータの保存

### 2. データの読み込み

準備済みデータを読み込む場合：

```bash
python src/natsume_simple/data.py --load \
    --jnlp-sample-size 3000 \
    --ted-sample-size 30000
```

オプション：
- `--jnlp-sample-size INT` - JNLPコーパスからのサンプルサイズ（デフォルト: 3000）
- `--ted-sample-size INT` - TEDコーパスからのサンプルサイズ（デフォルト: 30000）
- `--data-dir PATH` - データディレクトリの指定（デフォルト: ./data）
- `--seed INT` - 乱数シードの設定（デフォルト: 42）

注意：
- 各コマンドは必要な依存関係がインストールされていることを前提としています
- エラーが発生した場合は、依存関係のインストール状態を確認してください

### 3. パターン抽出

```bash
# JNLPコーパス用
python src/natsume_simple/pattern-extraction.py \
    --model ja_ginza_bert_large \
    --corpus-name "JNLP" \
    data/jnlp-corpus.txt \
    data/jnlp_npvs_ja_ginza_bert_large.csv

# TEDコーパス用
python src/natsume_simple/pattern-extraction.py \
    --model ja_ginza_bert_large \
    --corpus-name "TED" \
    data/ted-corpus.txt \
    data/ted_npvs_ja_ginza_bert_large.csv
```

オプション：
- `--model NAME` - 使用するspaCyモデル（オプション、デフォルト: ja_ginza_bert_large）
- `--corpus-name NAME` - コーパス名の指定（デフォルト: "Unknown"）
- `--seed INT` - 乱数シードの設定（デフォルト: 42）

この処理で以下が実行されます：
- コーパスの読み込み
- NPVパターンの抽出
- 結果のCSVファイルへの保存

### 4. サーバーの起動

```bash
uv run fastapi dev src/natsume_simple/server.py
```

このコマンドでは，server.pyをFastAPIでウエブサーバで起動し，ブラウザからアクセス可能にする。

オプション：
- `--reload` - コード変更時の自動リロード（開発時のみ）
- `--host HOST` - ホストの指定（デフォルト: 127.0.0.1）
- `--port PORT` - ポートの指定（デフォルト: 8000）

注意：
- `server.py`では，モデルの指定があるのでご注意。
- サーバを起動後は，出力される手順に従い，<http://127.0.0.1:8000/>にアクセスする。
- FastAPIによるドキュメンテーションは<http://127.0.0.1:8000/docs>にある。
- 環境によっては<http://0.0.0.0:8000>が<http://127.0.0.1:8000>と同様ではない

## 機能

- 特定の係り受け関係（名詞ー格助詞ー動詞，名詞ー格助詞ー形容詞など）における格助詞の左右にある語から検索できる
- 検索がブラウザを通して行われる
- 特定共起関係のジャンル間出現割合
- 特定共起関係のコーパスにおける例文表示

## プロジェクト構造

このプロジェクトは以下のファイルを含む：

## プロジェクト構造

```
.
├── data/                        # コーパスとパターン抽出結果
│   ├── ted_corpus.txt           # TEDコーパス
│   ├── jnlp_npvs_*.csv          # 自然言語処理コーパスのパターン抽出結果
│   └── ted_npvs_*.csv           # TEDコーパスのパターン抽出結果
│
├── notebooks/                   # 分析・可視化用Jupyterノートブック
│   ├── pattern-extraction.ipynb # パターン抽出処理の開発用
│   └── visualization.ipynb      # データ可視化用
│
├── natsume-frontend/            # Svelteベースのフロントエンド
│   ├── src/                     # アプリケーションソース
│   │   ├── routes/              # ページルーティング
│   │   └── tailwind.css         # スタイル定義
│   ├── static/                  # 静的アセット
│   └── tests/                   # フロントエンドテスト
│
├── src/natsume_simple/          # バックエンドPythonパッケージ
│   ├── server.py                # FastAPIサーバー
│   ├── data.py                  # データ処理
│   ├── pattern-extraction.py    # パターン抽出ロジック
│   └── utils.py                 # ユーティリティ関数
│
├── scripts/                     # データ準備スクリプト
│   ├── get-jnlp-corpus.py       # コーパス取得
│   └── convert-jnlp-corpus.py   # コーパス変換
│
├── tests/                       # バックエンドテスト
│   └── test_models.py           # モデルテスト
│
├── pyproject.toml               # Python依存関係定義
├── flake.nix                    # Nix開発環境定義
└── README.md                    # プロジェクトドキュメント
```

### data

各種のデータはdataに保存する。
特にscriptsやnotebooks下で行われる処理は，最終的にdataに書き込むようにする。

### notebooks

特に動的なプログラミングをするときや，データの性質を確認したいときに活用する。
ここでは，係り受け関係の抽出はすべてノートブック上で行う。

VS Codeなどでは，使用したいPythonの環境を選択の上，実行してください。
Google Colabで使用する場合は，[リンク](https://colab.research.google.com/drive/1pb7MXf2Q-4MkadWHmzUrb-qXsAVG4--T?usp=sharing)から開くか，`pattern_extraction_colab.ipynb`のファイルをColabにアップロードして利用する。

Jupyter Notebook/JupyterLabでは使用したPythonの環境をインストールの上，Jupterを立ち上げてください。

```bash
jupyter lab
```

右上のメニューに選択できない場合は環境に入った上で下記コマンドを実行するとインストールされる：

```bash
python -m ipykernel install --user --name=$(basename $VIRTUAL_ENV)
```

### natsume-frontend

[Svelte 5](https://svelte.dev/)で書かれた検索インターフェース。

Svelteのインターフェース（html, css, jsファイル）は以下のコマンドで生成できる：
（`natsume-frontend/`フォルダから実行）

```bash
npm install
npm run build
```

Svelteの使用にはnodejsの環境整備が必要になる。

#### static

サーバ読む静的ファイルを含むファルダ。
上記の`npm run build`コマンド実行で`static/`下にフロントエンドのファイルが作成される。
ここに置かれるものは基本的にAPIの`static/`URL下で同一ファイル名でアクセス可能。

## モデルの使用（Pythonコードから）

係り受け解析に使用されるモデルを利用するために以下のようにloadする必要がある。
環境設定が正常かどうかも以下のコードで検証できる。

```python
import spacy
nlp = spacy.load('ja_ginza_bert_large')
```

あるいは

```python
import spacy
nlp = spacy.load('ja_ginza')
```

ノートブックでは，優先的に`ja_ginza_bert_large`を使用するが，インストールされていない場合は`ja_ginza`を使用する。

## データ・コーパスの生成スクリプト（古い）

現在はデータが`notebooks`下にあるJupyter Notebookによって生成される。
その結果が`data`に保存される。

結果はモデルによって異なるとしてファイル名の末尾にモデル名も記載されている。

それぞれの依存パッケージ定義ファイルでは，Jupyterのカーネルは定義されていない。
必要な場合は別途インストールください（VS Codeでは自動でインストールできる）。

## scripts (古い)

（上記の`data.py`に移行してあるのここは参考まで）

定めた手順で，コーパスの前処理・データ整理などを行う。
ここでは，Hugginface Datasets以外のコーパスを扱う。
Huggingface Datasetsの方は，直接ノートブックで読み取っている。

注意：`scripts/`に置かれているBashスクリプト（.sh拡張子）はbash, awk, GNU grep, wgetなどを必要とするので，Windowsから実行するときはその環境整備が必要になる。
また，$\LaTeX$からGiNZAで読み取れる形式に変換するプログラムとして[pandoc](https://pandoc.org/)を使っているため，[pandocのインストール](https://pandoc.org/installing.html)は別途必要になる。

一回ダウンロードしたあとに再度ダウンロードせずに前処理課程を修正できるため，スクリプトはデータ処理をダウンロードと変換に分けている。

```bash
./get_jnlp_corpus.sh
./convert_jnlp_corpus.sh
```

並行して，Bashスクリプトと同様な処理を行うPythonスクリプトもある。
変換処理では，無作為にコーパス全体から3,000文を抽出しているために，
