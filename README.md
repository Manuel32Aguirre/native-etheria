# Native – Memorización Activa Estricta (Backend + Frontend)

Aplicación de aprendizaje de inglés basada en repetición espaciada (Ebbinghaus) con
tolerancia cero: solo se avanza cuando la transcripción de voz coincide 100% con la
oración objetivo.

## Estructura

- `backend/native`: API REST en Spring Boot (Java 21, PostgreSQL, JWT, MapStruct, OpenAI).
- `frontend/native_frontend`: App Flutter (Provider, http, record, audioplayers).

## Backend

1. Copia `backend/native/.env.example` a `backend/native/.env` y completa:
   - Credenciales de PostgreSQL.
   - `JWT_SECRET` (cadena larga y aleatoria).
   - `OPENAI_API_KEY`.
2. Levanta la base de datos:
   ```powershell
   cd backend/native
   docker compose --env-file .env up -d
   ```
3. Ejecuta la API (Spring Boot lee las variables del entorno; puedes exportarlas o usar un plugin como `spring-dotenv` / cargar el `.env` con tu shell):
   ```powershell
   ./mvnw spring-boot:run
   ```
   El servidor escucha en `0.0.0.0:8080`, por lo que es accesible desde cualquier
   dispositivo de tu red local usando la IP LAN de esta máquina (ej. `192.168.1.100`).

### Endpoints principales

- `POST /api/auth/register`, `POST /api/auth/login`
- `POST /api/sentences/extract-image` (Base64 → OpenAI Vision → guarda oraciones FIFO)
- `GET /api/sentences/block` (bloque actual de máx. 5 + `pendingNowCount`)
- `POST /api/sentences/{id}/complete` (avanza intervalo Ebbinghaus tras 20 repeticiones)
- `GET /api/practice/{sentenceId}/question` (pregunta variable vía GPT-4o-mini)
- `POST /api/practice/{sentenceId}/validate-audio` (Whisper + comparación exacta)
- `POST /api/practice/tts` (bridge a OpenAI TTS, devuelve `audio/mpeg`)

## Frontend

1. Abre `frontend/native_frontend/lib/config/app_config.dart` y actualiza `lanHost`
   con la IP LAN de la máquina donde corre el backend (`ipconfig` en Windows).
2. Instala dependencias y ejecuta:
   ```powershell
   cd frontend/native_frontend
   flutter pub get
   flutter run
   ```
3. Regístrate/inicia sesión, toma una foto de tus oraciones a memorizar (botón
   flotante en HomeScreen) y comienza la sesión de práctica.

## Reglas de negocio implementadas

- Bloques de máximo 5 oraciones; el resto queda como `PENDING_NOW` (no se reprograma).
- Intervalos estrictos: 3h → 12h → 1d → 3d → 1 semana → 2 semanas → 1 mes → `isMastered = true`.
- Tolerancia cero: se requiere coincidencia exacta (normalizada por espacios/mayúsculas/puntuación)
  entre la transcripción de Whisper y `originalText`.
- El contador de repeticiones (0/20) vive en el frontend durante la sesión; solo al
   llegar a 20 se llama a `/sentences/{id}/complete` para avanzar el intervalo.
