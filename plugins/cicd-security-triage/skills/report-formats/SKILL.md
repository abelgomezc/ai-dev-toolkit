# Report Formats Skill

## Cuándo usarlo
- **Analyst**: Lee reportes normalizados (output de parsers Python)
- **Fixer**: Entiende estructura para proponer fixes mínimos
- **QA Security**: Valida que fix resuelve hallazgo (re-scan)

## Cuándo NO usarlo
- Para crear nuevos formatos (usar parsers)
- Para análisis de severidad (eso es severity-rules)

## Descripción
Define el **schema JSON normalizado** que todos los parsers (Grype, SonarQube, StackHawk) deben producir. Permite procesamiento uniforme en Analyst/Fixer/QA.

## Schema Normalizado (report-formats v1)

```json
{
  "schema_version": "1.0",
  "source": "grype|sonarqube|stackhawk",
  "generated_at": "2026-01-15T10:30:00Z",
  "scan_target": {
    "type": "image|directory|url",
    "identifier": "myapp:latest|/path/to/repo|https://api.example.com"
  },
  "findings": [
    {
      "id": "CVE-2023-12345",
      "title": "Deserialization of Untrusted Data in Jackson",
      "description": "Jackson-databind 2.14.0 allows arbitrary code execution...",
      "severity": "critical|high|medium|low|info",
      "cvss_score": 9.8,
      "cvss_vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H",
      "cwe": ["CWE-502"],
      "location": {
        "file": "pom.xml",
        "line": 42,
        "dependency": {
          "name": "com.fasterxml.jackson.core:jackson-databind",
          "version": "2.14.0",
          "ecosystem": "maven"
        }
      },
      "exploitability": "exploited|poc|theoretical|none",
      "exposure": "public|internal|build-time",
      "fix_available": {
        "version": "2.15.2",
        "type": "upgrade|patch|workaround",
        "url": "https://github.com/FasterXML/jackson-databind/releases/tag/2.15.2"
      },
      "references": [
        "https://nvd.nist.gov/vuln/detail/CVE-2023-12345",
        "https://github.com/FasterXML/jackson-databind/security/advisories/GHSA-xxxx"
      ],
      "tags": ["deserialization", "rce", "supply-chain"]
    }
  ],
  "summary": {
    "total": 15,
    "by_severity": {
      "critical": 2,
      "high": 5,
      "medium": 6,
      "low": 2,
      "info": 0
    },
    "by_type": {
      "vulnerability": 12,
      "secret": 1,
      "misconfiguration": 2
    }
  }
}
```

## Campos Requeridos por Finding

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `id` | string | Sí | Identificador único (CVE, GHSA, rule key) |
| `title` | string | Sí | Título legible |
| `description` | string | Sí | Descripción detallada |
| `severity` | enum | Sí | critical/high/medium/low/info |
| `cvss_score` | number | No | CVSS 3.x base score |
| `cvss_vector` | string | No | Vector CVSS completo |
| `cwe` | string[] | No | IDs CWE |
| `location.file` | string | Sí* | Archivo afectado |
| `location.line` | number | No | Línea (si aplica) |
| `location.dependency` | object | Sí* | Para vulns de dependencias |
| `exploitability` | enum | Sí | exploited/poc/theoretical/none |
| `exposure` | enum | Sí | public/internal/build-time |
| `fix_available` | object | No | Info de fix si existe |
| `references` | string[] | No | URLs de referencia |
| `tags` | string[] | No | Tags para filtrado |

* `location.file` O `location.dependency` requerido (uno mínimo)

## Tipos de Finding

### Vulnerabilidad (dependency)
```json
{
  "id": "CVE-2023-12345",
  "title": "RCE in Jackson Databind",
  "type": "vulnerability",
  "location": {
    "dependency": {
      "name": "com.fasterxml.jackson.core:jackson-databind",
      "version": "2.14.0",
      "ecosystem": "maven"
    }
  }
}
```

### Secreto (secret)
```json
{
  "id": "ghs-xxxx",
  "title": "GitHub Token in config.yaml",
  "type": "secret",
  "severity": "critical",
  "location": {
    "file": "config.yaml",
    "line": 12
  },
  "exposure": "internal"
}
```

### Misconfiguración (misconfiguration)
```json
{
  "id": "DOCKER-001",
  "title": "Container runs as root",
  "type": "misconfiguration",
  "severity": "high",
  "location": {
    "file": "Dockerfile",
    "line": 3
  }
}
```

## Ecosystems Soportados
- `maven` (Java)
- `gradle` (Java/Kotlin)
- `npm` (JavaScript/TypeScript)
- `pnpm` (JavaScript/TypeScript)
- `yarn` (JavaScript/TypeScript)
- `pip` / `poetry` / `pipenv` (Python)
- `cargo` (Rust)
- `go` / `gomod` (Go)
- `nuget` (.NET)
- `composer` (PHP)
- `gem` / `bundler` (Ruby)
- `docker` (Container images)
- `helm` (Kubernetes)
- `terraform` (IaC)

## Severity Mapping (Entrada → Normalizado)

| Source | Critical | High | Medium | Low | Info |
|--------|----------|------|--------|-----|------|
| **Grype** | Critical | High | Medium | Low | Negligible |
| **SonarQube** | Blocker | Critical | Major | Minor | Info |
| **StackHawk** | Critical | High | Medium | Low | Info |
| **Normalizado** | critical | high | medium | low | info |

## Parsers Esperados

### parse-grype.py
```bash
# Input: grype output (JSON)
grype myapp:latest -o json > grype-report.json
python scripts/parse-grype.py grype-report.json normalized-report.json
```

### parse-sonar.py
```bash
# Input: SonarQube API response (issues + hotspots)
curl "https://sonar.example.com/api/issues/search?projectKey=myapp" > sonar-issues.json
curl "https://sonar.example.com/api/hotspots/search?projectKey=myapp" > sonar-hotspots.json
python scripts/parse-sonar.py sonar-issues.json sonar-hotspots.json normalized-report.json
```

### parse-stackhawk.py
```bash
# Input: StackHawk scan result (JSON)
hawk scan --output json > stackhawk-report.json
python scripts/parse-stackhawk.py stackhawk-report.json normalized-report.json
```

## Validación de Schema

```python
# validate-report.py (usado en CI)
import json
import jsonschema

SCHEMA = {
    "type": "object",
    "required": ["schema_version", "source", "generated_at", "scan_target", "findings", "summary"],
    "properties": {
        "schema_version": {"const": "1.0"},
        "source": {"enum": ["grype", "sonarqube", "stackhawk"]},
        "findings": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["id", "title", "description", "severity", "exploitability", "exposure"],
                "properties": {
                    "severity": {"enum": ["critical", "high", "medium", "low", "info"]},
                    "exploitability": {"enum": ["exploited", "poc", "theoretical", "none"]},
                    "exposure": {"enum": ["public", "internal", "build-time"]},
                    "cvss_score": {"type": "number", "minimum": 0, "maximum": 10},
                }
            }
        }
    }
}

def validate(report_path: str):
    with open(report_path) as f:
        report = json.load(f)
    jsonschema.validate(report, SCHEMA)
    print(f"✅ Valid: {report_path}")
```

## Uso en Pipeline

```yaml
# .github/workflows/security-triage.yml
jobs:
  normalize:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Grype
        run: grype ${{ env.IMAGE }} -o json > grype-raw.json
      - name: Parse Grype
        run: python scripts/parse-grype.py grype-raw.json grype-normalized.json
      - name: Validate Schema
        run: python scripts/validate-report.py grype-normalized.json
      - name: Upload Normalized
        uses: actions/upload-artifact@v4
        with:
          name: normalized-reports
          path: *-normalized.json
```

## Verificación
- **report-formats R1**: ¿Schema version = "1.0"?
- **report-formats R2**: ¿Source en [grype, sonarqube, stackhawk]?
- **report-formats R3**: ¿Todos findings tienen id, title, description, severity, exploitability, exposure?
- **report-formats R4**: ¿Severity en [critical, high, medium, low, info]?
- **report-formats R5**: ¿Exploitability en [exploited, poc, theoretical, none]?
- **report-formats R6**: ¿Exposure en [public, internal, build-time]?
- **report-formats R7**: ¿Location tiene file O dependency?
- **report-formats R8**: ¿Summary.by_severity suma total findings?