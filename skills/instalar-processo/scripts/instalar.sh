#!/usr/bin/env bash
# Instala as skills do processo por máquina, por links, a partir de um clone do template.
#
# Uso:
#   instalar.sh                 mostra o plano (somente leitura, não altera nada)
#   instalar.sh --aplicar       aplica o plano (cria clone, se preciso, e os links)
#   instalar.sh --atualizar     atualiza o clone (fast-forward) e aplica o plano
#   --aposentar                 com --aplicar: copia as outras skills de usuário para a raiz de aposentados
#   --remover-originais         com --aplicar --aposentar: remove do diretório ativo o original
#                               cuja cópia foi conferida (use só com a lista confirmada pelo mantenedor)
#
# Variáveis (para testes e outras máquinas):
#   ONLUIS_TEMPLATE_DIR   clone do instalador (padrão: $HOME/.local/share/onluis-dev/template)
#   ONLUIS_TEMPLATE_REPO  URL do template (padrão: https://github.com/onluis-dev/template.git)
#   ONLUIS_TEMPLATE_REF   referência remota (padrão: origin/main)
#
# Destinos: $HOME/.agents/skills (Codex, OpenCode, Hermes) e $HOME/.claude/skills (Claude).
# Nunca sobrescreve uma skill existente que não seja link deste clone. Só remove um original
# com --remover-originais, depois de conferir a cópia em aposentados.
# Não altera ~/.hermes/config.yaml: só mostra o trecho a incluir.
# Não imprime valores de segredo: só caminhos e contagens.

set -u

MODO="plano"
APOSENTAR=0
REMOVER=0
for arg in "$@"; do
  case "$arg" in
    --aplicar) MODO="aplicar" ;;
    --atualizar) MODO="atualizar" ;;
    --aposentar) APOSENTAR=1 ;;
    --remover-originais) REMOVER=1 ;;
    *) echo "Uso: $0 [--aplicar|--atualizar] [--aposentar [--remover-originais]]"; exit 64 ;;
  esac
done
if [ "$REMOVER" -eq 1 ] && { [ "$APOSENTAR" -eq 0 ] || [ "$MODO" != "aplicar" ]; }; then
  echo "Uso: --remover-originais exige --aplicar --aposentar"; exit 64
fi
# Raiz de aposentados: fora do repositório, configurada na Configuração de docs/PROCESSO.md (raiz_aposentados).
APOSENTADOS="${ONLUIS_APOSENTADOS_DIR:-$HOME/.local/share/onluis-dev/aposentados}"

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

# Sem clone (só no plano), as skills do processo não são conhecidas: a varredura
# de skills de usuário e o Hermes continuam, e nenhum link é planejado.
SKILLS=""
FONTE=""
if [ "$CLONE_EXISTE" -eq 0 ]; then
  echo "Clone ausente: a lista de links aparecerá depois de --aplicar. Skills de usuário são listadas abaixo."
else
  FONTE="$CLONE/skills"
  if [ ! -d "$FONTE" ]; then
    echo "ERRO: $FONTE não existe. O clone não é o template de processo."
    exit 1
  fi
  # Skills do processo: pastas em skills/ que têm SKILL.md.
  for pasta in "$FONTE"/*/; do
    nome=$(basename "$pasta")
    [ -f "$pasta/SKILL.md" ] && SKILLS="$SKILLS $nome"
  done
fi

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

# Skills de usuário fora do processo (ex.: GentleAI) em todos os diretórios conhecidos.
# Uma skill é uma pasta (ou link) com SKILL.md. No Hermes, as skills ficam em pastas de
# categoria e muitas vêm com o próprio Hermes: lá, só é candidata a skill cujo nome também
# aparece num dos outros diretórios (pacote instalado em vários harnesses).
eh_do_processo() {
  local alvo="$1" nome
  nome=$(basename "$alvo")
  [ -n "$FONTE" ] && [ -L "$alvo" ] && [ "$(readlink -f "$alvo")" = "$(readlink -f "$FONTE/$nome" 2>/dev/null)" ]
}
OUTRAS=()
NOMES_FORA=" "
for destino in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills" "$HOME/.config/opencode/skills"; do
  [ -d "$destino" ] || continue
  for alvo in "$destino"/*; do
    [ -e "$alvo" ] || [ -L "$alvo" ] || continue
    [ -f "$alvo/SKILL.md" ] || continue
    eh_do_processo "$alvo" && continue
    OUTRAS+=("$alvo")
    NOMES_FORA="$NOMES_FORA$(basename "$alvo") "
  done
done
HERMES_PROPRIAS=0
if [ -d "$HOME/.hermes/skills" ]; then
  while IFS= read -r skill_md; do
    alvo=$(dirname "$skill_md")
    case "$NOMES_FORA" in
      *" $(basename "$alvo") "*) OUTRAS+=("$alvo") ;;
      *) HERMES_PROPRIAS=$((HERMES_PROPRIAS + 1)) ;;
    esac
  done < <(find -L "$HOME/.hermes/skills" -mindepth 2 -maxdepth 3 -name SKILL.md 2>/dev/null)
fi
for alvo in "${OUTRAS[@]}"; do
  echo "Outra skill de usuário: $alvo (candidata a aposentar)"
done
[ "$HERMES_PROPRIAS" -gt 0 ] && echo "Hermes: $HERMES_PROPRIAS skill(s) próprias do Hermes ignoradas (não são candidatas)."

if [ "$APOSENTAR" -eq 1 ] && [ "$MODO" = "aplicar" ] && [ "${#OUTRAS[@]}" -gt 0 ]; then
  for alvo in "${OUTRAS[@]}"; do
    rel="${alvo#"$HOME"/}"
    copia="$APOSENTADOS/$rel"
    if [ -e "$copia" ]; then
      echo "Aposentados: já existe $copia. Não sobrescrito."
    else
      mkdir -p "$(dirname "$copia")" && cp -R -L "$alvo" "$copia" && echo "Cópia em aposentados: $copia"
    fi
    if [ "$REMOVER" -eq 1 ]; then
      if [ -e "$copia" ] && diff -rq "$alvo/" "$copia/" >/dev/null 2>&1; then
        if [ -L "$alvo" ]; then
          rm "$alvo" && echo "Removido do diretório ativo (link): $alvo"
        else
          rm -r "$alvo" && echo "Removido do diretório ativo: $alvo"
        fi
      else
        echo "Mantido: $alvo (cópia ausente ou diferente; nada removido)"
      fi
    fi
  done
fi

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
