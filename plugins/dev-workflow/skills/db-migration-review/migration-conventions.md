# Migration Conventions

## Naming
```
V{N}__{description_in_snake_case}.sql
```
- `V` + número secuencial (1, 2, 3...)
- `__` doble underscore
- Descripción en snake_case, imperativo: `create_users_table`, `add_email_index`
- Un archivo = una migración lógica

## Estructura de Archivo
```sql
-- V3__create_orders_table.sql
-- Descripción: Crea tabla orders con FK a users
-- Autor: architect
-- Fecha: 2024-01-15
-- Rollback: DROP TABLE orders;

-- UP
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total_cents BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status_created ON orders(status, created_at);

-- DOWN (para rollback manual)
-- DROP INDEX idx_orders_status_created;
-- DROP INDEX idx_orders_user_id;
-- DROP TABLE orders;
```

## Zero-Downtime Patterns

### Expand/Contract para Columnas
```sql
-- PASO 1: Expand (agregar columna nullable)
-- V5__add_phone_to_users.sql
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- PASO 2: Backfill (en aplicación o migración separada)
-- UPDATE users SET phone = 'unknown' WHERE phone IS NULL;

-- PASO 3: Contract (NOT NULL + default)
-- V6__make_phone_not_null.sql
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
ALTER TABLE users ALTER COLUMN phone SET DEFAULT 'unknown';
```

### Expand/Contract para Renombrar
```sql
-- MALO: ALTER TABLE users RENAME COLUMN email TO email_address;

-- BUENO - 3 Deployments:
-- Deploy 1: Expand
-- V5__add_email_address.sql
ALTER TABLE users ADD COLUMN email_address VARCHAR(255);
UPDATE users SET email_address = email WHERE email_address IS NULL;

-- Deploy 2: Código usa email_address (dual write)
-- Deploy 3: Contract
-- V7__drop_email_column.sql
ALTER TABLE users DROP COLUMN email;
```

### Índices Concurrentes
```sql
-- PostgreSQL
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- Oracle
CREATE INDEX idx_users_email ON users(email) ONLINE;

-- MySQL 8.0+
CREATE INDEX idx_users_email ON users(email) ALGORITHM=INPLACE, LOCK=NONE;

-- SQL Server
CREATE INDEX idx_users_email ON users(email) WITH (ONLINE = ON);
```

### Foreign Keys Seguras
```sql
-- Paso 1: Crear NOVALIDATE (no bloquea, no valida datos existentes)
ALTER TABLE orders ADD CONSTRAINT fk_orders_user 
    FOREIGN KEY (user_id) REFERENCES users(id) NOT VALID;

-- Paso 2: Validar en background (job separado)
-- ALTER TABLE orders VALIDATE CONSTRAINT fk_orders_user;
```

## Backfill en Batches (PostgreSQL)
```sql
-- Para tablas > 10k rows
DO $$
DECLARE
    batch_size INT := 5000;
    updated INT := 1;
    start_time TIMESTAMPTZ := NOW();
BEGIN
    WHILE updated > 0 AND EXTRACT(EPOCH FROM (NOW() - start_time)) < 300 LOOP  -- max 5 min
        UPDATE orders 
        SET total_cents = total * 100
        WHERE total_cents IS NULL
        AND ctid IN (
            SELECT ctid FROM orders 
            WHERE total_cents IS NULL 
            ORDER BY id
            LIMIT batch_size
        );
        GET DIAGNOSTICS updated = ROW_COUNT;
        COMMIT;
        PERFORM pg_sleep(0.05);  -- 50ms entre batches
    END LOOP;
END $$;
```

## Partitioning (PostgreSQL)
```sql
-- Tabla particionada por rango de fechas
CREATE TABLE orders_partitioned (
    id UUID NOT NULL,
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    total_cents BIGINT NOT NULL,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Particiones trimestrales
CREATE TABLE orders_2024_q1 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE orders_2024_q2 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');
-- ...

-- Índices en particionada (se propagan)
CREATE INDEX idx_orders_partitioned_user ON orders_partitioned(user_id);
CREATE INDEX idx_orders_partitioned_status ON orders_partitioned(status);
```

## Testing Checklist
```bash
# 1. BD limpia
flyway clean migrate -configFiles=test.conf
# Verificar: schema_version tiene N entries, tablas creadas

# 2. BD con datos (baseline)
flyway baseline -configFiles=prod.conf -baselineVersion=0
flyway migrate -configFiles=prod.conf
# Verificar: migraciones aplicadas, datos intactos

# 3. Rollback test
flyway undo -configFiles=test.conf
# Verificar: schema_version decrementa, tablas estado anterior

# 4. Performance
# EXPLAIN ANALYZE en queries críticas post-migración
```

## Documentación de Migraciones Complejas
```markdown
# V15__split_users_table.md

## Contexto
Separar users en users + user_profiles para cumplimiento GDPR (derecho al olvido).

## Estrategia: Expand/Contract (3 deployments)

### Deployment 1 - Expand (Esta migración)
- Crear tabla `user_profiles` con datos GDPR-sensibles
- Copiar datos existentes
- FK `user_profiles.user_id -> users.id`
- Trigger para sync automático

### Deployment 2 - Código Dual Write
- App escribe en AMBAS tablas
- Lee de `user_profiles` para datos sensibles
- Migración de datos histórica completada

### Deployment 3 - Contract (Migración futura)
- Dropar columnas GDPR de `users`
- `user_profiles` se convierte en tabla principal

## Rollback (Deployment 1)
```sql
DROP TRIGGER sync_user_profile ON users;
DROP TABLE user_profiles;
```
Datos en `users` intactos.

## Validación Post-Deployment
- [ ] Row count: `users` = `user_profiles`
- [ ] FK integrity: 0 orphans
- [ ] App: reads/writes both tables correctly
- [ ] Performance: query latency < baseline

## Riesgos
- Doble escritura temporal → inconsistencia si falla una
- Mitigación: Transacción distribuida / Saga para sync
```