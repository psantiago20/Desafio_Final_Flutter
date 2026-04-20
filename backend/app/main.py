from fastapi import FastAPI

app = FastAPI(title="Medical SaaS API")

@app.get("/")
def root():
    return {"message": "API is running 🚀"}