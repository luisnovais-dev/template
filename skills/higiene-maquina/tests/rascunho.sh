#!/usr/bin/env bash
# T4 (R12): REQUER_DECISAO de worktree lista os pendentes, e um pendente de Spec ou documento
# (*.md, docs/, openspec/, specs/) vira RASCUNHO com a comparação com a main e com a issue.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo rs
R="$FX_DIR/trabalho/rs"
mkdir -p "$FX_DIR/wt"

# Worktree da issue 6 e worktree de uma branch sem número de issue, ambas a partir da base.
git -C "$R" worktree add -q -b feat/6-spec "$FX_DIR/wt/i6" main
git -C "$R" worktree add -q -b rascunho-sem-numero "$FX_DIR/wt/sem" main

# Documento que já está na main com o mesmo conteúdo (depois da criação das worktrees).
mkdir -p "$R/docs"
printf '# Doc da main\n\nIgual.\n' > "$R/docs/main.md"
git -C "$R" add docs/main.md
git -C "$R" commit -q -m "doc na main"
git -C "$R" push -q origin main

W="$FX_DIR/wt/i6"
mkdir -p "$W/docs" "$W/openspec"
printf '# Spec igual\n\nCorpo da spec.\n' > "$W/docs/spec-igual.md"
printf '# Titulo\n\nTexto novo, diferente da issue.\n' > "$W/docs/spec-dif.md"
printf 'Rascunho sem relação com a issue.\n' > "$W/openspec/x.md"
printf '# Doc da main\n\nIgual.\n' > "$W/docs/main.md"
printf 'codigo\n' > "$W/codigo.ts"

cat > "$FX_DADOS/gh_issue_6.txt" <<'ISSUE'
Descrição da issue.

# Spec igual

Corpo da spec.

# Titulo

Outro texto na issue.
ISSUE

W2="$FX_DIR/wt/sem"
mkdir -p "$W2/docs"
printf 'Sem número.\n' > "$W2/docs/solto.md"

saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)

afirmar_contem "$saida" "RASCUNHO: docs/spec-igual.md main=AUSENTE issue=#6 IGUAL" "rascunho igual ao corpo da issue"
afirmar_contem "$saida" "RASCUNHO: docs/spec-dif.md main=AUSENTE issue=#6 DIFERENTE" "primeira linha na issue mas conteúdo diferente"
afirmar_contem "$saida" "RASCUNHO: openspec/x.md main=AUSENTE issue=#6 AUSENTE" "conteúdo sem relação com a issue"
afirmar_contem "$saida" "RASCUNHO: docs/main.md main=IGUAL" "documento igual ao da main"
afirmar_contem "$saida" "pendente: codigo.ts (??)" "código não versionado aparece como pendente, sem RASCUNHO"
afirmar_nao_contem "$saida" "RASCUNHO: codigo.ts" "código não vira RASCUNHO"
afirmar_contem "$saida" "RASCUNHO: docs/solto.md main=AUSENTE issue=SEM_ISSUE" "branch sem número de issue"
afirmar_nao_contem "$saida" "Descrição da issue" "o conteúdo da issue nunca é impresso"
afirmar_nao_contem "$saida" "Corpo da spec" "o conteúdo do rascunho nunca é impresso"
