---
name: implementar-spec
description: Implementa uma Spec em worktree própria, executando as Tasks na ordem definida, com TDD por nível de teste, commits atômicos, ciclo de validação visual quando houver interface, verificação final da Spec e, quando a invocação pedir a PR, o encadeamento até o relatório do merge gate. A invocação com a Spec aprova a Spec e autoriza a implementação.
---

# Implementar Spec

Executa a Spec. A Spec é a fonte de verdade. Ao final, verifica a entrega contra a própria Spec antes de qualquer PR.

Antes de agir, confira o estado real da issue e da PR no GitHub, conforme `docs/PROCESSO.md` (seção Estado real antes de agir). Se a PR estiver mesclada ou fechada, ou se outra branch ou PR estiver ligada à issue, pare e reporte, sem agir.

## Entrada

- Número da issue, com a Spec comentada na issue.
- Invocação com a Spec: aprova a Spec e autoriza a implementação. O label de aprovação (`label_aprovacao`) é aplicado por esta skill, como descrito em `docs/PROCESSO.md`, Etapa 1a.
- Se a invocação pedir a PR (por exemplo, "implemente e abra a PR"), autoriza também a abertura da PR e o encadeamento da etapa 3 em diante. O squash continua exigindo confirmação do mantenedor.

## Pré-condições

1. A Spec está comentada na issue e não tem dependência de decisão de produto que a issue não cobre. Se tiver, pare e pergunte.
2. Você está numa worktree dedicada da issue, a partir do main remoto atualizado. Nunca no checkout principal. Antes de criar branch ou worktree, procure a que já existe para a issue (ver Procedimento, passo 0).
3. `git status` está limpo. Se houver alterações prévias, classifique cada caminho antes de qualquer ação. Não descarte nada sem determinar a origem.
4. A Configuração de `docs/PROCESSO.md` está preenchida nos valores que a Spec usa, incluindo `visual_superficies` quando houver interface. Se houver placeholder, pare e peça o valor.

## Procedimento

0. Localize o trabalho já existente da issue `<n>`:
   - `git worktree list` e `git branch --list "*<n>*"` (e a branch com o prefixo da issue);
   - se existir branch ou worktree da issue, reutilize-a, depois de confirmar que ela está no estado esperado. Não crie uma segunda branch para a mesma issue sem decisão do mantenedor;
   - se houver branch sem número da issue ligada à mesma Spec, pare e pergunte antes de qualquer ação.
   - Se não existir nada, crie a branch com o prefixo e o número da issue, por exemplo `docs/<n>-<descrição>`, em worktree própria.
1. Atualize referências: `git fetch origin --prune`. Confirme a relação da branch com o main remoto.
   - Ao criar a branch, use `git worktree add -b <branch> <caminho> origin/main --no-track`, para que ela não rastreie a `main`.
   - Publique só a própria branch, com `git push -u origin <branch>`. Nunca faça push para `main`.
2. Aplique o label de aprovação (`label_aprovacao`) na issue, se ainda não estiver aplicado. Ele registra a aprovação da Spec por esta invocação.
3. Crie o registro de progresso em `.agent/progresso.md` (não versionado). Ele é atualizado a cada Task.
4. Se o ticket pertence a um épico, escreva os casos E2E que o ticket ativa, conforme `docs/PROCESSO.md` (seção Quando um ticket precisa de E2E). E2E só entra quando o ticket muda a costura com o sistema. Caso fora da costura não vira E2E.
5. Antes de criar um mecanismo de teste ou verificação, procure o que já existe no projeto. Mecanismo novo é versionado, declarado na Configuração, documentado e genérico. Nunca crie script ou configuração por PR ou issue.
6. Para cada Task, na ordem da Spec:
   - escolha o nível do teste conforme `docs/PROCESSO.md` (seção Níveis de teste);
   - **RED:** escreva o teste do comportamento e confirme que falha pelo motivo esperado. Falha de configuração, import, fixture ou ambiente não conta.
   - **GREEN:** implemente somente o necessário.
   - **REFACTOR:** melhore mantendo os testes verdes.
   - Execute os testes da Task. Só marque a Task como concluída se os critérios de conclusão estiverem satisfeitos.
   - Atualize a documentação que a Spec lista como afetada, na mesma Task da mudança que ela descreve. Se a Task não muda comportamento observável, registre "não aplicável" e o motivo.
   - Faça commit atômico, com mensagem descritiva. Não inclua alterações não relacionadas. Adicione os arquivos por caminho explícito.
   - Registre comportamentos, testes, resultados, commits, desvios e emendas no progresso.
7. Se a Task toca interface, execute o ciclo de validação visual de `validacao-visual` **antes** de marcá-la como concluída. A evidência vai para o progresso.
8. Classifique cada decisão que surgir fora da Spec: **produto** (emenda da Spec na issue, pedida ao mantenedor), **técnica local** (registrada no progresso e depois na PR) ou **transversal** (ADR em `docs/adr/`).
9. Não pare entre Tasks. Pare somente por bloqueio real: uma premissa da Spec está errada ou há decisão que a Spec não cobre. Nesse caso, registre o conflito e pergunte. Não tome decisão arquitetural diferente da Spec.

### Verificação final

10. Execute os comandos configurados em `docs/PROCESSO.md` (lint, testes, integração, typecheck e build, conforme o escopo), os casos E2E que o ticket ativa, e as verificações da Spec. Para testes que tocam serviços, confira o alvo conforme `ambiente-dev` e a matriz de ambientes antes de executar. Comando pendente ou vazio é NOT TESTED, com o motivo.
11. Compare os resultados com o baseline conhecido. Diferencie falha preexistente de regressão nova.
12. Classifique cada Requirement, Acceptance Criterion e Task como PASS, PARTIAL, FAIL ou NOT TESTED, com evidência: arquivo, implementação e teste correspondentes. Verifique também os Requisitos de Segurança declarados na Spec, incluindo os marcados como não aplicáveis, cuja justificativa precisa constar.
13. Confirme:
    - Tasks concluídas e critérios cobertos;
    - alterações fora do escopo e alterações de esquema ou de dados não previstas na Spec;
    - documentação afetada atualizada, e a lista de documentos da Spec conferida;
    - se houver interface, a captura das superfícies declaradas em `visual_superficies` (ou a marcação "não aplicável" da Spec, com justificativa);
    - emendas registradas no progresso, separadas por classe, com aceite do mantenedor nas de produto;
    - riscos residuais e testes que não puderam ser executados.
14. Produza o roteiro de aceite manual, conforme `docs/PROCESSO.md` (seção Roteiro de aceite manual): o que foi entregue (funções, telas e rotas), onde testar, conta de teste pela referência de identidade, cenários com o resultado esperado e o que já foi verificado automaticamente.
15. Se algum item estiver FAIL, corrija na própria rodada e repita a verificação. Se a correção depende de decisão do mantenedor, pare e reporte.

### Encadeamento até a PR

16. Só se a invocação autorizou a PR e não há FAIL: execute `abrir-pr`. Depois, siga o fluxo de `docs/PROCESSO.md` (seção Fluxo após a PR): `review-pr` em subagente de contexto novo, `tratar-findings` em subagente quando houver findings, re-review, e `merge-gate` para o relatório.
17. Pare no relatório do merge gate e apresente-o ao mantenedor, com o roteiro de aceite manual. Não faça squash sem a confirmação dele.

## Saída

- Branch com commits atômicos.
- Registro de progresso com todas as Tasks, emendas e desvios.
- Resultado da verificação final, item por item, e resultado de cada comando.
- Evidência do ciclo visual, se houver interface, ou a pendência registrada.
- Roteiro de aceite manual.
- Se autorizada, a PR e o relatório do merge gate. Caso contrário, a declaração de que a implementação está pronta para abrir PR, com o que falta.

## Não faça

- Não crie PR sem a autorização da invocação.
- Não faça squash nem merge sem a confirmação do mantenedor.
- Não faça `git add -A`.
- Não altere a Spec para acomodar a implementação. Se precisar, pare e reporte.
- Não marque teste como aprovado sem executá-lo.
- Não crie ticket separado para validação visual.
- Não rode teste contra produção.
- Não abra PR com item FAIL.
