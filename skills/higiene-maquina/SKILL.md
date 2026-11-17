---
name: higiene-maquina
description: Faz o inventário somente leitura de repositórios, worktrees, branches (conferindo a ponta no remoto vivo), remotos legados, resíduos de agente, recursos Docker órfãos e espaço desta máquina, classifica cada item e remove só o que for confirmado pelo mantenedor, a partir de uma lista aprovada. Substitui a higiene-git. Use para liberar espaço ou depois de concluir uma mudança.
---

# Higiene da máquina

Mostra o estado do que o trabalho com agentes deixou nesta máquina e remove somente o que for seguro e confirmado. Substitui a skill `higiene-git`.

## Entrada

- Opcional: raízes a inventariar. Sem raiz, o inventário procura repositórios até 4 níveis abaixo de `$HOME`.
- Para remover: a lista aprovada pelo mantenedor (a seção `LISTA PARA APROVAÇÃO` do inventário, com as linhas que ele aprova).

## Procedimento

1. Rode o inventário, que não altera nada:
   ```bash
   skills/higiene-maquina/scripts/inventario.sh [raiz ...]
   ```
   O inventário não faz fetch. Para atualizar a referência de cada repositório antes, rode `git fetch origin --prune` quando o mantenedor pedir.
2. Leia a saída por classe (ver [Classes](#classes)).
3. Mostre ao mantenedor a seção `LISTA PARA APROVAÇÃO`, com `ESPACO_LIBERAVEL` e os avisos de disco. Ele apaga as linhas que não aprova.
4. Aguarde a aprovação. A aprovação de uma linha não vale para outra.
5. Com a lista aprovada num arquivo, aplique:
   ```bash
   skills/higiene-maquina/scripts/inventario.sh --remover lista-aprovada.tsv
   ```
   Cada linha é revalidada no momento da remoção. O modo aplica só o que está na lista, recusa o que não for seguro e mostra `REMOVIDO:` ou `RECUSADO:` por item. Ele sai com código 3 se algo foi recusado.
6. Ao final, rode o inventário de novo e reporte o que mudou.

## Classes

- **SEGURO_REMOVER:** worktree limpa e integrada (ancestral de `origin/main`, ou PR mesclada por squash com a ponta conferida), e branch integrada sem worktree. "Limpa" inclui arquivos ignorados pelo `.gitignore` (um `.env` local conta como pendência); ficam de fora da conta só as pastas regeneráveis (`node_modules`, `.next`, `dist`, `coverage` e `.venv` por padrão, ou a lista de `HIGIENE_REGENERAVEIS`) e `.agent/`. Um `.env` ou outro arquivo ignorado fora dessa lista bloqueia a remoção; para aceitar outra pasta, inclua-a em `HIGIENE_REGENERAVEIS`. Entra na lista aprovada.
- **RESGATAR:** branch com commits fora do remoto vivo e sem PR mesclada. Inclui o caso em que o GitHub não pôde ser consultado. **Nunca** é segura. Confirme com o mantenedor antes de qualquer ação.
- **REQUER_DECISAO:** worktree suja, worktree com submódulo, HEAD solto com alterações, branch não integrada, branch integrada que está no checkout principal, ou branch sem PR mesclada cujo commit já existe no GitHub. Para worktree, o inventário lista os pendentes (até 20, com o total).
- **RASCUNHO:** pendente de Spec ou documento não versionado (`*.md`, `docs/`, `openspec/`, `specs/`). Mostra `main=` (AUSENTE, IGUAL ou DIFERENTE em relação a `origin/main`) e `issue=` (IGUAL, DIFERENTE, AUSENTE, INDETERMINADO ou SEM_ISSUE, pela branch e pela issue no GitHub). O conteúdo nunca é impresso.
- **ORFAO:** worktree registrada cujo diretório sumiu. Limpe o registro com `git worktree prune` só após confirmação.
- **DOCKER_ORFAO:** containers, volumes e redes de uma execução de teste cujo PID já não existe. São agrupados pela chave de execução `<pid>-<8 hex>` do nome ou do projeto do compose, e não pelo nome exato. Entram na lista aprovada.
- **DOCKER_ATIVO:** o mesmo agrupamento, com o PID vivo. Só informativo.
- **REMOTO_LEGADO:** remote cujo dono não é o usuário do `gh`, nem uma organização dele, nem está em `HIGIENE_DONOS`, inclusive o `origin`. Revise para decidir se é um remoto antigo.
- **PROGRESSO:** `.agent/` com registro de trabalho. Não é lixo e não é removido por esta skill.
- **LIXO:** arquivo temporário (`_tmp*`, `*.log`, `tmp-verif-*`) que **não** está versionado. Arquivo versionado nunca é LIXO. Entra na lista aprovada quando está dentro do repositório.
- **RECURSO:** espaço de Docker e caches. É informativo. Limpeza de recurso exige pedido explícito.
- **AVISO_DISCO:** partição com uso acima de `HIGIENE_LIMITE_DISCO` (padrão 90%).
- **AVISO_STORE:** worktree com `node_modules/.pnpm`. O store é compartilhado, e a remoção não o libera.
- **ESPACO_LIBERAVEL:** o que a lista de SEGURO_REMOVER e LIXO liberaria. Cada arquivo conta uma vez, e só quando todos os seus links estão no conjunto. Um hard link para um store de fora não entra.

## Regras de remoção (modo `--remover`)

- Worktree: `git worktree remove` sem `--force`. Recusada se houver alteração pendente, processo com o diretório dentro, ou trabalho não integrado. A pasta-mãe é removida só se ficar vazia. Worktree com submódulo é recusada: o git não a remove, e o inventário a classifica como REQUER_DECISAO com a indicação `SUBMODULO`. A remoção dela segue o procedimento de `docs/PROCESSO.md` (seção Worktrees e branches), com confirmação do mantenedor antes de qualquer passo.
- Branch: `-d` se for ancestral de `origin/main`. `-D` só pela regra de squash (PR mesclada, ponta igual ou atrás do `headRefOid`, sem PR aberta e commit no GitHub). Recusada se estiver em uso em worktree ou no checkout principal.
- Lixo: só dentro do repositório, só se não estiver versionado.
- Docker: só se o PID morreu. Remove containers (`stop`, `rm`), volumes e redes da chave.
- A branch remota nunca é apagada por esta skill. O GitHub cuida dela com `delete_branch_on_merge`.

## Execução em outra máquina

Para inventariar uma máquina remota, sem copiar nada para lá:

```bash
ssh <host> 'bash -s' < skills/higiene-maquina/scripts/inventario.sh
```

Para passar raízes: `ssh <host> 'bash -s -- <raiz>' < skills/higiene-maquina/scripts/inventario.sh`. O script é autocontido. A remoção (`--remover`) só roda na máquina onde a lista foi aprovada.

## Plataforma

Testado em Linux. No Linux, o cwd dos processos é lido em `/proc`. Quando o cwd de um processo não pode ser lido, a remoção recusa a worktree com código 2 (não verificado), mas só se o processo pode estar dentro dela:
- **Do próprio usuário:** sempre conta.
- **De outro usuário:** conta só se nenhum diretório do caminho da worktree é bloqueado para outros (`x` para outros). Se algum bloqueia, o outro usuário não alcança a worktree e o processo é ignorado.
- **De root:** ignorado. Não se verifica sem privilégio, e o mantenedor aceitou esse risco. Um processo de root dentro da worktree não é detectado pelo inventário.

Sem privilégio, processos do próprio usuário que não deixam ler o cwd (`systemd --user`, `sd-pam`, `sshd`, `ssh-agent`) bloqueiam a remoção por `--remover` enquanto estiverem rodando. Isso vale em qualquer sessão de desktop ou SSH. O mantenedor aceitou esse risco, registrado na PR #7. Nesse caso, a remoção manual por `git worktree remove <caminho>` (sem `--force`) é o caminho, mas ele remove arquivos ignorados sem aviso. No macOS, o cwd é verificado com `lsof`, e a remoção recusa a worktree quando não consegue verificar (código 2). Esse caminho não foi testado (ver D6 da Spec da #6).

## Saída

- Tabela com repositórios, worktrees e branches, com estado e classe.
- Seção `LISTA PARA APROVAÇÃO`, com `ESPACO_LIBERAVEL` e os avisos.
- No modo `--remover`: `REMOVIDO:` e `RECUSADO:` por item, e o resumo.

## Testes

Os testes ficam em `skills/higiene-maquina/tests/` e rodam com `scripts/testar-template.sh`. Eles usam uma pasta temporária, `HOME` temporário, repositórios com origem local e stubs de `gh`, `docker` e `df`. Nenhum teste toca o GitHub, o Docker ou o `HOME` real.

## Regras

- Nada é removido sem lista e confirmação.
- Não use `--force`, `-D` fora da regra de squash, `rm -rf` sobre worktree nem `git stash pop`/`drop` em lote: o stack de stash é compartilhado entre sessões.
- Não remova worktree de outra sessão sem confirmar que não há trabalho ativo.
- Não migre pastas nem reorganize repositórios. Esta skill só inventaria e remove o confirmado.
- Não imprima conteúdo de arquivos nem valores de segredo.
- Branch cujo commit não existe no remoto vivo é RESGATAR, nunca SEGURO_REMOVER.

## Não faça

- Não faça checkout no repositório do mantenedor para inspecionar algo.
- Não apague o que não está na lista confirmada.
