# Severity Rules Skill

## Cuándo usarlo
- **Analyst**: Calcula severidad ajustada para cada hallazgo (no solo CVSS)
- **Fixer**: Entiende priorización para ordenar fixes
- **QA**: Valida que fixes resuelven hallazgos de alta severidad primero

## Cuándo NO usarlo
- Como sustituto de CVSS (es complemento)
- Para scoring de vulnerabilidades sin contexto de despliegue

## Descripción
Reglas para calcular **severidad ajustada** considerando explotabilidad real, exposición del componente, y disponibilidad de fix. CVSS base score es solo punto de partida.

## Reglas de Cálculo (se aplican en orden)

### Regla 1: Explotabilidad Real (Exploitability)
| Nivel | Criterio | Ajuste |
|-------|----------|--------|
| **High** | Exploit público conocido (Exploit-DB, Metasploit, PoC en wild) | +2 niveles |
| **Medium** | Exploit teórico posible, requiere condiciones específicas | +1 nivel |
| **Low** | Solo DoS o información, sin RCE/SQLi/Auth bypass | 0 |
| **None** | No explotable en contexto real (ej: test scope) | -2 niveles |

**Verificación**: Buscar en Exploit-DB, CISA KEV, Metasploit modules, GitHub PoCs

### Regla 2: Exposición Real (Exposure)
| Nivel | Criterio | Ajuste |
|-------|----------|--------|
| **Direct** | Componente expuesto a internet (web server, API gateway, LB) | +2 niveles |
| **Internal** | Componente en red interna, accesible desde otros servicios | +1 nivel |
| **Build-only** | Solo en build/CI (test deps, build plugins, dev tools) | -2 niveles |
| **Isolated** | No accesible desde red (librería interna no expuesta) | -1 nivel |

**Verificación**: Arquitectura de despliegue, network policies, ingress rules

### Regla 3: Fix Disponible (Fix Availability)
| Nivel | Criterio | Ajuste |
|-------|----------|--------|
| **Available** | Versión parcheada publicada, upgrade path claro | -1 nivel (más urgente fixear) |
| **Workaround** | Config change o mitigation documentada | 0 |
| **None** | Sin fix conocido, requiere patch manual o fork | +1 nivel (mayor riesgo residual) |

**Verificación**: Changelog de librería, security advisory, GitHub releases

### Regla 4: Impacto de Negocio (Business Impact)
| Nivel | Criterio | Ajuste |
|-------|----------|--------|
| **Critical** | Afecta datos PII, financieros, auth, pagos | +1 nivel |
| **High** | Afecta funcionalidad core, disponibilidad | 0 |
| **Medium** | Afecta features secundarias, logging, metrics | -1 nivel |
| **Low** | Solo documentación, tooling, ejemplos | -1 nivel |

**Verificación**: Data classification, threat modeling, business context

## Algoritmo de Severidad Ajustada
```
adjusted_severity = cvss_base_severity 
    + exploitability_adjustment 
    + exposure_adjustment 
    + fix_availability_adjustment 
    + business_impact_adjustment

Clamp: CRITICAL > HIGH > MEDIUM > LOW > INFO
```

### Ejemplo
| Hallazgo | CVSS | Exploitability | Exposure | Fix | Business | Adjusted |
|----------|------|----------------|----------|-----|----------|----------|
| CVE-2021-44228 (Log4Shell) | CRITICAL | High (+2) | Direct (+2) | Available (-1) | Critical (+1) | **CRITICAL** |
| CVE-2023-XXXX (snakeyaml) | HIGH | Medium (+1) | Internal (+1) | Available (-1) | Medium (0) | **HIGH** |
| CVE-2022-XXXXX (test dep) | MEDIUM | None (-2) | Build-only (-2) | Available (-1) | Low (-1) | **INFO (discard)** |

## Tabula de Decisión Rápida

| CVSS | Exploit Público | Expuesto a Internet | Fix Disponible | → Severidad Final |
|------|-----------------|---------------------|----------------|-------------------|
| CRITICAL | Sí | Sí | Sí | CRITICAL |
| CRITICAL | No | No | No | HIGH |
| HIGH | Sí | Sí | Sí | CRITICAL |
| HIGH | No | Internal | Sí | HIGH |
| MEDIUM | Sí | Direct | Sí | HIGH |
| MEDIUM | No | Build-only | Sí | LOW/INFO |

## Verificación en Analyst
- **severity-rules regla 1**: ¿Exploit público verificado? (link a PoC/Exploit-DB)
- **severity-rules regla 2**: ¿Componente expuesto? (archivo de arquitectura/network policy)
- **severity-rules regla 3**: ¿Fix disponible? (changelog/advisory version)
- **severity-rules regla 4**: ¿Impacto negocio? (data classification doc)