# Stack Python FastAPI Skill

## Cuándo usarlo
- Stack detectado: `python-fastapi` (Python 3.11+, FastAPI 0.109+)
- APIs REST, microservicios, backends para SPAs
- Proyectos con Pydantic v2, SQLAlchemy 2.x, async/await

## Cuándo NO usarlo
- Proyectos Django, Flask, Starlette puro
- Python < 3.11 (EOL)
- Pydantic v1 (migración obligatoria a v2)

## Descripción
Convenciones obligatorias para Python moderno con FastAPI. Tipado estricto, inyección de dependencias, async correcto, testing con pytest.

## Archivos de referencia
- `python-fastapi-conventions.md` — Convenciones con código bueno/malo
- `python-fastapi-antipatterns.md` — Antipatrones comunes
- `pydantic-v2-migration.md` — Guía migración Pydantic v1 → v2

## Reglas verificables

### Regla 1: Python 3.11+ + FastAPI 0.109+ + Pydantic v2
```toml
# pyproject.toml (poetry/uv/pip)
[project]
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.109.0",
    "uvicorn[standard]>=0.27.0",
    "pydantic>=2.5.0",
    "pydantic-settings>=2.1.0",
    "sqlalchemy>=2.0.0",
    "alembic>=1.13.0",
    "asyncpg>=0.29.0",  # PostgreSQL async
]
```
**Verificación**: `python --version` ≥ 3.11; `pip show fastapi pydantic` muestra versiones correctas

### Regla 2: Tipado estricto en toda la API (mypy strict)
```python
# BUENO - Tipos completos, mypy --strict pasa
from pydantic import BaseModel, EmailStr, Field
from typing import Annotated
from uuid import UUID

class UserCreateRequest(BaseModel):
    email: Annotated[EmailStr, Field(description="Email del usuario")]
    password: Annotated[str, Field(min_length=8, description="Mínimo 8 caracteres")]
    full_name: Annotated[str, Field(max_length=100)]

    model_config = {"extra": "forbid"}  # Rechaza campos extra

# MALO - Sin tipos, extra fields permitidos
class UserCreateRequest(BaseModel):
    email: str
    password: str
    # FALLA REGLA 2: sin validación, sin tipos estrictos
```

### Regla 3: Inyección de dependencias con Depends (no globals)
```python
# BUENO - Depends, testable, lifecycle managed
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session

@router.post("/users")
async def create_user(
    request: UserCreateRequest,
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    service = UserService(db)
    return await service.create(request)

# MALO - Global session (no testable, race conditions)
db = create_engine(...).connect()  # FALLA REGLA 3

@router.post("/users")
async def create_user(request: UserCreateRequest):
    return UserService(db).create(request)  # Comparte conexión entre requests
```

### Regla 4: Async/await correcto (no blocking en event loop)
```python
# BUENO - Async en I/O (DB, HTTP, Redis)
@router.get("/users/{user_id}")
async def get_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    user = await user_service.get(db, user_id)  # await en async function
    return UserResponse.model_validate(user)

# MALO - Sync en async function (bloquea event loop)
@router.get("/users/{user_id}")
async def get_user(user_id: UUID) -> UserResponse:
    user = user_service.get_sync(db, user_id)  # FALLA REGLA 4: bloquea
    return UserResponse.model_validate(user)

# MALO - Async en sync function (no hace nada)
def get_user(user_id: UUID) -> UserResponse:
    user = await user_service.get(db, user_id)  # SyntaxError
```

### Regla 5: Pydantic models para request/response (no dicts)
```python
# BUENO - Models tipados, validados, documentados en OpenAPI
@router.post("/users", response_model=UserResponse, status_code=201)
async def create_user(request: UserCreateRequest, ...) -> UserResponse:
    return await service.create(request)

# MALO - Dicts sin validación ni documentación
@router.post("/users")
async def create_user(request: dict) -> dict:  # FALLA REGLA 5
    return {"id": "..."}
```

### Regla 6: Excepciones HTTP tipadas (no raise genérico)
```python
# BUENO - HTTPException con detail estructurado
from fastapi import HTTPException, status

async def get_user(user_id: UUID, db: AsyncSession = Depends(get_db)) -> UserResponse:
    user = await service.get(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "USER_NOT_FOUND", "message": f"User {user_id} not found"}
        )
    return UserResponse.model_validate(user)

# MALO - Excepción genérica, 500
async def get_user(user_id: UUID) -> UserResponse:
    user = await service.get(user_id)
    if not user:
        raise Exception("Not found")  # FALLA REGLA 6: 500, sin detail
```

### Regla 7: Paginación con limit/offset o cursor
```python
# BUENO - Parámetros validados, respuesta consistente
from pydantic import BaseModel, Field

class PageParams(BaseModel):
    limit: Annotated[int, Field(ge=1, le=100, default=20)]
    offset: Annotated[int, Field(ge=0, default=0)]

class PageResponse(BaseModel, Generic[T]):
    items: list[T]
    total: int
    limit: int
    offset: int

@router.get("/users", response_model=PageResponse[UserResponse])
async def list_users(params: PageParams = Depends(), db: AsyncSession = Depends(get_db)):
    total, items = await service.list(db, params.limit, params.offset)
    return PageResponse(items=items, total=total, limit=params.limit, offset=params.offset)

# MALO - Sin paginación
@router.get("/users")
async def list_users() -> list[UserResponse]:  # FALLA REGLA 7: OOM risk
    return await service.list_all()
```

### Regla 8: Settings con pydantic-settings (no os.getenv)
```python
# BUENO - Tipado, validado, documentado
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    database_url: str
    redis_url: str = "redis://localhost:6379"
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()  # Singleton

# MALO - os.getenv sin validación
DATABASE_URL = os.getenv("DATABASE_URL")  # FALLA REGLA 8: None si falta, sin tipo
```

### Regla 9: Tests con pytest + httpx.AsyncClient + Testcontainers
```python
# conftest.py
import pytest
from httpx import AsyncClient
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def postgres():
    with PostgresContainer("postgres:16") as pg:
        yield pg.get_connection_url()

@pytest.fixture
async def client(postgres) -> AsyncGenerator[AsyncClient, None]:
    app = create_app(postgres)
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

# test_users.py
async def test_create_user(client: AsyncClient):
    response = await client.post("/api/v1/users", json={
        "email": "test@example.com",
        "password": "secret123",
        "full_name": "Test User"
    })
    assert response.status_code == 201
    assert "id" in response.json()
    assert response.headers["location"].startswith("/api/v1/users/")
```

### Regla 10: Ruff + mypy en CI (lint + typecheck)
```toml
# pyproject.toml
[tool.ruff]
target-version = "py311"
line-length = 100
select = ["E", "F", "I", "N", "W", "UP", "B", "C4", "PTH", "T20"]
ignore = ["E501"]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true

# CI
# ruff check . && mypy .
```

## Verificación automática
```bash
# Lint + typecheck
ruff check . && mypy .

# Tests + cobertura
pytest --cov=src --cov-fail-under=80 --cov-report=term-missing

# Pre-commit (opcional)
pre-commit run --all-files
```