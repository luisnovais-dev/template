#!/usr/bin/env bash
# Registro de trabalho em .agent/ (ignorado pelo git) nunca é seguro para remover: é trabalho
# não publicado. A worktree com esse registro é REQUER_DECISAO, e o modo --remover a recusa.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo ag
R="$FX_DIR/trabalho/ag"
mkdir -p "$FX_DIR/wt"
printf '.agent/\n' > "$R/.gitignore"
git -C "$R" add .gitignore
git -C "$R" commit -q -m "ignora registro"
git -C "$R" push -q origin main

git -C "$R" worktree add -q -b feat/6-ag "$FX_DIR/wt/ag" main
W="$FX_DIR/wt/ag"
mkdir -p "$W/.agent"
echo "decisão registrada, nunca commitada" > "$W/.agent/decisoes.md"

saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)
afirmar_contem "$saida" "REQUER_DECISAO: worktree $W" "worktree com registro .agent não é segura"
afirmar_nao_contem "$saida" "SEGURO_REMOVER: worktree $W" "registro .agent impede SEGURO_REMOVER"

lista="$FX_DADOS/lista.tsv"
printf 'SEGURO_REMOVER\tworktree\t%s\t%s\n' "$R" "$W" > "$lista"
rc=0
saida_rm=$(bash "$INV" --remover "$lista" 2>&1) || rc=$?
afirmar_igual "$rc" "3" "o modo --remover recusa a worktree"
afirmar_contem "$saida_rm" "RECUSADO: worktree $W: registro .agent" "a recusa diz o motivo"
afirmar_igual "$([ -f "$W/.agent/decisoes.md" ] && echo existe || echo removido)" "existe" "o registro continua no disco"
