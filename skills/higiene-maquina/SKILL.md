---
name: higiene-maquina
description: Faz o inventário somente leitura de repositórios, worktrees, branches (conferindo a ponta no remoto vivo), remotos legados, resíduos de agente e recursos desta máquina, classifica cada item e remove só o que for confirmado pelo mantenedor. Substitui a higiene-git. Use para liberar espaço ou depois de concluir uma mudança.
---

# Higiene da máquina

Mostra o estado do que o trabalho com agentes deixou nesta máquina e remove somente o que for seguro e confirmado. Substitui a skill `higiene-git`.

## Entrada

- Opcional: raízes a inventariar. Sem raiz, o inventário procura repositórios até 4 níveis abaixo de `$HOME`.
- Para remover: lista aprovada pelo mantenedor, item a item ou por grupo.

## Procedimento

1. Rode o inventário, que não altera nada:
   ```bash
   skills/higiene-maquina/scripts/inventario.sh [raiz ...]
   ```
   Antes, atualize a referência de cada repositório com `git fetch origin --prune` quando o mantenedor pedir. O inventário não faz fetch.
2. Leia a saída por classe:
   - **SEGURO_REMOVER:** worktree limpa com branch mesclada no `origin/main`, ou branch mesclada sem worktree.
   - **RESGATAR:** branch com commits que não estão em nenhuma branch do remoto vivo. **Nunca** é tratada como segura. Pode ser trabalho não publicado ou branch com PR squash-mesclada cujo remoto foi apagado. Confirme com o mantenedor antes de qualquer ação.
   - **ORFAO:** worktree registrada cujo diretório sumiu. Limpe o registro com `git worktree prune` só após confirmação.
   - **REMOTO_LEGADO:** remote além de `origin`. Liste para decisão.
   - **LIXO:** resíduo de agente ou temporário dentro do repositório (`.agent/`, `*.log`, `_tmp*`). Liste para decisão.
   - **RECURSO:** espaço de Docker e caches. É informativo. Limpeza de recurso exige pedido explícito.
   - **REQUER_DECISAO:** worktree suja, branch não mesclada, ou branch de outra sessão.
3. Monte a lista de remoções propostas, agrupada por classe, com o caminho ou a branch de cada item e o motivo.
4. Apresente a lista ao mantenedor e aguarde confirmação. Confirmação de um grupo não vale para outro.
5. Remova apenas o confirmado:
   - worktree: `git worktree remove <caminho>` (sem `--force`);
   - branch local mesclada: `git branch -d <branch>` (sem `-D`);
   - branch remota: `git push origin --delete <branch>`, só se confirmada;
   - resíduo de agente: remova o arquivo específico, nunca por padrão amplo.
6. Ao final, rode o inventário de novo e reporte o que mudou.

## Saída

- Tabela com repositórios, worktrees e branches, com estado e classe.
- Lista do que foi removido, do que foi preservado e do que requer decisão.
- Recursos encontrados (informativo).

## Regras

- Nada é removido sem lista e confirmação.
- Não use `--force`, `-D`, `rm -rf` sobre worktree nem `git stash pop`/`drop` em lote: o stack de stash é compartilhado entre sessões.
- Não remova worktree de outra sessão sem confirmar que não há trabalho ativo.
- Não migre pastas nem reorganize repositórios. Esta skill só inventaria e remove o confirmado.
- Não imprima conteúdo de arquivos nem valores de segredo.
- Branch cujo commit não existe no remoto vivo é RESGATAR, nunca SEGURO_REMOVER.

## Não faça

- Não faça checkout no repositório do mantenedor para inspecionar algo.
- Não apague o que não está na lista confirmada.
