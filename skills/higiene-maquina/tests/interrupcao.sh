#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
# Prova que a fixture remove a pasta temporária quando o teste recebe TERM, e que a saída
# normal também a remove. Cada caso roda num bash filho, para observar a limpeza de fora.
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"

LIB="$(cd "$(dirname "$0")" && pwd)/lib/fixture.sh"

# Caso 1: termina com TERM enquanto a fixture existe.
caminho=$(bash -c '. "$1"; fixture_iniciar; echo "$FX_DIR"; kill -TERM $$; sleep 5' _ "$LIB" 2>/dev/null)
afirmar_igual "$([ -e "$caminho" ] && echo existe || echo removida)" "removida" "TERM remove a pasta temporária"

# Caso 2: termina normalmente.
caminho=$(bash -c '. "$1"; fixture_iniciar; echo "$FX_DIR"' _ "$LIB")
afirmar_igual "$([ -e "$caminho" ] && echo existe || echo removida)" "removida" "saída normal remove a pasta temporária"
