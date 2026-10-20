---
name: merge-gate
description: Verifica a prontidão final de uma PR contra o último review, checks e conflitos; se estiver pronta, faz o squash merge com mensagem orientada à entrega e limpa a branch e a worktree. Use como etapa final, depois do re-review.
---

# Merge gate

Decide se a PR pode ser mesclada e, se pode, faz o squash.

## Entrada

- Número da PR e da issue.
- Autorização explícita para squash na invocação. Quando o gate estiver verde, a própria invocação desta etapa é a autorização do squash.

## Procedimento

1. Compare o HEAD revisado pelo último review com o HEAD atual da PR. Se houver commits posteriores, o review anterior não basta: reporte que novo review é necessário.
2. Confirme que a issue e a Spec correspondem à implementação entregue.
3. Confirme que o code review foi concluído e que não há finding bloqueante aberto.
4. Confirme que todos os findings bloqueantes anteriores estão resolvidos e verificados pelo revisor.
5. Verifique o estado dos checks. Se a API não permitir consultar as regras de proteção de `main`, registre "Required checks: NOT VERIFIED — insufficient repository/API permission". Não infira quais checks são obrigatórios.
6. Verifique conflitos com `main`.
7. Confirme que não há commits inesperados, alterações fora de escopo, segredos, arquivos de ambiente, artefatos de build ou temporários no diff.
8. Confirme que as limitações conhecidas estão documentadas e não apresentadas como verificações aprovadas.
9. Se houver follow-up não bloqueante não corrigido, verifique se existe issue para ele. Se não existir, crie a issue (com autorização da invocação) e registre o link na descrição da PR.

## Resultado

Apresente o gate:

```
MERGE GATE
Reviewed SHA: <sha>
Current PR SHA: <sha>
SHA unchanged since review: YES | NO
Mergeability: <estado>
Conflicts: <estado>
Reviews: <estado>
Known checks: <lista>
Required checks: PASS | FAIL | NOT VERIFIED
Manual acceptance: <estado>
Blocking findings: <lista ou nenhum>
Accepted risks / non-blocking follow-ups: <lista>
Unexpected changes since review: <lista ou nenhuma>
FINAL STATUS: READY FOR SQUASH MERGE | NOT READY FOR MERGE
```

`NOT READY FOR MERGE` só com blocker concreto: check obrigatório falhando ou pendente, conflito, alteração após o SHA revisado, finding bloqueante, solicitação formal de changes ou impossibilidade imposta pelo GitHub. `NOT VERIFIED` não é FAIL.

## Squash e limpeza

Se `READY FOR SQUASH MERGE`:

1. Faça o squash com `gh pr merge <PR> --squash --delete-branch`, usando mensagem orientada à entrega da issue (não a um commit individual), com `Closes #<issue>`.
2. Confirme que a PR consta como merged, o commit resultante em `main` e o encerramento da issue.
3. Atualize o `main` local com fast-forward, sem alterar nada além disso. Preserve alterações locais não rastreadas.
4. Remova a worktree da issue somente se estiver limpa e sem trabalho não publicado. Use `git worktree remove`, nunca `rm -rf`.
5. Reporte: PR, issue, commit resultante, estado da issue, branch removida ou preservada, worktree removida ou preservada e pendências de limpeza.

## Não faça

- Não faça nenhuma alteração adicional em `main` depois do merge.
- Não faça bypass de proteção de branch sem autorização explícita da invocação e somente se a plataforma oferecer o mecanismo.
- Não converta COMMENTED em bloqueio automaticamente.
