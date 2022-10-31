# natsume-simple

## 概要

natsume-simple は日本語の係り受け関係を検索できるシステム

## 機能

- 特定の係り受け関係（名詞ー格助詞ー動詞，名詞ー格助詞ー形容詞など）における格助詞の左右にある語から検索できる
- 検索がブラウザを返して行われる
- 特定共起関係のジャンル間出現割合
- 特定共起関係のコーパスにおける例文表示

## プロジェクト構造

このプロジェクトは以下のファイルを含む：

```
.
├── data
│   ├── ted_corpus.txt
│   └── ted_npvs.csv
├── notebooks
│   └── pattern-extraction.ipynb
├── README.md
├── requirements-electra.txt
├── requirements.txt
├── scripts
├── server.py
└── static
    ├── app.js
    └── index.html
```
## インストール

必要な Python のパッケージは`requirements.txt`に記載されている。

```bash
pip install -r requirements.txt
```

メモリ・容量に余裕があれば，より精度の高い言語モデル ja-ginza-electra を下記で入れ替えられる：

```bash
pip install -r requirements-electra.txt
```

このモデルを使用するために以下のように load する必要がある。

```python
nlp = spacy.load('ja_ginza_electra')
```

## データ・コーパスの生成スクリプト

現在はデータが`notebooks`下にあるJupyter Notebookによって生成される。
その結果が`data`に保存される。

## サーバの起動

```bash
uvicorn server:app --reload
```

上記コマンドでは，server.pyをUnicornというウエブサーバで起動し，ブラウザからアクセス可能にする。

サーバを起動後は，出力される手順に従い，<http://127.0.0.1:8000/static/>にアクセスする。
FastAPIによるドキュメンテーションは<http://127.0.0.1:8000/docs>にある。
