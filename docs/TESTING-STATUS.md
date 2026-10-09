# Testing Status - ai-dev-toolkit

> **Clasificación**: verificado / parcialmente verificado / no verificado  
> **Evidencia**: Comando ejecutado, salida, fecha  
> **Actualizado**: 2026-10-09

---

## Resumen General

| Componente | Validación Estructura | Validación Hooks | Validación Scripts | Integración E2E | Evaluaciones |
|------------|----------------------|------------------|-------------------|-----------------|--------------|
| **dev-workflow** | ✅ verificado | ✅ verificado | ✅ verificado | ❌ no verificado | ❌ no verificado |
| **cicd-security-triage** | 🟡 parcialmente verificado | ❌ no verificado | ❌ no verificado | ❌ no verificado | ❌ no verificado |
| **frontend-ui** | 🟡 parcialmente verificado | ❌ no verificado | ❌ no verificado | ❌ no verificado | ❌ no verificado |
| **context-toolkit** | 🟡 parcialmente verificado | ❌ no verificado | ❌ no verificado | ❌ no verificado | ❌ no verificado |
| **Marketplace** | ✅ verificado | N/A | N/A | ❌ no verificado | N/A |

---

## dev-workflow

| Afirmación | Estado | Evidencia |
|------------|--------|-----------|
| Plugin manifest JSON válido | ✅ verificado | `jq empty plugins/dev-workflow/.claude-plugin/plugin.json` - OK |
| 4 agentes con frontmatter válido | ✅ verificado | `head -1 agents/*.md` - todos tienen `---` |
| 10 skills con SKILL.md | ✅ verificado | `ls skills/*/SKILL.md` - 10 archivos |
| Comando feature.md con frontmatter | ✅ verificado | `head -1 commands/feature.md` - OK |
| config/stacks.json válido | ✅ verificado | `jq empty config/stacks.json` - OK |
| config/sensitive-patterns.json válido | ✅ verificado | `jq empty config/sensitive-patterns.json` - OK |
| hooks/hooks.json válido | ✅ verificado | `jq empty hooks/hooks.json` - OK |
| 4 scripts bash creados | ✅ verificado | `ls scripts/*.sh` - 4 archivos |
| Scripts tienen `set -euo pipefail` | ✅ verificado | `grep -l "set -euo pipefail" scripts/*.sh` - 4/4 |
| test-plugin-structure.sh pasa | ✅ verificado | `./tests/test-plugin-structure.sh` - 0 fallos |
| test-hooks.sh pasa | ✅ verificado | `./tests/test-hooks.sh` - 0 fallos |
| workflow-contract schema válido | ✅ verificado | `python3 -m jsonschema` validate example vs schema - OK |
| workflow-contract example válido | ✅ verificado | `jq empty workflow-contract-example.json` - OK |
| detect-stack.sh produce JSON | ✅ verificado | `./scripts/detect-stack.sh \| jq .` - output válido |
| run-checks.sh --dry-run funciona | ✅ verificado | `./scripts/run-checks.sh --dry-run --stack java-spring` - OK |
| guard-sensitive.sh detecta patrones | ✅ verificado | `./scripts/guard-sensitive.sh /tmp/bad --dry-run` - "BLOQUEADO" |
| validate-contract.sh valida schema | ✅ verificado | `./scripts/validate-contract.sh example.json` - OK |
| Shellcheck en scripts | 🟡 parcialmente verificado | `shellcheck scripts/*.sh` - warnings menores (SC2155, SC2034) |
| Flujo multiagente E2E | ❌ no verificado | Requiere Claude Code runtime para invocar subagentes |
| Integración Architect→Implementer | ❌ no verificado | Requiere mecanismo Task tool real |
| Integración Reviewer→QA | ❌ no verificado | Requiere Claude Code runtime |
| Evaluaciones (evals) | ❌ no verificado | Fase 9 pendiente |

---

## cicd-security-triage

| Afirmación | Estado | Evidencia |
|------------|--------|-----------|
| Plugin manifest JSON válido | ✅ verificado | `jq empty plugins/cicd-security-triage/.claude-plugin/plugin.json` - OK |
| 3 agentes declarados | 🟡 parcialmente verificado | Declarados en plugin.json, archivos no creados (Fase 6) |
| 3 skills declaradas | 🟡 parcialmente verificado | Declaradas en plugin.json, archivos no creados (Fase 6) |
| 3 parsers Python declarados | 🟡 parcialmente verificado | Declarados en plugin.json, archivos no creados (Fase 6) |
| Tests/fixtures declarados | 🟡 parcialmente verificado | Declarados en plugin.json, archivos no creados (Fase 6) |
| Parsers normalizan reportes | ❌ no verificado | Fase 6 pendiente |
| Fixtures anonimizados | ❌ no verificado | Fase 6 pendiente |
| Analyst clasifica/descarta FP | ❌ no verificado | Fase 6 pendiente |
| Fixer propone fix mínimo | ❌ no verificado | Fase 6 pendiente |
| QA valida fix | ❌ no verificado | Fase 6 pendiente |

---

## frontend-ui

| Afirmación | Estado | Evidencia |
|------------|--------|-----------|
| Plugin manifest JSON válido | ✅ verificado | `jq empty plugins/frontend-ui/.claude-plugin/plugin.json` - OK |
| 3 agentes declarados | 🟡 parcialmente verificado | Declarados en plugin.json, archivos no creados (Fase 7) |
| 9 skills declaradas | 🟡 parcialmente verificado | Declaradas en plugin.json, archivos no creados (Fase 7) |
| Comando ui.md declarado | 🟡 parcialmente verificado | Declarado en plugin.json, archivo no creado (Fase 7) |
| 2 scripts declarados | 🟡 parcialmente verificado | Declarados en plugin.json, archivos no creados (Fase 7) |
| Stack React/TS/Tailwind/shadcn | ❌ no verificado | Fase 7 pendiente - versiones por confirmar |
| Stack Angular alterno | ❌ no verificado | Fase 7 pendiente |
| UI Designer (read-only) | ❌ no verificado | Fase 7 pendiente |
| UI Implementer (write) | ❌ no verificado | Fase 7 pendiente |
| UI Reviewer (read-only) | ❌ no verificado | Fase 7 pendiente |
| Accessibility WCAG skills | ❌ no verificado | Fase 7 pendiente |
| Responsive/performance skills | ❌ no verificado | Fase 7 pendiente |

---

## context-toolkit

| Afirmación | Estado | Evidencia |
|------------|--------|-----------|
| Plugin manifest JSON válido | ✅ verificado | `jq empty plugins/context-toolkit/.claude-plugin/plugin.json` - OK |
| 3 skills declaradas | 🟡 parcialmente verificado | Declaradas en plugin.json, archivos no creados (Fase 8) |
| 2 comandos declarados | 🟡 parcialmente verificado | Declarados en plugin.json, archivos no creados (Fase 8) |
| claude-md-writer skill | ❌ no verificado | Fase 8 pendiente |
| codebase-map skill | ❌ no verificado | Fase 8 pendiente |
| session-handoff skill | ❌ no verificado | Fase 8 pendiente |
| Comando handoff.md | ❌ no verificado | Fase 8 pendiente |
| Comando map.md | ❌ no verificado | Fase 8 pendiente |

---

## Marketplace

| Afirmación | Estado | Evidencia |
|------------|--------|-----------|
| marketplace.json JSON válido | ✅ verificado | `jq empty .claude-plugin/marketplace.json` - OK |
| 4 plugins declarados | ✅ verificado | `jq '.plugins | length' .claude-plugin/marketplace.json` = 4 |
| dev-workflow declarado | ✅ verificado | `jq '.plugins[] | select(.name=="dev-workflow")' marketplace.json` - OK |
| cicd-security-triage declarado | ✅ verificado | `jq '.plugins[] | select(.name=="cicd-security-triage")' marketplace.json` - OK |
| frontend-ui declarado | ✅ verificado | `jq '.plugins[] | select(.name=="frontend-ui")' marketplace.json` - OK |
| context-toolkit declarado | ✅ verificado | `jq '.plugins[] | select(.name=="context-toolkit")' marketplace.json` - OK |
| Rutas relativas correctas | ✅ verificado | Paths: `plugins/<name>` |
| Instalación documentada | ✅ verificado | README.md tiene comandos `claude plugin marketplace add` |

---

## Validación Cruzada

| Validación | Estado | Evidencia |
|------------|--------|-----------|
| validate-all.sh pasa | ✅ verificado | `./scripts/validate-all.sh` - 0 fallos |
| GitHub Actions workflow válido | ✅ verificado | `yamllint .github/workflows/validate.yml` - OK |
| JSON schema validation | ✅ verificado | python3 jsonschema validate example vs schema |
| Frontmatter en agentes/comandos | ✅ verificado | 5/5 archivos con `---` |
| Shellcheck warnings | 🟡 parcialmente verificado | 4 scripts, warnings menores (no errores) |
| No secretos en repo | ✅ verificado | `grep -r "password\|secret\|key" --include="*.json" --include="*.md" | grep -v test | grep -v example` - limpio |
| .gitignore cubre basics | ✅ verificado | `cat .gitignore` - node_modules, .env, build, secrets |

---

## Limitaciones Conocidas

1. **No hay runtime de Claude Code**: No se puede validar la invocación real de subagentes (Task tool), la persistencia del contrato entre agentes, ni la ejecución de hooks por Claude Code.

2. **Frontmatter no validado contra spec oficial**: La estructura de agents/commands/hooks se basa en convenciones asumidas. Falta confirmar con documentación oficial de Claude Code.

3. **Variables en hooks**: `${plugin_root}`, `${file_path}` son placeholders; sintaxis real por confirmar.

4. **Bash en Windows**: Scripts probados en WSL/Git Bash; no hay versiones PowerShell (.ps1).

5. **Dependencias de validación**: `jq`, `python3`, `jsonschema`, `shellcheck` requeridos para CI completo.

6. **Versiones de librerías**: Spring Boot 3.2.x, FastAPI 0.109+, React 18, Tailwind 3.4, shadcn/ui - verificar versiones vigentes al usar.

7. **Evaluaciones (Fase 9)**: Pendientes - requieren diseñar casos, implementar run-evals.py, ejecutar comparativas CON/SIN plugin.

---

## Próximos Pasos

- [ ] **Fase 6**: Completar cicd-security-triage (parsers, fixtures, agentes, tests)
- [ ] **Fase 7**: Completar frontend-ui (agentes, skills, comandos, scripts)
- [ ] **Fase 8**: Completar context-toolkit (skills, comandos)
- [ ] **Fase 9**: Implementar evals (5 casos/plugin, run-evals.py, comparativa CON/SIN)
- [ ] **Fase 10**: Iterar basado en evals, actualizar CHANGELOG, README final
- [ ] Validar frontmatter/hooks contra spec oficial de Claude Code cuando esté disponible
- [ ] Crear versiones .ps1 de scripts para Windows nativo
- [ ] Medir ahorro real de tokens en flujos multiagente (documentar en ARCHITECTURE.md)

---

## Historial de Validaciones

| Fecha | Ejecutado Por | Comando | Resultado |
|-------|---------------|---------|-----------|
| 2026-10-09 | Kilo (Fase 1) | JSON validation | 5/5 marketplace + plugins OK |
| 2026-10-09 | Kilo (Fase 2) | Agent frontmatter | 4/4 agents OK |
| 2026-10-09 | Kilo (Fase 3) | Skills + command | 10 skills + 1 command OK |
| 2026-10-09 | Kilo (Fase 4) | Hooks + scripts + config | 2 hooks + 4 scripts + 2 configs OK |
| 2026-10-09 | Kilo (Fase 5) | validate-all.sh | 0 fallos - TODO VERDE |