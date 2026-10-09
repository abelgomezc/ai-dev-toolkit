# Stack Detector Skill

## Cuándo usarlo
- Al inicio de cualquier tarea en dev-workflow (Architect lo invoca primero)
- Cuando no hay CLAUDE.md con stack declarado
- Para validar que el stack detectado coincide con la realidad del proyecto

## Cuándo NO usarlo
- Si el proyecto ya tiene `config/stacks.json` configurado y CLAUDE.md declara el stack
- Para proyectos que no usan los stacks soportados (Java/Spring, Python/FastAPI, Node/React)

## Descripción
Detecta el stack tecnológico del proyecto examinando archivos de configuración y dependencias. Devuelve un identificador de stack normalizado que el resto de skills usan para aplicar convenciones correctas.

## Archivos de referencia
- `stack-detector-rules.md` — Reglas de detección por prioridad y evidencia
- `supported-stacks.json` — Stacks soportados con sus comandos de verificación

## Lógica de detección (orden de prioridad)

### 1. Java/Spring (stack: `java-spring`)
| Archivo | Evidencia | Peso |
|---------|-----------|------|
| `pom.xml` | `<parent>spring-boot-starter-parent</parent>` | 100 |
| `build.gradle` | `id 'org.springframework.boot'` | 100 |
| `pom.xml` | `spring-boot-starter-web` | 80 |
| `build.gradle` | `implementation 'org.springframework.boot:spring-boot-starter-web'` | 80 |
| `*.java` | `@SpringBootApplication` | 60 |

### 2. Python/FastAPI (stack: `python-fastapi`)
| Archivo | Evidencia | Peso |
|---------|-----------|------|
| `pyproject.toml` | `fastapi` en dependencies | 100 |
| `requirements.txt` | `fastapi` | 90 |
| `pyproject.toml` | `uvicorn` | 70 |
| `*.py` | `from fastapi import FastAPI` | 60 |

### 3. Node/React (stack: `node-react`)
| Archivo | Evidencia | Peso |
|---------|-----------|------|
| `package.json` | `react` + `react-dom` en dependencies | 100 |
| `package.json` | `next` | 90 |
| `package.json` | `vite` + `@vitejs/plugin-react` | 80 |
| `tsconfig.json` | `"jsx": "react-jsx"` | 60 |

### 4. Angular (stack: `angular`)
| Archivo | Evidencia | Peso |
|---------|-----------|------|
| `package.json` | `@angular/core` | 100 |
| `angular.json` | existe | 90 |

## Algoritmo
1. Recopilar evidencia de todos los archivos listados arriba
2. Sumar pesos por stack
3. Stack con mayor puntuación gana (mínimo 60 para considerar detectado)
4. Si empate o < 60 → `unknown` (requiere intervención manual)

## Salida
```json
{
  "stack": "java-spring",
  "confidence": 95,
  "evidence": [
    {"file": "pom.xml", "pattern": "spring-boot-starter-parent", "weight": 100},
    {"file": "src/main/java/Application.java", "pattern": "@SpringBootApplication", "weight": 60}
  ],
  "build_tool": "maven",
  "java_version": "21"
}
```

## Antipatrón: detección por extensión solamente
```bash
# MALO - solo mira extensiones
find . -name "*.java" | head -1 && echo "java-spring"

# BUENO - mira dependencias y configuración real
grep -r "spring-boot-starter" pom.xml build.gradle 2>/dev/null
```

## Verificación
```bash
./scripts/detect-stack.sh  # Devuelve JSON con stack detectado
```