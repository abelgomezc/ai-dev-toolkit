# Python FastAPI Conventions - Código Bueno vs Malo

## Estructura de proyecto recomendada
```text
src/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app factory
│   ├── config.py               # Settings (pydantic-settings)
│   ├── database.py             # Engine, session factory
│   ├── models/                 # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── mixins.py           # TimestampMixin, UUIDMixin
│   ├── schemas/                # Pydantic models (API contracts)
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── common.py           # PageParams, PageResponse, ErrorResponse
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py             # Dependencies (get_db, get_current_user)
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── router.py       # APIRouter principal v1
│   │   │   ├── users.py
│   │   │   └── auth.py
│   │   └── exceptions.py       # Exception handlers
│   ├── services/               # Business logic
│   │   ├── __init__.py
│   │   ├── user_service.py
│   │   └── exceptions.py       # Domain exceptions
│   ├── repositories/           # Data access
│   │   ├── __init__.py
│   │   └── user_repository.py
│   └── core/
│       ├── security.py         # JWT, password hashing
│       └── events.py           # Event publishing
├── tests/
│   ├── __init__.py
│   ├── conftest.py             # Fixtures (Testcontainers, client)
│   ├── unit/
│   │   └── test_user_service.py
│   └── integration/
│       └── test_users_api.py
├── alembic/
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
├── pyproject.toml
├── .env.example
├── Dockerfile
└── docker-compose.yml
```

## FastAPI App Factory (main.py)
```python
# BUENO - Factory pattern, lifespan para startup/shutdown
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import create_tables, close_db
from app.api.v1.router import api_router
from app.api.exceptions import register_exception_handlers

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await create_tables()
    yield
    # Shutdown
    await close_db()

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="API documentation",
        lifespan=lifespan,
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
    )

    # Middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Exception handlers
    register_exception_handlers(app)

    # Routes
    app.include_router(api_router, prefix="/api/v1")

    return app

app = create_app()
```

## Database (database.py) - SQLAlchemy 2.x Async
```python
# BUENO - AsyncEngine, AsyncSession, sessionmaker
from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker,
    AsyncEngine
)
from sqlalchemy.orm import DeclarativeBase
from app.config import settings

class Base(DeclarativeBase):
    pass

engine: AsyncEngine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

async def create_tables() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

async def close_db() -> None:
    await engine.dispose()
```

## Models (models/user.py)
```python
# BUENO - Mixins, typed columns, relationships
import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, func, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from app.database import Base

class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

class UUIDMixin:
    id: Mapped[uuid.UUID] = mapped_column(
        PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )

class User(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(100), nullable=False)
    is_active: Mapped[bool] = mapped_column(default=True, nullable=False)
    is_superuser: Mapped[bool] = mapped_column(default=False, nullable=False)

    # Relationships
    # orders: Mapped[list["Order"]] = relationship(back_populates="user", lazy="selectin")
```

## Schemas (schemas/user.py)
```python
# BUENO - Separación request/response, validación, extra=forbid
from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Annotated
from uuid import UUID
from datetime import datetime

class UserBase(BaseModel):
    email: Annotated[EmailStr, Field(description="Email único del usuario")]
    full_name: Annotated[str, Field(min_length=1, max_length=100)]

    model_config = ConfigDict(extra="forbid", from_attributes=True)

class UserCreateRequest(UserBase):
    password: Annotated[str, Field(min_length=8, max_length=128, description="Mínimo 8 caracteres")]

class UserUpdateRequest(BaseModel):
    full_name: Annotated[str | None, Field(min_length=1, max_length=100)] = None
    is_active: bool | None = None

    model_config = ConfigDict(extra="forbid", from_attributes=True)

class UserResponse(UserBase):
    id: UUID
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
```

## Service (services/user_service.py)
```python
# BUENO - Lógica de negocio, domain exceptions, async
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.models.user import User
from app.schemas.user import UserCreateRequest, UserUpdateRequest, UserResponse
from app.repositories.user_repository import UserRepository
from app.core.security import hash_password
from app.services.exceptions import UserNotFound, EmailAlreadyExists

class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = UserRepository(db)

    async def create(self, request: UserCreateRequest) -> UserResponse:
        # Validación de negocio
        if await self.repo.exists_by_email(request.email):
            raise EmailAlreadyExists(request.email)

        user = User(
            email=request.email,
            password_hash=hash_password(request.password),
            full_name=request.full_name,
        )
        user = await self.repo.create(user)
        return UserResponse.model_validate(user)

    async def get(self, user_id: UUID) -> UserResponse:
        user = await self.repo.get(user_id)
        if not user:
            raise UserNotFound(user_id)
        return UserResponse.model_validate(user)

    async def list(self, limit: int, offset: int) -> tuple[int, list[UserResponse]]:
        total, users = await self.repo.list(limit, offset)
        return total, [UserResponse.model_validate(u) for u in users]

    async def update(self, user_id: UUID, request: UserUpdateRequest) -> UserResponse:
        user = await self.repo.get(user_id)
        if not user:
            raise UserNotFound(user_id)

        update_data = request.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(user, field, value)

        user = await self.repo.update(user)
        return UserResponse.model_validate(user)

    async def delete(self, user_id: UUID) -> None:
        user = await self.repo.get(user_id)
        if not user:
            raise UserNotFound(user_id)
        await self.repo.delete(user)
```

## Repository (repositories/user_repository.py)
```python
# BUENO - Solo data access, sin lógica de negocio
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from app.models.user import User

class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, user: User) -> User:
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def get(self, user_id: UUID) -> User | None:
        stmt = select(User).where(User.id == user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def exists_by_email(self, email: str) -> bool:
        stmt = select(func.count()).select_from(User).where(User.email == email)
        result = await self.db.execute(stmt)
        return result.scalar_one() > 0

    async def list(self, limit: int, offset: int) -> tuple[int, list[User]]:
        # Count total
        count_stmt = select(func.count()).select_from(User)
        total_result = await self.db.execute(count_stmt)
        total = total_result.scalar_one()

        # Paginated results
        stmt = select(User).offset(offset).limit(limit).order_by(User.created_at.desc())
        result = await self.db.execute(stmt)
        return total, list(result.scalars().all())

    async def update(self, user: User) -> User:
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def delete(self, user: User) -> None:
        await self.db.delete(user)
        await self.db.flush()
```

## API Router (api/v1/users.py)
```python
# BUENO - Router slim, delega a service, response_models
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.api.deps import get_db
from app.schemas.user import (
    UserCreateRequest, UserUpdateRequest, UserResponse, PageResponse, PageParams
)
from app.services.user_service import UserService
from app.services.exceptions import UserNotFound, EmailAlreadyExists
from app.api.exceptions import handle_domain_exceptions

router = APIRouter(prefix="/users", tags=["users"])

@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    request: UserCreateRequest,
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    service = UserService(db)
    return await service.create(request)

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    service = UserService(db)
    return await service.get(user_id)

@router.get("", response_model=PageResponse[UserResponse])
async def list_users(
    params: PageParams = Depends(),
    db: AsyncSession = Depends(get_db)
) -> PageResponse[UserResponse]:
    service = UserService(db)
    total, items = await service.list(params.limit, params.offset)
    return PageResponse(items=items, total=total, limit=params.limit, offset=params.offset)

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: UUID,
    request: UserUpdateRequest,
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    service = UserService(db)
    return await service.update(user_id, request)

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db)
) -> None:
    service = UserService(db)
    await service.delete(user_id)
```

## Tests (tests/integration/test_users_api.py)
```python
# BUENO - Testcontainers, AsyncClient, assertions claras
import pytest
from httpx import AsyncClient
from uuid import UUID

class TestUsersAPI:
    async def test_create_user_success(self, client: AsyncClient):
        response = await client.post("/api/v1/users", json={
            "email": "new@example.com",
            "password": "secret123",
            "full_name": "New User"
        })
        assert response.status_code == 201
        data = response.json()
        assert "id" in data
        UUID(data["id"])  # Valida UUID
        assert data["email"] == "new@example.com"
        assert data["full_name"] == "New User"
        assert "location" in response.headers
        assert response.headers["location"].startswith("/api/v1/users/")

    async def test_create_user_duplicate_email(self, client: AsyncClient, created_user):
        response = await client.post("/api/v1/users", json={
            "email": created_user.email,  # Fixture crea usuario
            "password": "secret123",
            "full_name": "Another User"
        })
        assert response.status_code == 409
        assert response.json()["code"] == "EMAIL_ALREADY_EXISTS"

    async def test_create_user_validation_error(self, client: AsyncClient):
        response = await client.post("/api/v1/users", json={
            "email": "invalid-email",  # Inválido
            "password": "short",       # < 8 chars
            "full_name": ""            # Vacío
        })
        assert response.status_code == 422
        errors = response.json()["detail"]
        assert any(e["loc"] == ["body", "email"] for e in errors)
        assert any(e["loc"] == ["body", "password"] for e in errors)

    async def test_get_user_not_found(self, client: AsyncClient):
        response = await client.get("/api/v1/users/550e8400-e29b-41d4-a716-446655440000")
        assert response.status_code == 404
        assert response.json()["code"] == "USER_NOT_FOUND"

    async def test_list_users_pagination(self, client: AsyncClient, multiple_users):
        response = await client.get("/api/v1/users?limit=5&offset=0")
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) <= 5
        assert "total" in data
        assert data["limit"] == 5
        assert data["offset"] == 0
```

## pyproject.toml completo
```toml
[project]
name = "my-api"
version = "0.1.0"
description = "FastAPI application"
readme = "README.md"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.109.0",
    "uvicorn[standard]>=0.27.0",
    "pydantic>=2.5.0",
    "pydantic-settings>=2.1.0",
    "sqlalchemy>=2.0.0",
    "alembic>=1.13.0",
    "asyncpg>=0.29.0",
    "python-jose[cryptography]>=3.3.0",
    "passlib[bcrypt]>=1.7.4",
    "python-multipart>=0.0.6",
    "email-validator>=2.1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "httpx>=0.26.0",
    "testcontainers>=4.7.0",
    "ruff>=0.3.0",
    "mypy>=1.8.0",
    "pre-commit>=3.6.0",
]

[tool.ruff]
target-version = "py311"
line-length = 100
select = ["E", "F", "I", "N", "W", "UP", "B", "C4", "PTH", "T20", "PERF"]
ignore = ["E501", "TRY003"]
fixable = ["ALL"]
unfixable = ["T20"]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
no_implicit_optional = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "--cov=src --cov-fail-under=80 --cov-report=term-missing -v"

[tool.coverage.run]
source = ["src/app"]
omit = ["*/tests/*", "*/migrations/*"]

[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"
```