# Eval Case: Configuration Hardening - Dockerfile Security

## Plugin
cicd-security-triage

## Escenario
Recibir un reporte de Grype que detecta 3 misconfigurations en un Dockerfile (usuario root, capabilities innecesarias, secrets en layer). El Fixer debe proponer config fixes mínimos.

## Input (Report)
```json
{
  "source": "grype",
  "findings": [
    {
      "id": "DOCKER-001",
      "title": "Container runs as root user",
      "severity": "high",
      "cwe": ["CWE-250"],
      "location": {"file": "Dockerfile", "line": 3},
      "exploitability": "theoretical",
      "exposure": "public",
      "fix_available": {"type": "config", "version": null}
    },
    {
      "id": "DOCKER-002",
      "title": "Privileged container capabilities",
      "severity": "high",
      "cwe": ["CWE-250"],
      "location": {"file": "Dockerfile", "line": 5},
      "exploitability": "theoretical",
      "exposure": "public",
      "fix_available": {"type": "config", "version": null}
    },
    {
      "id": "DOCKER-003",
      "title": "Secrets in image layer",
      "severity": "critical",
      "cwe": ["CWE-522"],
      "location": {"file": ".env", "line": 1},
      "exploitability": "poc",
      "exposure": "public",
      "fix_available": {"type": "config", "version": null}
    }
  ]
}
```

## Métricas de Evaluación

| Métrica | CON Plugin (Fixer) | SIN Plugin (manual) |
|---------|---------------------|---------------------|
| Fix type identification | ✅ config (no upgrade/code) | ⚠️ propone rebuild |
| Minimal change principle | ✅ adds USER + drops capabilities + .dockerignore | ⚠️ rewrite completo |
| Risk explained (each change) | ✅ breaking: app must run as non-root | ⚠️ solo "safe" |
| Compatibility consideration | ✅ checks file perms for non-root user | ⚠️ omitido |
| Verification steps included | ✅ `docker build` + `docker history` check | ❌ |
| Fix traceability | ✅ maps to DOCKER-001/002/003 | ⚠️ genérico |

## Expected Outcome
- **CON Plugin**: Propone 3 fixes mínimos: USER directive (non-root), `--cap-drop=ALL --cap-add=NET_BIND_SERVICE`, `.dockerignore` para .env. Cada fix con riesgo explicado, pasos de verificación con `docker build` y `docker history`.
- **SIN Plugin**: Propone rebuild con multistage, no considera breaking changes de non-root.

## Difficulty: Medium
## Est. Tokens: 20,000 (CON) vs 15,000 (SIN)

## Skill References
- report-formats R7 (location.file for misconfig)
- severity-rules R6 (config-based fix risk assessment)
- false-positive-triage R5 (verification methodology)