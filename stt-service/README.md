# STT Service (Whisper local)

Microservicio de audio → texto para Native Etheria. Spring Boot le envía las grabaciones de práctica en lugar de llamar a OpenAI Whisper, así los reintentos no gastan crédito de API.

## Arquitectura (simple)

```text
Flutter  →  Spring Boot (:8080)  →  stt-service (:9000)  →  faster-whisper (CPU)
                 │
                 ├── Vision / preguntas / TTS siguen en OpenAI
                 └── Solo la transcripción de respuestas es local
```

No es una arquitectura compleja: es **un proceso extra** en el mismo Lightsail, en la misma red Docker.

## Por qué `tiny` por defecto

El plan Lightsail de ~$7 suele tener poca RAM y ya corres:

- PostgreSQL (~256 MB)
- Spring Boot (~256 MB)
- sistema operativo

`tiny` + `int8` cabe mejor. Si más adelante tienes RAM libre, cambia a `base` en `.env`:

```dotenv
WHISPER_MODEL=base
```

## Desarrollo local

```powershell
cd stt-service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 9000
```

Prueba:

```powershell
curl http://localhost:9000/health
```

## Producción (Docker Compose)

Desde `backend/`, con el servicio añadido en `docker-compose.yml`:

```powershell
docker compose up -d --build stt
docker compose up -d --build native
```

Variables relevantes en `backend/.env`:

```dotenv
STT_PROVIDER=local
STT_LOCAL_URL=http://stt:9000
WHISPER_MODEL=tiny
```

Para volver temporalmente a OpenAI Whisper:

```dotenv
STT_PROVIDER=openai
```

## Expectativas de precisión

- En inglés, `tiny`/`base` locales suelen ir bien en frases y párrafos cortos.
- No es magia: ruido, acento fuerte o audio cortado pueden fallar igual que con la API.
- Si `tiny` se queda corto, sube a `base` antes de volver a pagar Whisper cloud.
