# natsume-simple

## 概要

natsume-simpleは日本語の係り受け関係を検索できるシステム

## 開発用OSインストール手順

本プロジェクトを動かすにはソースコードをパソコンにダウンロードする必要がある。
GitHub上からは，ZIP圧縮ファイルでのダウンロードか，Gitでのクローンか，で利用できる。

ソースコードの最新版が入っているZIPファイルのダウンロードは，[ここ](https://github.com/borh/natsume-simple/archive/refs/heads/main.zip)からできる。
Git利用には事前にインストール必要がある。

コマンドライン以外でもインストール可能であるが，以下はそれぞれのOSのコマンドラインインターフェースを利用したインストール方法：

-   Linux (Debian/Ubuntuの場合):

```bash
sudo apt get install git
```

-   macOS:

```zsh
brew install git
```

-   Windows (最新版でないと[Wingetの設定](https://learn.microsoft.com/ja-jp/windows/package-manager/winget/)が必要):

```powershell
winget install -e Git.Git
```

それで`git`での入手方法は：

```bash
git clone https://github.com/borh/natsume-simple.git
```

インストールは2022年10月時点で，poetryを使用することをおすすめするが，以下は標準のPython/pipによるインストール方法を紹介する。

Python以外にもPandocなど外部プログラムも使用しているので，下記OS別にインストール基準も書いている。

### OS別手順

#### macOS

```bash
brew install pandoc
```

#### Linux

パッケージマネージャで`pandoc`をインストールする。
バージョン1ではなく2もしくは3系が必要になる。

#### Windows

```powershell
winget install pandoc
```

## Python環境のインストール

natsume-simpleは[uv](https://docs.astral.sh/uv)を使用しているが，pip/condaの場合も可能である。

```bash
uv sync --extra backend
```

<!--
### pip

必要なPythonのパッケージは`requirements.txt`に記載されている。
以下のコマンドでは，現在のPython環境に必要パッケージがインストールし始める。
他のPythonプログラム・環境と干渉しないためには，仮想環境の利用をおすすめする。

```bash
pip install -r requirements.txt
```

GPUがあれば，上記の`requirements.txt`の代わりに以下のコマンドで一括インストールできる：

```bash
pip install -r requirements-cuda.txt
```

`requirements.txt`, `requirements-apple-silicon.txt`及び`requirements-cuda.txt`はPoetryから自動生成される。

### GPU

#### CUDA/ROCM (Linux/Windows)

GPUの利用には，OSでの適切なドライバとCuDNNなどのペッケージのインスールの他，GPU対応のspaCyやPyTorchのインストールも必要になる。

例えば，CUDA使用時はGPU対応の[PyTorch](https://pytorch.org/get-started/locally/)（Transformersパッケージで使用）と[CuPY](https://docs.cupy.dev/en/stable/install.html)（spaCyパッケージで使用）をインストールする。


PyTorch ([https://pytorch.org/get-started/locally/](https://pytorch.org/get-started/locally/)):

```
pip install torch
```

spaCy ([https://spacy.io/usage](https://spacy.io/usage)):

```
pip install -U 'spacy[cuda-autodetect]'
```
あるいは
```
pip install cupy-cuda12x
```

#### Apple Silicon (macOS)

spaCyは[thinc](https://github.com/explosion/thinc/issues/792)というライブラリを使用しているので，PyTorch以外，thincの正しいバージョンをインストールする必要がある。
下記の`requirements-apple-silicon.txt`ですべて記載されているので，インストールするとGPUが使用できるはずである。確認方法は[ここ](https://support.apple.com/guide/activity-monitor/view-gpu-activity-actm9329b315/mac)にある。

```bash
pip install -r requirements-apple-silicon.txt
```

### 問題対策

まず，現在利用しているPythonのバージョン・場所を確認する：

```bash
which python
```

```bash
python -V
```

Pythonは従来バージョン2と3にわかれていて，OSとそのバージョンによってpythonを実行時，どちらか一方のバージョンを指す。
間違いなくPython 3を使いたい場合は，python3, pip3の通り，末尾に3をつける。
現在ではPython 2を使う場面がほとんどないが，同じくpython2で指定することができる。
また，将来的にはPython 2がインストールされず，pythonが常に3を指すことになる。

### virtualenv仮想環境

上記pipインストールで問題が発生すると，使用するPythonが3.8かそれより最新のものであることを確認するとよい。
また，他のパッケージとの干渉を除外するために[簡単な仮想環境](https://xkcd.com/1987/)を作る方法がある。
Python内蔵の仮想環境を作成する場合は[ここ](https://docs.python.org/ja/3/tutorial/venv.html)を参照。

上記の手動の仮想環境作成以外にも，poetry, pipenv, condaの環境・システムがある。
2022年10月時点では，poetryとその`pyproject.toml`の定義ファイルが人気であろう。
Anacondaも総括的な環境提供という点で人気である。

#### poetry

[Poetry](https://python-poetry.org/)は仮想環境・プロジェクト管理の総合的なツールで，その定義ファイルは`pyproject.toml`で記述されている。

VS Codeなど一部エディターではプロジェクト内のフォルダ以外に仮想環境を見つけ出せないために，仮想環境を作る前に以下のコマンドでPoetry使用時にフォルダ内に作る設定にする。

```bash
poetry config virtualenvs.in-project true
```

Poetryを使う場合は下記コマンドで仮想環境作成，使用ペッケージのインストールを一斉に行える：

```bash
poetry install
```

あるいはNVIDIAのGPU搭載時：

```bash
poetry install -E cuda
```

上記により`poetry.lock`というファイルが作成される。中身は`pyproject.toml`で記述されている依存パッケージの実際にインストールされたバージョンなどの情報になる。

```bash
poetry shell
```

脱出方法は`deactivate`（またはControl+d）。

##### PDM

[PDM](https://pdm.fming.dev/latest/)はPythonの最新スタンダード（PEP 582, 517, 621）に従い，プロジェクト管理を可能にする。
PDMを使う場合は，`pyproject.toml`の`build-tools`のセクションをPoetryのものと入れ替えることが必要である。

#### conda

conda (Anaconda)で`natsume-simple`という仮想環境にインストールする：

```bash
conda env create -n natsume-simple -f environment.yml
```

インストール後は以下のコマンドで仮想環境を有効にできる：

```bash
conda activate natsume-simple
```

必要な場合はGPUサポート用のrequirements-*も参照してインストールして下さい。

仮想環境から脱出したいときは`conda deactivate`でできる。

動作確認はAnacondaの2023.09で行われたが，最新のバージョンの使用をおすすめする。
同じ環境を作る場合は以下のコマンドでできる：

```bash
conda update conda
conda install anaconda=2023.0]
```
-->

## 機能

- 特定の係り受け関係（名詞ー格助詞ー動詞，名詞ー格助詞ー形容詞など）における格助詞の左右にある語から検索できる
- 検索がブラウザを通して行われる
- 特定共起関係のジャンル間出現割合
- 特定共起関係のコーパスにおける例文表示

## プロジェクト構造

このプロジェクトは以下のファイルを含む：

```
.
├── data                         # データ
│   ├── jnlp-sample-3000.txt     # scripts実行後にできるコーパスファイル
│   └── ted_corpus.txt
├── environment.yml              # conda仮想環境用
├── notebooks                    # ノートブック
│   ├── pattern-extraction.ipynb
│   └── pattern_extraction_colab.ipynb # Google Colab用
├── Pipfile                      # pipenv仮想環境用
├── pyproject.toml               # poetry仮想環境用
├── README.md                    # このファイル
├── requirements.txt             # デフォルトの依存ペッケージ定義
├── requirements-electra.txt     # Electraモデル／GPU使用時の依存ペッケージ定義
├── requirements-colab.txt       # Google Colab用の依存ペッケージ定義
├── scripts                      # スクリプト（データ入手用）
│   ├── convert-jnlp-corpus.sh   # 自然言語処理コーパスの作成
│   └── get-jnlp-corpus.sh       # 自然言語処理コーパスのダウンロード
├── server.py                    # APIサーバ
├── static                       # （古い）検索インターフェースの静的ファイル
│   ├── app.js
│   └── index.html
└── svelte-frontend              # （新）検索インターフェース
    ├── package.json             # nodejsの依存パッケージ
    ├── public
    ├── README.md
    ├── scripts
    └── src
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

### CLI

```bash
uv run python src/natsume_simple/data.py --prepare
```

```bash
uv run python src/natsume_simple/pattern-extraction.py --corpus-name 自然言語処理 data/jnlp-corpus.txt data/jnlp-npvs.csv
uv run python src/natsume_simple/pattern-extraction.py --corpus-name TED data/ted-corpus.txt data/ted-npvs.csv
```

### scripts (deprecated)

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

### svelte-frontend

[Svelte](https://svelte.dev/)で書かれた検索インターフェース。

Svelteのインターフェース（html, css, jsファイル）は以下のコマンドで生成できる：
（`svelte-frontend/`フォルダから実行）

```bash
npm run build
```

Svelteの使用にはnodejsの環境整備が必要になる。

<!--
### static

サーバ読む静的ファイルを含むファルダ。
ここに置かれるものは基本的にAPIの`static/`URL下で同一ファイル名でアクセス可能。

-->

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

## データ・コーパスの生成スクリプト

現在はデータが`notebooks`下にあるJupyter Notebookによって生成される。
その結果が`data`に保存される。

結果はモデルによって異なるとしてファイル名の末尾にモデル名も記載されている。

それぞれの依存パッケージ定義ファイルでは，Jupyterのカーネルは定義されていない。
必要な場合は別途インストールください（VS Codeでは自動でインストールできる）。

## サーバの起動


```bash
uv run fastapi dev src/natsume_simple/server.py
```

上記コマンドでは，server.pyをFastAPIでウエブサーバで起動し，ブラウザからアクセス可能にする。

`server.py`では，モデルの指定があるのでご注意。

サーバを起動後は，出力される手順に従い，<http://127.0.0.1:8000/>にアクセスする。
FastAPIによるドキュメンテーションは<http://127.0.0.1:8000/docs>にある。
（環境によっては<http://0.0.0.0:8000>が<http://127.0.0.1:8000>と同様ではない）
