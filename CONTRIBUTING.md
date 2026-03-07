# Contributing to SentinelForge

First off, thank you for considering contributing to SentinelForge!

SentinelForge is a security-focused homelab platform for running autonomous AI agents with strict governance, auditing, and observability. Contributions that maintain or improve security, reliability, and clarity are especially welcome.

## How We Work

- We aim for **defense-in-depth** and **least privilege** in all code and configuration.[web:77][web:128][web:133]
- We value clear documentation, reproducible setups, and small, focused pull requests.
- Security and observability are first-class features, not afterthoughts.

## Getting Started

1. **Fork the repository** on GitHub.
2. **Clone your fork**:

   ```bash
   git clone https://github.com/<your-username>/sentinelforge.git
   cd sentinelforge
   ```

3. **Set up the infra** (homelab or local Docker): see `infra/README.md`.
4. **Run the API**:

   ```bash
   cd infra
   cp .env.example .env
   # Fill in secrets, then
   docker-compose up -d
   ```

5. Make sure `http://localhost:8000/health` returns a healthy response.

## Types of Contributions

- **Bug fixes** (preferred: with test coverage)
- **Security hardening** (sandboxing, policies, safer defaults)
- **Observability improvements** (metrics, traces, dashboards)
- **Documentation** (clarifications, tutorials, diagrams)
- **Integrations** (new tools, MCP servers, model backends) that follow the security model

## Coding Guidelines

- Python 3.11+
- Use `black`, `ruff`, and `mypy` for formatting and linting.
- Prefer type hints and explicit imports.
- Avoid introducing new dependencies unless necessary, especially security-sensitive ones.

Run checks locally:

```bash
make lint
make test
```

## Security Expectations

Because SentinelForge is a security-sensitive project:

- **Never commit secrets** (API keys, passwords, private keys). `.env` files and key directories are in `.gitignore`.
- Avoid adding tools that provide unrestricted shell access or network access without going through the Tool Gateway and policy engine.
- If you add new tools or MCP integrations, document their security model and failure modes.

## Pull Request Process

1. Create a feature branch: `git checkout -b feature/my-change`.
2. Make your changes.
3. Add or update tests where appropriate.
4. Run `make lint` and `make test` and ensure all checks pass.
5. Open a PR with:
   - A clear description of the change.
   - Any security implications.
   - How you tested it.

We will review PRs with a focus on:

- Correctness and clarity.
- Security and privacy impact.
- Alignment with project roadmap.

## Security Vulnerabilities

If you discover a security vulnerability:

- **Do not** open a public issue.
- Email the maintainer (see GitHub profile) or use GitHub Security Advisories.
- Include:
  - Steps to reproduce.
  - Potential impact.
  - Any suggested mitigations.

We will coordinate a fix and disclosure timeline.

## Code of Conduct

- Be respectful and constructive.
- Assume good intent.
- No harassment, hate speech, or personal attacks.

## Inspiration & Prior Art

SentinelForge is inspired by ongoing industry work on Zero Trust for AI agents, MCP security, and fine-grained authorization for tools.[web:77][web:128][web:129][web:133][web:139][web:140]

Thank you again for helping build a safer ecosystem for autonomous AI agents.
