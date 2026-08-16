"""
Local speech-to-text microservice for Native Etheria.

Spring Boot sends practice audio here instead of OpenAI Whisper,
so retries during practice cost $0 in STT API usage.
"""

from __future__ import annotations

import logging
import os
import tempfile
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from faster_whisper import WhisperModel
from starlette.datastructures import UploadFile as StarletteUploadFile

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("stt-service")

# Lightsail $7 plans are tight on RAM. Default to "tiny" (int8).
# Upgrade to "base" only if the instance has spare memory after Java + Postgres.
MODEL_NAME = os.getenv("WHISPER_MODEL", "tiny")
COMPUTE_TYPE = os.getenv("WHISPER_COMPUTE_TYPE", "int8")
DEVICE = os.getenv("WHISPER_DEVICE", "cpu")
DEFAULT_LANGUAGE = os.getenv("WHISPER_LANGUAGE", "en")
CPU_THREADS = int(os.getenv("WHISPER_CPU_THREADS", "1"))

model: WhisperModel | None = None


@asynccontextmanager
async def lifespan(_app: FastAPI):
    global model
    logger.info(
        "Loading Whisper model=%s device=%s compute_type=%s threads=%s",
        MODEL_NAME,
        DEVICE,
        COMPUTE_TYPE,
        CPU_THREADS,
    )
    model = WhisperModel(
        MODEL_NAME,
        device=DEVICE,
        compute_type=COMPUTE_TYPE,
        cpu_threads=CPU_THREADS,
    )
    logger.info("Whisper model ready")
    yield
    model = None


app = FastAPI(title="Native STT Service", version="1.0.0", lifespan=lifespan)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok" if model is not None else "starting",
        "model": MODEL_NAME,
        "device": DEVICE,
        "compute_type": COMPUTE_TYPE,
    }


async def _read_audio(request: Request) -> tuple[bytes, str, str]:
    """Accepts multipart uploads under any field name, or a raw audio body."""
    content_type = request.headers.get("content-type", "")
    language = DEFAULT_LANGUAGE

    if content_type.startswith("multipart/form-data"):
        form = await request.form()
        upload = next(
            (value for value in form.values() if isinstance(value, StarletteUploadFile)),
            None,
        )
        raw_language = form.get("language")
        if isinstance(raw_language, str) and raw_language.strip():
            language = raw_language.strip()

        if upload is None:
            logger.warning("Multipart request without a file part. Fields=%s", list(form.keys()))
            raise HTTPException(
                status_code=400,
                detail=f"No audio file part found. Received fields: {list(form.keys())}",
            )
        return await upload.read(), upload.filename or "audio.m4a", language

    body = await request.body()
    return body, "audio.m4a", language


@app.post("/transcribe")
async def transcribe(request: Request) -> dict[str, str]:
    if model is None:
        raise HTTPException(status_code=503, detail="STT model is still loading")

    raw, filename, language = await _read_audio(request)
    if not raw:
        raise HTTPException(status_code=400, detail="Audio file is empty")

    suffix = Path(filename).suffix or ".m4a"
    tmp_path: str | None = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(raw)
            tmp_path = tmp.name

        segments, _info = model.transcribe(
            tmp_path,
            language=language,
            vad_filter=True,
            beam_size=1,
        )
        text = " ".join(segment.text.strip() for segment in segments).strip()
        logger.info("Transcribed %s bytes -> %s chars", len(raw), len(text))
        return {"text": text}
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001 - surface any decode/model failure
        logger.exception("Transcription failed")
        raise HTTPException(status_code=500, detail=f"Transcription failed: {exc}") from exc
    finally:
        if tmp_path:
            Path(tmp_path).unlink(missing_ok=True)
