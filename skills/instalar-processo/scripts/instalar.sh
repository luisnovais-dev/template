#!/usr/bin/env bash
# Instala as skills do processo por máquina, por links, a partir de um clone do template.
#
# Uso:
#   instalar.sh                 mostra o plano (somente leitura, não altera nada)
#   instalar.sh --aplicar       aplica o plano (cria clone, se preciso, e os links)
#   instalar.sh --atualizar     atualiza o clone (fast-forward) e aplica o plano
#
# Variáveis (para testes e outras máquinas):
#   ONLUIS_TEMPLATE_DIR   clone do instalador (padrão: $HOME/.local/share/onluis-dev/template)
#   ONLUIS_TEMPLATE_REPO  URL do template (padrão: https://github.com/onluis-dev/template.git)
#   ONLUIS_TEMPLATE_REF   referência remota (padrão: origin/main)
#
# Destinos: $HOME/.agents/skills (Codex, OpenCode, Hermes) e $HOME/.claude/skills (Claude).
# Nunca sobrescreve uma skill existente que não seja link deste clone. Nunca apaga nada.
# Não altera ~/.hermes/config.yaml: só mostra o trecho a incluir.
# Não imprime valores de segredo: só caminhos e contagens.

set -u

MODO="plano"
case "${1:-}" in
  "") MODO="plano" ;;
  --aplicar) MODO="aplicar" ;;
  --atualizar) MODO="atualizar" ;;
  *) echo "Uso: $0 [--aplicar|--atualizar]"; exit 64 ;;
esac

CLONE="${ONLUIS_TEMPLATE_DIR:-$HOME/.local/share/onluis-dev/template}"
REPO="${ONLUIS_TEMPLATE_REPO:-https://github.com/onluis-dev/template.git}"
REF="${ONLUIS_TEMPLATE_REF:-origin/main}"
DEST_AGENTS="$HOME/.agents/skills"
DEST_CLAUDE="$HOME/.claude/skills"
HERMES_CFG="$HOME/.hermes/config.yaml"

echo "Modo: $MODO"
echo "Clone do instalador: $CLONE"

# 1. Clone do instalador.
if [ ! -d "$CLONE/.git" ]; then
  if [ "$MODO" = "plano" ]; then
    echo "Plano: clonar $REPO em $CLONE"
    CLONE_EXISTE=0
  else
    echo "Clonando $REPO em $CLONE"
    mkdir -p "$(dirname "$CLONE")"
    if ! git clone --quiet "$REPO" "$CLONE"; then
      echo "ERRO: falha ao clonar"
      exit 1
    fi
    CLONE_EXISTE=1
  fi
else
  CLONE_EXISTE=1
  if [ "$MODO" = "atualizar" ]; then
    git -C "$CLONE" fetch --quiet origin --prune || { echo "ERRO: falha no fetch"; exit 1; }
    if ! git -C "$CLONE" merge --ff-only --quiet "$REF"; then
      echo "ERRO: o clone do instalador não avança em fast-forward. Não foi alterado. Resolva manualmente."
      exit 1
    fi
    echo "Clone atualizado para $(git -C "$CLONE" rev-parse --short HEAD)"
  fi
fi

if [ "$CLONE_EXISTE" -eq 0 ]; then
  echo "Plano concluído: não há skills para listar até o clone existir."
  exit 0
fi

FONTE="$CLONE/skills"
if [ ! -d "$FONTE" ]; then
  echo "ERRO: $FONTE não existe. O clone não é o template de processo."
  exit 1
fi

# Skills do processo: pastas em skills/ que têm SKILL.md.
SKILLS=""
for pasta in "$FONTE"/*/; do
  nome=$(basename "$pasta")
  [ -f "$pasta/SKILL.md" ] && SKILLS="$SKILLS $nome"
done

# 2. Verificação prévia de conflitos (antes de qualquer alteração).
CONFLITOS=0
for destino in "$DEST_AGENTS" "$DEST_CLAUDE"; do
  [ -d "$destino" ] || continue
  for nome in $SKILLS; do
    alvo="$destino/$nome"
    if [ -e "$alvo" ] || [ -L "$alvo" ]; then
      if [ -L "$alvo" ] && [ "$(readlink -f "$alvo")" = "$(readlink -f "$FONTE/$nome")" ]; then
        continue
      fi
      echo "CONFLITO: $alvo já existe e não é link deste clone. Nada foi alterado."
      CONFLITOS=$((CONFLITOS + 1))
    fi
  done
done

# Skills de usuário fora do processo (informativo: ex. GentleAI). Não são apagadas.
for destino in "$DEST_AGENTS" "$DEST_CLAUDE"; do
  [ -d "$destino" ] || continue
  for alvo in "$destino"/*; do
    [ -e "$alvo" ] || [ -L "$alvo" ] || continue
    nome=$(basename "$alvo")
    case " $SKILLS " in *" $nome "*) continue ;; esac
    echo "Outra skill de usuário: $alvo (candidata a aposentar; não é removida por este script)"
  done
done

if [ "$CONFLITOS" -gt 0 ]; then
  echo "Parado: $CONFLITOS conflito(s). Resolva antes de aplicar."
  exit 2
fi

# 3. Plano ou aplicação dos links.
for destino in "$DEST_AGENTS" "$DEST_CLAUDE"; do
  # Claude só é instalado se o harness existir. O caminho ~/.agents é comum a Codex, OpenCode e Hermes, e é criado.
  if [ "$destino" = "$DEST_CLAUDE" ] && [ ! -d "$HOME/.claude" ]; then
    echo "Harness Claude ausente: $HOME/.claude não existe. Pulado."
    continue
  fi
  for nome in $SKILLS; do
    alvo="$destino/$nome"
    if [ -L "$alvo" ]; then
      continue
    fi
    if [ "$MODO" = "plano" ]; then
      echo "Plano: criar link $alvo -> $FONTE/$nome"
    else
      mkdir -p "$destino" && ln -s "$FONTE/$nome" "$alvo" && echo "Criado: $alvo"
    fi
  done
done

# 4. Hermes: só mostra o trecho a incluir.
if [ -f "$HERMES_CFG" ]; then
  if grep -q '\.agents/skills' "$HERMES_CFG"; then
    echo "Hermes: $HERMES_CFG já referencia ~/.agents/skills. Nada a fazer."
  else
    echo "Hermes: para ler as skills, inclua em $HERMES_CFG (não alterado por este script):"
    echo "  skills:"
    echo "    external_dirs:"
    echo "      - ~/.agents/skills"
  fi
else
  echo "Hermes: $HERMES_CFG ausente ou inválido. Nada foi criado nem alterado."
fi

if [ "$MODO" = "plano" ]; then
  echo "Plano apresentado. Nada foi alterado. Rode com --aplicar para aplicar."
else
  echo "Concluído."
fi
exit 0
