#!/usr/bin/env bash
# Worktree com submódulo: o git não a remove, então o inventário não a propõe como SEGURO_REMOVER,
# e o --remover recusa com a indicação do procedimento de docs/PROCESSO.md. A worktree continua no lugar.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

g() { git -c protocol.file.allow=always "$@"; }

fixture_iniciar
fixture_repo_novo sm
R="$FX_DIR/trabalho/sm"
SUB="$FX_DIR/sub"
W="$FX_DIR/wt/com-sub"

git init -q -b main "$SUB"
echo "submódulo" > "$SUB/s.txt"
git -C "$SUB" add s.txt
git -C "$SUB" commit -q -m "submódulo"

g -C "$R" submodule add -q "$SUB" third
git -C "$R" commit -q -m "adiciona submódulo"
git -C "$R" push -q origin main

# Worktree limpa, integrada (sem commits além da main) e com o submódulo inicializado.
git -C "$R" worktree add -q -b feat/7-sub "$W" main
g -C "$W" submodule update --init -q

saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)
afirmar_contem "$saida" "REQUER_DECISAO: worktree $W" "worktree com submódulo não é proposta como segura"
afirmar_contem "$saida" "SUBMODULO:" "o inventário indica o procedimento de submódulo"
afirmar_nao_contem "$saida" "SEGURO_REMOVER"$'\t'"worktree"$'\t'"$R"$'\t'"$W" "a worktree não sai na lista de remoção"

printf 'SEGURO_REMOVER\tworktree\t%s\t%s\n' "$R" "$W" > "$FX_DADOS/lista.tsv"
rc=0
saida_rm=$(bash "$INV" --remover "$FX_DADOS/lista.tsv" 2>&1) || rc=$?
afirmar_igual "$rc" "3" "lista com worktree de submódulo sai com código 3"
afirmar_contem "$saida_rm" "RECUSADO: worktree $W: contém submódulo" "--remover recusa a worktree com submódulo"
afirmar_igual "$(test -e "$W/.git" && echo sim)" "sim" "a worktree continua no lugar após a recusa"
