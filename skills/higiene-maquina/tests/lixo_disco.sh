#!/usr/bin/env bash
# T2 (R14, R16): LIXO nunca é arquivo versionado, e AVISO_DISCO aparece acima do limite.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo lx
R="$FX_DIR/trabalho/lx"

echo "registro versionado" > "$R/debug.log"
git -C "$R" add debug.log
git -C "$R" commit -q -m "log versionado"
git -C "$R" push -q origin main
echo "temporário" > "$R/_tmp1"

saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)
afirmar_contem "$saida" "LIXO: _tmp1" "temporário não versionado é LIXO"
afirmar_nao_contem "$saida" "LIXO: debug.log" "arquivo versionado nunca é LIXO"

echo 91 > "$FX_DADOS/df_uso"
saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)
afirmar_contem "$saida" "AVISO_DISCO" "disco a 91% gera aviso"

echo 90 > "$FX_DADOS/df_uso"
saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)
afirmar_nao_contem "$saida" "AVISO_DISCO" "disco a 90% não gera aviso (limite é acima de 90)"
