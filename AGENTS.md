# AGENTS.md

Regras de trabalho para qualquer agente de IA neste repositório (Claude, Codex, OpenCode ou outro). Este arquivo é a fonte única das regras compartilhadas. Regras específicas do Claude estão em `CLAUDE.md`, que importa este arquivo.

## Onde está cada assunto

| Assunto | Documento |
|---|---|
| Processo: etapas, gates, review, merge, autorização | [`docs/PROCESSO.md`](docs/PROCESSO.md) |
| Skills de cada etapa | [`skills/`](skills/) |

Cada regra tem um único dono. Não copie regras para outro arquivo: referencie.

## Fonte de verdade

- Código de produção: o main remoto.
- Branch local `main`: somente integração. Não desenvolva diretamente nela.
- Nenhuma mudança é feita fora de uma branch e de uma worktree próprias.

## Regras invariantes

1. Adicione arquivos por caminho explícito. `git add -A` inclui o que não foi previsto (arquivos locais, dumps, `.env`), e `git commit -a` ignora arquivos novos sem aviso. Revise os caminhos antes de cada commit.
2. Nunca commite `.env*`, cookies, backups, logs, coverage, dumps de dados ou arquivos temporários. Segredos não vão para issues, PRs, logs nem arquivos do projeto.
3. Não use `git reset --hard`, `git checkout --` nem limpeza de worktree para "preparar" o ambiente. Classifique o que existe antes de descartar.
4. Não faça merge, squash ou push para `main` sem a instrução explícita da etapa correspondente.
5. Nunca aponte testes, comandos de escrita ou ferramentas para produção. Confira o alvo antes de executar.
6. Nunca desative verificação TLS (`rejectUnauthorized: false` ou equivalente).

## Autorização

- **A autorização vale para a invocação.** Ações de publicação (issue, PR, comentário, label), merge, squash, remoção de branch ou worktree e qualquer ação em produção exigem instrução explícita na invocação. Nenhum arquivo versionado concede autorização permanente.
- Não contorne proteção de branch ou check obrigatório por conta própria. Se a plataforma bloquear, registre o bloqueio e peça decisão. Bypass só com autorização explícita do mantenedor na invocação.
- Uma vez autorizada uma etapa, execute as Tasks sem pausar, exceto por bloqueio real (decisão que a Spec não cobre). Pausas por cautela não são necessárias.

## Identidade no GitHub

Use a sessão `gh` ativa (`gh auth status`). A conta pode variar por colaborador. Não fixe identidade em commits, PRs ou prompts.

## Desenvolvimento

1. Atualize as referências antes de criar a worktree: `git fetch origin --prune`.
2. Crie a branch com prefixo (`feat/`, `fix/`, `docs/`) em uma worktree própria. O diretório segue a ferramenta usada, conforme [`docs/PROCESSO.md`](docs/PROCESSO.md#worktrees-e-branches).
3. Antes de editar, confirme `git status` limpo e a relação com o main remoto.
4. Faça commits por unidade lógica. Testes e documentação entram no mesmo commit da mudança que descrevem.
5. Respeite o [teto de tamanho de PR](docs/PROCESSO.md#tamanho-de-pr).

## Verificação mínima

Os comandos de verificação do projeto estão na seção Configuração de [`docs/PROCESSO.md`](docs/PROCESSO.md#configuração). Até que sejam preenchidos, nenhuma verificação é considerada aprovada.

## Gate de documentação

Toda mudança de funcionalidade atualiza a documentação existente, ou cria a seção que falta, antes de a PR ser aberta.

O README e a descrição do repositório no GitHub acompanham o crescimento do projeto. Quando uma mudança alterar o que o projeto faz, para quem ele serve ou o seu status, a linha de descrição do README (e a descrição do repositório no GitHub) é atualizada na mesma PR.

## Mudanças de interface

Mudanças de interface (UX/UI) passam por validação visual antes de concluir a auditoria (ver [`docs/PROCESSO.md`](docs/PROCESSO.md#validação-visual)).

## Worktrees

- Worktree é temporária. Ela é removida ao fim do trabalho, se estiver limpa.
- A localização depende da ferramenta. Não crie worktrees fora do diretório que a ferramenta usa.
- Antes de remover, confirme que não há trabalho não publicado. Não remova worktree de outra sessão.
- Use `git worktree list` para inspecionar.

## Estado local

Não limpe branches, worktrees ou artefatos de outra sessão automaticamente. Liste o alvo, confirme que não está associado a trabalho ativo e peça confirmação antes de remover.

## Skills

As etapas do processo estão em [`skills/`](skills/). Cada skill é um procedimento com entrada, saída e gates. Claude as carrega por `.claude/skills/`, que aponta para cada pasta em `skills/`. Outras ferramentas podem ler `skills/` diretamente, conforme o mecanismo que suportarem.

## Configuração de stack

Preencha este bloco ao adotar o template em um projeto. Enquanto estiver vazio, as skills que dependem de stack devem parar e pedir a configuração, em vez de assumir comandos.

```yaml
stack:
  gerenciador_pacotes: <!-- ex.: nome do gerenciador -->
  lockfile: <!-- arquivo único de lock -->
  linguagens: <!-- ex.: linguagem e versão -->
  frameworks: <!-- ex.: frameworks principais -->
  servicos_locais: <!-- ex.: banco, fila, armazenamento -->
  regras_adicionais: <!-- regras de stack que valem para todos os agentes -->
```
