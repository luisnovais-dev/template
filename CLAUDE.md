# CLAUDE.md

@AGENTS.md

## Específico do Claude Code

- As skills são carregadas de `.claude/skills/`. Cada entrada aponta para uma pasta em `skills/` por link simbólico. Não edite a cópia em `.claude/skills/`: edite a fonte em `skills/`.
- Worktrees criadas pelo Claude ficam em `.claude/worktrees/<nome>` e não são versionadas (ver `.gitignore`).
- `.claude/settings.local.json` é local e não é versionado.
