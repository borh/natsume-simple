#!/usr/bin/env python

from pathlib import Path
import urllib.request
import zipfile

if __name__ == "__main__":
    data_dir = Path("../data")
    file = data_dir / "NLP_LATEX_CORPUS.zip"
    if not file.is_file():
        print("Downloading...")
        urllib.request.urlretrieve(
            "https://www.anlp.jp/resource/journal_latex/NLP_LATEX_CORPUS.zip",
            file,
        )

    with zipfile.ZipFile(file, "r") as z:
        z.extractall(data_dir)
