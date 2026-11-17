---
name: abrir-pr
description: Cria a pull request de uma branch com a verificação final concluída, vinculada à issue, com o template do repositório, a seção de documentação, o roteiro de aceite manual e a evidência de verificação. Use quando a invocação pedir a PR, por implementar-spec ou diretamente.
---

# Abrir PR

Cria a PR da branch verificada. Não faz merge. Depois da criação, o fluxo segue para o review, conforme `docs/PROCESSO.md` (seção Fluxo após a PR).

Antes de agir, confira o estado real da issue e da PR no GitHub, conforme `docs/PROCESSO.md` (seção Estado real antes de agir). Se a PR estiver mesclada ou fechada, ou se outra branch ou PR estiver ligada à issue, pare e reporte, sem agir.

## Entrada

- Número da issue, branch e worktree.
- Autorização explícita para abrir a PR na invocação, dada pelo mantenedor em `implementar-spec` ou diretamente.
- Relatório da verificação final de `implementar-spec`.

## Pré-condições

1. Você está na worktree da branch, não no checkout principal.
2. `git status` limpo.
3. A branch está atualizada sobre o main remoto. Se `main` avançou, informe quantos commits e se há conflito antes de continuar.
4. A verificação final concluiu sem FAIL. Se houver FAIL, pare e reporte.

## Procedimento

1. Atualize referências: `git fetch origin --prune`.
2. Revise o diff completo contra o main remoto. Confirme que não há arquivos, credenciais, artefatos de build, dumps ou mudanças fora do escopo.
3. Calcule as linhas alteradas, excluindo arquivos gerados. Se passar de `teto_pr_linhas`, registre na descrição a justificativa e um aviso. Não bloqueie. Use o label `label_excecao_tamanho` se o mantenedor quiser registrar a exceção.
4. Escolha o vínculo com a issue:
   - última fatia, ou PR única: `Closes #<número>`;
   - fatia intermediária: `Refs #<número>`.
   - Issues relacionadas que a PR resolve também recebem `Closes`, uma por linha (`Closes #10`, `Closes #11`). Liste todas no corpo, para que o merge as feche. Confirme antes que cada uma está coberta pela PR.
5. Preencha `.github/pull_request_template.md` com o conteúdo real. Seções: Resumo, Spec, Implementação, Tarefas, Critérios de aceite, Verificação, Documentação, Roteiro de aceite manual, Limitações conhecidas e riscos residuais, Tamanho e Evidência.
6. Em **Documentação**, liste os documentos atualizados. Se a mudança não altera comportamento observável, escreva "não aplicável" e o motivo. Se o que o projeto faz mudou, atualize também a linha do README e a descrição do repositório, e registre.
7. Em **Roteiro de aceite manual**, use o roteiro produzido pela verificação final: o que foi entregue, onde testar, conta de teste pela referência de identidade, cenários e o que já foi verificado automaticamente.
8. Em **Verificação**, informe o que foi executado, com resultados. Diferencie falha preexistente de falha introduzida. Se a validação ocorreu em checkout temporário, diga isso.
9. Em mudança de interface, tente anexar as capturas das superfícies declaradas em `visual_superficies` e o resultado da autoavaliação. Se não conseguir anexar, registre na PR a pendência e siga. A falha de anexo não interrompe o fluxo. O mantenedor pode anexar depois do squash.
10. Registre explicitamente "CI não configurada" quando não houver workflow aplicável ou quando o check falhar por placeholder. Nunca registre como check passado.
11. Crie a PR com `gh pr create --body-file`, com exatamente um label `type:*`.
12. Não altere o label de aprovação. Ele já foi aplicado na Etapa 1a e registra a Spec, não a PR.

## Saída

- URL e número da PR.
- Branch de origem e de destino.
- HEAD da branch e número de commits.
- Vínculo com a issue (`Closes` ou `Refs`).
- Estado dos checks disponíveis.
- Divergência atual em relação a `main`.
- Pendências de anexo de captura, se houver.

## Não faça

- Não faça merge, squash nem fechamento manual da issue.
- Não marque como aprovado o que não rodou.
- Não inclua segredos, dumps ou dados pessoais reais na descrição.
- Não use o label de aprovação como forma de aprovar a PR.
- Não deixe a seção de documentação ou o roteiro de aceite vazios.
