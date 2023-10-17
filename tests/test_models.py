import spacy


def test_model_loading():
    try:
        nlp = spacy.load("ja_ginza_electra")
    except Exception:
        nlp = spacy.load("ja_ginza")

    doc = nlp("これはテストです")
    assert len(doc) == 4
    assert [t.text for t in doc] == ["これ", "は", "テスト", "です"]
