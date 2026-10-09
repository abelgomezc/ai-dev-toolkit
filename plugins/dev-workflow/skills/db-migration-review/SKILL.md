# Database Migration Review Skill

## Cuándo usarlo
- **Reviewer**: Verifica cada migración en revisión (antes de merge)
- **Architect**: Diseña estrategia de migración en el plan
- **Implementer**: Escribe migraciones siguiendo estas reglas
- **QA**: Valida migraciones en entorno de staging

## Cuándo NO usarlo
- Para NoSQL sin esquema (MongoDB, DynamoDB) - principios aplican pero herramientas difieren
- Para migraciones ORM auto-generadas sin revisión (Hibernate `ddl-auto=update` PROHIBIDO en prod)

## Descripción
Reglas verificables para migraciones SQL/PLSQL seguras: versionado, rollback, compatibilidad hacia atrás, zero-downtime, datos existentes, locking.

## Archivos de referencia
- `migration-conventions.md` — Convenciones de命名, estructura, herramientas
- `zero-downtime-patterns.md` — Patrones expand/contract, dual-write
- `plsql-migrations.md` — Específicos para Oracle PL/SQL

## Reglas verificables

### Regla 1: Versionado secuencial y descriptivo
```
V1__create_users_table.sql
V2__add_email_index_to_users.sql
V3__create_orders_table.sql
V4__add_foreign_key_orders_user.sql
V5__alter_users_add_phone.sql
```
- Prefijo `V` + número secuencial + `__` + descripción en snake_case
- **UN SOLO** statement por archivo (o transacción explícita)
- **Verificación**: `ls db/migration/V*.sql | sort -V` → secuencia sin gaps

### Regla 2: Rollback obligatorio (down migration)
```sql
-- V5__alter_users_add_phone.sql
-- UP
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- DOWN (comentado al final o archivo separado U5__)
-- ALTER TABLE users DROP COLUMN phone;
```
- Flyway: callback `afterMigrate` / manual `flyway undo` (requiere edición)
- Liquibase: `<rollback>` tag obligatorio
- **Verificación**: Cada migración tiene rollback documentado/probado

### Regla 3: Compatibilidad hacia atrás (Expand/Contract)
**Fase Expand (additive only - seguro):**
```sql
-- BUENO - Solo agrega, no rompe código existente
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
CREATE INDEX idx_users_email ON users(email);
```

**Fase Contract (breaking - requiere deploy coordinado):**
```sql
-- MALO - Rompe código que usa 'name'
ALTER TABLE users DROP COLUMN name;
ALTER TABLE users RENAME COLUMN email TO email_address;

-- BUENO - En dos deployments:
-- Deploy 1: Expand (agregar nueva, mantener antigua)
ALTER TABLE users ADD COLUMN email_address VARCHAR(255);
UPDATE users SET email_address = email WHERE email_address IS NULL;
-- Deploy 2: Código usa email_address
-- Deploy 3: Contract (dropar antigua)
ALTER TABLE users DROP COLUMN email;
```

### Regla 4: Zero-downtime para columnas NOT NULL
```sql
-- MALO - Bloquea tabla, falla si hay filas existentes
ALTER TABLE users ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';

-- BUENO - 3 pasos:
-- 1. Agregar nullable
ALTER TABLE users ADD COLUMN status VARCHAR(20);
-- 2. Backfill (en batches si tabla grande)
UPDATE users SET status = 'ACTIVE' WHERE status IS NULL;
-- 3. Agregar NOT NULL (metadata only en PG 12+)
ALTER TABLE users ALTER COLUMN status SET NOT NULL;
```

### Regla 5: Índices CONCURRENTLY (PostgreSQL) / ONLINE (Oracle/MySQL)
```sql
-- MALO - Bloquea escrituras
CREATE INDEX idx_users_email ON users(email);

-- BUENO - No bloquea (PG)
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- BUENO - Oracle
CREATE INDEX idx_users_email ON users(email) ONLINE;

-- BUENO - MySQL 8.0+
CREATE INDEX idx_users_email ON users(email) ALGORITHM=INPLACE, LOCK=NONE;
```

### Regla 6: Foreign Keys con VALIDATE / NOVALIDATE
```sql
-- MALO - Valida todas las filas existentes (bloquea, falla si datos sucios)
ALTER TABLE orders ADD CONSTRAINT fk_orders_user 
    FOREIGN KEY (user_id) REFERENCES users(id);

-- BUENO - Crear NOVALIDATE, luego validar en background
ALTER TABLE orders ADD CONSTRAINT fk_orders_user 
    FOREIGN KEY (user_id) REFERENCES users(id) NOT VALID;

-- Luego (en job separado o siguiente migración)
ALTER TABLE orders VALIDATE CONSTRAINT fk_orders_user;
```

### Regla 7: Datos existentes - Backfill en batches
```sql
-- MALO - Una transacción gigante, lock prolongado
UPDATE orders SET total_cents = total * 100;

-- BUENO - Batches con commit intermedio (pg_sleep para no saturar)
DO $$
DECLARE
    batch_size INT := 10000;
    updated INT := 1;
BEGIN
    WHILE updated > 0 LOOP
        UPDATE orders 
        SET total_cents = total * 100
        WHERE total_cents IS NULL
        AND ctid IN (
            SELECT ctid FROM orders 
            WHERE total_cents IS NULL 
            LIMIT batch_size
        );
        GET DIAGNOSTICS updated = ROW_COUNT;
        COMMIT;
        PERFORM pg_sleep(0.1);
    END LOOP;
END $$;
```

### Regla 8: Enum changes - Solo ADD, nunca REMOVE/REORDER
```sql
-- MALO - Rompe código que usa valores
ALTER TYPE order_status DROP VALUE 'CANCELLED';
ALTER TYPE order_status RENAME VALUE 'PENDING' TO 'NEW';

-- BUENO - Solo agregar al final
ALTER TYPE order_status ADD VALUE 'REFUNDED' AFTER 'CANCELLED';
-- O crear nuevo tipo y migrar gradualmente
```

### Regla 9: Particionamiento de tablas grandes
```sql
-- Partition by range (fecha) - mejor para time-series
CREATE TABLE orders_partitioned (
    id UUID NOT NULL,
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    total_cents BIGINT NOT NULL,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_2024_q1 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
-- ... una partición por trimestre
```

### Regla 10: Migraciones PL/SQL (Oracle) - Específicas
```sql
-- BUENO - Package spec + body separados, versionados
-- V10__create_order_pkg_spec.sql
CREATE OR REPLACE PACKAGE order_pkg AS
    FUNCTION calculate_total(p_order_id IN orders.id%TYPE) RETURN NUMBER;
    PROCEDURE confirm_order(p_order_id IN orders.id%TYPE);
END order_pkg;
/

-- V11__create_order_pkg_body.sql
CREATE OR REPLACE PACKAGE BODY order_pkg AS
    FUNCTION calculate_total(p_order_id IN orders.id%TYPE) RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT SUM(quantity * unit_price) INTO v_total
        FROM order_items WHERE order_id = p_order_id;
        RETURN NVL(v_total, 0);
    END;

    PROCEDURE confirm_order(p_order_id IN orders.id%TYPE) IS
    BEGIN
        UPDATE orders SET status = 'CONFIRMED', confirmed_at = SYSTIMESTAMP
        WHERE id = p_order_id AND status = 'PAYMENT_COMPLETED';
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Order not in valid state for confirmation');
        END IF;
    END;
END order_pkg;
/
```

**Reglas PL/SQL:**
- `CREATE OR REPLACE` para idempotencia
- Spec y body en archivos separados
- Excepciones custom con `RAISE_APPLICATION_ERROR(-20xxx, ...)`
- `PRAGMA AUTONOMOUS_TRANSACTION` solo para logging/auditoría
- **NUNCA** `COMMIT`/`ROLLBACK` en package body (lo maneja caller)

### Regla 11: Testing de migraciones
```bash
# Flyway: test en BD limpia + BD con datos
flyway clean migrate -configFiles=test.conf
flyway migrate -configFiles=prod.conf -baselineOnMigrate=true

# Verificar: migración aplicada, esquema correcto, datos íntegros
# Rollback test:
flyway undo -configFiles=test.conf
# Verificar: esquema vuelve a estado anterior
```

### Regla 12: Documentación de migraciones complejas
```markdown
# V15__split_users_table.md
## Contexto
Separar users en users + user_profiles para GDPR.

## Estrategia Expand/Contract
1. **Expand** (esta migración): Crear user_profiles, copiar datos, FK
2. **Deploy** código escribe en ambas tablas
3. **Contract** (migración futura): Dropar columnas de users

## Rollback
DROP TABLE user_profiles;  -- Datos en users intactos

## Validación
- Row count users = user_profiles
- FK integrity
- App reads/writes both tables
```

## Verificación en Review
- **db-migration-review-1**: ¿Versionado secuencial `V{N}__description.sql`?
- **db-migration-review-2**: ¿Rollback documentado y probado?
- **db-migration-review-3**: ¿Expand/Contract para cambios breaking?
- **db-migration-review-4**: ¿NOT NULL en 3 pasos (nullable → backfill → constraint)?
- **db-migration-review-5**: ¿Índices `CONCURRENTLY` / `ONLINE`?
- **db-migration-review-6**: ¿FK `NOT VALID` → `VALIDATE` separado?
- **db-migration-review-7**: ¿Backfill en batches para tablas > 10k rows?
- **db-migration-review-8**: ¿Enums solo ADD?
- **db-migration-review-10**: ¿PL/SQL: spec/body separados, excepciones custom?
- **db-migration-review-11**: ¿Test en BD limpia + BD con datos + rollback?
- **db-migration-review-12**: ¿Migraciones complejas documentadas en .md?