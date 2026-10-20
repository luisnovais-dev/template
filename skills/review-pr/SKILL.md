---
name: review-pr
description: Faz o review independente de uma pull request, em contexto novo e sem ter participado da implementação, classificando findings por severidade. Também faz o re-review após a remediação. Use na etapa de review da PR ou quando pedido o re-review.
---

# Review independente de PR

Revisa a PR sem alterar código. O revisor não participou da implementação.

## Entrada

- Número da PR e da issue.
- Modo: `review` (primeira revisão) ou `re-review` (após remediação, com os findings anteriores).

## Procedimento (modo review)

1. Leia integralmente a issue, a Spec aprovada e a descrição da PR.
2. Inspecione o diff completo contra a base.
3. Leia o código relacionado ao diff para entender o contexto, não só as linhas alteradas.
4. Examine os testes existentes e os alterados. Verifique se o teste comprova o comportamento alegado, não apenas se existe.
5. Leia `AGENTS.md` e `docs/PROCESSO.md`.
6. Avalie: correção funcional, aderência à issue e à Spec, critérios de aceite, invariantes, regressões, edge cases, validação de entrada, autorização, tratamento de erros, segurança, concorrência, consistência frontend e backend, persistência e restauração de estado, consistência de renderização entre servidor e cliente quando aplicável, qualidade da API, arquitetura, duplicação, complexidade, performance e consultas, acessibilidade pertinente, testes ausentes ou frágeis, falsos positivos, alterações fora de escopo, alterações de esquema ou de dados não previstas e compatibilidade.
7. Não assuma que o relatório do implementador está correto. Confronte com código, diff e testes.

## Classificação

- **BLOCKING:** CRITICAL, HIGH ou MEDIUM.
- **NON-BLOCKING:** LOW ou NIT.
- **ACCEPTED / DOCUMENTED RISKS:** limitações já registradas na Spec ou na PR. Verifique antes se a implementação respeitou a decisão documentada.

Cada finding traz severidade, arquivo e linha, comportamento observado, comportamento esperado, justificativa, cenário que reproduz e sugestão de correção, sem implementá-la. Só registre o que tiver evidência técnica razoável.

## Procedimento (modo re-review)

1. Atualize o estado da PR e leia os novos commits, as respostas aos findings e os testes alterados.
2. Para cada finding anterior, classifique como RESOLVED, PARTIALLY RESOLVED ou UNRESOLVED. Confirme a correção da causa, o teste de regressão quando aplicável e a ausência de regressão nova.
3. Revise o diff incremental das correções em busca de problemas introduzidos durante a remediação.
4. Faça a verificação final da PR completa contra a issue e a Spec.

## Saída

- Modo review: contagem por severidade, riscos aceitos, Spec Compliance (PASS, PARTIAL ou FAIL), Test Coverage, alterações fora de escopo e merge blockers.
- Modo re-review: tabela dos findings anteriores com estado, novos findings e blockers restantes.
- Se não houver blocker: `REVIEW STATUS: NO BLOCKING FINDINGS`, com o SHA revisado.

## Identidade e publicação

Publique o review na PR com a sessão `gh` ativa, quando o ambiente permitir. Se a identidade for a mesma do autor, use `--comment`, que aparece como COMMENTED.

## Não faça

- Não altere código, não faça commit, não faça merge nem squash.
- Não trate COMMENTED como bloqueio automático.
