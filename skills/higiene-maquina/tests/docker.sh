#!/usr/bin/env bash
# T6 (R10): containers, volumes e redes de uma mesma execução de teste são agrupados pela chave
# <pid>-<8 hex>, lida do nome ou do projeto do compose. Grupo com PID morto é DOCKER_ORFAO, e com
# PID vivo é DOCKER_ATIVO. Volume montado por um container do grupo entra no grupo sem a chave.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo dk

# PID de teste morto (acima do que o sistema costuma usar) e o PID vivo deste próprio teste.
MORTO=3999991
VIVO=$$

cat > "$FX_DADOS/docker_ps" <<EOF
supabase_db_esmeralda-gas-pr-d-e2e-$MORTO-0b6ae018|running|esmeralda-gas-pr-d-e2e-$MORTO-0b6ae018
tests-app-$MORTO-0b6ae018|exited|
app-de-teste-$VIVO-abcdef12|running|
neon-dev-db|running|
suso-mysql-dev|running|issue-134-processo
EOF
cat > "$FX_DADOS/docker_volumes" <<EOF
supabase_db_esmeralda-gas-pr-d-e2e-$MORTO-0b6ae018
mysql84-data
EOF
cat > "$FX_DADOS/docker_redes" <<EOF
esmeralda-gas-e2e-$MORTO-0b6ae018
esmeralda-gas-local
bridge
EOF
# O container do banco monta um volume anônimo, sem chave de execução, e o volume entra no grupo.
printf 'supabase_db_esmeralda-gas-pr-d-e2e-%s-0b6ae018\nanon-hash-1\n' "$MORTO" > "$FX_DADOS/docker_mounts_supabase_db_esmeralda-gas-pr-d-e2e-$MORTO-0b6ae018"
echo "anon-hash-1" >> "$FX_DADOS/docker_volumes"

saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)

afirmar_contem "$saida" "DOCKER_ORFAO: execução $MORTO-0b6ae018" "grupo com PID morto é órfão"
afirmar_contem "$saida" "container: supabase_db_esmeralda-gas-pr-d-e2e-$MORTO-0b6ae018" "container do grupo listado"
afirmar_contem "$saida" "container: tests-app-$MORTO-0b6ae018" "container só com a chave no nome também entra"
afirmar_contem "$saida" "volume: supabase_db_esmeralda-gas-pr-d-e2e-$MORTO-0b6ae018" "volume com a chave listado"
afirmar_contem "$saida" "volume: anon-hash-1" "volume montado pelo grupo entra mesmo sem chave"
afirmar_contem "$saida" "rede: esmeralda-gas-e2e-$MORTO-0b6ae018" "rede com a chave listada"
afirmar_contem "$saida" "DOCKER_ATIVO: execução $VIVO-abcdef12" "grupo com PID vivo é ativo"
afirmar_nao_contem "$saida" "DOCKER_ORFAO: execução $VIVO-abcdef12" "grupo ativo não é órfão"
afirmar_nao_contem "$saida" "container: neon-dev-db" "container sem chave fica fora dos grupos"
afirmar_nao_contem "$saida" "rede: esmeralda-gas-local" "rede de desenvolvimento fica fora dos grupos"
