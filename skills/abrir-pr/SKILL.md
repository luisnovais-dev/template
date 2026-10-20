---
name: abrir-pr
description: Cria a pull request de uma branch auditada e aceita pelo mantenedor, vinculada à issue, com o template do repositório e a evidência de verificação. Use somente após o aceite local do mantenedor.
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

## Procedimento

1. Atualize referências: `git fetch origin --prune`.
2. Revise o diff completo contra o main remoto. Confirme que não há arquivos, credenciais, artefatos de build, dumps ou mudanças fora do escopo.
3. Calcule as linhas alteradas, excluindo arquivos gerados. Se passar do teto da configuração, use o label `size:exception` e registre a justificativa.
4. Preencha `.github/pull_request_template.md` com o conteúdo real: Summary, Spec, Implementation, Tasks, Acceptance Criteria, Verification, Manual Acceptance, Known Limitations, Size e Evidence.
5. Em Verification, informe o que foi executado, com resultados. Diferencie falha preexistente de falha introduzida. Se a validação ocorreu em checkout temporário, diga isso.
6. Registre explicitamente "CI não configurada" quando não houver workflow aplicável. Nunca registre como check passado.
7. Use `Closes #<número>` no corpo.
8. Crie a PR com `gh pr create --body-file`, com exatamente um label `type:*`.
9. Se o repositório exigir, adicione o label de aprovação da configuração, somente com autorização explícita.

## Saída

- URL e número da PR.
- Branch de origem e de destino.
- HEAD da branch e número de commits.
- Estado dos checks disponíveis.
- Divergência atual em relação a `main`.

## Não faça

- Não faça merge, squash nem fechamento da issue.
- Não marque como aprovado o que não rodou.
- Não inclua segredos, dumps ou dados pessoais reais na descrição.
- Não aplique o label `status:approved` como forma de aprovar a PR. Ele registra a aprovação da Spec.
