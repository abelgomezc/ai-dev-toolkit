---
name: feature
description: Punto de entrada para el flujo multiagente dev-workflow. Lanza architect → implementer → reviewer → qa en secuencia.
tools: [Task, Read, Write, Glob, Grep, Bash]
---

# Feature Command - Dev Workflow Entry Point

## Uso
```
/feature "Descripción de la funcionalidad a implementar"
```

## Flujo
1. **Genera task_id** (UUID)
2. **Lanza Architect** con task_id y descripción
3. **Architect** produce `workflow-contract` con plan y `acceptance_criteria`
4. **Lanza Implementer** con el contrato
5. **Implementer** implementa, ejecuta `run-checks.sh`, actualiza contrato
6. **Lanza Reviewer** con el contrato
7. **Reviewer** revisa con `review-checklist` + skills dominio, actualiza contrato con hallazgos
8. **Si blockers/majors** → Vuelve a Implementer (máx 3 ciclos)
9. **Lanza QA** con el contrato
10. **QA** ejecuta tests, verifica criterios, decide approved/rejected
11. **Si rejected** → Vuelve a Implementer (máx 3 ciclos totales)
12. **Final**: Reporta al usuario con resumen y contrato final

## Implementación (pseudocódigo para el agente que ejecuta este comando)

```python
async def execute_feature_workflow(task_description: str):
    task_id = uuid.uuid4()
    contract_path = f".claude-workflow/contracts/{task_id}.json"
    
    # 1. Architect
    architect_result = await launch_agent("architect", {
        "task_id": task_id,
        "description": task_description,
        "contract_path": contract_path
    })
    
    if not architect_result.success:
        return {"error": "Architect failed", "details": architect_result.error}
    
    # 2. Implementer
    implementer_result = await launch_agent("implementer", {
        "contract_path": contract_path
    })
    
    if not implementer_result.success:
        return {"error": "Implementer failed", "details": implementer_result.error}
    
    # 3. Reviewer
    reviewer_result = await launch_agent("reviewer", {
        "contract_path": contract_path
    })
    
    # 4. Handle reviewer findings
    contract = read_contract(contract_path)
    cycle = 0
    max_cycles = 3
    
    while contract.get("blockers_count", 0) > 0 or contract.get("majors_count", 0) > 0:
        if cycle >= max_cycles:
            return {"error": "Max review cycles exceeded", "contract": contract}
        
        # Back to implementer with findings
        implementer_result = await launch_agent("implementer", {
            "contract_path": contract_path,
            "reviewer_findings": contract["findings"]
        })
        
        if not implementer_result.success:
            return {"error": "Implementer failed on fix", "details": implementer_result.error}
        
        # Re-review
        reviewer_result = await launch_agent("reviewer", {
            "contract_path": contract_path
        })
        cycle += 1
    
    # 5. QA
    qa_result = await launch_agent("qa", {
        "contract_path": contract_path
    })
    
    contract = read_contract(contract_path)
    qa_cycle = 0
    
    while contract.get("stage") == "qa" and contract.get("status") == "rejected":
        if qa_cycle >= max_cycles:
            return {"error": "Max QA cycles exceeded", "contract": contract}
        
        # Back to implementer with QA decision
        implementer_result = await launch_agent("implementer", {
            "contract_path": contract_path,
            "qa_decision": contract["decision"]
        })
        
        if not implementer_result.success:
            return {"error": "Implementer failed on QA fix", "details": implementer_result.error}
        
        # Re-review (light)
        reviewer_result = await launch_agent("reviewer", {
            "contract_path": contract_path
        })
        
        # Re-QA
        qa_result = await launch_agent("qa", {
            "contract_path": contract_path
        })
        qa_cycle += 1
    
    # 6. Final result
    final_contract = read_contract(contract_path)
    return {
        "task_id": task_id,
        "status": final_contract["status"],
        "summary": final_contract["summary"],
        "artifacts": final_contract["artifacts"],
        "decision": final_contract.get("decision"),
        "contract_path": contract_path
    }
```

## Contract Path
- Ubicación: `.claude-workflow/contracts/{task_id}.json`
- El directoro se crea automáticamente
- Persiste entre invocaciones de agentes

## Skills que usan los agentes
- **Architect**: `stack-detector`, `workflow-contract`, `spring-microservices-patterns`, `api-design-review`, `security-review-owasp`, `db-migration-review`
- **Implementer**: `stack-java-spring` / `stack-python-fastapi`, `test-strategy`, `spring-microservices-patterns`, `api-design-review`, `security-review-owasp`, `db-migration-review`
- **Reviewer**: `review-checklist`, `stack-java-spring` / `stack-python-fastapi`, `spring-microservices-patterns`, `api-design-review`, `security-review-owasp`, `db-migration-review`
- **QA**: `test-strategy`, `config/stacks.json`

## Validación Previa
Antes de lanzar el flujo, verificar:
```bash
# 1. Stack detectado
./scripts/detect-stack.sh

# 2. Config de stacks existe
cat config/stacks.json

# 3. Scripts de verificación ejecutables
./scripts/run-checks.sh --dry-run
./scripts/guard-sensitive.sh --dry-run
```

## Ejemplo de uso
```
/feature "Crear endpoint POST /api/v1/users para registrar usuarios con validación de email único, password hash bcrypt, y respuesta 201 con Location header"
```

## Output esperado
```
✅ Task ID: 550e8400-e29b-41d4-a716-446655440000
✅ Stack detectado: java-spring
✅ Architect: Plan completado (5 pasos, 4 criterios de aceptación)
✅ Implementer: Implementación completada (8 archivos, run-checks.sh PASSED)
✅ Reviewer: 0 blockers, 0 majors, 1 minor (JavaDoc faltante)
✅ QA: APPROVED (ciclo 1) - 24 tests passed, coverage 87%

📋 Resumen final:
- Archivos creados: 8 (controller, service, repository, DTOs, tests, migration)
- Criterios de aceptación: 4/4 verificados
- Hallazgos: 1 minor (JavaDoc en UserService)
- Tiempo total: ~3 min
```