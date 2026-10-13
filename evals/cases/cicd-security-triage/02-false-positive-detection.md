# Eval Case: False Positive Detection - Vulnerable and Outdated Components

## Plugin
cicd-security-triage

## Escenario
SonarQube reporta una vulnerabilidad CRÍTICA (CWE-787 Out-of-bounds Write) en una librería de logging que NO está expuesta al input del usuario. El Analyst debe evaluar si es FP y justificar.

## Input (Report - simplified)
```json
{
  "source": "sonarqube",
  "findings": [
    {
      "id": "SONAR-123",
      "title": "Out-of-bounds Write in log4j-core 2.17.1",
      "severity": "critical",
      "cwe": ["CWE-787"],
      "location": {
        "dependency": {"name": "org.apache.logging.log4j:log4j-core", "version": "2.17.1", "ecosystem": "maven"}
      },
      "exploitability": "poc",
      "exposure": "build-time",
      "fix_available": {"version": "2.17.2", "type": "upgrade"}
    },
    {
      "id": "SONAR-124",
      "title": "SQL Injection in UserQueryService",
      "severity": "critical",
      "cwe": ["CWE-89"],
      "location": {"file": "UserQueryService.java", "line": 45},
      "exploitability": "exploited",
      "exposure": "public"
    }
  ]
}
```

## Métricas de Evaluación

| Métrica | CON Plugin (Analyst) | SIN Plugin (manual) |
|---------|---------------------|---------------------|
| FP identification | ✅ identifica log4j 2.17.1 como FP (build-time, no exposición) | ⚠️ puede marcar todo como crítico |
| FP justification | ✅ CWE aplicable pero exposure=build-time, no reachable | ⚠️ solo "es CVE critical" |
| True positive kept | ✅ SQL Injection (public exposure, exploited) | ✅ |
| Priority ordering | 1. SQLi (public+exploited), 2. log4j (build-time FP) | 1. log4j (CVSS 9.1), 2. SQLi |
| FP confidence rating | ✅ HIGH (justificado con architecture) | ❌ (sin rating) |

## Expected Outcome
- **CON Plugin**: log4j 2.17.1 marcado como FP con justificación: exposure=build-time, dependency transitive, no control flow al input del usuario, migración pendiente. SQL Injection como prioridad #1 (public + exploited).
- **SIN Plugin**: Prioriza log4j por severity (critical) ignorando exposición real. No descarta FP.

## Difficulty: Hard
## Est. Tokens: 22,000 (CON) vs 15,000 (SIN)

## Skill References
- false-positive-triage R1-R7 (FP criteria, confidence, validation)
- severity-rules R3 (explotabilidad > CVSS), R5 (exposure-based priority)