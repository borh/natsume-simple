#!/usr/bin/env python

from pathlib import Path
import urllib.request


if __name__ == "__main__":
    file = Path("../data/NLP_LATEX_CORPUS.zip")
    if not file.is_file():
        print("Downloading...")
        urllib.request.urlretrieve(
            "https://www.anlp.jp/resource/journal_latex/NLP_LATEX_CORPUS.zip",
            file,
        )
