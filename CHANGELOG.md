# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial marketplace structure with 4 plugins
- dev-workflow plugin with complete multi-agent flow
- 10 domain skills for dev-workflow
- Validation scripts and CI/CD pipeline

## [0.1.0] - 2026-10-09

### Added - Phase 1: Skeleton & Marketplace
- Marketplace declaration with 4 plugins (dev-workflow, cicd-security-triage, frontend-ui, context-toolkit)
- Plugin manifests for all 4 plugins
- MIT License
- .gitignore with standard exclusions
- Initial README with installation instructions

### Added - Phase 2: dev-workflow Agents & Contract
- 4 agents: Architect (read-only), Implementer (write), Reviewer (read-only), QA (read+Bash)
- Workflow contract skill with JSON Schema (Draft 2020-12) and example
- Contract validation script (validate-contract.sh)

### Added - Phase 3: dev-workflow Skills & Command
- stack-detector: Detection rules + supported-stacks.json
- stack-java-spring: 10 rules + conventions + antipatterns + Spring Boot 3 migration guide
- stack-python-fastapi: 10 rules + conventions + antipatterns
- review-checklist: 28 rules in 6 sections (Correctness, Architecture, API, DB, Testing, Observability)
- test-strategy: Testing pyramid, thresholds, Testcontainers, mutation testing
- spring-microservices-patterns: Saga (orchestrated/choreographed), Outbox, Idempotency, DLQ, gRPC resilience, Eventual consistency
- api-design-review: 12 rules (versioning, RFC 7807, HTTP codes, pagination, idempotency-key, naming, etc.)
- security-review-owasp: 27 rules mapped to OWASP Top 10 2021 + ASVS Level 2
- db-migration-review: 12 rules (versioning, rollback, expand/contract, zero-downtime, PL/SQL)
- Command: feature.md entry point for multi-agent flow

### Added - Phase 4: dev-workflow Hooks, Scripts & Config
- config/stacks.json: 4 stacks with test/lint/build commands per tool
- config/sensitive-patterns.json: Regex patterns for secrets detection
- scripts/detect-stack.sh: Returns JSON with stack, confidence, evidence
- scripts/run-checks.sh: Runs compile/lint/tests per detected stack
- scripts/guard-sensitive.sh: Blocks editing of sensitive files/content
- hooks/hooks.json: post_edit (run-checks) + pre_edit (guard-sensitive)

### Added - Phase 5: Tests, Validation, CI & Base Documentation
- tests/test-plugin-structure.sh: Validates complete plugin structure
- tests/test-hooks.sh: Validates hooks.json and referenced scripts
- scripts/validate-all.sh: Runs all validations (JSON, frontmatter, scripts, tests)
- .github/workflows/validate.yml: CI pipeline with matrix for 4 plugins
- docs/ARCHITECTURE.md: Design decisions, flows, limitations
- docs/CONVENTIONS.md: Naming, structure, commits, validation patterns
- docs/TESTING-STATUS.md: Honest classification (verified/partial/not verified) with evidence
- AGENTS.md: Complete agent reference with permissions matrix and flows
- Updated README with full documentation

### Changed
- README.md: Complete rewrite with usage, structure, validation, status

### Fixed
- Shell script syntax with `set -euo pipefail`
- JSON validation for all manifest and config files
- Frontmatter validation for agents and commands

---

## Versioning Policy

- **MAJOR**: Breaking changes to plugin manifests, agent interfaces, or contract schema
- **MINOR**: New skills, agents, commands, or non-breaking enhancements
- **PATCH**: Bug fixes, documentation updates, validation improvements

## Plugin Versioning

Each plugin has independent versioning in its `plugin.json`:
- dev-workflow: 0.1.0
- cicd-security-triage: 0.1.0
- frontend-ui: 0.1.0
- context-toolkit: 0.1.0

Marketplace version in `.claude-plugin/marketplace.json` tracks overall release.