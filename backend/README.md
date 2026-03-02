# MyFshools Backend (Spring Boot)

## Prerequisites
- JDK 17+
- Maven 3.9+
- Docker (optional, if you run PostgreSQL by compose)

## 1) Start PostgreSQL
```bash
cd backend
docker compose up -d
```

## 2) Run backend
```bash
cd backend
mvn spring-boot:run
```

Default API: `http://localhost:8080`

## Environment variables
- `DB_HOST` (default `localhost`)
- `DB_PORT` (default `5432`)
- `DB_NAME` (default `myfshools`)
- `DB_USER` (default `postgres`)
- `DB_PASSWORD` (default `postgres`)
- `JWT_SECRET` (default in `application.yml`, should change in real env)
- `JWT_EXPIRATION_MS` (default `86400000`)

## Seed account
- Phone: `0386852628`
- Password: `123456`
- Phone: `0900000001`
- Password: `123456`
- Phone: `0900000002`
- Password: `123456`

## Login API
`POST /api/auth/login`

Body:
```json
{
  "phone": "0386852628",
  "password": "123456"
}
```

## Main APIs (Bearer token required)
- `GET /api/dashboard`
- `GET /api/homework?status=all|pending|submitted|overdue`
- `GET /api/grades`
- `GET /api/notes`
- `POST /api/notes`
- `PUT /api/notes/{noteId}`
- `GET /api/timetable`
- `GET /api/chat/threads`
- `POST /api/chat/direct`
- `POST /api/chat/groups`
- `POST /api/chat/groups/{conversationId}/invite`
- `GET /api/chat/threads/{threadId}/messages`
- `POST /api/chat/threads/{threadId}/messages`
- `GET /api/me/profile`
