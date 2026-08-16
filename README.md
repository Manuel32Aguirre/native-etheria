# Native

Native es una aplicación móvil para memorizar inglés mediante práctica activa y repetición espaciada. La idea es sencilla: eliges imágenes con frases que quieres aprender, la aplicación las extrae y organiza en bloques de práctica, y sólo avanzas cuando puedes decir cada frase correctamente.

El proyecto está compuesto por una app Flutter y una API en Spring Boot. La parte móvil se encarga de la experiencia de práctica, grabación y notificaciones; el backend protege la información de cada cuenta, administra los repasos y conecta con los servicios de OpenAI.

## Qué hace

- Extrae frases en inglés desde fotografías o capturas de pantalla.
- Agrupa las frases en bloques de hasta cinco elementos para evitar sesiones pesadas.
- Genera una pregunta de contexto por frase y la lee en voz alta.
- Permite responder con la voz; Whisper transcribe la respuesta y se compara contra el texto objetivo.
- Acepta diferencias normales de mayúsculas, espacios y puntuación, pero mantiene la exigencia sobre las palabras de la frase.
- Aplica repetición espaciada con intervalos de 3 horas, 12 horas, 1 día, 3 días, 1 semana, 2 semanas y 1 mes.
- Guarda la voz seleccionada y el número de repeticiones por cuenta.
- Guarda el audio de la pregunta por frase y por voz. Así, una vez generado, se reutiliza en sesiones posteriores sin pedir el mismo audio otra vez a OpenAI.
- Incluye registro, inicio de sesión con JWT y verificación de correo.

## Estructura

```text
native-etheria/
├── backend/                 # API REST con Spring Boot
│   ├── src/main/java/       # Dominio, seguridad, controladores y servicios
│   ├── src/main/resources/  # application.yml
│   ├── .env.example         # Plantilla de configuración local
│   ├── mvnw / mvnw.cmd      # Maven Wrapper
│   └── pom.xml
└── frontend/                # Aplicación Flutter para Android
    ├── lib/                 # Pantallas, providers, modelos y servicios
    ├── android/
    └── pubspec.yaml
```

## Tecnologías

| Área | Tecnologías |
| --- | --- |
| Aplicación móvil | Flutter, Dart, Provider, `http` |
| Audio | `record`, `audioplayers` |
| Captura y recordatorios | `image_picker`, notificaciones locales, `shared_preferences` |
| API | Java 21, Spring Boot 4.1, Spring Security, Spring Data JPA |
| Persistencia | PostgreSQL, Hibernate |
| Autenticación | JSON Web Tokens (JWT) |
| IA | GPT-4o, Whisper y TTS de OpenAI |
| Correo | Spring Mail mediante SMTP |

## Requisitos

Para ejecutar el proyecto localmente necesitas:

- Java 21.
- Flutter con Dart 3.13 o superior.
- Android Studio, un emulador Android o un dispositivo físico con depuración USB.
- PostgreSQL 16 o una instancia compatible.
- Una clave de OpenAI con acceso a `gpt-4o`, `whisper-1` y `tts-1`.
- Una cuenta SMTP si quieres probar la verificación de correo.

Los wrappers incluidos permiten usar Maven sin instalarlo globalmente.

## Configurar el backend

Desde la raíz del proyecto, crea el archivo de entorno a partir de la plantilla:

```powershell
Copy-Item backend\.env.example backend\.env
```

Completa `backend/.env` con tus credenciales. El archivo contiene secretos y no debe subirse al repositorio.

```dotenv
# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=native_db
DB_USERNAME=native_user
DB_PASSWORD=tu_password

# JWT
JWT_SECRET=un-secreto-largo-y-aleatorio
JWT_EXPIRATION_MS=86400000

# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_VISION_MODEL=gpt-4o
OPENAI_STT_MODEL=whisper-1
OPENAI_TTS_MODEL=tts-1
OPENAI_TTS_VOICE=alloy

# Verificación de correo
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=tu-correo@example.com
MAIL_PASSWORD=tu-app-password
MAIL_FROM=tu-correo@example.com
MAIL_VERIFICATION_BASE_URL=http://localhost:8080/api/auth/verify
```

Crea la base de datos antes de iniciar la aplicación:

```sql
CREATE USER native_user WITH PASSWORD 'tu_password';
CREATE DATABASE native_db OWNER native_user;
```

> El proyecto utiliza `spring.jpa.hibernate.ddl-auto=update`. Al iniciar, Hibernate crea o actualiza las tablas necesarias. Es conveniente usar migraciones versionadas antes de llevar cambios de esquema a un entorno con datos importantes.

Inicia la API:

```powershell
Set-Location backend
.\mvnw.cmd spring-boot:run
```

La API quedará disponible en `http://localhost:8080`. Para ejecutar sus pruebas:

```powershell
.\mvnw.cmd test
```

## Configurar Flutter

La URL que usa la app se concentra en [frontend/lib/config/app_config.dart](frontend/lib/config/app_config.dart). Para desarrollo local, configura `lanHost` con la IP LAN del equipo donde ejecutas Spring Boot, por ejemplo `192.168.1.25`. No uses `localhost` cuando pruebes desde un teléfono: desde el dispositivo, `localhost` apunta al propio teléfono.

Después instala dependencias y ejecuta la app:

```powershell
Set-Location frontend
flutter pub get
flutter run
```

Para comprobar el código estático:

```powershell
flutter analyze
```

Para crear un APK de distribución:

```powershell
flutter build apk --release
```

El resultado queda en `frontend/build/app/outputs/flutter-apk/app-release.apk`.

## Flujo de uso

1. Crea una cuenta y verifica el correo recibido.
2. Inicia sesión.
3. En la pantalla principal, usa el botón de cámara para tomar una foto o seleccionar hasta cinco imágenes de la galería.
4. Native envía cada imagen a la API; GPT-4o detecta las frases en inglés y evita guardar duplicados.
5. Inicia el bloque de práctica cuando haya frases disponibles.
6. Escucha la pregunta, responde en voz alta y espera la validación.
7. Repite cada frase el número configurado de veces. Al completar la meta, la frase se programa para su siguiente repaso.

## Reglas de práctica

Cada usuario tiene una cola independiente. El backend entrega bloques de máximo cinco frases; las frases que no caben quedan pendientes para el siguiente bloque disponible.

La comparación no depende de la puntuación que Whisper pueda omitir. Antes de comparar, el backend normaliza Unicode, mayúsculas, apóstrofes, puntuación y espacios. Esto significa que `I'm ready.` y `im ready` se consideran equivalentes, pero cambiar una palabra sigue siendo un error.

La cantidad de repeticiones y la voz de síntesis se guardan en la cuenta. El valor inicial es de 20 repeticiones y voz `alloy`. Esos valores se recuperan al iniciar sesión, por lo que se conservan aunque cambies de teléfono.

## Uso de OpenAI y costos

Native usa tres servicios diferentes:

| Servicio | Cuándo se usa | Cómo se evita gasto innecesario |
| --- | --- | --- |
| GPT-4o | Al analizar una imagen y al crear una pregunta para una frase nueva | La pregunta se guarda con la frase y no se vuelve a generar. |
| TTS | Cuando se necesita escuchar la pregunta | El MP3 queda almacenado por frase y voz. Sólo se genera otra vez si eliges una voz distinta. |
| Whisper | Después de cada respuesta grabada | Se envía el audio de ese intento para poder validar lo que se dijo. El costo depende de la duración del audio. |

La parte más sensible al uso repetido es Whisper: cada respuesta hablada requiere una transcripción. La aplicación no usa dos servicios de micrófono al mismo tiempo; `record` toma el audio y controla el silencio antes de enviar el archivo a la API.

## API principal

Todas las rutas, salvo registro, inicio de sesión y verificación, requieren un encabezado JWT:

```http
Authorization: Bearer <token>
```

| Método | Ruta | Descripción |
| --- | --- | --- |
| `POST` | `/api/auth/register` | Crea una cuenta y solicita la verificación por correo. |
| `POST` | `/api/auth/login` | Inicia sesión y devuelve el token JWT. |
| `GET` | `/api/auth/verify` | Confirma una cuenta desde el enlace enviado por correo. |
| `POST` | `/api/sentences/extract-image` | Extrae y guarda frases desde una imagen codificada en Base64. |
| `GET` | `/api/sentences/block` | Obtiene el bloque actual de práctica. |
| `GET` | `/api/sentences/history` | Consulta las frases guardadas y su historial. |
| `POST` | `/api/sentences/{id}/complete` | Marca una frase como terminada para programar el siguiente intervalo. |
| `DELETE` | `/api/sentences/{id}` | Elimina una frase propia. |
| `GET` | `/api/practice/{sentenceId}/question` | Obtiene la pregunta guardada o genera una nueva. |
| `POST` | `/api/practice/{sentenceId}/question-audio?voice=alloy` | Devuelve el audio cacheado de la pregunta. |
| `POST` | `/api/practice/{sentenceId}/validate-audio` | Recibe `multipart/form-data`, transcribe con Whisper y valida la respuesta. |
| `GET` | `/api/settings/practice` | Consulta voz y número de repeticiones de la cuenta. |
| `POST` | `/api/settings/practice` | Actualiza voz y número de repeticiones. |

## Despliegue

La app móvil sólo necesita conocer una URL pública accesible desde el teléfono. Antes de compilar una versión de producción, actualiza `lanHost` y, si es necesario, `port` en [frontend/lib/config/app_config.dart](frontend/lib/config/app_config.dart); luego genera de nuevo el APK.

En el servidor, configura las mismas variables de `backend/.env.example`, pero con secretos propios del entorno. En particular:

- Usa una contraseña segura para PostgreSQL y un `JWT_SECRET` largo y aleatorio.
- Conserva `OPENAI_VISION_MODEL=gpt-4o` para mantener la calidad de extracción actual.
- Configura `MAIL_VERIFICATION_BASE_URL` con la URL pública real de la API.
- No expongas PostgreSQL a Internet salvo que exista una razón clara y controles de red adecuados.
- Restringe el acceso público a la API con HTTPS mediante un proxy inverso antes de una distribución amplia.

## Notas de seguridad

- `backend/.env` contiene credenciales y debe permanecer fuera de Git.
- Una clave de OpenAI publicada debe revocarse y reemplazarse de inmediato.
- La app recibe y conserva el JWT con `SharedPreferences`; para un producto con requisitos de seguridad más altos, conviene migrar ese almacenamiento a `flutter_secure_storage`.
- La verificación de correo depende de que el SMTP permita conexiones autenticadas desde el servidor.

## Estado de validación

La base actual se valida con:

```powershell
Set-Location backend
.\mvnw.cmd test

Set-Location ..\frontend
flutter analyze
```

Con eso se comprueba que el backend construye y sus pruebas pasan, y que Flutter no tiene errores de análisis estático.
