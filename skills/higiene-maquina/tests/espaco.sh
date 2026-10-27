#!/usr/bin/env bash
# T5 (R11): ESPACO_LIBERAVEL conta cada arquivo uma vez, e só quando todos os seus links estão
# dentro do que a remoção apagaria. Um hard link para um store fora do conjunto (como o do pnpm)
# não entra. Uma worktree com node_modules/.pnpm recebe AVISO_STORE.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo esp
R="$FX_DIR/trabalho/esp"
mkdir -p "$FX_DIR/wt" "$FX_DIR/store"

# Artefatos ignorados (node_modules, *.bin) não aparecem no status: a worktree continua limpa.
printf 'node_modules/\n*.bin\n' > "$R/.gitignore"
git -C "$R" add .gitignore
git -C "$R" commit -q -m "ignora artefatos"
git -C "$R" push -q origin main

# Branch sem commits novos: ancestral da main, integrada e limpa -> SEGURO_REMOVER.
git -C "$R" worktree add -q -b feat/6-espaco "$FX_DIR/wt/esp" main
W="$FX_DIR/wt/esp"

head -c 1048576 /dev/urandom > "$W/proprio.bin"            # 1 MB, só nesta worktree
head -c 4194304 /dev/urandom > "$FX_DIR/store/compartilhado.bin"  # 4 MB, no store externo
ln "$FX_DIR/store/compartilhado.bin" "$W/compartilhado.bin"  # hard link para dentro da worktree
mkdir -p "$W/node_modules/.pnpm"
echo "x" > "$W/node_modules/.pnpm/marca"

saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)

afirmar_contem "$saida" "SEGURO_REMOVER: worktree $W" "a worktree integrada e limpa é segura"
afirmar_contem "$saida" "ESPACO_LIBERAVEL: 1.0 MB" "conta só o arquivo próprio, sem o hard link do store"
afirmar_nao_contem "$saida" "ESPACO_LIBERAVEL: 5.0 MB" "não soma o store compartilhado"
afirmar_contem "$saida" "AVISO_STORE: $W usa store pnpm compartilhado" "avisa quando há node_modules/.pnpm"
