# Eval Case: Code Audit - SQL Injection Pattern

## Plugin
cicd-security-triage

## Escenario
SonarQube detecta 5 instancias de posible SQL Injection (string concatenation en queries JPA). El Analyst debe clasificar cada una evaluando si el input es validado/sanitizado antes de llegar al query.

## Input (Report - simplified)
```json
{
  "source": "sonarqube",
  "findings": [
    {
      "id": "SONAR-SQL-01",
      "title": "SQL Injection in OrderRepository.findByStatus",
      "severity": "critical",
      "cwe": ["CWE-89"],
      "location": {"file": "OrderRepository.java", "line": 35},
      "exploitability": "theoretical",
      "exposure": "public"
    },
    {
      "id": "SONAR-SQL-02",
      "title": "SQL Injection in ProductService.searchProducts",
      "severity": "major",
      "cwe": ["CWE-89"],
      "location": {"file": "ProductService.java", "line": 68},
      "exploitability": "theoretical",
      "exposure": "public"
    },
    {
      "id": "SONAR-SQL-03",
      "title": "SQL Injection in AuditLogService.logAction",
      "severity": "low",
      "cwe": ["CWE-89"],
      "location": {"file": "AuditLogService.java", "line": 22},
      "exploitability": "theoretical",
      "exposure": "internal"
    }
  ]
}
```

## Métricas de Evaluación

| Métrica | CON Plugin (Analyst) | SIN Plugin (manual) |
|---------|---------------------|---------------------|
| FP identification | ✅ SONAR-SQL-03 = FP (internal exposure, audit log no user input control) | ⚠️ marca los 3 como crítico |
| Context-aware classification | ✅ SONAR-SQL-01 = true positive (status from API param) | ⚠️ solo severity |
| Input validation assessment | ✅ SONAR-SQL-02 = true positive (search from user input) | ❌ |
| Priority reordering | 1. OrderRepository (public+API params), 2. ProductService (public+user input), 3. AuditLog (internal) | 1. OrderRepository (critical), 2. ProductService (major), 3. AuditLog (low) |
| Fix recommendations | ✅ JPA Criteria API o @Param con validación | ⚠️ solo "use prepared statements" |
| Justification depth | ✅ cites code flow + exposure + exploitability | ⚠️ cites only line numbers |

## Expected Outcome
- **CON Plugin**: SONAR-SQL-01 = critical (public endpoint, status param from request), SONAR-SQL-02 = high (public endpoint, user search query), SONAR-SQL-03 = descartado como FP (audit log, internal service, no user input path). Recomienda Criteria API con @Param.
- **SIN Plugin**: Tres findings marcados por severity (critical/major/low) sin análisis de exposure ni input flow.

## Difficulty: Hard
## Est. Tokens: 25,000 (CON) vs 18,000 (SIN)

## Skill References
- false-positive-triage R1-R5 (code flow analysis, exposure-based, validation assessment)
- severity-rules R4 (context-aware reclassification)
- report-formats R4 (by_type vulnerability)