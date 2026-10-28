#!/usr/bin/env bash
# F2 (review da PR #7): processo cujo cwd não pode ser lido pode estar dentro da worktree. Então a
# remoção é recusada com código 2 (não verificado). Thread do kernel e zumbi (sem cmdline) não
# contam. A árvore de processos vem de HIGIENE_PROC, que aponta para uma pasta falsa no teste.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo cw
R="$FX_DIR/trabalho/cw"
mkdir -p "$FX_DIR/wt"
git -C "$R" worktree add -q -b feat/6-cw "$FX_DIR/wt/cw" main
W="$FX_DIR/wt/cw"

PROC="$FX_DIR/proc"
mkdir -p "$PROC/self" "$PROC/100" "$PROC/101"
# 100: processo de outro usuário. Tem cmdline, mas o cwd não pode ser lido.
printf 'daemon\0' > "$PROC/100/cmdline"
# 101: thread do kernel. Sem cmdline e sem cwd: não está em lugar nenhum.
: > "$PROC/101/cmdline"

lista="$FX_DADOS/lista.tsv"
printf 'SEGURO_REMOVER\tworktree\t%s\t%s\n' "$R" "$W" > "$lista"

rc=0
saida=$(HIGIENE_PROC="$PROC" bash "$INV" --remover "$lista" 2>&1) || rc=$?
afirmar_igual "$rc" "3" "cwd ilegível de processo com cmdline recusa a remoção"
afirmar_contem "$saida" "RECUSADO: worktree $W: processo com diretório dentro, ou não verificado (código 2)" "a recusa diz que não foi verificado"
afirmar_igual "$([ -d "$W" ] && echo existe || echo removida)" "existe" "a worktree continua no lugar"

# Sem o processo de outro usuário, só a thread do kernel: a remoção segue.
rm -rf "$PROC/100"
rc=0
saida=$(HIGIENE_PROC="$PROC" bash "$INV" --remover "$lista" 2>&1) || rc=$?
afirmar_igual "$rc" "0" "thread do kernel sem cwd não impede a remoção"
afirmar_contem "$saida" "REMOVIDO: worktree $W" "a worktree sai quando só há thread do kernel"
exit 0
