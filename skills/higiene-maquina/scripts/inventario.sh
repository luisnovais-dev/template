#!/usr/bin/env bash
# Inventário somente leitura de repositórios, worktrees, branches e resíduos desta máquina.
#
# Uso: inventario.sh [raiz ...]
#   Sem argumentos, procura repositórios git até 4 níveis abaixo de $HOME e
#   resíduos (scratch-*, *snapshot*) até 2 níveis abaixo de $HOME.
#
# Variáveis:
#   HIGIENE_DONOS  donos de remoto reconhecidos, separados por espaço (ex.: "onluis-dev luisnovais-dev").
#                  Remoto de dono fora dessa lista vira REMOTO_LEGADO para revisão.
#
# Não altera nada: não remove, não faz checkout, não faz fetch. Lê o remoto
# com ls-remote e o estado de PR com gh (somente leitura). Imprime caminhos,
# estados e contagens. Nunca imprime conteúdo de arquivos nem credenciais.
#
# Classes de saída:
#   SEGURO_REMOVER  worktree limpa e trabalho integrado (mesclado, ou PR mesclada por squash)
#   RESGATAR        branch com commits que não estão no remoto vivo nem em PR mesclada
#   REQUER_DECISAO  worktree suja, HEAD solto com alterações, branch não integrada ou PR indeterminada
#   ORFAO           worktree registrada cujo diretório não existe
#   REMOTO_LEGADO   remote cujo dono não está em HIGIENE_DONOS
#   LIXO            resíduo temporário sem trabalho ativo (apenas listado)
#   PROGRESSO       .agent/ com registro de trabalho (nunca lixo; apenas informativo)
#   RECURSO         espaço usado por cache ou container (apenas informativo)

set -u

RAIZES=("$@")
if [ "${#RAIZES[@]}" -eq 0 ]; then
  RAIZES=("$HOME")
fi

# Caminhos que a remoção apagaria (SEGURO_REMOVER e LIXO), para somar ESPACO_LIBERAVEL.
REMOVIVEIS=()

# Repositórios: diretórios com .git, em qualquer nível até 4.
REPOS=()
for raiz in "${RAIZES[@]}"; do
  if [ -d "$raiz/.git" ]; then
    REPOS+=("$raiz")
  fi
  while IFS= read -r git_dir; do
    REPOS+=("$(dirname "$git_dir")")
  done < <(find "$raiz" -maxdepth 4 -name .git -type d \
    -not -path '*/node_modules/*' -not -path '*/.cache/*' -not -path '*/Library/*' \
    -not -path '*/.claude/worktrees/*' 2>/dev/null)
done

if [ "${#REPOS[@]}" -eq 0 ]; then
  echo "Nenhum repositório encontrado em: ${RAIZES[*]}"
  exit 0
fi

# Remove duplicatas preservando a ordem.
declare -A VISTO
UNICOS=()
for repo in "${REPOS[@]}"; do
  real=$(readlink -f "$repo")
  if [ -z "${VISTO[$real]:-}" ]; then
    VISTO[$real]=1
    UNICOS+=("$real")
  fi
done

# Usuário do gh, se disponível (para reconhecer o dono do remoto).
GH_USUARIO=""
if command -v gh >/dev/null 2>&1; then
  GH_USUARIO=$(gh api user --jq .login 2>/dev/null || true)
fi
# Organizações do usuário também são donos reconhecidos (ex.: onluis-dev).
GH_ORGS=""
if [ -n "$GH_USUARIO" ]; then
  GH_ORGS=$(gh api user/orgs --jq '.[].login' 2>/dev/null | tr '\n' ' ' || true)
fi
DONOS="${HIGIENE_DONOS:-} $GH_USUARIO $GH_ORGS"

# Aviso de disco: uma linha por partição (dedupe por ponto de montagem) acima do limite.
# HIGIENE_LIMITE_DISCO é o limite em porcentagem, padrão 90 (acima dele, avisa).
avisar_disco() {
  local limite="${HIGIENE_LIMITE_DISCO:-90}" ponto
  for ponto in "$HOME" "${RAIZES[@]}"; do
    df -P "$ponto" 2>/dev/null | awk 'NR == 2 {print $6 "\t" $5 "\t" $4}'
  done | awk -v lim="$limite" -F'\t' '
    !seen[$1]++ {
      uso = $2; sub("%", "", uso)
      if (uso + 0 > lim) {
        printf "  AVISO_DISCO: %s a %s%% de uso, %.1f GB livres. Limite: %s%%. Libere espaço antes de novas execuções.\n", $1, uso, $3 / 1048576, lim
      }
    }'
}

# O commit existe no GitHub (por exemplo, ponta de uma PR cuja branch remota foi apagada)?
# Responde SIM, NAO ou INDETERMINADO.
commit_no_github() {
  local slug="$1" sha="$2" r
  if [ -z "$slug" ] || ! command -v gh >/dev/null 2>&1; then
    echo "INDETERMINADO"; return
  fi
  r=$(gh api "repos/$slug/commits/$sha" --jq .sha 2>&1)
  case "$r" in
    "$sha") echo "SIM" ;;
    *"No commit found"*|*"Not Found"*|*"404"*|*"422"*) echo "NAO" ;;
    *) echo "INDETERMINADO" ;;
  esac
}

# Converte a URL de origin em owner/repo do GitHub (vazio se não for GitHub).
slug_github() {
  # config (URL crua), não get-url: get-url aplica insteadOf e pode esconder o GitHub.
  git -C "$1" config --get remote.origin.url 2>/dev/null \
    | sed -E 's#^(git@github.com:|https?://(www\.)?github\.com/)##; s#\.git$##' \
    | grep -E '^[^/:@ ]+/[^/:@ ]+$' || true
}

# Estado de PR para uma branch: MESCLADA, ABERTA, NENHUMA ou INDETERMINADO.
estado_pr() {
  local slug="$1" branch="$2" n
  if [ -z "$slug" ] || ! command -v gh >/dev/null 2>&1; then
    echo "INDETERMINADO"; return
  fi
  n=$(gh pr list --repo "$slug" --state merged --head "$branch" --json number --jq 'length' 2>/dev/null)
  if [ -z "$n" ]; then echo "INDETERMINADO"; return; fi
  if [ "$n" -gt 0 ]; then echo "MESCLADA"; return; fi
  n=$(gh pr list --repo "$slug" --state open --head "$branch" --json number --jq 'length' 2>/dev/null)
  if [ "${n:-x}" = "0" ]; then echo "NENHUMA"; elif [ -n "$n" ]; then echo "ABERTA"; else echo "INDETERMINADO"; fi
}

avisar_disco

# Integração por squash (R9): SIM só se valerem todas as condições abaixo.
#   1. não há PR aberta para a branch;
#   2. há PR mesclada para a branch, e o headRefOid dela é igual à ponta local ou está à frente
#      dela (o compare headRefOid...ponta responde identical ou behind);
#   3. o commit da ponta existe no GitHub.
# Qualquer resposta indeterminada do GitHub resulta em NAO.
integrada_por_squash() {
  local slug="$1" branch="$2" tip="$3" n oid status
  if [ -z "$slug" ] || ! command -v gh >/dev/null 2>&1; then echo NAO; return; fi

  n=$(gh pr list --repo "$slug" --state open --head "$branch" --json number --jq 'length' 2>/dev/null)
  [ "${n:-1}" = "0" ] || { echo NAO; return; }

  oid=$(gh pr list --repo "$slug" --state merged --head "$branch" --json headRefOid --jq '.[0].headRefOid // empty' 2>/dev/null)
  [ -n "$oid" ] || { echo NAO; return; }

  status=$(gh api "repos/$slug/compare/$oid...$tip" --jq .status 2>/dev/null)
  case "$status" in
    identical|behind) ;;
    *) echo NAO; return ;;
  esac

  [ "$(commit_no_github "$slug" "$tip")" = "SIM" ] && echo SIM || echo NAO
}

# Classifica um pendente de Spec ou documento (RASCUNHO) pela comparação com a main e com a issue.
# main: AUSENTE, IGUAL ou DIFERENTE (compara o blob do arquivo com o de origin/main).
# issue: IGUAL (conteúdo normalizado contido no corpo ou num comentário), DIFERENTE (a primeira
# linha aparece, mas o conteúdo não), AUSENTE, INDETERMINADO, ou SEM_ISSUE quando a branch não tem número.
# Só o resultado é impresso, nunca o conteúdo.
classificar_rascunho() {
  local repo="$1" slug="$2" caminho="$3" branch="$4" rel="$5" main blob_main blob_wt n issue texto
  if git -C "$repo" cat-file -e "origin/main:$rel" 2>/dev/null; then
    blob_main=$(git -C "$repo" rev-parse "origin/main:$rel" 2>/dev/null)
    blob_wt=$(git -C "$caminho" hash-object -- "$rel" 2>/dev/null)
    if [ "$blob_main" = "$blob_wt" ]; then main=IGUAL; else main=DIFERENTE; fi
  else
    main=AUSENTE
  fi

  n=$(printf '%s\n' "$branch" | sed -nE -e 's#^[^/]+/([0-9]+)-.*#\1#p' -e 's#^issue-([0-9]+)(-.*)?$#\1#p' | head -1)
  if [ -z "$n" ]; then
    echo "main=$main issue=SEM_ISSUE"
    return
  fi
  if [ -z "$slug" ] || ! texto=$(gh issue view "$n" --repo "$slug" --json body,comments \
      --jq '([.body] + [.comments[]?.body]) | map(select(. != null)) | join("\n\n")' 2>/dev/null); then
    echo "main=$main issue=#$n INDETERMINADO"
    return
  fi
  issue=$(ARQ="$caminho/$rel" ISSUE_TXT="$texto" python3 -c '
import os
def norm(t):
    return "\n".join(l.rstrip() for l in t.replace("\r", "").split("\n") if l.strip())
with open(os.environ["ARQ"], encoding="utf-8", errors="replace") as f:
    c = norm(f.read())
i = norm(os.environ["ISSUE_TXT"])
if c and c in i:
    print("IGUAL")
elif c and c.split("\n")[0] in i:
    print("DIFERENTE")
else:
    print("AUSENTE")
' 2>/dev/null || echo INDETERMINADO)
  echo "main=$main issue=#$n $issue"
}

# Lista os pendentes de uma worktree: até 20 caminhos, com o total. Pendente de Spec ou
# documento não versionado vira RASCUNHO. Só caminhos e estados são impressos.
detalhar_pendentes() {
  local repo="$1" slug="$2" caminho="$3" branch="$4" linha rel total
  total=$(git -C "$caminho" status --porcelain --untracked-files=all 2>/dev/null | wc -l | tr -d ' ')
  git -C "$caminho" status --porcelain --untracked-files=all 2>/dev/null | head -20 \
    | while IFS= read -r linha; do
      rel="${linha:3}"
      case "$linha" in
        '?? '*)
          case "$rel" in
            *.md|docs/*|openspec/*|specs/*)
              echo "    RASCUNHO: $rel $(classificar_rascunho "$repo" "$slug" "$caminho" "$branch" "$rel")" ;;
            *)
              echo "    pendente: $rel (??)" ;;
          esac ;;
        *)
          echo "    pendente: $rel (${linha:0:2})" ;;
      esac
    done
  if [ "$total" -gt 20 ]; then
    echo "    ... e mais $((total - 20)) pendente(s), não listados."
  fi
}

# Uma linha por worktree do repositório: caminho e branch (ou DETACHED).
listar_worktrees() {
  git -C "$1" worktree list --porcelain | awk '
    /^worktree /{ if (p != "") print p "\t" (b == "" ? "DETACHED" : b); p=substr($0,10); b="" }
    /^branch /{ b=substr($0,8); sub("refs/heads/","",b) }
    END{ if (p != "") print p "\t" (b == "" ? "DETACHED" : b) }'
}

# Espaço que a remoção liberaria para os caminhos recebidos. Conta cada inode uma vez, e só
# quando todos os seus links estão dentro do conjunto. Sem python3, soma o du de cada caminho
# e marca como estimativa, porque hard link entre caminhos pode ser contado duas vezes.
PY_LIBERAVEL=$(cat <<'PY'
import os, stat, sys
from collections import Counter
caminhos = [p for p in sys.stdin.read().split("\0") if p]
vistos = Counter()
info = {}
def registra(s):
    k = (s.st_dev, s.st_ino)
    vistos[k] += 1
    info[k] = (s.st_nlink, s.st_blocks * 512)
for c in caminhos:
    try:
        s = os.lstat(c)
    except OSError:
        continue
    if stat.S_ISDIR(s.st_mode):
        for raiz, dirs, arqs in os.walk(c):
            for nome in arqs + dirs:
                try:
                    t = os.lstat(os.path.join(raiz, nome))
                except OSError:
                    continue
                if stat.S_ISREG(t.st_mode):
                    registra(t)
    elif stat.S_ISREG(s.st_mode):
        registra(s)
total = sum(b for k, (n, b) in info.items() if vistos[k] >= n)
x, i = float(total), 0
unidades = ["B", "KB", "MB", "GB", "TB"]
while x >= 1024 and i < len(unidades) - 1:
    x /= 1024
    i += 1
print("%d B" % total if i == 0 else "%.1f %s" % (x, unidades[i]))
PY
)

espaco_liberavel() {
  if [ "$#" -eq 0 ]; then
    echo "0 B"
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s\0' "$@" | python3 -c "$PY_LIBERAVEL" 2>/dev/null && return
  fi
  local total=0 p kb
  for p in "$@"; do
    kb=$(du -sk "$p" 2>/dev/null | cut -f1)
    total=$((total + ${kb:-0}))
  done
  echo "$total KB (estimativa, sem python3)"
}

# Aviso para worktree com store de pnpm: o store é compartilhado e a remoção não o libera.
aviso_store() {
  if [ -d "$1/node_modules/.pnpm" ]; then
    echo "  AVISO_STORE: $1 usa store pnpm compartilhado. A remoção não libera o store."
  fi
}

for repo in "${UNICOS[@]}"; do
  echo "== REPOSITÓRIO: $repo"

  base_ref="origin/main"
  if ! git -C "$repo" rev-parse --verify --quiet "$base_ref" >/dev/null; then
    echo "  REQUER_DECISAO: sem origin/main local. Rode 'git fetch origin --prune' antes de classificar."
    continue
  fi

  slug=$(slug_github "$repo")

  # Remotos: origin e demais. Dono fora de HIGIENE_DONOS é revisado, inclusive o origin.
  git -C "$repo" remote | while IFS= read -r remote; do
    url=$(git -C "$repo" remote get-url "$remote" 2>/dev/null | sed -E 's#(https?://)[^@/]+@#\1***@#')
    dono=$(printf '%s' "$url" | sed -E 's#^(git@github.com:|https?://(www\.)?github\.com/)##' | cut -d/ -f1)
    if printf ' %s ' "$DONOS" | grep -q " $dono "; then
      echo "  REMOTO: $remote ($url)"
    else
      echo "  REMOTO_LEGADO: $remote ($url). Dono '$dono' não está em HIGIENE_DONOS. Revisar."
    fi
  done

  # Pontas no remoto vivo (ls-remote lê o GitHub, não o remote-tracking local).
  REMOTO_VIVO=$(git -C "$repo" ls-remote --heads origin 2>/dev/null | awk '{print $1}')

  # Worktrees (inclui HEAD solto). Uma linha por worktree: caminho, branch ou DETACHED.
  while IFS=$'\t' read -r caminho branch; do
      if [ "$caminho" = "$repo" ]; then
        continue
      fi
      if [ ! -d "$caminho" ]; then
        echo "  ORFAO: worktree $caminho (branch $branch) sem diretório. Use 'git worktree prune' somente após confirmação."
        continue
      fi
      sujo=$(git -C "$caminho" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      tamanho=$(du -sh "$caminho" 2>/dev/null | cut -f1)
      if [ "$branch" = "DETACHED" ]; then
        ref=$(git -C "$caminho" rev-parse HEAD 2>/dev/null)
        if [ "$sujo" -eq 0 ] && git -C "$repo" merge-base --is-ancestor "$ref" "$base_ref" 2>/dev/null; then
          REMOVIVEIS+=("$caminho")
          echo "  SEGURO_REMOVER: worktree $caminho (HEAD solto já integrado, limpa, libera $(espaco_liberavel "$caminho"))"
          aviso_store "$caminho"
        else
          echo "  REQUER_DECISAO: worktree $caminho (HEAD solto, alterações pendentes: $sujo, $tamanho)"
        fi
        continue
      fi
      integrada=0
      if git -C "$repo" merge-base --is-ancestor "$branch" "$base_ref" 2>/dev/null; then
        integrada=1
      elif [ "$(integrada_por_squash "$slug" "$branch" "$(git -C "$caminho" rev-parse HEAD 2>/dev/null)")" = "SIM" ]; then
        integrada=1
      fi
      if [ "$integrada" -eq 1 ] && [ "$sujo" -eq 0 ]; then
        REMOVIVEIS+=("$caminho")
        echo "  SEGURO_REMOVER: worktree $caminho (branch $branch integrada, limpa, libera $(espaco_liberavel "$caminho"))"
        aviso_store "$caminho"
      else
        echo "  REQUER_DECISAO: worktree $caminho (branch $branch, integrada: $integrada, alterações pendentes: $sujo, $tamanho)"
        detalhar_pendentes "$repo" "$slug" "$caminho" "$branch"
      fi
  done < <(listar_worktrees "$repo")

  # Branches locais.
  git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads | while IFS= read -r branch; do
    [ "$branch" = "main" ] && continue
    sha=$(git -C "$repo" rev-parse "$branch")
    if git -C "$repo" merge-base --is-ancestor "$branch" "$base_ref" 2>/dev/null; then
      integrada=1
    else
      integrada=0
    fi
    no_remoto=0
    estado=""
    printf '%s\n' "$REMOTO_VIVO" | grep -q "^$sha$" && no_remoto=1

    if [ "$integrada" -eq 0 ]; then
      estado=$(estado_pr "$slug" "$branch")
      if [ "$estado" = "MESCLADA" ] && [ "$(integrada_por_squash "$slug" "$branch" "$sha")" = "SIM" ]; then
        integrada=1
      fi
    fi

    # Branch em uso numa worktree adicional já foi tratada na seção de worktrees.
    # A branch em uso no checkout principal é classificada aqui, mas nunca como remover.
    em_worktree=$(git -C "$repo" worktree list --porcelain | awk -v r="$repo" -v b="refs/heads/$branch" '
      /^worktree /{p=substr($0,10)} /^branch /{ if (substr($0,8)==b && p!=r) print "sim" }')
    if [ -n "$em_worktree" ]; then
      continue
    fi
    if [ "$branch" = "$(git -C "$repo" symbolic-ref --short -q HEAD)" ] && [ "$integrada" -eq 1 ]; then
      echo "  REQUER_DECISAO: branch $branch integrada, mas em uso no checkout principal (troque de branch antes de remover)"
      continue
    fi

    if [ "$integrada" -eq 1 ]; then
      echo "  SEGURO_REMOVER: branch $branch integrada (ancestral de origin/main ou PR mesclada), sem worktree"
    elif [ "$no_remoto" -eq 1 ]; then
      echo "  REQUER_DECISAO: branch $branch com ponta publicada e sem PR mesclada (PR: ${estado:-?})"
    elif [ "$(commit_no_github "$slug" "$sha")" = "SIM" ]; then
      echo "  REQUER_DECISAO: branch $branch sem PR mesclada, mas o commit $sha já existe no GitHub (nada a resgatar)"
    else
      echo "  RESGATAR: branch $branch com commits ($sha) fora do remoto vivo e sem PR mesclada (PR: ${estado:-INDETERMINADO}). Não remover."
    fi
  done

  # Resíduos de agente dentro do repositório. .agent/ é trabalho, não lixo.
  if [ -d "$repo/.agent" ]; then
    echo "  PROGRESSO: $repo/.agent (registro de trabalho; não remover por esta skill)"
  fi
  # Só é LIXO o que não está versionado: arquivo rastreado nunca entra, mesmo com nome de temporário.
  while IFS= read -r item; do
    rel="${item#"$repo"/}"
    if git -C "$repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
      continue
    fi
    REMOVIVEIS+=("$item")
    echo "  LIXO: $rel"
  done < <(find "$repo" -maxdepth 3 \( -name '_tmp*' -o -name '*.log' -o -name 'tmp-verif-*' \) \
    -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.claude/worktrees/*' 2>/dev/null \
    | head -50)
done

# Resíduos fora dos repositórios (scratch e snapshots), só listados.
echo "== RESÍDUOS FORA DOS REPOSITÓRIOS (apenas listados)"
for raiz in "${RAIZES[@]}"; do
  find "$raiz" -maxdepth 2 -type d \( -name 'scratch-*' -o -name '*snapshot*' \) \
    -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.cache/*' 2>/dev/null \
    | while IFS= read -r item; do
        [ -d "$item/.git" ] && continue
        echo "  LIXO: $item ($(du -sh "$item" 2>/dev/null | cut -f1))"
      done
done

echo "== ESPAÇO"
echo "  ESPACO_LIBERAVEL: $(espaco_liberavel ${REMOVIVEIS[@]+"${REMOVIVEIS[@]}"}) (SEGURO_REMOVER e LIXO; cada arquivo contado uma vez, só se todos os seus links estão no conjunto)"

echo "== RECURSOS (informativo)"
if command -v docker >/dev/null 2>&1; then
  echo "  RECURSO: docker system df"
  docker system df 2>/dev/null | sed 's/^/    /' || echo "    docker indisponível"
fi
for cache in "$HOME/.cache" "$HOME/.npm" "$HOME/.local/share/pnpm"; do
  if [ -d "$cache" ]; then
    echo "  RECURSO: $(du -sh "$cache" 2>/dev/null | cut -f1)  $cache"
  fi
done

avisar_disco
echo "== FIM. Nada foi alterado. Remoções exigem lista aprovada pelo mantenedor."
exit 0
