#!/bin/sh
# Executa os comandos de verificação configurados em docs/PROCESSO.md (Configuração, bloco comandos).
# Ordem: lint, typecheck, test, integracao, build, smoke. Valor vazio ou com placeholder (<!--) é pulado.
# e2e não entra: os casos E2E rodam nos tickets que os ativam (ver docs/PROCESSO.md, Quando um ticket precisa de E2E).
# Sai com código diferente de zero se algum comando falhar, ou se nenhum estiver configurado.
set -u

PROCESSO="${CI_PROCESSO:-docs/PROCESSO.md}"

if [ ! -f "$PROCESSO" ]; then
  echo "ERRO: $PROCESSO não encontrado" >&2
  exit 1
fi

# Imprime chave<TAB>valor do bloco comandos (primeiro bloco yaml da Configuração).
extrair_comandos() {
  awk '
    /^```yaml/ { em_yaml = 1; next }
    /^```/ && em_yaml { em_yaml = 0; em_comandos = 0; next }
    em_yaml && /^comandos:/ { em_comandos = 1; next }
    em_yaml && em_comandos && /^[^ #]/ { em_comandos = 0 }
    em_yaml && em_comandos && /^  [A-Za-z_]+:/ {
      linha = $0
      sub(/^  /, "", linha)
      chave = linha
      sub(/:.*/, "", chave)
      valor = linha
      sub(/^[^:]*:[ \t]*/, "", valor)
      sub(/[ \t]+#.*$/, "", valor)
      print chave "\t" valor
    }
  ' "$PROCESSO"
}

comandos=$(extrair_comandos)
executados=0
falhas=0

for chave in lint typecheck test integracao build smoke; do
  valor=$(printf '%s\n' "$comandos" | awk -F '\t' -v k="$chave" '$1 == k { print $2; exit }')
  case "$valor" in
    ""|"<!--"*|pendente)
      echo "PULADO $chave: sem comando configurado"
      continue
      ;;
  esac
  executados=$((executados + 1))
  echo "==> $chave: $valor"
  if ! sh -c "$valor"; then
    echo "FALHOU $chave" >&2
    falhas=$((falhas + 1))
  fi
done

if [ "$executados" -eq 0 ]; then
  echo "ERRO: nenhum comando de verificação configurado em $PROCESSO" >&2
  exit 1
fi

if [ "$falhas" -gt 0 ]; then
  echo "ERRO: $falhas comando(s) falharam" >&2
  exit 1
fi

echo "OK: $executados comando(s) executados sem falha"
