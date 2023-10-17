#!/usr/bin/env python

from pathlib import Path
import subprocess
import re
import random


def main(corpus_dir=Path("../data/NLP_LATEX_CORPUS")):
    latex_files = corpus_dir.rglob("*.tex")

    for latex_file in latex_files:
        text_file = latex_file.with_suffix(".txt")
        print(latex_file, "=>", text_file)
        if text_file.is_file():
            print("File exists, skipping.")
            continue

        p = subprocess.run(
            [
                "pandoc",
                "--quiet",
                "-f",
                "latex+east_asian_line_breaks",
                "-t",
                "plain",
                "--wrap=none",
                "--strip-comments",
                "-N",
                "-s",
                latex_file,
                "-o",
                text_file,
            ]
        )
        if p.returncode != 0:
            print("Failed to convert using pandoc, skipping!")

    print("Writing corpus...")
    lines = list(filter_non_japanese(dir=corpus_dir))
    random.shuffle(lines)
    with open("../data/jnlp-sample-3000-python.txt", "w", encoding="utf-8") as f:
        f.writelines(lines[:3000])


# 以下のBashでの処理をPythonで実装：
# awkで200字未満のパラグラフを除外し，grepで英文字3字以上の文を除外し，3000パラグラフを無作為抽出し，ファイルに出力
# cat $CORPUS_DIR/*/*.txt | awk 'length($0)>200' | grep -vP "[a-z]{2,}|-{2,}|\||[\d\.]{4,}" | shuf -n 3000 > $CORPUS_DIR/../jnlp-sample-3000.txt
# --random-source=<(yes 42)指定で再現可能にする

random.seed(42)  # Set random seed for reproducible results


def filter_non_japanese(dir):
    files = dir.rglob("*.txt")
    for file in files:
        with open(file, encoding="utf-8", errors="replace") as f:
            for line in f:
                if len(line) <= 200:
                    continue
                elif re.search(r"[a-z]{2,}|-{2,}|\||[\d\.]{4,}", line):
                    continue
                yield line


if __name__ == "__main__":
    main()
