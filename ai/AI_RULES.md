# AI Rules — sentinelforge

These rules apply to ALL AI assistants (Claude, Copilot, Perplexity, Cursor, etc.) working in this repository.

## Non-Negotiable Rules

1. **No secrets in commits** — API keys, tokens, threat intel credentials must NEVER be committed
2. **Read before write** — always read existing files before modifying
3. **Security data handling** — threat intelligence data, IOCs, and security findings are sensitive; never log or expose them unnecessarily
4. **Run tests before committing** — `make test` or see README for test commands
5. **Update CHANGELOG.md** for any user-visible change

## Code Style

- Python 3.11+, full type hints, docstrings
- Follow existing service patterns in `services/`
- Error handling: explicit, never silent failures
- Use `make` targets for common operations

## File Ownership

| File/Folder | Rule |
|-------------|------|
| `services/` | Read fully before modifying existing services |
| `infra/` | Infrastructure config — high caution |
| `main.py` | Entry point — read before modifying |
| `ai/AI_HANDOVER.md` | Update at end of every session |
| `CHANGELOG.md` | Append only, newest at top |

## Commit Message Format

`feat:`, `fix:`, `docs:`, `chore:`, `security:` — conventional commits

## Before Every Commit

- [ ] No credentials or threat intel data in changed files
- [ ] Tests pass
- [ ] `ai/AI_HANDOVER.md` updated if significant session
