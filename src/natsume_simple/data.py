import re
import subprocess
import urllib.request
import zipfile
from pathlib import Path
from typing import List, Iterator, Tuple
import random
import argparse

import datasets
from natsume_simple.log import setup_logger
from natsume_simple.utils import set_random_seed

logger = setup_logger(__name__)


def download_jnlp_corpus(data_dir: Path) -> None:
    """Download the JNLP corpus."""
    file = data_dir / "NLP_LATEX_CORPUS.zip"
    if not file.is_file():
        logger.info("Downloading JNLP corpus...")
        urllib.request.urlretrieve(
            "https://www.anlp.jp/resource/journal_latex/NLP_LATEX_CORPUS.zip",
            file,
        )

    with zipfile.ZipFile(file, "r") as z:
        z.extractall(data_dir)


def convert_latex_to_text(corpus_dir: Path) -> None:
    """Convert LaTeX files to plain text."""
    latex_files = corpus_dir.rglob("*.tex")

    for latex_file in latex_files:
        text_file = latex_file.with_suffix(".txt")
        logger.info(f"{latex_file} => {text_file}")
        if text_file.is_file():
            logger.info("File exists, skipping.")
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
            logger.error("Failed to convert using pandoc, skipping!")


def filter_non_japanese(dir: Path) -> Iterator[str]:
    """Filter out non-Japanese text from converted files."""
    files = dir.rglob("*.txt")
    for file in files:
        with open(file, encoding="utf-8", errors="replace") as f:
            for line in f:
                if len(line) <= 200:
                    continue
                elif re.search(r"[a-z]{2,}|-{2,}|\||[\d\.]{4,}", line):
                    continue
                yield line


def prepare_jnlp_corpus(data_dir: Path) -> int:
    """Prepare the JNLP corpus for use."""
    corpus_dir = data_dir / "NLP_LATEX_CORPUS"
    download_jnlp_corpus(data_dir)
    convert_latex_to_text(corpus_dir)

    logger.info("Filtering and writing JNLP corpus...")
    lines = list(filter_non_japanese(dir=corpus_dir))

    output_file = data_dir / "jnlp-corpus.txt"
    with open(output_file, "w", encoding="utf-8") as f:
        f.writelines(lines)

    logger.info(f"JNLP corpus saved to {output_file}")
    return len(lines)


def get_ted_corpus() -> List[str]:
    """Get the TED corpus from the datasets library."""
    logger.info("Downloading TED corpus...")

    ted_dataset_2014 = datasets.load_dataset(
        "ted_talks_iwslt",
        language_pair=("en", "ja"),
        year="2014",
        trust_remote_code=True,
    )
    ted_dataset_2015 = datasets.load_dataset(
        "ted_talks_iwslt", language_pair=("en", "ja"), year="2015"
    )
    ted_dataset_2016 = datasets.load_dataset(
        "ted_talks_iwslt", language_pair=("en", "ja"), year="2016"
    )
    ted_dataset_2017jaen = datasets.load_dataset(
        "iwslt2017", "iwslt2017-ja-en", trust_remote_code=True
    )

    ted_corpus: List[str] = (
        [d["ja"] for d in ted_dataset_2014["train"]["translation"]]
        + [d["ja"] for d in ted_dataset_2015["train"]["translation"]]
        + [d["ja"] for d in ted_dataset_2016["train"]["translation"]]
        + [d["ja"] for d in ted_dataset_2017jaen["train"]["translation"]]
    )

    return ted_corpus


def prepare_ted_corpus(data_dir: Path) -> int:
    """Prepare the TED corpus for use."""
    ted_corpus = get_ted_corpus()

    output_file = data_dir / "ted-corpus.txt"
    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(ted_corpus))

    logger.info(f"TED corpus saved to {output_file}")
    return len(ted_corpus)


def prepare_corpora(data_dir: Path) -> Tuple[int, int]:
    """Prepare both JNLP and TED corpora."""
    data_dir.mkdir(parents=True, exist_ok=True)
    jnlp_count = prepare_jnlp_corpus(data_dir)
    ted_count = prepare_ted_corpus(data_dir)
    return jnlp_count, ted_count


def load_corpus(data_dir: Path, corpus_name: str, sample_size: int) -> List[str]:
    """Load a corpus with a specified sample size."""
    corpus_file = data_dir / f"{corpus_name}-corpus.txt"
    with open(corpus_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    random.shuffle(lines)
    return lines[:sample_size]


def load_corpora(
    data_dir: Path, jnlp_sample_size: int = 3000, ted_sample_size: int = 30000
) -> Tuple[List[str], List[str]]:
    """Load both JNLP and TED corpora with specified sample sizes."""
    jnlp_corpus = load_corpus(data_dir, "jnlp", jnlp_sample_size)
    ted_corpus = load_corpus(data_dir, "ted", ted_sample_size)
    return jnlp_corpus, ted_corpus


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Prepare and load JNLP and TED corpora for use in NLP tasks.",
        epilog="This script can download, process, prepare, and load the JNLP and TED corpora for further use in natural language processing tasks.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducibility (default: 42)",
    )
    parser.add_argument(
        "--prepare",
        action="store_true",
        help="Prepare the corpora by downloading and processing the data.",
    )
    parser.add_argument(
        "--load",
        action="store_true",
        help="Load the prepared corpora.",
    )
    parser.add_argument(
        "--jnlp-sample-size",
        type=int,
        default=3000,
        help="Sample size for the JNLP corpus (default: 3000). This determines how many sentences from the JNLP corpus will be randomly selected when loading.",
    )
    parser.add_argument(
        "--ted-sample-size",
        type=int,
        default=30000,
        help="Sample size for the TED corpus (default: 30000). This determines how many sentences from the TED corpus will be randomly selected when loading.",
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=Path("data"),
        help="Directory to store or load the prepared corpora (default: './data').",
    )
    args = parser.parse_args()

    set_random_seed(args.seed)
    logger.info(f"Random seed set to {args.seed}")

    if not (args.prepare or args.load):
        parser.print_help()
        print("\nNo action specified. Use --prepare or --load to perform operations.")
    else:
        if args.prepare:
            jnlp_count, ted_count = prepare_corpora(args.data_dir)
            logger.info(f"Corpora prepared and saved in {args.data_dir}")
            logger.info(f"JNLP corpus: {jnlp_count} sentences/paragraphs prepared")
            logger.info(f"TED corpus: {ted_count} sentences/paragraphs prepared")

        if args.load:
            jnlp_corpus, ted_corpus = load_corpora(
                args.data_dir, args.jnlp_sample_size, args.ted_sample_size
            )
            logger.info(
                f"Loaded {len(jnlp_corpus)} sentences from JNLP corpus (sample size: {args.jnlp_sample_size})"
            )
            logger.info(
                f"Loaded {len(ted_corpus)} sentences from TED corpus (sample size: {args.ted_sample_size})"
            )
