---
name: implementar-spec
description: Implementa uma Spec aprovada em worktree própria, executando as Tasks na ordem definida, com TDD, commits atômicos e registro de progresso. Use somente depois da aprovação explícita da Spec.
---

# Implementar Spec

Executa a Spec aprovada. A Spec é a fonte de verdade.

## Entrada

- Número da issue, com Spec aprovada e comentada.
- Autorização explícita para implementar na invocação.

## Pré-condições

1. A Spec está aprovada e registrada na issue, com o label `status:approved`.
2. Você está numa worktree dedicada, criada a partir do main remoto atualizado. Nunca no checkout principal.
3. `git status` está limpo. Se houver alterações prévias, classifique cada caminho antes de qualquer ação. Não descarte nada sem determinar a origem.

## Procedimento

1. Atualize referências: `git fetch origin --prune`. Confirme a relação da branch com o main remoto.
2. Crie o registro de progresso em `.agent/progresso.md` (não versionado). Ele é atualizado a cada Task.
3. Para cada Task, na ordem da Spec:
   - **RED:** escreva o teste do comportamento e confirme que falha pelo motivo esperado. Falha de configuração, import, fixture ou ambiente não conta.
   - **GREEN:** implemente somente o necessário.
   - **REFACTOR:** melhore mantendo os testes verdes.
   - Execute os testes da Task. Só marque a Task como concluída se os critérios de conclusão estiverem satisfeitos.
   - Faça commit atômico, com mensagem descritiva. Não inclua alterações não relacionadas.
   - Registre comportamentos, testes, resultados, commits e desvios no progresso.
4. Não pare entre Tasks. Pare somente por bloqueio real: uma premissa da Spec está errada ou há decisão que a Spec não cobre. Nesse caso, registre o conflito e pergunte. Não tome decisão arquitetural diferente da Spec.
5. Ao final, execute a verificação definida na Spec e em `docs/PROCESSO.md` (seção Configuração): lint, testes, integração quando aplicável, typecheck e build, conforme o escopo.
6. Compare os resultados com o baseline conhecido. Diferencie falha preexistente de regressão nova.

## Saída

- Branch com commits atômicos.
- Registro de progresso com todas as Tasks.
- Resultado da verificação, por comando.
- Declaração de que a implementação está pronta para auditoria. Não há afirmação de pronto sem os resultados.

## Não faça

- Não crie PR nesta etapa.
- Não faça squash nem merge.
- Não faça `git add -A`.
- Não altere a Spec para acomodar a implementação. Se precisar, pare e reporte.
- Não marque teste como aprovado sem executá-lo.
