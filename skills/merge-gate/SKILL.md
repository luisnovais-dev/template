---
name: merge-gate
description: Verifica a prontidão final de uma PR contra o último review válido, checks, conflitos, documentação e suíte de aceite do épico; se estiver pronta, faz o squash merge com mensagem orientada à entrega e limpa a branch e a worktree. Use como etapa final, depois do re-review.
---

# Merge gate

Decide se a PR pode ser mesclada e, se pode, faz o squash.

## Entrada

- Número da PR e da issue.
- Autorização explícita para squash na invocação. Quando o gate estiver verde, a própria invocação desta etapa é a autorização do squash.

## Procedimento

1. Compare o HEAD revisado pelo último review válido com o HEAD atual da PR. O SHA vem do marcador do review. Se houver commits posteriores, o review anterior não basta: reporte que novo review é necessário.
2. Leia os reviews nas três fontes (reviews formais, comentários da PR e comentários inline), aplicando a regra de validade de `docs/PROCESSO.md` (seção Review como comentário). Não considere COMMENTED como bloqueio automático.
3. Confirme que a issue e a Spec correspondem à implementação entregue.
4. Confirme que todos os findings bloqueantes anteriores estão resolvidos e verificados pelo revisor no re-review.
5. Confirme a documentação: a seção "Documentação" da PR está preenchida, e os documentos citados foram de fato atualizados.
6. Verifique se a PR é o último ticket filho aberto do épico ao qual pertence ("Parte de #<épico>" na issue). Se for, aplique a seção **Fechamento do épico** de `docs/PROCESSO.md`: a suíte de aceite do épico precisa estar ativada e verde na branch integrada, a checklist do épico não pode ter item pendente, e o flag de feature precisa estar tratado. Sem isso, o épico não fecha. Informe "fecha o épico" no resultado. O fechamento em si só ocorre com instrução explícita na invocação.
7. Verifique o estado dos checks. Se a API não permitir consultar as regras de proteção de `main`, registre "Required checks: NOT VERIFIED — insufficient repository/API permission". Não infira quais checks são obrigatórios.
8. Se a plataforma reportar `REVIEW_REQUIRED`, trate como bloqueio da plataforma e siga o procedimento de `docs/PROCESSO.md` (seção Bloqueios da plataforma). Não contorne sem autorização.
9. Verifique conflitos com `main`.
10. Confirme que não há commits inesperados, alterações fora de escopo, segredos, arquivos de ambiente, artefatos de build ou temporários no diff.
11. Confirme que as limitações conhecidas estão documentadas e não apresentadas como verificações aprovadas.
12. Se houver follow-up não bloqueante não corrigido, verifique se existe issue para ele. Se não existir, crie a issue (com autorização da invocação) e registre o link na descrição da PR.

## Resultado

Apresente o gate:

```
MERGE GATE
Reviewed SHA: <sha>
Current PR SHA: <sha>
SHA unchanged since review: YES | NO
Mergeability: <estado>
Conflicts: <estado>
Reviews: <estado, por fonte>
Known checks: <lista>
Required checks: PASS | FAIL | NOT VERIFIED
Documentation: <estado>
Epic acceptance suite: <não aplicável | verde | pendente>
Manual acceptance: <estado>
Blocking findings: <lista ou nenhum>
Accepted risks / non-blocking follow-ups: <lista>
Unexpected changes since review: <lista ou nenhuma>
FINAL STATUS: READY FOR SQUASH MERGE | NOT READY FOR MERGE
```

`NOT READY FOR MERGE` só com blocker concreto: check obrigatório falhando ou pendente, conflito, alteração após o SHA revisado, finding bloqueante, documentação ausente, suíte de aceite do épico não verde, solicitação formal de changes ou `REVIEW_REQUIRED` sem o mecanismo da plataforma. `NOT VERIFIED` não é FAIL.

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
- Não feche épico sem a suíte de aceite verde.
