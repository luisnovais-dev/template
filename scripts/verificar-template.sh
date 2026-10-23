#!/usr/bin/env bash
# Verifica a consistência do template de processo.
#
# Uso: scripts/verificar-template.sh [diretório-raiz]
#   Sem argumento, verifica o repositório atual. Com argumento, verifica a árvore
#   indicada (usado nos testes com casos quebrados em diretório temporário).
#
# Saída: uma linha por falha. Código 0 se não houver falhas, 1 caso contrário.

set -u

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT" || exit 1

FALHAS=0

falha() {
  echo "FALHA: $1"
  FALHAS=$((FALHAS + 1))
}

# 1. Links relativos em Markdown devem resolver.
verificar_links() {
  local arq dir alvo
  while IFS= read -r arq; do
    dir=$(dirname "$arq")
    # Destinos no formato ](destino), sem URLs, âncoras puras, e-mails nem caminhos absolutos.
    while IFS= read -r alvo; do
      alvo="${alvo#](}"
      alvo="${alvo%)}"
      case "$alvo" in
        http://*|https://*|mailto:*|\#*|'') continue ;;
      esac
      alvo="${alvo%%#*}"
      [ -z "$alvo" ] && continue
      if [ ! -e "$dir/$alvo" ]; then
        falha "link quebrado em $arq -> $alvo"
      fi
    done < <(grep -oE '\]\([^)]+\)' "$arq" 2>/dev/null)
  done < <(git ls-files '*.md' 2>/dev/null || find . -name '*.md' -not -path './.git/*')
}

# 2. YAML dos formulários e do manifesto de labels deve ser válido.
verificar_yaml() {
  local arq
  command -v python3 >/dev/null 2>&1 || { falha "python3 ausente (necessário para validar YAML)"; return; }
  for arq in .github/ISSUE_TEMPLATE/*.yml .github/labels.yml; do
    [ -e "$arq" ] || continue
    if ! python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1], encoding="utf-8"))' "$arq" 2>/dev/null; then
      falha "YAML inválido: $arq"
    fi
  done
}

# 2b. Labels usados pelos formulários devem existir no manifesto .github/labels.yml.
verificar_labels() {
  [ -e .github/labels.yml ] || return
  command -v python3 >/dev/null 2>&1 || return
  local saida
  saida=$(python3 - <<'PY' 2>&1
import glob, sys, yaml
manifesto = yaml.safe_load(open(".github/labels.yml", encoding="utf-8"))
existentes = {item["name"] for item in manifesto.get("labels", [])}
for arq in glob.glob(".github/ISSUE_TEMPLATE/*.yml"):
    dados = yaml.safe_load(open(arq, encoding="utf-8")) or {}
    usados = dados.get("labels") or []
    for label in usados:
        if label not in existentes:
            print(f"label {label} de {arq} ausente em .github/labels.yml")
PY
)
  if [ -n "$saida" ]; then
    while IFS= read -r linha; do falha "$linha"; done <<< "$saida"
  fi
}

# 3. Frontmatter de cada skill: name igual ao nome da pasta, minúsculas e hífens, e description presente.
verificar_skills() {
  local arq pasta nome
  for arq in skills/*/SKILL.md; do
    [ -e "$arq" ] || continue
    pasta=$(basename "$(dirname "$arq")")
    nome=$(awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f && /^name:/{sub(/^name: */,""); print; exit}' "$arq")
    if [ -z "$nome" ]; then
      falha "frontmatter sem name: $arq"
    elif [ "$nome" != "$pasta" ]; then
      falha "name ($nome) difere da pasta ($pasta): $arq"
    elif ! printf '%s' "$nome" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
      falha "name fora do padrão minúsculas e hífens: $arq"
    fi
    if ! awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f && /^description:/{found=1} END{exit !found}' "$arq"; then
      falha "frontmatter sem description: $arq"
    fi
  done
}

# 4. Links simbólicos em .claude/skills devem apontar para pastas existentes em skills/.
verificar_links_simbolicos() {
  local link alvo
  [ -d .claude/skills ] || return
  for link in .claude/skills/*; do
    [ -e "$link" ] || [ -L "$link" ] || continue
    if [ ! -L "$link" ]; then
      falha "$link não é link simbólico (edite a fonte em skills/)"
      continue
    fi
    alvo=$(readlink "$link")
    if [ ! -d "$link/" ]; then
      falha "link simbólico quebrado: $link -> $alvo"
    fi
  done
}

# 5. Nenhum .env versionado, exceto .env.example.
verificar_env_versionado() {
  local arq
  while IFS= read -r arq; do
    case "$arq" in
      .env.example) ;;
      .env|.env.*) falha "arquivo de ambiente versionado: $arq" ;;
    esac
  done < <(git ls-files 2>/dev/null)
}

# 6. .env.example só pode ter referências op:// ou valor vazio.
verificar_env_example() {
  [ -e .env.example ] || return
  local linha chave valor
  while IFS= read -r linha; do
    case "$linha" in
      ''|'#'*) continue ;;
    esac
    valor="${linha#*=}"
    chave="${linha%%=*}"
    if [ -n "$valor" ] && ! printf '%s' "$valor" | grep -qE '^op://'; then
      falha ".env.example com valor que não é op:// em $chave"
    fi
  done < .env.example
}

# 7. Padrões de segredo em arquivos versionados.
verificar_segredos() {
  local padroes arq
  padroes='AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY-----|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{32,}'
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks detect --no-git --source "$ROOT" --redact -q >/dev/null 2>&1 || falha "gitleaks encontrou possível segredo (execute gitleaks detect --no-git para ver os caminhos)"
    return
  fi
  while IFS= read -r arq; do
    if grep -qE "$padroes" "$arq" 2>/dev/null; then
      falha "possível segredo em $arq (padrão conhecido; valor não exibido)"
    fi
  done < <(git ls-files 2>/dev/null)
}

verificar_links
verificar_yaml
verificar_labels
verificar_skills
verificar_links_simbolicos
verificar_env_versionado
verificar_env_example
verificar_segredos

if [ "$FALHAS" -eq 0 ]; then
  echo "OK: verificação do template sem falhas"
  exit 0
fi
echo "$FALHAS falha(s)"
exit 1
