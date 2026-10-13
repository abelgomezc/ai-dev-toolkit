# Eval Case: Vulnerability Triage - CVE-2023-12345 Jackson Databind

## Plugin
cicd-security-triage

## Escenario
Recibir un reporte de Grype para una imagen Docker `myapp:2.1.0` que detecta 15 vulnerabilidades. El Analyst debe clasificar, descartar falsos positivos y priorizar para el Fixer.

## Input (Report)
```json
{
  "source": {"type": "image", "name": "myapp:2.1.0"},
  "matches": [
    {
      "vulnerability": {"id": "CVE-2023-12345", "severity": "Critical", "cvss": [{"score": 9.8}]},
      "artifact": {"name": "com.fasterxml.jackson.core:jackson-databind", "version": "2.14.0", "type": "maven"}
    },
    {
      "vulnerability": {"id": "CVE-2023-12346", "severity": "High", "cvss": [{"score": 7.5}]},
      "artifact": {"name": "org.springframework:spring-web", "version": "5.3.25", "type": "maven"}
    },
    // 13 findings más (mix de severidades)
  ]
}
```

## Métricas de Evaluación

| Métrica | CON Plugin (Analyst) | SIN Plugin (manual) |
|---------|---------------------|---------------------|
| Findings procesados | 15 | 15 |
| Falsos positivos detectados | 2 (con justificación técnica) | 0-1 (superficial) |
| Hallazgos priorizados | Top 5 con explotabilidad + exposure | Top 3 solo CVSS |
| Recomendaciones de fix | 3 (upgrade, config, code) | 1-2 (solo upgrade) |
| Justification for each FP | ✅ (CWE, version, context) | ⚠️ (vago o ausente) |
| Severity rules aplicadas | ✅ severity-rules R1-R5 | ⚠️ solo CVSS score |

## Expected Outcome
- **CON Plugin**: 2 FP descartados con justificación técnica detallada (CWE-502 no aplicable porque librería no expone gadget, versión afectada no usada directamente), 3 fixes propuestos con riesgo explicado, priorización por exploitability + exposure no solo CVSS
- **SIN Plugin**: Priorización por CVSS alone, 0-1 FPs descartados, fixes genéricos

## Difficulty: Medium
## Est. Tokens: 18,000 (CON) vs 12,000 (SIN)

## Skill References
- report-formats R1-R8 (schema validation)
- severity-rules R1-R10 (explotabilidad, exposure, fix availability)