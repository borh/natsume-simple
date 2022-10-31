#!/usr/bin/env bash

wget -c https://www.anlp.jp/resource/journal_latex/NLP_LATEX_CORPUS.zip

CORPUS_DIR=../data

if [ ! -d "$CORPUS_DIR/NLP_LATEX_CORPUS" ]; then
	unzip NLP_LATEX_CORPUS.zip -d $CORPUS_DIR
fi
