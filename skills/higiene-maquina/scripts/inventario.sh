#!/usr/bin/env bash
# Inventário somente leitura de repositórios, worktrees, branches e resíduos desta máquina.
#
# Uso: inventario.sh [raiz ...]
#   Sem argumentos, procura repositórios git até 4 níveis abaixo de $HOME.
#
# Não altera nada: não remove, não faz checkout, não faz fetch (usa ls-remote,
# que só lê). Imprime caminhos, estados e contagens. Nunca imprime conteúdo de
# arquivos nem valores de segredo.
#
# Classes de saída:
#   SEGURO_REMOVER  worktree limpa com branch mesclada, ou branch mesclada sem worktree
#   RESGATAR        branch com commits que não existem em nenhuma branch do remoto vivo
#   ORFAO           worktree registrada cujo diretório não existe
#   REMOTO_LEGADO   remote além de origin
#   LIXO            resíduo de agente ou temporário dentro do repositório
#   RECURSO         espaço usado por cache ou container (apenas informativo)
#   REQUER_DECISAO  worktree suja, branch não mesclada ou branch de outra sessão

set -u

RAIZES=("$@")
if [ "${#RAIZES[@]}" -eq 0 ]; then
  RAIZES=("$HOME")
fi

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

for repo in "${UNICOS[@]}"; do
  echo "== REPOSITÓRIO: $repo"

  base_ref="origin/main"
  if ! git -C "$repo" rev-parse --verify --quiet "$base_ref" >/dev/null; then
    echo "  REQUER_DECISAO: sem origin/main local. Rode 'git fetch origin --prune' antes de classificar."
    continue
  fi

  # Remotos além de origin.
  git -C "$repo" remote | while IFS= read -r remote; do
    [ "$remote" = "origin" ] && continue
    echo "  REMOTO_LEGADO: $remote ($(git -C "$repo" remote get-url "$remote" 2>/dev/null | sed -E 's#(https?://)[^@/]+@#\1***@#'))"
  done

  # Ponta de cada branch no remoto vivo (não no remote-tracking local).
  REMOTO_VIVO=$(git -C "$repo" ls-remote --heads origin 2>/dev/null | awk '{print $1}')

  # Worktrees.
  git -C "$repo" worktree list --porcelain | awk '
    /^worktree /{p=substr($0,10)}
    /^branch /{b=substr($0,8); sub("refs/heads/","",b); print p "\t" b}
    /^$/{p=""; b=""}' | while IFS=$'\t' read -r caminho branch; do
      if [ "$caminho" = "$repo" ]; then
        continue
      fi
      if [ ! -d "$caminho" ]; then
        echo "  ORFAO: worktree $caminho (branch ${branch:-?}) sem diretório. Use 'git worktree prune' somente após confirmação."
        continue
      fi
      sujo=$(git -C "$caminho" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      tamanho=$(du -sh "$caminho" 2>/dev/null | cut -f1)
      if git -C "$repo" merge-base --is-ancestor "$branch" "$base_ref" 2>/dev/null && [ "$sujo" -eq 0 ]; then
        echo "  SEGURO_REMOVER: worktree $caminho (branch $branch mesclada, limpa, $tamanho)"
      else
        echo "  REQUER_DECISAO: worktree $caminho (branch $branch, alterações pendentes: $sujo, $tamanho)"
      fi
  done

  # Branches locais.
  git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads | while IFS= read -r branch; do
    [ "$branch" = "main" ] && continue
    sha=$(git -C "$repo" rev-parse "$branch")
    if ! printf '%s\n' "$REMOTO_VIVO" | grep -q "^$sha$"; then
      if ! git -C "$repo" merge-base --is-ancestor "$sha" "$base_ref" 2>/dev/null; then
        echo "  RESGATAR: branch $branch tem commits ($sha) que não estão em nenhuma branch remota viva. Não remover."
        continue
      fi
    fi
    if git -C "$repo" merge-base --is-ancestor "$branch" "$base_ref" 2>/dev/null; then
      if ! git -C "$repo" worktree list --porcelain | grep -q "^branch refs/heads/$branch$"; then
        echo "  SEGURO_REMOVER: branch $branch mesclada, sem worktree"
      fi
    else
      echo "  REQUER_DECISAO: branch $branch não mesclada no $base_ref"
    fi
  done

  # Lixo de agente e temporários dentro do repositório (apenas caminhos).
  lixo=$(find "$repo" -maxdepth 3 \( -name '_tmp*' -o -name '*.log' -o -name '.agent' -o -name 'tmp-verif-*' \) \
    -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.claude/worktrees/*' 2>/dev/null | head -20)
  if [ -n "$lixo" ]; then
    printf '%s\n' "$lixo" | while IFS= read -r item; do
      echo "  LIXO: ${item#"$repo"/}"
    done
  fi
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
