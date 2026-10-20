---
name: higiene-git
description: Lista worktrees e branches locais e remotas com seu estado e tamanho, e remove somente o que já foi mesclado e está limpo, com confirmação. Use para liberar espaço em disco ou após concluir uma mudança.
---

# Higiene de git

Mostra o estado das worktrees e branches e remove o que é seguro remover.

## Entrada

- Opcional: escopo (somente worktrees, somente branches ou ambos).
- Para remover: confirmação explícita do mantenedor na invocação, por item ou por lista aprovada.

## Procedimento

1. Atualize referências: `git fetch origin --prune`.
2. Liste as worktrees: `git worktree list`. Para cada uma, verifique estado (limpa ou suja), branch, se a branch está mesclada no main remoto e o tamanho em disco.
3. Liste as branches locais e remotas, com a mesma classificação: mesclada, não mesclada, sem upstream, com commits não publicados.
4. Classifique cada item:
   - **Seguro remover:** worktree limpa e branch mesclada, ou branch mesclada sem worktree.
   - **Requer decisão:** worktree suja, branch não mesclada, commits locais não publicados, ou branch de outra sessão.
   - **Preservar:** qualquer item sem confirmação de que não há trabalho ativo.
5. Apresente a tabela ao mantenedor e aguarde a confirmação para cada item do grupo "seguro remover".
6. Remova o confirmado: `git worktree remove <caminho>` para worktrees e `git branch -d <branch>` para branches locais mescladas. Remova a branch remota somente se confirmada.
7. Rode `git worktree prune` ao final, para limpar registros órfãos.

## Saída

- Tabela com todas as worktrees e branches, estado, tamanho e classificação.
- Lista do que foi removido, do que foi preservado e do que requer decisão.

## Regras

- Não use `git worktree remove --force` nem `git branch -D` sem confirmação explícita.
- Não remova worktree de outra sessão sem confirmar que não há trabalho ativo.
- Nunca use `rm -rf` sobre uma worktree.
- Não use `git stash pop` nem `git stash drop` em lote: o stack é compartilhado entre sessões.
