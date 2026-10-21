# context-toolkit

Ahorro de contexto y tokens, continuidad entre sesiones: generación de CLAUDE.md, mapa compacto del codebase y handoff entre sesiones.

## Skills

| Skill | Descripción |
|-------|-------------|
| `claude-md-writer` | Genera y mantiene CLAUDE.md con stack, estructura, comandos y convenciones |
| `codebase-map` | Genera mapa compacto con entry points, módulos, hotspots y dependencias |
| `session-handoff` | Captura estado de sesión para reanudar sin pérdida de contexto |

## Comandos

```bash
# Mapear codebase
/map
/map --depth=4 --dir=plugins/frontend-ui

# Generar resumen de sesión
/handoff --objective="Continuar implementación" --scope=changed
```

## Uso

- **claude-md-writer**: Ideal al iniciar en proyecto nuevo o tras cambios significativos
- **codebase-map**: Ideal para explorar repos grandes con menor consumo de contexto
- **session-handoff**: Ideal al finalizar sesión o antes de interrupción
