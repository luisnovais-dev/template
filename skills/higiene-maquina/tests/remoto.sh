#!/usr/bin/env bash
# T8 (R15): o inventário roda como script vindo da entrada padrão (como em
# ssh <host> 'bash -s' < inventario.sh), sem arquivo auxiliar, e dá a mesma saída que a execução local.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo rem
echo "lixo" > "$FX_DIR/trabalho/rem/_tmp1"

local_saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)
remota_saida=$(bash -s -- "$FX_DIR/trabalho" < "$INV" 2>&1)

afirmar_igual "$remota_saida" "$local_saida" "execução por entrada padrão igual à local"
afirmar_contem "$remota_saida" "LIXO: _tmp1" "a execução remota classifica como a local"
