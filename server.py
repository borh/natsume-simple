from collections import defaultdict
from typing import Optional
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
import pandas as pd
from collections import defaultdict, Counter

app = FastAPI()


db = pd.read_csv("data/ted_npvs.csv")


@app.get("/npv/noun/{noun}")
def read_npv(noun: str):
    matches = db[db.n == noun][["p", "v"]].to_records(index=False)
    results = defaultdict(Counter)
    for p, v in matches:
        results[p][v] += 1
    return {"results": [{'p': particle, 'v': verb, 'f': frequency}
                        for particle, vf in results.items()
                        for verb, frequency in vf.items()]}


app.mount("/static", StaticFiles(directory="static", html=True), name="static")
