from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
import polars as pl
from typing import Dict, List, Any

app = FastAPI()


def load_database(model_name: str) -> pl.DataFrame:
    db = pl.read_csv(f"data/ted_npvs_{model_name}.csv")
    db = db.vstack(pl.read_csv(f"data/jnlp_npvs_{model_name}.csv"))
    return db.group_by(db.columns).agg(pl.len().alias("frequency"))


def calculate_corpus_norm(db: pl.DataFrame) -> Dict[str, float]:
    corpus_freqs = {
        corpus: db.filter(pl.col("corpus") == corpus)["frequency"].sum()
        for corpus in db["corpus"].unique()
    }
    min_count = min(corpus_freqs.values())
    return {corpus: min_count / frequency for corpus, frequency in corpus_freqs.items()}


model_name = "ja_ginza_bert_large"
db = load_database(model_name)
corpus_norm = calculate_corpus_norm(db)


@app.get("/corpus/norm")
def get_corpus_norm() -> Dict[str, float]:
    return corpus_norm


@app.get("/npv/noun/{noun}")
def read_npv(noun: str) -> List[Dict[str, Any]]:
    matches = db.filter(pl.col("n") == noun).drop("n").to_dicts()
    return matches


# app.mount(
#    "/static",
#    StaticFiles(directory="natsume-frontend/static", html=True),
#    name="static",
# )
app.mount("/", StaticFiles(directory="natsume-frontend/build", html=True), name="app")
