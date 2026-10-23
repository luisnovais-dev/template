---
name: tratar-findings
description: Corrige todos os findings de um code review numa PR, bloqueantes e não bloqueantes, com TDD e commits atômicos, lendo o review nas três fontes válidas e respondendo a cada finding com evidência. Use depois do review independente, antes do re-review.
---

# Tratar findings

Corrige os findings do review. Todo finding aplicável é tratado, bloqueante ou não.

## Entrada

- Número da PR, com os findings publicados.
- Autorização explícita para corrigir na invocação.

## Como ler o review

Leia os findings de três fontes da PR:

1. reviews formais;
2. comentários da PR;
3. comentários inline.

Um review é válido se for formal de identidade diferente da do autor da PR, se tiver o marcador `<!-- review-pr ... -->` (de qualquer identidade), ou se o mantenedor o declarar como review. Use o SHA do marcador para saber se o review ainda vale (ver `docs/PROCESSO.md`, seção Review como comentário).

## Procedimento

1. Confirme que está na worktree e branch da PR.
2. Atualize referências: `git fetch origin --prune`. Não altere o checkout principal.
3. Leia cada finding nas três fontes e confirme sua aplicabilidade ao código atual.
4. Relacione cada finding aos Requirements, Acceptance Criteria e Tasks afetados.
5. Se um finding conflitar com a Spec ou exigir decisão de produto ou arquitetura não prevista, interrompa esse item e reporte a decisão necessária. Não altere a Spec em silêncio.
6. Para cada bug ou comportamento incorreto confirmado, use TDD:
   - **RED:** crie o teste que reproduz o finding e confirme a falha pelo motivo esperado. Erro de ambiente ou configuração não é RED válido.
   - **GREEN:** implemente a correção mínima.
   - **REFACTOR:** melhore mantendo os testes verdes.
7. Se o finding for de documentação, corrija a documentação no mesmo commit da mudança que ela descreve.
8. Após cada correção, execute os testes diretamente relacionados e os de regressão pertinentes.
9. Faça commits atômicos, com mensagem que relacione a correção ao finding. Não reescreva nem faça squash dos commits existentes.
10. Ao final, execute os testes focados, a integração pertinente, lint nos arquivos alterados, typecheck e build conforme o escopo. Compare com o baseline para detectar regressão nova.
11. Faça push para a mesma branch com `git push` (sem force).
12. Responda a cada finding na PR com: causa, correção, teste que reproduziu, teste que comprova a correção e commit correspondente.

## Saída

- Lista de findings com a correção aplicada ou o motivo de não aplicar.
- Commits e resultados dos testes.
- Declaração de que a PR está pronta para re-review.

## Regras

- Não resolva nem oculte finding sem evidência da correção.
- Não crie issue de follow-up para finding não bloqueante sem a decisão do mantenedor. Ele é corrigido por padrão.
- Não ignore um review porque ele aparece como comentário. Use o marcador e as três fontes.
- Não faça merge nem squash.
