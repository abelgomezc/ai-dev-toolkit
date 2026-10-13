# False Positive Triage Skill

## Cuándo usarlo
- **Analyst**: Evalúa cada hallazgo para decidir keep vs discard
- **Fixer**: Entiende por qué ciertos hallazgos fueron descartados
- **QA**: Verifica que FPs descartados no reaparecen tras fixes

## Cuándo NO usarlo
- Para ignorar hallazgos sin análisis (cada descarte requiere justificación)
- Como excusa para no fixear vulnerabilidades reales

## Descripción
Reglas objetivas para identificar y justificar falsos positivos en reportes de seguridad CI/CD. **Cada descarte debe citar la regla exacta y evidencia**.

## Reglas de Falso Positivo (FP)

### FP-1: Test Scope / Build Scope Dependencies
**Criterio**: Vulnerabilidad en dependencia marcada como `test`, `testImplementation`, `devDependency`, `provided`, `compileOnly`, o en plugins de build.

**Evidencia requerida**:
- `pom.xml`: `<scope>test</scope>` o `<scope>provided</scope>`
- `build.gradle`: `testImplementation` / `compileOnly`
- `package.json`: `"devDependencies"`
- `requirements.txt`: instalado solo en `test-requirements.txt` / `requirements-dev.txt`

**Justificación template**: "Hallazgo en `{package}` v`{version}` - scope `{scope}` confirmado en `{build_file}`. No incluido en artifact de producción. Regla FP-1 aplica."

**Ejemplo**: CVE en `org.mockito:mockito-core:4.0.0` (test scope) → **DESCARTAR**

### FP-2: Vulnerabilidad en Código No Alcanzable (Dead Code)
**Criterio**: Hallazgo SAST/StackHawk en código que no se ejecuta en producción (feature flags off, código legacy no llamado, endpoints deshabilitados).

**Evidencia requerida**:
- Análisis de call graph: función no llamada desde entry points
- Feature flag: `@ConditionalOnProperty` / config deshabilitado
- Endpoint: `@Deprecated` + no routed / 404 confirmado

**Justificación template**: "Hallazgo `{rule_id}` en `{file}:{line}` - código no alcanzable: `{razón}`. Verificado call graph / feature flag. Regla FP-2 aplica."

**Ejemplo**: SQLi en `LegacyAdminController.deleteAll()` - controller no registrado en router → **DESCARTAR**

### FP-3: Vulnerabilidad Mitigada por Controles Externos
**Criterio**: Vulnerabilidad real pero mitigada por WAF, API Gateway, network policy, o runtime protection (ej: ModSecurity, AWS WAF, Falco, SELinux).

**Evidencia requerida**:
- Regla WAF bloqueando payload específico
- Network policy: pod no tiene egress a internet
- Runtime: Falco rule detectando exploit attempt

**Justificación template**: "Hallazgo `{CVE}` en `{component}` - mitigado por `{control}`: `{detalle}`. Regla FP-3 aplica. **Nota**: Revisar si control falla (defense in depth)."

**Ejemplo**: Path traversal en file upload - WAF rule `REQUEST-930-APPLICATION-ATTACK-LFI` bloquea → **DESCARTAR** (pero documentar residual risk)

### FP-4: Versión Parcheada Ya Aplicada (Backported Fix)
**Criterio**: Herramienta reporta CVE en versión X, pero distro/vendor backporteó fix sin cambiar versión (común en RHEL, Debian, Alpine, distroless).

**Evidencia requerida**:
- `rpm -q --changelog package | grep CVE-XXXX`
- `apt-get changelog package | grep CVE-XXXX`
- Security advisory del vendor confirmando backport
- Docker image: `docker scan` / `grype` con `--add-cpes-if-none` mostrando patched

**Justificación template**: "CVE-XXXX reportado en `{package}:{version}` - backport confirmado en `{vendor} {release}`: `{link_advisory}`. Regla FP-4 aplica."

**Ejemplo**: CVE-2021-44228 en `log4j:2.14.1` - Red Hat 8.6 backporteó fix en `log4j-2.14.1-3.el8` → **DESCARTAR** (si usando RHEL)

### FP-5: Configuración Segura por Defecto (Default Safe Config)
**Criterio**: Hallazgo de "insecure default" pero configuración explícita en proyecto lo hace seguro.

**Evidencia requerida**:
- Config file con setting seguro explícito
- Documentación de framework confirmando default cambiado

**Justificación template**: "Hallazgo `{rule}` - default inseguro reportado, pero config explícita en `{file}`: `{setting}=true`. Regla FP-5 aplica."

**Ejemplo**: Spring Boot Actuator `/env` endpoint expuesto - pero `management.endpoints.web.exposure.exclude=env` en `application.yml` → **DESCARTAR**

### FP-6: Hallazgo Duplicado (Same Root Cause)
**Criterio**: Múltiples hallazgos reportados por diferentes tools/rules para la misma causa raíz.

**Evidencia requerida**:
- Mismo CVE / misma ubicación / misma librería
- Tool A y Tool B reportan mismo issue

**Justificación template**: "Hallazgo duplicado de `{CVE}` en `{location}` - ya contabilizado en `{finding_id_principal}`. Regla FP-6 aplica."

**Ejemplo**: Grype y SonarQube reportan CVE-2023-XXXX en `jackson-databind` → **DESCARTAR** duplicado

### FP-7: Vulnerabilidad en Entorno No Productivo
**Criterio**: Hallazgo en ambiente de desarrollo, staging, o feature branch que no llega a producción.

**Evidencia requerida**:
- Pipeline config: job solo corre en `develop` branch
- Environment variable: `DEPLOY_ENV=staging`
- Kubernetes namespace: `namespace: dev`

**Justificación template**: "Hallazgo en `{tool}` ejecutado en `{env}` - no promociona a prod. Regla FP-7 aplica. **Nota**: Fixear antes de merge a main."

**Ejemplo**: StackHawk scan en PR staging environment → **DESCARTAR** (pero trackear para pre-merge)

## Proceso de Decisión (Decision Tree)
```
Para cada hallazgo:
1. ¿Es test/build scope? → FP-1 → DESCARTAR
2. ¿Código no alcanzable? → FP-2 → DESCARTAR
3. ¿Mitigado por control externo? → FP-3 → DESCARTAR (documentar residual)
4. ¿Fix backporteado? → FP-4 → DESCARTAR
5. ¿Config explícita segura? → FP-5 → DESCARTAR
6. ¿Duplicado? → FP-6 → DESCARTAR
7. ¿Solo env no-prod? → FP-7 → DESCARTAR (trackear)
8. → KEEP (priorizar con severity-rules)
```

## Formato de Justificación (Obligatorio)
```json
{
  "finding_id": "CVE-2023-XXXXX",
  "decision": "discard",
  "fp_rule": "FP-3",
  "justification": "Path traversal in file upload endpoint mitigated by AWS WAF rule REQUEST-930-APPLICATION-ATTACK-LFI (managed rule group). WAF logs show 0 bypass attempts in last 30 days. Residual risk: WAF misconfiguration. Track in risk register.",
  "evidence": [
    "waf-config.yaml: managedRuleGroup: AWSManagedRulesKnownBadInputsRuleSet",
    "cloudwatch-metric: WAFBlockedRequests > 0 for rule REQUEST-930"
  ],
  "residual_risk": "low",
  "review_date": "2024-07-15"
}
```

## Verificación en Analyst
- **FP-1**: ¿Scope confirmado en build file?
- **FP-2**: ¿Call graph / feature flag verificado?
- **FP-3**: ¿Control externo documentado y verificado?
- **FP-4**: ¿Vendor advisory confirmando backport?
- **FP-5**: ¿Config explícita en repo?
- **FP-6**: ¿Mismo CVE/location ya contabilizado?
- **FP-7**: ¿Env confirmado no-prod?