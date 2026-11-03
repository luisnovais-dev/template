#!/usr/bin/env bash
# Roda os testes automatizados do template: todo skills/*/tests/*.sh.
#
# Uso: scripts/testar-template.sh [diretório-raiz]
#   Sem argumento, usa o repositório atual. Com argumento, roda a árvore indicada.
#
# Cada teste roda num processo bash próprio e passa se sair com 0. Um teste que falha
# mostra a saída completa. Código 0 se todos passarem, 1 caso contrário ou se não houver teste.

set -u

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT" || exit 1

TOTAL=0
FALHAS=0
for teste in skills/*/tests/*.sh; do
  [ -e "$teste" ] || continue
  TOTAL=$((TOTAL + 1))
  if saida=$(bash "$teste" 2>&1); then
    echo "PASSOU: $teste"
  else
    FALHAS=$((FALHAS + 1))
    echo "FALHOU: $teste"
    printf '%s\n' "$saida" | sed 's/^/  /'
  fi
done

if [ "$TOTAL" -eq 0 ]; then
  echo "FALHA: nenhum teste encontrado em skills/*/tests/"
  exit 1
fi
if [ "$FALHAS" -eq 0 ]; then
  echo "OK: $TOTAL teste(s) sem falhas"
  exit 0
fi
echo "$FALHAS de $TOTAL teste(s) falharam"
exit 1
