---
name: security-triage
description: "Punto de entrada para triage de reportes de seguridad CI/CD. Normaliza reportes de Grype/SonarQube/StackHawk, lanza analyst → fixer → qa-security."
tools: [Task, Read, Write, Glob, Grep, Bash]
---

# Security Triage Command - CI/CD Security Entry Point

## Uso
```
/security-triage <ruta-al-reporte> [--parser=grype|sonar|stackhawk] [--auto-fix] [--priority-only]
```

## Flujo
1. **Detecta tipo de reporte** basado en extensión/contenido (grype-*.json, sonar-*.json, stackhawk-*.json)
2. **Normaliza reporte** usando parser apropiado (parse-grype.py / parse-sonar.py / parse-stackhawk.py)
3. **Lanza Analyst** con reporte normalizado
4. **Analyst** clasifica hallazgos, descarta falsos positivos justificando, prioriza por `severity-rules`
5. **Lanza Fixer** con hallazgos priorizados
6. **Fixer** propone fix mínimo (actualizar dependencia, cambiar config, parche de código) con riesgo del cambio explicado
7. **Lanza QA Security** con fix propuesto
8. **QA Security** valida: fix resuelve hallazgo (re-scan), no rompe tests, no introduce nuevos hallazgos
9. **Si hallazgos restantes** → itera (máx 3 ciclos)
10. **Final**: Reporta al usuario con prioridad final, fixes aplicados, y reporte resumen

## Implementación (pseudocódigo)

```python
async def execute_security_triage(report_path: str, parser: str | None = None, auto_fix: bool = False):
    import uuid, json, subprocess, os

    # 0. Detectar tipo de reporte si no se especificó parser
    if not parser:
        filename = os.path.basename(report_path).lower()
        if "grype" in filename or "grype" in report_path:
            parser = "grype"
        elif "sonar" in filename or "sonar" in report_path:
            parser = "sonar"
        elif "stackhawk" in filename or "stackhawk" in report_path:
            parser = "stackhawk"
        else:
            # Intentar detectar tipo inspeccionando contenido
            with open(report_path) as f:
                content = json.load(f)
            if "matches" in content and "source" in content:
                parser = "grype"
            elif "issues" in content:
                parser = "sonar"
            elif "findings" in content and "scan" in content:
                parser = "stackhawk"
            else:
                return {"error": "No se pudo detectar tipo de reporte. Use --parser=grype|sonar|stackhawk"}

    # 1. Normalizar reporte
    normalized_path = f".claude-security/reports/{uuid.uuid4()}-normalized.json"
    os.makedirs(os.path.dirname(normalized_path), exist_ok=True)

    parser_script = f"plugins/cicd-security-triage/scripts/parse-{parser}.py"
    
    if parser == "sonar":
        # SonarQube requiere issues + hotspots (hotspots opcional)
        subprocess.run([
            "python3", parser_script, report_path, normalized_path
        ], check=True)
    else:
        subprocess.run([
            "python3", parser_script, report_path, normalized_path
        ], check=True)

    # 2. Lanzar Analyst
    analyst_result = await launch_agent("analyst", {
        "report_path": normalized_path,
        "parser": parser
    })

    if not analyst_result.success:
        return {"error": "Analyst failed", "details": analyst_result.error}

    prioritized_findings_path = f".claude-security/reports/{uuid.uuid4()}-prioritized.json"
    write_json(prioritized_findings_path, analyst_result.prioritized_findings)

    # 3. Lanzar Fixer
    fixer_result = await launch_agent("fixer", {
        "findings_path": prioritized_findings_path
    })

    if not fixer_result.success:
        return {"error": "Fixer failed", "details": fixer_result.error}

    # 4. Aplicar fixes (si --auto-fix)
    if auto_fix:
        for fix in fixer_result.proposed_fixes:
            apply_fix(fix)  # Implementa según tipo de fix

    # 5. Lanzar QA Security
    qa_result = await launch_agent("qa_security", {
        "original_findings_path": prioritized_findings_path,
        "fixer_output": fixer_result.fixes_summary
    })

    # 6. Iterar si hay findings restantes
    cycle = 0
    max_cycles = 3
    remaining_findings = qa_result.remaining_findings

    while len(remaining_findings) > 0 and cycle < max_cycles:
        # Re-lanzar Fixer para findings restantes
        fixer_result = await launch_agent("fixer", {
            "findings_path": prioritized_findings_path,
            "remaining_findings": remaining_findings
        })

        # Re-lanzar QA Security
        qa_result = await launch_agent("qa_security", {
            "original_findings_path": prioritized_findings_path,
            "fixer_output": fixer_result.fixes_summary
        })
        remaining_findings = qa_result.remaining_findings
        cycle += 1

    # 7. Generar reporte final
    final_report = {
        "triage_id": str(uuid.uuid4()),
        "scan_source": parser,
        "normalized_report": normalized_path,
        "prioritized_report": prioritized_findings_path,
        "total_findings": len(analyst_result.prioritized_findings),
        "findings_by_severity": analyst_result.summary.by_severity,
        "fixes_applied": fixer_result.fixes_summary,
        "qa_decision": qa_result.decision,
        "cycles": cycle,
        "remaining_findings": len(remaining_findings)
    }

    # Write final report
    final_report_path = f".claude-security/reports/{final_report['triage_id']}-final.json"
    write_json(final_report_path, final_report)

    return final_report
```

## Funciones Auxiliares

```python
def apply_fix(fix: dict):
    """Aplica fix según tipo"""
    fix_type = fix.get("type", "")
    
    if fix_type == "upgrade":
        # Ejecutar package manager upgrade
        deps = fix.get("dependencies", [])
        for dep in deps:
            run_package_manager_upgrade(dep["name"], dep["version"])
    elif fix_type == "config":
        # Modificar archivo de configuración
        update_config_file(fix["file"], fix["changes"])
    elif fix_type == "code":
        # Aplicar parche de código
        apply_code_patch(fix["file"], fix["patch"])

def write_json(path: str, data: dict):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)

def run_package_manager_upgrade(name: str, version: str):
    """Actualiza dependencia a versión específica"""
    # Detect package manager and update
    if os.path.exists("package-lock.json"):
        subprocess.run(["npm", "install", f"{name}@{version}", "--save"])
    elif os.path.exists("pnpm-lock.yaml"):
        subprocess.run(["pnpm", "add", f"{name}@{version}"])
    elif os.path.exists("requirements.txt"):
        subprocess.run(["pip", "install", f"{name}=={version}", "--upgrade"])
    elif os.path.exists("pom.xml"):
        # Maven - update dependency version in pom.xml
        update_maven_dependency(name, version)
```

## Parsers Soportados

| Parser | Input | Normaliza | Uso |
|--------|-------|-----------|-----|
| **Grype** | `grype myapp:latest -o json` | parse-grype.py | Container images, SBOM |
| **SonarQube** | `sonarqube-api-issues.json` + `sonarqube-api-hotspots.json` | parse-sonar.py | Código estático, hotspots |
| **StackHawk** | `hawk scan --output json` | parse-stackhawk.py | DAST (runtime) |

## Skills que usan los agentes
- **Analyst**: `severity-rules`, `false-positive-triage`, `report-formats`
- **Fixer**: `severity-rules`, `report-formats`
- **QA Security**: `report-formats`

## Validación Previa
```bash
# 1. Parser detectado o especificado
python3 plugins/cicd-security-triage/scripts/parse-grype.py --help
python3 plugins/cicd-security-triage/scripts/parse-sonar.py --help
python3 plugins/cicd-security-triage/scripts/parse-stackhawk.py --help

# 2. Schema de reporte normalizado válido
python3 plugins/cicd-security-triage/tests/test-parsers.py

# 3. Agentes existen
ls plugins/cicd-security-triage/agents/{analyst,fixer,qa}.md
```

## Ejemplos de Uso

### Triage de reporte de Grype (container image)
```
/security-triage reports/grype-production.json
```

### Triage de reporte de SonarQube con auto-fix
```
/security-triage reports/sonar-issues.json --parser=sonar --auto-fix
```

### Triage de reporte de StackHawk (prioridad alta solo)
```
/security-triage reports/stackhawk-scan.json --priority-only
```

## Output Esperado
```
✅ Triage ID: 550e8400-e29b-41d4-a716-446655440000
✅ Parser: grype
✅ Analyst: 15 findings priorizados (2 critical, 3 high, 6 medium, 4 low)
  - 2 falsos positivos descartados (justificación técnica)
  - Prioridad: CVE-2023-12345 (9.8, RCE jackson-databind)
✅ Fixer: 3 fixes propuestos (1 upgrade, 1 config, 1 code)
  - jackson-databind: 2.14.0 → 2.15.2 (breaking change: none)
  - Config: Dockerfile USER directive
  - Code: Input validation in UserController
✅ QA Security: 2 fixes validados, 1 remaining (low severity, accepted risk)
  - Re-scan: CVE-2023-12345 no aparece ✅
  - No nuevos hallazgos introducidos ✅
  - 24 tests de regresión: PASSED ✅

📋 Resumen final:
- Findings totales: 15 (pre-triage) → 13 (post-analyst)
- Fixes aplicados: 2/3
- Hallazgos restantes: 1 (low, accepted risk)
- Tiempo total: ~5 min
- Reporte: .claude-security/reports/550e8400-final.json
```

## Reporte de Hallazgos

### Estructura de salida del Analyst
```json
{
  "prioritized_findings": [
    {
      "id": "CVE-2023-12345",
      "severity": "critical",
      "priority_score": 98,
      "exploitability": "poc",
      "exposure": "public",
      "false_positive": false,
      "justification": "Jackson-databind 2.14.0 con gadget chain confirmada en classpath. Exploitability POC en GitHub.",
      "fix_available": { "version": "2.15.2", "type": "upgrade" },
      "recommendation": "IMMEDIATE: Actualizar jackson-databind a 2.15.2+"
    }
  ],
  "false_positives": [
    {
      "id": "CVE-2022-9999",
      "severity": "high",
      "justification": "Descartado: versión afectada no está en runtime. Jackson no se usa directamente.",
      "confidence": "high"
    }
  ],
  "summary": {
    "total": 15,
    "by_severity": { "critical": 2, "high": 3, "medium": 6, "low": 4 },
    "false_positives": 2,
    "priority_threshold": "high"
  }
}
```

## Limitaciones
- Los parsers requieren Python 3.x
- `--auto-fix` solo aplica fixes de tipo `upgrade` y `config` (no `code`)
- Re-scan requiere el escáner original disponible en runtime