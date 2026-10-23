# Changelog do processo

Cada versão do processo tem uma entrada. O `adotar-processo`, no modo `atualizar`, lê as notas de migração entre a `processo_versao` do projeto e a versão atual, nesta ordem.

## 2

Reescrita do processo para fatias verticais, Spec pronta, validação dentro do ticket e distribuição por máquina.

- Hierarquia épico, ticket, PR e tarefa. Fatias com `Refs #` e a última com `Closes #`. Sem unidades de tempo.
- Suíte de aceite do épico, escrita no primeiro ticket e ativada no ticket que fecha o épico.
- Gate "Spec pronta" no `spec-issue`. Investigações antes da aprovação.
- Requisitos de Segurança acionados pela superfície, com itens novos.
- Ciclo de validação visual dentro do ticket de interface.
- Um dono por regra: `AGENTS.md` com invariantes e ponteiros, `docs/PROCESSO.md` com o procedimento e a Configuração.
- Matriz de ambientes, identidade de teste e clone de produção como ambiente de ensaio.
- Segredos com um `.env` por projeto e `.env.example` com referências `op://`.
- Labels pelo manifesto `.github/labels.yml`. Formulário `melhoria.yml`.
- Review com marcador `<!-- review-pr ... -->`, lido por `merge-gate` e `tratar-findings` nas três fontes.
- Skills novas: `instalar-processo`, `adotar-processo` e `higiene-maquina`. A `higiene-git` foi substituída.
- Formulários e template de PR em pt-BR.
- Label `type:chore` no conjunto final. `duplicate`, `invalid` e `wontfix` são mantidos.
- `delete_branch_on_merge` ligado no repositório. Branches com PR mesclada são removidas.
- `higiene-maquina` classifica branch integrada por PR mesclada por squash como seguro remover, e nunca como resgate quando o GitHub confirma a PR.
- `instalar-processo` varre `~/.codex/skills`, `~/.config/opencode/skills` e `~/.hermes/skills`, e com `--aposentar` copia as skills de usuário para a raiz de aposentados.
- Cada issue tem uma só branch, com o número da issue no nome. Não se rastreia a `main`.

### Notas de migração desde a versão 1

Para um projeto que já adotou a versão 1:

1. Atualize `docs/PROCESSO.md` e `AGENTS.md` pelo manifesto (modo `copy`). Preserve a Configuração do projeto: copie só o procedimento e recoloque os valores de `comandos`, `ambientes` e `stack` depois.
2. Adicione `processo_versao: 2` à Configuração.
3. Substitua `.github/ISSUE_TEMPLATE/*.yml` e `.github/pull_request_template.md` pelos do template. O PR template passa a ter as seções Documentação e Roteiro de aceite manual.
4. Crie `.github/labels.yml` e aplique o conjunto final. Remarque os labels em uso antes de remover qualquer um, e peça autorização para criar ou alterar labels. Ligue `delete_branch_on_merge` (com autorização).
4a. Não remova `duplicate`, `invalid` nem `wontfix`. Remova `good first issue`, `help wanted` e `question` só com a lista confirmada pelo mantenedor.
5. Se o projeto tiver a skill `higiene-git` instalada na máquina, substitua-a pela `higiene-maquina` com `instalar-processo`.
6. Remova `skills/` da raiz do projeto, se houver. As skills agora são instaladas por máquina. Ajuste o `CLAUDE.md` do projeto para o texto novo do manifesto (apenas `@AGENTS.md` e a seção Claude Code), sem links para `.claude/skills`.
7. Abra uma PR única com a adoção, sem reorganizar o código nem a documentação.

## 1

Bootstrap do template de processo de trabalho: AGENTS, PROCESSO, skills de cada etapa e formulários de issue e PR.
