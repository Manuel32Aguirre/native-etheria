"""
Local speech-to-text microservice for Native Etheria.

Spring Boot sends practice audio here instead of OpenAI Whisper,
so retries during practice cost $0 in STT API usage.
"""

from __future__ import annotations

import logging
import os
import tempfile
from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from faster_whisper import WhisperModel

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("stt-service")

# Lightsail $7 plans are tight on RAM. Default to "tiny" (int8).
# Upgrade to "base" only if the instance has spare memory after Java + Postgres.
MODEL_NAME = os.getenv("WHISPER_MODEL", "tiny")
COMPUTE_TYPE = os.getenv("WHISPER_COMPUTE_TYPE", "int8")
DEVICE = os.getenv("WHISPER_DEVICE", "cpu")
DEFAULT_LANGUAGE = os.getenv("WHISPER_LANGUAGE", "en")

app = FastAPI(title="Native STT Service", version="1.0.0")
model: WhisperModel | None = None


@app.on_event("startup")
def load_model() -> None:
    global model
    logger.info(
        "Loading Whisper model=%s device=%s compute_type=%s",
        MODEL_NAME,
        DEVICE,
        COMPUTE_TYPE,
    )
    model = WhisperModel(MODEL_NAME, device=DEVICE, compute_type=COMPUTE_TYPE)
    logger.info("Whisper model ready")


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok" if model is not None else "starting",
        "model": MODEL_NAME,
        "device": DEVICE,
        "compute_type": COMPUTE_TYPE,
    }


@app.post("/transcribe")
async def transcribe(
    file: UploadFile = File(...),
    language: str = Form(DEFAULT_LANGUAGE),
) -> dict[str, str]:
    if model is None:
        raise HTTPException(status_code=503, detail="STT model is still loading")

    suffix = Path(file.filename or "audio.m4a").suffix or ".m4a"
    raw = await file.read()
    if not raw:
        raise HTTPException(status_code=400, detail="Audio file is empty")

    tmp_path: str | None = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(raw)
            tmp_path = tmp.name

        segments, _info = model.transcribe(
            tmp_path,
            language=language or DEFAULT_LANGUAGE,
            vad_filter=True,
            beam_size=1,
        )
        text = " ".join(segment.text.strip() for segment in segments).strip()
        return {"text": text}
    except Exception as exc:  # noqa: BLE001 - surface any decode/model failure
        logger.exception("Transcription failed")
        raise HTTPException(status_code=500, detail=f"Transcription failed: {exc}") from exc
    finally:
        if tmp_path:
            Path(tmp_path).unlink(missing_ok=True)
