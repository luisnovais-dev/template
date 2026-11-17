#!/usr/bin/env bash
# Prova que instalar.sh --atualizar lista, e que --atualizar --aplicar remove, só os links
# órfãos do clone do template: links que apontam para uma pasta de skills/ que não existe mais.
# Preserva o que não é órfão: link para skill atual, link de fora do clone (válido ou quebrado),
# pasta comum com SKILL.md e a criação dos links que faltam.
# Usa HOME e ONLUIS_TEMPLATE_DIR temporários. Nunca toca o HOME real.

set -u

RAIZ=$(cd "$(dirname "$0")/../../.." && pwd)
INSTALAR="$RAIZ/skills/instalar-processo/scripts/instalar.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM HUP

FALHAS=0
ok() { echo "ok: $1"; }
falha() { echo "FALHA: $1"; FALHAS=$((FALHAS + 1)); }

export HOME="$TMP/home"
export ONLUIS_TEMPLATE_DIR="$TMP/clone"
mkdir -p "$HOME/.claude" "$HOME/.agents/skills"

# Template de semente: origem bare e clone de trabalho do instalador.
SEMEADURA="$TMP/semeadura"
ORIGEM="$TMP/origem.git"
mkdir -p "$SEMEADURA/skills/alpha" "$SEMEADURA/skills/beta"
echo "# alpha" > "$SEMEADURA/skills/alpha/SKILL.md"
echo "# beta" > "$SEMEADURA/skills/beta/SKILL.md"
git -C "$SEMEADURA" init -q -b main
git -C "$SEMEADURA" add skills
git -C "$SEMEADURA" -c user.name=teste -c user.email=teste@teste.invalid commit -q -m base
git init -q --bare "$ORIGEM"
git --git-dir="$ORIGEM" symbolic-ref HEAD refs/heads/main
git -C "$SEMEADURA" push -q "$ORIGEM" main
git clone -q "$ORIGEM" "$ONLUIS_TEMPLATE_DIR" || { falha "clone de semeadura"; exit 1; }

# Estado inicial da máquina:
# - alpha: link atual para o clone (deve ficar);
# - gamma: link para pasta que saiu de skills/ (órfão);
# - externo: link válido para fora do clone (deve ficar);
# - quebrado: link quebrado para fora do clone (deve ficar);
# - real: pasta comum com SKILL.md, não é link (deve ficar).
mkdir -p "$HOME/.claude/skills" "$TMP/fora/skill-externa"
ln -s "$ONLUIS_TEMPLATE_DIR/skills/alpha" "$HOME/.claude/skills/alpha"
ln -s "$ONLUIS_TEMPLATE_DIR/skills/gamma" "$HOME/.agents/skills/gamma"
ln -s "$TMP/fora/skill-externa" "$HOME/.claude/skills/externo"
ln -s "$TMP/fora/inexistente" "$HOME/.agents/skills/quebrado"
mkdir -p "$HOME/.agents/skills/real"
echo "# real" > "$HOME/.agents/skills/real/SKILL.md"

# 1. --atualizar: lista o órfão, não remove, cria o link que falta (beta).
saida=$(bash "$INSTALAR" --atualizar 2>&1)
if [ -L "$HOME/.agents/skills/gamma" ]; then ok "--atualizar não remove o órfão"; else falha "--atualizar removeu o órfão sem --aplicar"; fi
case "$saida" in
  *"Órfão:"*"gamma"*) ok "--atualizar lista o órfão no plano" ;;
  *) falha "--atualizar não listou o órfão"; echo "$saida" | sed 's/^/  /' ;;
esac
if [ -L "$HOME/.claude/skills/beta" ]; then ok "criação de link que falta preservada"; else falha "link beta não foi criado"; fi

# 2. --atualizar --aplicar: remove só o órfão.
saida=$(bash "$INSTALAR" --atualizar --aplicar 2>&1)
if [ ! -e "$HOME/.agents/skills/gamma" ] && [ ! -L "$HOME/.agents/skills/gamma" ]; then
  ok "--atualizar --aplicar remove o link órfão"
else
  falha "link órfão gamma continua existindo após --aplicar"
  echo "$saida" | sed 's/^/  /'
fi
case "$saida" in
  *"Removido:"*"gamma"*) ok "saída informa a remoção do órfão" ;;
  *) falha "saída não informa a remoção do órfão" ;;
esac

# 3. O que não é órfão do clone permanece intacto.
[ -L "$HOME/.claude/skills/alpha" ] && [ "$(readlink "$HOME/.claude/skills/alpha")" = "$ONLUIS_TEMPLATE_DIR/skills/alpha" ] \
  && ok "link de skill atual preservado" || falha "link de skill atual alterado ou removido"
[ -L "$HOME/.claude/skills/externo" ] && ok "link externo válido preservado" || falha "link externo removido"
[ -L "$HOME/.agents/skills/quebrado" ] && ok "link externo quebrado preservado" || falha "link externo quebrado removido"
[ -f "$HOME/.agents/skills/real/SKILL.md" ] && ok "pasta comum preservada" || falha "pasta comum removida"
[ -f "$ONLUIS_TEMPLATE_DIR/skills/alpha/SKILL.md" ] && ok "destino do link no clone preservado" || falha "destino no clone removido"

if [ "$FALHAS" -eq 0 ]; then
  echo "OK: teste de links órfãos"
  exit 0
fi
echo "$FALHAS falha(s) no teste de links órfãos"
exit 1
