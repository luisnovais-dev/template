---
name: implementar-spec
description: Implementa uma Spec aprovada em worktree própria, executando as Tasks na ordem definida, com TDD em dois níveis, commits atômicos, ciclo de validação visual quando houver interface e registro de progresso. Use somente depois da aprovação explícita da Spec.
---

# Implementar Spec

Executa a Spec aprovada. A Spec é a fonte de verdade.

## Entrada

- Número da issue, com Spec aprovada e comentada.
- Autorização explícita para implementar na invocação.

## Pré-condições

1. A Spec está aprovada e registrada na issue, com o label de aprovação (`label_aprovacao` da Configuração de `docs/PROCESSO.md`).
2. Você está numa worktree dedicada da issue, a partir do main remoto atualizado. Nunca no checkout principal. Antes de criar branch ou worktree, procure a que já existe para a issue (ver Procedimento, passo 0).
3. `git status` está limpo. Se houver alterações prévias, classifique cada caminho antes de qualquer ação. Não descarte nada sem determinar a origem.
4. A configuração de comandos e de ambientes (Configuração de `docs/PROCESSO.md`) está preenchida. Se houver placeholder no que a Spec usa, pare e peça o valor.

## Procedimento

0. Localize o trabalho já existente da issue `<n>`:
   - `git worktree list` e `git branch --list "*<n>*"` (e a branch com o prefixo da issue);
   - se existir branch ou worktree da issue, reutilize-a, depois de confirmar que ela está no estado esperado. Não crie uma segunda branch para a mesma issue sem decisão do mantenedor;
   - se houver branch sem número da issue ligada à mesma Spec, pare e pergunte antes de qualquer ação.
   - Se não existir nada, crie a branch com o prefixo e o número da issue, por exemplo `docs/<n>-<descrição>`, em worktree própria.
1. Atualize referências: `git fetch origin --prune`. Confirme a relação da branch com o main remoto.
   - Ao criar a branch, use `git worktree add -b <branch> <caminho> origin/main --no-track`, para que ela não rastreie a `main`.
   - Publique só a própria branch, com `git push -u origin <branch>`. Nunca faça push para `main`.
2. Crie o registro de progresso em `.agent/progresso.md` (não versionado). Ele é atualizado a cada Task.
3. Se o ticket pertence a um épico, escreva o teste de aceitação do épico na primeira Task que o permitir, marcado como pendente com a tag do épico. Ele é ativado somente no ticket que fecha o épico.
4. Antes de criar um mecanismo de teste ou verificação, procure o que já existe no projeto. Mecanismo novo é versionado, declarado na Configuração, documentado e genérico. Nunca crie script ou configuração por PR ou issue.
5. Para cada Task, na ordem da Spec:
   - **RED:** escreva o teste do comportamento e confirme que falha pelo motivo esperado. Falha de configuração, import, fixture ou ambiente não conta.
   - **GREEN:** implemente somente o necessário.
   - **REFACTOR:** melhore mantendo os testes verdes.
   - Execute os testes da Task. Só marque a Task como concluída se os critérios de conclusão estiverem satisfeitos.
   - Atualize a documentação que a Spec lista como afetada, na mesma Task da mudança que ela descreve.
   - Faça commit atômico, com mensagem descritiva. Não inclua alterações não relacionadas. Adicione os arquivos por caminho explícito.
   - Registre comportamentos, testes, resultados, commits, desvios e emendas no progresso.
6. Se a Task toca interface, execute o ciclo de validação visual de `validacao-visual` **antes** de marcá-la como concluída. A evidência vai para o progresso.
7. Classifique cada decisão que surgir fora da Spec: **produto** (emenda da Spec na issue, pedida ao mantenedor), **técnica local** (registrada no progresso e depois na PR) ou **transversal** (ADR em `docs/adr/`).
8. Não pare entre Tasks. Pare somente por bloqueio real: uma premissa da Spec está errada ou há decisão que a Spec não cobre. Nesse caso, registre o conflito e pergunte. Não tome decisão arquitetural diferente da Spec.
9. Ao final, execute a verificação definida na Spec e na Configuração de `docs/PROCESSO.md`: lint, testes, integração quando aplicável, typecheck e build, conforme o escopo. Para testes que tocam serviços, confira o alvo conforme `ambiente-dev` e a matriz de ambientes antes de executar.
10. Compare os resultados com o baseline conhecido. Diferencie falha preexistente de regressão nova.

## Saída

- Branch com commits atômicos.
- Registro de progresso com todas as Tasks, emendas e desvios.
- Resultado da verificação, por comando.
- Evidência do ciclo visual, se houver interface.
- Roteiro de aceite manual (ver `docs/PROCESSO.md`, seção Interface).
- Declaração de que a implementação está pronta para auditoria. Não há afirmação de pronto sem os resultados.

## Não faça

- Não crie PR nesta etapa.
- Não faça squash nem merge.
- Não faça `git add -A`.
- Não altere a Spec para acomodar a implementação. Se precisar, pare e reporte.
- Não marque teste como aprovado sem executá-lo.
- Não crie ticket separado para validação visual.
- Não rode teste contra produção.
