# Test Strategy Skill

## Cuándo usarlo
- **Architect**: Define estrategia de testing en el plan (acceptance_criteria → verification_method)
- **Implementer**: Escribe tests según esta estrategia
- **Reviewer**: Verifica que tests cubren criterios de aceptación
- **QA**: Ejecuta suite y valida coverage thresholds

## Cuándo NO usarlo
- Como sustituto de pensar qué testear (la pirámide es guía, no ley)
- Para testing de UI/E2E (eso es frontend-ui plugin)

## Descripción
Estrategia de testing por capas, tipos, y criterios de aceptación. Define qué se testea en cada nivel, herramientas, y thresholds.

## Pirámide de Testing (adaptada por stack)

### Java/Spring
```
         ┌─────────────┐
         │   E2E       │  ← Pocos (5-10%), críticos: flujos completos usuario
         ├─────────────┤
         │  Contract   │  ← Pact/Spring Cloud Contract: APIs entre servicios
         ├─────────────┤
         │Integration  │  ← Testcontainers: BD real, repos, controllers, wiring
         ├─────────────┤
         │   Unit      │  ← Muchos (70-80%): services, utils, mappers, domain
         └─────────────┘
```

### Python/FastAPI
```
         ┌─────────────┐
         │   E2E       │  ← Playwright/Pytest: flujos críticos
         ├─────────────┤
         │  Contract   │  ← Schemathesis: OpenAPI spec vs implementation
         ├─────────────┤
         │Integration  │  ← Testcontainers: BD real, routers, services, deps
         ├─────────────┤
         │   Unit      │  ← pytest + mock: services, validators, domain logic
         └─────────────┘
```

## Tipos de test y cuándo usar cada uno

| Tipo | Qué testea | Herramientas | Cuándo |
|------|------------|--------------|--------|
| **Unit** | Función/clase aislada, lógica pura | JUnit5+Mockito / pytest+mock | Siempre. Base de la pirámide. |
| **Integration** | Wiring real: BD, repos, controllers, DI | @SpringBootTest+Testcontainers / pytest+Testcontainers | Repos, controllers, flujos service→repo |
| **Contract** | API spec vs implementación | Spring Cloud Contract / Schemathesis | Microservicios, APIs públicas |
| **E2E** | Flujo usuario completo (UI + API) | Playwright / Cypress | Pocos: happy paths críticos |
| **Performance** | Latencia, throughput, carga | Gatling / k6 / Locust | Pre-release, regresiones |
| **Security** | Vulnerabilidades, OWASP | OWASP ZAP, dependency-check | CI/CD pipeline |

## Criterios de aceptación → Verification Method

| Criterio de aceptación | Verification Method | Ejemplo |
|------------------------|---------------------|---------|
| "POST /users retorna 201 con Location" | `integration_test` | `UserControllerIntegrationTest.testCreateUser` |
| "Email duplicado retorna 409" | `integration_test` | `UserControllerIntegrationTest.testDuplicateEmail` |
| "Password hash usa bcrypt cost 12" | `unit_test` | `PasswordServiceTest.testBcryptCost` |
| "Cobertura ≥ 80%" | `static_analysis` | JaCoCo / pytest-cov report |
| "Sin vulnerabilidades críticas" | `static_analysis` | OWASP Dependency Check / safety |
| "Latencia p99 < 200ms" | `performance_test` | Gatling simulation |
| "OpenAPI spec válida" | `contract_test` | Schemathesis / spring-cloud-contract |

## Thresholds obligatorios

| Métrica | Java/Spring | Python/FastAPI | Node/React |
|---------|-------------|----------------|------------|
| Line coverage | ≥ 80% | ≥ 80% | ≥ 80% |
| Branch coverage | ≥ 70% | ≥ 70% | ≥ 70% |
| Mutation testing (Pitest/mutmut) | ≥ 60% | ≥ 60% | - |
| Integration test coverage | ≥ 50% de endpoints | ≥ 50% de endpoints | - |
| Build time (CI) | < 10 min | < 8 min | < 5 min |

## Estructura de tests por stack

### Java/Spring
```text
src/test/
├── java/
│   ├── unit/
│   │   ├── service/
│   │   │   └── UserServiceTest.java          # Mockito, sin Spring context
│   │   ├── mapper/
│   │   │   └── UserMapperTest.java
│   │   └── util/
│   │       └── PasswordUtilTest.java
│   ├── integration/
│   │   ├── repository/
│   │   │   └── UserRepositoryIntegrationTest.java  # @DataJpaTest + Testcontainers
│   │   ├── controller/
│   │   │   └── UserControllerIntegrationTest.java  # @SpringBootTest + MockMvc
│   │   └── service/
│   │       └── UserServiceIntegrationTest.java     # @SpringBootTest + BD real
│   └── contract/
│       └── UserApiContractTest.java         # Spring Cloud Contract
└── resources/
    ├── application-test.yml
    └── testcontainers.properties
```

### Python/FastAPI
```text
tests/
├── unit/
│   ├── test_user_service.py          # pytest + mock, sin BD
│   ├── test_password_util.py
│   └── test_user_mapper.py
├── integration/
│   ├── test_user_repository.py       # Testcontainers PostgreSQL
│   ├── test_users_api.py             # httpx.AsyncClient + Testcontainers
│   └── test_auth_api.py
├── contract/
│   └── test_openapi_schema.py        # schemathesis
├── conftest.py                       # Fixtures: client, db, postgres
└── fixtures/
    └── users.json
```

## Convenciones de naming

| Tipo | Java | Python |
|------|------|--------|
| Unit test class | `*Test.java` | `test_*.py` |
| Integration test class | `*IntegrationTest.java` | `test_*_api.py` / `test_*_repository.py` |
| Contract test | `*ContractTest.java` | `test_*_contract.py` |
| Test method | `shouldDoSomethingWhenCondition()` | `test_should_do_something_when_condition()` |
| Fixture | N/A | `conftest.py` + `@pytest.fixture` |

## Test Data Management

### Testcontainers (Java y Python)
```java
// Java - @Testcontainers en clase base
@Testcontainers
@SpringBootTest
class BaseIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
        .withDatabaseName("test")
        .withUsername("test")
        .withPassword("test");

    @DynamicPropertySource
    static void props(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
```

```python
# Python - conftest.py
@pytest.fixture(scope="session")
def postgres():
    with PostgresContainer("postgres:16") as pg:
        yield pg.get_connection_url()

@pytest.fixture
async def client(postgres) -> AsyncGenerator[AsyncClient, None]:
    app = create_app(postgres)
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
```

### Fixtures / Test Data Builders
```java
// Java - Test Data Builder pattern
public class UserTestBuilder {
    private String email = "test@example.com";
    private String password = "secret123";
    private String fullName = "Test User";

    public UserTestBuilder withEmail(String email) { this.email = email; return this; }
    public User build() { return new User(email, password, fullName); }
    public UserCreateRequest buildRequest() { return new UserCreateRequest(email, password, fullName); }
}

// Uso
User user = new UserTestBuilder().withEmail("other@test.com").build();
```

```python
# Python - factory_boy o dataclasses
from dataclasses import dataclass
from uuid import uuid4

@dataclass
class UserFactory:
    email: str = "test@example.com"
    password: str = "secret123"
    full_name: str = "Test User"

    def build(self) -> User:
        return User(id=uuid4(), email=self.email, password_hash=hash(self.password), full_name=self.full_name)

    def build_request(self) -> UserCreateRequest:
        return UserCreateRequest(email=self.email, password=self.password, full_name=self.full_name)

# Uso
user = UserFactory(email="other@test.com").build()
```

## CI/CD Integration

### GitHub Actions / GitLab CI
```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env: { POSTGRES_DB: test, POSTGRES_USER: test, POSTGRES_PASSWORD: test }
        ports: [5432:5432]
        options: --health-cmd="pg_isready" --health-interval=10s --health-timeout=5s --health-retries=5

    steps:
      - uses: actions/checkout@v4
      - name: Set up Java/Python
        uses: actions/setup-java@v4 / actions/setup-python@v5
      - name: Cache dependencies
        uses: actions/cache@v4
      - name: Run tests
        run: ./mvnw verify / pytest --cov-fail-under=80
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## Mutation Testing (opcional pero recomendado)
```xml
<!-- Java - Pitest en pom.xml -->
<plugin>
  <groupId>org.pitest</groupId>
  <artifactId>pitest-maven</artifactId>
  <version>1.15.0</version>
  <configuration>
    <targetClasses>
      <param>com.example.service.*</param>
    </targetClasses>
    <targetTests>
      <param>com.example.service.*Test</param>
    </targetTests>
    <mutationThreshold>60</mutationThreshold>
  </configuration>
</plugin>
```

```toml
# Python - mutmut en pyproject.toml
[tool.mutmut]
paths_to_mutate = "src/app/services"
runner = "pytest -x"
tests_dir = "tests/unit"
```

## Verificación automática
```bash
# Java
./mvnw verify                    # Tests + coverage + checkstyle + spotbugs
./mvnw org.pitest:pitest-maven:mutationCoverage  # Mutation testing

# Python
ruff check . && mypy .           # Lint + typecheck
pytest --cov=src --cov-fail-under=80 --cov-report=xml
mutmut run --paths-to-mutate=src/app/services
```