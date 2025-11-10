from fastapi import FastAPI, Request

app = FastAPI()

@app.post("/analyze")
async def analyze(request: Request):
    data = await request.json()
    text = data.get("text", "")
    response = {
        "original_text": text,
        "word_count": len(text.split()),
        "character_count": len(text)
    }
    return response
