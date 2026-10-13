---
name: ui
description: Punto de entrada para el flujo UI: ui-designer → ui-implementer → ui-reviewer. Lanza diseño, implementación y revisión de interfaces.
tools: [Task, Read, Write, Glob, Grep, Bash]
---

# UI Command - Frontend UI Entry Point

## Uso
```
/ui "Descripción de la pantalla/feature a implementar"
```

## Flujo
1. **Genera design_id** (UUID)
2. **Lanza UI Designer** con descripción
3. **UI Designer** produce `design-proposal.md` con estructura, componentes, estados, accesibilidad, responsive, performance
4. **Lanza UI Implementer** con design-proposal.md
5. **UI Implementer** implementa siguiendo design system + skills de stack, ejecuta `check-a11y.sh` y `check-bundle.sh`
6. **Lanza UI Reviewer** con implementación + design-proposal.md
7. **UI Reviewer** revisa con `ui-review-checklist` (41 reglas) + skills dominio
8. **Si hallazgos blocker/major** → Vuelve a UI Implementer (máx 3 ciclos)
9. **Final**: Reporta al usuario con resumen y archivos generados

## Implementación (pseudocódigo)

```python
async def execute_ui_workflow(screen_description: str):
    design_id = uuid.uuid4()
    design_path = f".claude-ui/designs/{design_id}.md"
    
    # 1. UI Designer
    designer_result = await launch_agent("ui-designer", {
        "design_id": design_id,
        "description": screen_description,
        "design_path": design_path
    })
    
    if not designer_result.success:
        return {"error": "UI Designer failed", "details": designer_result.error}
    
    # 2. UI Implementer
    implementer_result = await launch_agent("ui-implementer", {
        "design_path": design_path
    })
    
    if not implementer_result.success:
        return {"error": "UI Implementer failed", "details": implementer_result.error}
    
    # 3. Validaciones automáticas pre-review
    a11y_result = await run_script("check-a11y.sh")
    bundle_result = await run_script("check-bundle.sh")
    
    if not a11y_result.passed:
        return {"error": "Accessibility check failed", "details": a11y_result.violations}
    
    if not bundle_result.passed:
        return {"error": "Bundle size check failed", "details": bundle_result.report}
    
    # 4. UI Reviewer
    reviewer_result = await launch_agent("ui-reviewer", {
        "design_path": design_path,
        "implementation_files": implementer_result.created_files
    })
    
    # 5. Handle reviewer findings
    cycle = 0
    max_cycles = 3
    
    while reviewer_result.has_blockers_or_majors:
        if cycle >= max_cycles:
            return {"error": "Max review cycles exceeded", "findings": reviewer_result.findings}
        
        # Back to implementer with findings
        implementer_result = await launch_agent("ui-implementer", {
            "design_path": design_path,
            "reviewer_findings": reviewer_result.findings
        })
        
        if not implementer_result.success:
            return {"error": "UI Implementer failed on fix", "details": implementer_result.error}
        
        # Re-validate
        a11y_result = await run_script("check-a11y.sh")
        bundle_result = await run_script("check-bundle.sh")
        
        # Re-review
        reviewer_result = await launch_agent("ui-reviewer", {
            "design_path": design_path,
            "implementation_files": implementer_result.created_files
        })
        cycle += 1
    
    # 6. Final result
    return {
        "design_id": design_id,
        "status": "completed",
        "design_proposal": design_path,
        "created_files": implementer_result.created_files,
        "review_summary": reviewer_result.summary,
        "a11y_report": a11y_result,
        "bundle_report": bundle_result
    }
```

## Design Proposal Format (design-proposal.md)
```markdown
# Design Proposal: User Dashboard

## Screen Structure
- Header: Logo, navigation, user menu
- Sidebar: Navigation rail (desktop), drawer (mobile)
- Main: Grid de widgets (responsive: 1 col mobile, 2 tablet, 4 desktop)
- Footer: Copyright, links

## Visual Hierarchy
- Typography: Heading 1 (clamp(2rem, 5vw, 3rem)), Heading 2 (clamp(1.5rem, 3vw, 2.25rem)), Body (1rem/1.6), Caption (0.875rem/1.5)
- Color: Primary #2563eb (token), Secondary #64748b, Success #16a34a, Error #dc2626
- Spacing: Base 4px scale (4, 8, 12, 16, 24, 32, 48)
- Elevation: Card (shadow-sm), Modal (shadow-lg), Dropdown (shadow-md)

## Components (shadcn/ui)
| Componente | Variante | Props clave | Estados |
|------------|----------|-------------|---------|
| Card | default | title, description, action | loading, empty, error |
| Table | sortable | columns, data, pagination | loading, empty, error |
| Button | default/outline/ghost | size, disabled, loading | - |
| Select | default | options, placeholder, error | error |
| Toast | - | title, description, variant | success, error, warning |

## States
| Componente | Loading | Empty | Error | Success |
|------------|---------|-------|-------|---------|
| Widget Grid | Skeleton cards | "No data" + CTA | Inline alert + retry | Data rendered |
| Table | Row skeletons | "No rows" + CTA | Row error badge | Paginated data |
| Form | Disabled inputs | N/A | Field inline + submit disabled | Toast success |

## Interactions
- Sidebar toggle: hamburger (mobile), collapse (desktop)
- Widget refresh: pull-to-refresh (mobile), button (desktop)
- Table sort: click header, multi-sort with Shift
- Form submit: validate on blur + submit, show errors inline

## Accessibility (WCAG 2.1 AA)
- Focus order: Header → Sidebar → Main → Footer
- ARIA: Sidebar `role="navigation"`, Main `role="main"`, Dialog `role="dialog" aria-modal="true"`
- Contrast: 4.5:1 texto normal, 3:1 texto grande/UI components
- Keyboard: Tab navigation, Escape cierra modales/drawers, Enter/Space activa botones
- Screen reader: Live regions para toasts, aria-labels en icon-only buttons

## Responsive Behavior
- Breakpoints: sm (640px), md (768px), lg (1024px), xl (1280px), 2xl (1536px)
- Sidebar: Drawer < lg, Fixed rail ≥ lg
- Grid: 1 col < sm, 2 cols sm-lg, 4 cols ≥ xl
- Typography: Fluid clamp(1rem, 2vw, 1.5rem) para headings

## Performance Notes
- Code split: Dashboard lazy-loaded (`React.lazy` + `Suspense`)
- Widgets: Independent Suspense boundaries
- Images: Next/Image o `<img loading="lazy">` con srcset
- Bundle: Tree-shake shadcn/ui (solo componentes usados), evita Radix completo
```

## Skills que usan los agentes
- **UI Designer**: `design-system-foundations`, `accessibility-wcag`, `responsive-and-performance`, `react-component-patterns`/`angular-ui-patterns`, `forms-and-validation`, `data-display-and-charts`
- **UI Implementer**: `react-component-patterns`/`angular-ui-patterns`, `tailwind-shadcn-stack`/`angular-ui-patterns`, `forms-and-validation`, `data-display-and-charts`, `accessibility-wcag`, `responsive-and-performance`
- **UI Reviewer**: `ui-review-checklist`, `accessibility-wcag`, `responsive-and-performance`, `design-system-foundations`

## Validación Previa
```bash
# 1. Stack detectado
cat package.json | grep -E "react|angular|vue|next|vite"

# 2. Design system tokens existen
ls src/components/ui/

# 3. Scripts de validación ejecutables
./scripts/check-a11y.sh --dry-run
./scripts/check-bundle.sh --dry-run
```

## Ejemplo de Uso
```
/ui "Dashboard de usuario con sidebar navegación, grid de métricas (4 widgets), tabla de actividad reciente con paginación y filtros, y modal de detalle. Responsive: mobile drawer sidebar, tablet 2 cols, desktop 4 cols."
```

## Output Esperado
```
✅ Design ID: 550e8400-e29b-41d4-a716-446655440000
✅ Stack detectado: react-typescript-tailwind
✅ UI Designer: Propuesta completada (estructura, 12 componentes, 4 estados cada uno)
✅ UI Implementer: Implementación completada (15 archivos, check-a11y.sh PASSED, check-bundle.sh PASSED: 245KB gzipped)
✅ UI Reviewer: 0 blockers, 0 majors, 2 minors (espaciado arbitrario mt-7, heading hierarchy)
✅ Fix aplicado: 1 ciclo

📋 Resumen final:
- Archivos creados: 15 (Dashboard, Sidebar, MetricCard, ActivityTable, DetailModal, hooks, types)
- Criterios UI: 41/41 reglas verificadas
- Hallazgos: 2 minors corregidos
- Bundle: 245KB gzipped (budget 500KB)
- A11y: 0 violations (axe-core)
- Tiempo total: ~4 min
```