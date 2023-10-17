from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
import pandas as pd


app = FastAPI()

model_name = "ja_ginza_electra"
db = pd.read_csv(f"data/ted_npvs_{model_name}.csv")
db = pd.concat([db, pd.read_csv(f"data/jnlp_npvs_{model_name}.csv")])
# NPV＋コーパスごとに集計したいので，Pandasのvalue_counts()を利用し，その結果SeriesオブジェクトをDataFrameに戻す
db = db.value_counts().to_frame(name="frequency").reset_index()

# コーパス間の頻度が比べるために一番小さいコーパスのNPVの数で正規化する
corpus_freqs: dict[str, int] = {
    corpus: db[db.corpus == corpus]["frequency"].sum() for corpus in db.corpus.unique()
}
min_count = min(corpus_freqs.values())
corpus_norm = {
    corpus: min_count / frequency for corpus, frequency in corpus_freqs.items()
}

print(corpus_norm)


@app.get("/corpus/norm")
def get_corpus_norm():
    return corpus_norm


@app.get("/npv/noun/{noun}")
def read_npv(noun: str):
    matches = (
        db[db.n == noun].drop(columns=["n"]).to_dict("records")
    )  # nは検索語と同じなので，省略できる
    return matches


app.mount("/static", StaticFiles(directory="static", html=True), name="static")
app.mount(
    "/app", StaticFiles(directory="svelte-frontend/public", html=True), name="app"
)
