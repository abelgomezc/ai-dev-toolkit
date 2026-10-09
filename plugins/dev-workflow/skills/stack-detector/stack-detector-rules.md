# Stack Detector Rules

## Reglas de detección por prioridad

### Regla 1: Archivos de build tienen prioridad sobre código fuente
- `pom.xml`, `build.gradle`, `pyproject.toml`, `package.json` definen dependencias reales
- Código fuente puede ser heredado o no representativo

### Regla 2: Spring Boot parent starter = java-spring definitivo
- `pom.xml` con `<parent><artifactId>spring-boot-starter-parent</artifactId></parent>` → 100 puntos
- `build.gradle` con `id 'org.springframework.boot' version '3.x'` → 100 puntos

### Regla 3: FastAPI explícito = python-fastapi definitivo
- `pyproject.toml` o `requirements.txt` con `fastapi` → 90-100 puntos
- Presencia de `uvicorn` o `gunicorn` como servidor confirma

### Regla 4: React/Angular/Vue son mutuamente excluyentes en package.json
- Solo uno tendrá dependencias core instaladas
- `next` implica React (Next.js)

### Regla 5: Múltiples stacks = monorepo
- Si detecta >1 stack con >80 puntos cada uno → `monorepo`
- Requiere configuración manual en `config/stacks.json`

## Evidencia por archivo

### pom.xml (Maven)
```xml
<!-- Spring Boot 3.x -->
<parent>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-parent</artifactId>
  <version>3.2.0</version>
</parent>

<!-- Dependencias clave -->
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
```

### build.gradle (Gradle)
```groovy
plugins {
  id 'org.springframework.boot' version '3.2.0'
  id 'io.spring.dependency-management' version '1.1.4'
}

dependencies {
  implementation 'org.springframework.boot:spring-boot-starter-web'
  implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
}
```

### pyproject.toml (Python moderno)
```toml
[project]
dependencies = [
  "fastapi>=0.109.0",
  "uvicorn[standard]>=0.27.0",
  "pydantic>=2.5.0",
  "pydantic-settings>=2.1.0",
]

[tool.poetry.dependencies]
fastapi = "^0.109.0"
```

### requirements.txt (Python legacy)
```
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
pydantic>=2.5.0
```

### package.json (Node/React/Angular)
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "next": "^14.0.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.0",
    "typescript": "^5.3.0"
  }
}
```

## Detección de versión de Java
```bash
# En pom.xml
<properties>
  <java.version>21</java.version>
</properties>

# En build.gradle
java {
  toolchain {
    languageVersion = JavaLanguageVersion.of(21)
  }
}
```

## Detección de gestor de paquetes Python
- `pyproject.toml` + `poetry.lock` → poetry
- `pyproject.toml` + `uv.lock` → uv
- `requirements.txt` → pip
- `Pipfile` → pipenv