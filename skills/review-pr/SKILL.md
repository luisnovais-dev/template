---
name: review-pr
description: Faz o review independente de uma pull request, em contexto novo e sem ter participado da implementação, classificando findings por severidade e publicando com marcador reconhecível pelo merge gate. Também faz o re-review após a remediação. Use na etapa de review da PR ou quando pedido o re-review.
---

# Review independente de PR

Revisa a PR sem alterar código. O revisor não participou da implementação.

Antes de agir, confira o estado real da issue e da PR no GitHub, conforme `docs/PROCESSO.md` (seção Estado real antes de agir). Se a PR estiver mesclada ou fechada, ou se outra branch ou PR estiver ligada à issue, pare e reporte, sem agir.

## Entrada

- Número da PR e da issue.
- Modo: `review` (primeira revisão) ou `re-review` (após remediação, com os findings anteriores).

## Procedimento (modo review)

1. Leia integralmente a issue, a Spec aprovada e a descrição da PR, incluindo as seções Documentação e Roteiro de aceite manual.
2. Inspecione o diff completo contra a base.
3. Leia o código relacionado ao diff para entender o contexto, não só as linhas alteradas.
4. Examine os testes existentes e os alterados. Verifique se o teste comprova o comportamento alegado, não apenas se existe.
5. Leia `AGENTS.md` e `docs/PROCESSO.md`.
6. Avalie: correção funcional, aderência à issue e à Spec, critérios de aceite, invariantes, regressões, edge cases, validação de entrada, autorização por perfil, isolamento entre clientes, tratamento de erros, segurança (incluindo os Requisitos de Segurança declarados e as justificativas de "não aplicável"), concorrência, consistência frontend e backend, persistência e restauração de estado, consistência de renderização entre servidor e cliente quando aplicável, qualidade da API, arquitetura, duplicação, complexidade, performance e consultas, acessibilidade pertinente, testes ausentes ou frágeis, falsos positivos, alterações fora de escopo, alterações de esquema ou de dados não previstas, compatibilidade, e a documentação (se a seção da PR corresponde ao que mudou).
7. Se a PR fecha um épico, confirme que a suíte de aceite do épico está ativada e verde na branch.
8. Se a mudança alterar interface, confirme a evidência do ciclo visual (capturas, autoavaliação e roteiro). Sua ausência é finding bloqueante.
9. Não assuma que o relatório do implementador está correto. Confronte com código, diff e testes.

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

- Modo review: contagem por severidade, riscos aceitos, Spec Compliance (PASS, PARTIAL ou FAIL), Test Coverage, documentação conferida, alterações fora de escopo e merge blockers.
- Modo re-review: tabela dos findings anteriores com estado, novos findings e blockers restantes.
- Se não houver blocker: `REVIEW STATUS: NO BLOCKING FINDINGS`, com o SHA revisado.

## Publicação com marcador

O review é publicado como comentário da PR, com a primeira linha de marcador e a linha de status, para que `merge-gate` e `tratar-findings` o reconheçam:

```text
<!-- review-pr mode=<review|re-review> sha=<sha revisado> -->
REVIEW STATUS: <NO BLOCKING FINDINGS | BLOCKING FINDINGS | ...>
```

Publique com a sessão `gh` ativa, quando o ambiente permitir:

- se a identidade for **diferente** da do autor da PR, publique como review formal com `gh pr review`: `--approve` quando não houver blocker, `--request-changes` quando houver blocker, e o marcador e a linha de status no corpo;
- se a identidade for **a mesma** do autor, publique como comentário (`gh pr comment`), com o marcador. Ele aparece como COMMENTED, e continua válido (ver `docs/PROCESSO.md`, seção Review como comentário).

Nunca publique sem o marcador, nem como review formal da própria PR.

## Não faça

- Não altere código, não faça commit, não faça merge nem squash.
- Não trate COMMENTED como bloqueio automático.
- Não registre finding especulativo.
- Não publique review sem o marcador.
