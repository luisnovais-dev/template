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
DONOS="${HIGIENE_DONOS:-} $GH_USUARIO"

# Converte a URL de origin em owner/repo do GitHub (vazio se não for GitHub).
slug_github() {
  git -C "$1" remote get-url origin 2>/dev/null \
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
  git -C "$repo" worktree list --porcelain | awk '
    /^worktree /{ if (p != "") print p "\t" (b == "" ? "DETACHED" : b); p=substr($0,10); b="" }
    /^branch /{ b=substr($0,8); sub("refs/heads/","",b) }
    END{ if (p != "") print p "\t" (b == "" ? "DETACHED" : b) }' \
    | while IFS=$'\t' read -r caminho branch; do
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
          echo "  SEGURO_REMOVER: worktree $caminho (HEAD solto já integrado, limpa, $tamanho)"
        else
          echo "  REQUER_DECISAO: worktree $caminho (HEAD solto, alterações pendentes: $sujo, $tamanho)"
        fi
        continue
      fi
      integrada=0
      if git -C "$repo" merge-base --is-ancestor "$branch" "$base_ref" 2>/dev/null; then
        integrada=1
      elif [ "$(estado_pr "$slug" "$branch")" = "MESCLADA" ]; then
        integrada=1
      fi
      if [ "$integrada" -eq 1 ] && [ "$sujo" -eq 0 ]; then
        echo "  SEGURO_REMOVER: worktree $caminho (branch $branch integrada, limpa, $tamanho)"
      else
        echo "  REQUER_DECISAO: worktree $caminho (branch $branch, integrada: $integrada, alterações pendentes: $sujo, $tamanho)"
      fi
  done

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
    printf '%s\n' "$REMOTO_VIVO" | grep -q "^$sha$" && no_remoto=1

    if [ "$integrada" -eq 0 ]; then
      estado=$(estado_pr "$slug" "$branch")
      if [ "$estado" = "MESCLADA" ]; then
        integrada=1
      fi
    fi

    if git -C "$repo" worktree list --porcelain | grep -q "^branch refs/heads/$branch$"; then
      continue   # tratada na seção de worktrees
    fi

    if [ "$integrada" -eq 1 ]; then
      echo "  SEGURO_REMOVER: branch $branch integrada (ancestral de origin/main ou PR mesclada), sem worktree"
    elif [ "$no_remoto" -eq 1 ]; then
      echo "  REQUER_DECISAO: branch $branch com ponta publicada e sem PR mesclada (PR: ${estado:-?})"
    else
      echo "  RESGATAR: branch $branch com commits ($sha) fora do remoto vivo e sem PR mesclada (PR: ${estado:-INDETERMINADO}). Não remover."
    fi
  done

  # Resíduos de agente dentro do repositório. .agent/ é trabalho, não lixo.
  if [ -d "$repo/.agent" ]; then
    echo "  PROGRESSO: $repo/.agent (registro de trabalho; não remover por esta skill)"
  fi
  lixo=$(find "$repo" -maxdepth 3 \( -name '_tmp*' -o -name '*.log' -o -name 'tmp-verif-*' \) \
    -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.claude/worktrees/*' 2>/dev/null | head -20)
  if [ -n "$lixo" ]; then
    printf '%s\n' "$lixo" | while IFS= read -r item; do
      echo "  LIXO: ${item#"$repo"/}"
    done
  fi
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

echo "== FIM. Nada foi alterado. Remoções exigem lista aprovada pelo mantenedor."
exit 0
