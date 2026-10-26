# CLAUDE.md

@AGENTS.md

## Claude Code

- As skills do processo são instaladas nesta máquina por links em `~/.claude/skills`. Não as copie para o projeto (ver [`docs/PROCESSO.md`](docs/PROCESSO.md#skills)).
- `.claude/skills/`, quando existir no projeto, só contém links para as skills próprias do projeto em `.agents/skills/`.
- Worktrees criadas pelo Claude ficam em `.claude/worktrees/<nome>` e não são versionadas (ver [`docs/PROCESSO.md`](docs/PROCESSO.md#worktrees-e-branches)).
- `.claude/settings.local.json` é local e não é versionado.
