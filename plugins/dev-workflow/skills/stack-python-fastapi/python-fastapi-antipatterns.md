# Python FastAPI Antipatrones

## Antipatrón 1: Variables globales para DB/Redis/Clients
```python
# MALO - Estado global, no testable, race conditions
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

engine = create_async_engine("postgresql+asyncpg://...")
SessionLocal = async_sessionmaker(engine)

async def get_user(user_id: UUID) -> User:
    async with SessionLocal() as db:  # Comparte engine global
        return await db.get(User, user_id)

# BUENO - Dependency injection con Depends
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session

@router.get("/users/{user_id}")
async def get_user(user_id: UUID, db: AsyncSession = Depends(get_db)) -> User:
    return await db.get(User, user_id)
```

## Antipatrón 2: Bloquear event loop con código síncrono
```python
# MALO - requests.get() bloquea todo el event loop
import requests

@router.get("/external")
async def call_external():
    response = requests.get("https://api.example.com/data")  # FALLA: bloquea
    return response.json()

# BUENO - httpx async
import httpx

@router.get("/external")
async def call_external():
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com/data")
        return response.json()

# BUENO - run_in_threadpool para librerías sync obligatorias
from fastapi.concurrency import run_in_threadpool

@router.get("/cpu-intensive")
async def cpu_task():
    result = await run_in_threadpool(heavy_computation)
    return result
```

## Antipatrón 3: Dicts en lugar de Pydantic models
```python
# MALO - Sin validación, sin documentación OpenAPI, sin tipos
@router.post("/users")
async def create_user(request: dict) -> dict:
    email = request.get("email")  # None si falta
    # Sin validación de formato, longitud, etc.
    return {"id": str(uuid.uuid4()), "email": email}

# BUENO - Pydantic model con validación completa
class UserCreateRequest(BaseModel):
    email: EmailStr
    password: Annotated[str, Field(min_length=8)]
    full_name: Annotated[str, Field(min_length=1, max_length=100)]

@router.post("/users", response_model=UserResponse)
async def create_user(request: UserCreateRequest) -> UserResponse:
    return await service.create(request)
```

## Antipatrón 4: Excepciones genéricas → 500 Internal Server Error
```python
# MALO - raise Exception -> 500 sin información útil
@router.get("/users/{user_id}")
async def get_user(user_id: UUID):
    user = await service.get(user_id)
    if not user:
        raise Exception("User not found")  # FALLA: 500, log genérico
    return user

# BUENO - HTTPException con código y detail estructurado
from fastapi import HTTPException, status

@router.get("/users/{user_id}")
async def get_user(user_id: UUID):
    user = await service.get(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "USER_NOT_FOUND", "message": f"User {user_id} not found"}
        )
    return user
```

## Antipatrón 5: Pydantic v1 patterns en v2
```python
# MALO - v1 syntax (deprecado, warnings, será removido)
class User(BaseModel):
    class Config:
        orm_mode = True
        allow_population_by_field_name = True
        schema_extra = {"example": {"email": "test@test.com"}}

    email: str
    @validator("email")
    def validate_email(cls, v):
        if "@" not in v:
            raise ValueError("Invalid email")
        return v

# BUENO - v2 syntax
class User(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,      # orm_mode
        populate_by_name=True,     # allow_population_by_field_name
        json_schema_extra={        # schema_extra
            "example": {"email": "test@test.com"}
        }
    )
    email: EmailStr  # Validación built-in

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        if "@" not in v:
            raise ValueError("Invalid email")
        return v
```

## Antipatrón 6: Sin paginación en listados
```python
# MALO - Carga todo en memoria (OOM en tablas grandes)
@router.get("/users")
async def list_users(db: AsyncSession = Depends(get_db)) -> list[UserResponse]:
    result = await db.execute(select(User))
    return [UserResponse.model_validate(u) for u in result.scalars().all()]

# BUENO - Paginación obligatoria con validación
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
```

## Antipatrón 7: Settings con os.getenv sin validación
```python
# MALO - None si no existe, sin tipo, sin validación
import os
DATABASE_URL = os.getenv("DATABASE_URL")  # None en producción = crash tarde
JWT_SECRET = os.getenv("JWT_SECRET")      # "" en producción = seguridad rota

# BUENO - pydantic-settings con validación
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    database_url: str
    jwt_secret: Annotated[str, Field(min_length=32)]  # Valida longitud
    jwt_algorithm: str = "HS256"
    debug: bool = False

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()  # Falla al inicio si falta DATABASE_URL o JWT_SECRET corto
```

## Antipatrón 8: Tests que dependen de orden/estado compartido
```python
# MALO - Tests dependientes, @pytest.mark.order
@pytest.mark.order(1)
def test_create_user():
    global created_user_id
    response = client.post("/users", json={...})
    created_user_id = response.json()["id"]

@pytest.mark.order(2)
def test_get_user():
    response = client.get(f"/users/{created_user_id}")  # Depende del test 1
    assert response.status_code == 200

# BUENO - Tests aislados con fixtures
@pytest.fixture
async def created_user(client: AsyncClient) -> UserResponse:
    response = await client.post("/api/v1/users", json={...})
    return UserResponse(**response.json())

async def test_get_user(client: AsyncClient, created_user: UserResponse):
    response = await client.get(f"/api/v1/users/{created_user.id}")
    assert response.status_code == 200
```

## Antipatrón 9: SQLAlchemy sync en async context
```python
# MALO - Session sync en función async (bloquea)
from sqlalchemy.orm import Session

@router.get("/users/{user_id}")
async def get_user(user_id: UUID, db: Session = Depends(get_db_sync)):
    return db.get(User, user_id)  # Bloquea event loop

# BUENO - AsyncSession en todo el stack
from sqlalchemy.ext.asyncio import AsyncSession

@router.get("/users/{user_id}")
async def get_user(user_id: UUID, db: AsyncSession = Depends(get_db)):
    return await db.get(User, user_id)  # await = no bloquea
```

## Antipatrón 10: Cyclic imports con models/schemas
```python
# MALO - models importa schemas, schemas importa models
# models/user.py
from app.schemas.user import UserResponse  # CICLO

# schemas/user.py
from app.models.user import User  # CICLO

# BUENO - Separación clara, models no conoce schemas
# models/user.py - Solo SQLAlchemy, sin imports de schemas
# schemas/user.py - Solo Pydantic, from_attributes=True para ORM
# services/user_service.py - Convierte model -> schema
return UserResponse.model_validate(user)  # from_attributes=True
```

## Antipatrón 11: Middleware para auth en lugar de Depends
```python
# MALO - Middleware global, difícil de testear, inflexible
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    token = request.headers.get("Authorization")
    user = await validate_token(token)
    request.state.user = user
    return await call_next(request)

# BUENO - Dependency injection, granular, testable
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> User:
    payload = decode_token(token)
    user = await user_service.get(db, payload.sub)
    if not user:
        raise HTTPException(401, "Invalid token")
    return user

@router.get("/me")
async def me(current_user: User = Depends(get_current_user)):
    return current_user
```

## Antipatrón 12: Alembic migrations sin rollback / sin revisar
```python
# MALO - Auto-generado sin revisar, sin downgrade
def upgrade():
    op.create_table("users", ...)  # ¿Qué pasa si falla a mitad?

# BUENO - Revisado, con downgrade, transaccional
def upgrade():
    # Paso a paso, verificable
    op.create_table(
        "users",
        sa.Column("id", pg.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("full_name", sa.String(100), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

def downgrade():
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
```