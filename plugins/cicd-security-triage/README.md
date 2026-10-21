# cicd-security-triage

Triage de reportes de seguridad de CI/CD (Grype, SonarQube, StackHawk) con parsers que normalizan reportes, clasificación de hallazgos, descarte justificado de falsos positivos y priorización.

## Agentes

| Agente | Permisos | Rol |
|--------|----------|-----|
| `analyst` | Read, Glob, Grep, WebFetch, WebSearch | Clasifica hallazgos, descarta falsos positivos con justificación, prioriza por explotabilidad real |
| `fixer` | Read, Write, Edit, MultiEdit, Glob, Grep, Bash | Propone fix mínimo (upgrade, config, código) con riesgo explicado |
| `qa` | Read, Bash, Glob, Grep | Valida fix, ejecuta tests de regresión, re-escannea, confirma sin nuevos hallazgos |

## Skills

| Skill | Descripción |
|-------|-------------|
| `severity-rules` | Reglas de severidad basadas en explotabilidad, exposición y disponibilidad de fix |
| `false-positive-triage` | Criterios para descartar falsos positivos con justificación técnica |
| `report-formats` | Schema normalizado v1.0 para Grype, SonarQube y StackHawk |

## Comando

```bash
/security-triage reports/grype-production.json
/security-triage reports/sonar-issues.json --auto-fix
/security-triage reports/stackhawk-scan.json --priority-only
```

## Parsers

| Parser | Uso |
|--------|-----|
| `scripts/parse-grype.py` | Normaliza salida JSON de Grype |
| `scripts/parse-sonar.py` | Normaliza issues y hotspots de SonarQube |
| `scripts/parse-stackhawk.py` | Normaliza findings de StackHawk |

## Tests

```bash
python plugins/cicd-security-triage/tests/test-parsers.py
```
