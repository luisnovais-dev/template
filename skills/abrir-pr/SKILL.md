---
name: abrir-pr
description: Cria a pull request de uma branch auditada e aceita pelo mantenedor, vinculada à issue, com o template do repositório, a seção de documentação, o roteiro de aceite manual e a evidência de verificação. Use somente após o aceite local do mantenedor.
---

# Abrir PR

Cria a PR da branch auditada. Não faz merge.

## Entrada

- Número da issue, branch e worktree.
- Autorização explícita para abrir a PR na invocação.
- Aceite local do mantenedor registrado na conversa.

## Pré-condições

1. Você está na worktree da branch, não no checkout principal.
2. `git status` limpo.
3. A branch está atualizada sobre o main remoto. Se `main` avançou, informe quantos commits e se há conflito antes de continuar.
4. A auditoria (`auditar-spec`) concluiu pronto para aceite, e o aceite local do mantenedor foi dado.

## Procedimento

1. Atualize referências: `git fetch origin --prune`.
2. Revise o diff completo contra o main remoto. Confirme que não há arquivos, credenciais, artefatos de build, dumps ou mudanças fora do escopo.
3. Calcule as linhas alteradas, excluindo arquivos gerados. Se passar de `teto_pr_linhas`, use o label `label_excecao_tamanho` e registre a justificativa.
4. Escolha o vínculo com a issue:
   - última fatia, ou PR única: `Closes #<número>`;
   - fatia intermediária: `Refs #<número>`.
5. Preencha `.github/pull_request_template.md` com o conteúdo real. Seções: Resumo, Spec, Implementação, Tarefas, Critérios de aceite, Verificação, Documentação, Roteiro de aceite manual, Limitações conhecidas e riscos residuais, Tamanho e Evidência.
6. Em **Documentação**, liste os documentos atualizados. Se a mudança não altera funcionalidade, escreva "não aplicável" e o motivo. Se o que o projeto faz mudou, atualize também a linha do README e a descrição do repositório, e registre.
7. Em **Roteiro de aceite manual**, use o roteiro produzido pela auditoria: o que foi entregue, onde testar, conta de teste pela referência de identidade, cenários e o que já foi verificado automaticamente.
8. Em **Verificação**, informe o que foi executado, com resultados. Diferencie falha preexistente de falha introduzida. Se a validação ocorreu em checkout temporário, diga isso. Em mudança de interface, anexe as capturas desktop e mobile e o resultado da autoavaliação.
9. Registre explicitamente "CI não configurada" quando não houver workflow aplicável. Nunca registre como check passado.
10. Crie a PR com `gh pr create --body-file`, com exatamente um label `type:*`.
11. Se o projeto exigir o label de aprovação, adicione-o somente com autorização explícita. Ele registra a aprovação da Spec, não da PR.

## Saída

- URL e número da PR.
- Branch de origem e de destino.
- HEAD da branch e número de commits.
- Vínculo com a issue (`Closes` ou `Refs`).
- Estado dos checks disponíveis.
- Divergência atual em relação a `main`.

## Não faça

- Não faça merge, squash nem fechamento manual da issue.
- Não marque como aprovado o que não rodou.
- Não inclua segredos, dumps ou dados pessoais reais na descrição.
- Não use o label de aprovação como forma de aprovar a PR.
- Não deixe a seção de documentação ou o roteiro de aceite vazios.
