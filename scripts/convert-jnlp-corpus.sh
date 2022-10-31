#!/usr/bin/env bash

CORPUS_DIR=../data/NLP_LATEX_CORPUS

# In order to force a reconversion of an existing plaintext file (because of improvements in Pandoc, etc.), you need to delete the generated plaintext file.
find $CORPUS_DIR -name "*.tex" -print0 | while read -d $'\0' latex_file
do
	output_file=${latex_file/.tex/.txt}
	if [ ! -f $output_file ]; then 
		pandoc --quiet -f latex+east_asian_line_breaks -t plain --wrap=none --strip-comments -N -s $latex_file -o $output_file
	fi
done

# awkで200字未満のパラグラフを除外し，grepで英文字3字以上の文を除外し，3000パラグラフを無作為抽出し，ファイルに出力
# --random-source=<(yes 42)指定で再現可能にする
cat $CORPUS_DIR/*/*.txt | awk 'length($0)>200' | grep -vP "[a-z]{2,}|-{2,}|\||[\d\.]{4,}" | shuf -n 3000 --random-source=<(yes 42) > $CORPUS_DIR/../jnlp-sample-3000.txt
