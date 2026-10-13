# Eval Case: Fix Validation - Dependency Upgrade Verification

## Plugin
cicd-security-triage

## Escenario
El Fixer propuso actualizar `org.springframework:spring-web:5.3.25` → `5.3.27` para resolver CVE-2023-12346. El QA Security debe validar que el fix resuelve el hallazgo, no introduce regresiones y no rompe tests.

## Input (Fixer Output)
```json
{
  "proposed_fix": {
    "id": "CVE-2023-12346",
    "type": "upgrade",
    "dependency": "org.springframework:spring-web",
    "from_version": "5.3.25",
    "to_version": "5.3.27",
    "risk": "LOW - patch version, no breaking changes per semver",
    "breaking_changes": "none",
    "commands": ["mvn versions:use-dep-version -Dincludes=org.springframework:spring-web -DdepVersion=5.3.27"]
  },
  "verification_plan": {
    "re-scan": "Run grype on new image after upgrade",
    "regression_tests": "mvn test -Dtest=OrderControllerTest,UserControllerTest",
    "compatibility_check": "Verify Spring 5.3.27 compatible with Spring Boot 2.7.18"
  }
}
```

## Métricas de Evaluación

| Métrica | CON Plugin (QA Security) | SIN Plugin (manual) |
|---------|--------------------------|---------------------|
| Fix proposal quality | ✅ includes risk assessment + verification plan | ⚠️ solo `mvn versions:use-latest-versions` |
| Dependency compatibility verified | ✅ Spring Boot 2.7.18 ↔ Spring 5.3.27 matrix checked | ⚠️ asume compatible |
| Regression tests specified | ✅ lists 2 specific test classes | ⚠️ solo "run all tests" |
| Re-scan strategy defined | ✅ `grype image:tag -o json` | ⚠️ no definido |
| Breaking change analysis | ✅ "none" justified (semver patch) | ❌ |
| Fix validation report | ✅ structured (passed/failed criteria) | ⚠️ freeform text |

## Expected Outcome
- **CON Plugin**: Fix proposal incluye análisis de compatibilidad Spring Boot ↔ Spring Framework, lista de tests de regresión específicos, comando de re-scan para Grype, justificación "no breaking changes" con semver.
- **SIN Plugin**: Comando genérico `mvn dependency:upgrade`, "run all tests", sin análisis de compatibilidad.

## Difficulty: Medium
## Est. Tokens: 19,000 (CON) vs 14,000 (SIN)

## Skill References
- report-formats R7 (location.dependency fields)
- severity-rules R8 (fix availability + compatibility check)
- false-positive-triage R6 (validation methodology)