# AGENTS.md

Regras invariantes para qualquer agente de IA neste repositório (Claude, Codex, OpenCode ou outro). Este arquivo contém somente invariantes e ponteiros. O procedimento está em [`docs/PROCESSO.md`](docs/PROCESSO.md), e os valores de configuração estão na seção Configuração desse mesmo documento. Regras específicas do Claude estão em `CLAUDE.md`, que importa este arquivo.

## Regras invariantes

1. Fonte de verdade: o main remoto. A branch local `main` é só de integração. Nenhuma mudança é feita fora de uma branch e de uma worktree próprias.
2. Adicione arquivos por caminho explícito. `git add -A` inclui o que não foi previsto, e `git commit -a` ignora arquivos novos sem aviso. Revise os caminhos antes de cada commit.
3. Nunca commite `.env*` (exceto `.env.example`), cookies, backups, logs, coverage, dumps de dados ou arquivos temporários. Segredos não vão para issues, PRs, logs nem arquivos do projeto.
4. Não use `git reset --hard`, `git checkout --` nem limpeza de worktree para "preparar" o ambiente. Classifique o que existe antes de descartar.
5. Nunca escreva em produção, nem aponte testes ou ferramentas de escrita para ela. A leitura de produção só ocorre por acesso somente leitura configurado e com pedido explícito. Os ambientes que não são produção são regidos pela matriz de ambientes.
6. Não faça merge, squash ou push para o main remoto sem a instrução explícita da etapa correspondente.
7. Nunca desative verificação TLS (`rejectUnauthorized: false` ou equivalente).
8. Nenhum conflito, falha de check ou divergência é resolvido por tentativa silenciosa. Registre o que aconteceu e peça decisão.

## Ponteiros

| Assunto | Onde está |
|---|---|
| Etapas, gates, review, merge | [`docs/PROCESSO.md`](docs/PROCESSO.md#fluxo) |
| Autorização e bloqueios da plataforma | [`docs/PROCESSO.md`](docs/PROCESSO.md#autorização) |
| Worktrees, branches e identidade | [`docs/PROCESSO.md`](docs/PROCESSO.md#worktrees-e-branches) |
| Ambientes e identidade de teste | [`docs/PROCESSO.md`](docs/PROCESSO.md#ambientes) |
| Segredos | [`docs/PROCESSO.md`](docs/PROCESSO.md#segredos) |
| Tamanho de PR | [`docs/PROCESSO.md`](docs/PROCESSO.md#tamanho-de-pr) |
| Gate de documentação | [`docs/PROCESSO.md`](docs/PROCESSO.md#gate-de-documentação) |
| Validação visual | [`docs/PROCESSO.md`](docs/PROCESSO.md#validação-visual) |
| Valores de configuração | [`docs/PROCESSO.md`](docs/PROCESSO.md#configuração) |
| Skills de cada etapa (instaladas por máquina; se faltarem, ver a seção Skills) | [`docs/PROCESSO.md`](docs/PROCESSO.md#skills) |
