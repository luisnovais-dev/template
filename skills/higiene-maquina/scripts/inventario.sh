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
#   HIGIENE_REGENERAVEIS  pastas ignoradas que não bloqueiam a remoção de worktree, separadas por espaço.
#                  Padrão: "node_modules .next dist coverage .venv". Pasta fora dessa lista e ignorada
#                  pelo .gitignore (um .env, por exemplo) bloqueia a remoção.
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
# Lista para aprovação: uma linha por item removível, TSV com CLASSE, TIPO, REPO e ALVO.
LISTA_APROVACAO=()

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

if [ "${#REPOS[@]}" -eq 0 ] && [ "${1:-}" != "--remover" ]; then
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

[ "${1:-}" = "--remover" ] || avisar_disco

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

# Pendências de uma worktree, uma linha por entrada do git. Inclui o que o .gitignore esconde
# (um .env local, por exemplo). Ficam de fora as pastas regeneráveis (HIGIENE_REGENERAVEIS, padrão
# node_modules, .next, dist, coverage e .venv) e .agent/, que tem contagem própria em agent_pendente.
pendentes_worktree() {
  local nome padrao='^!! (.*/)?(\.agent'
  local -a nomes=()
  read -ra nomes <<< "${HIGIENE_REGENERAVEIS:-node_modules .next dist coverage .venv}"
  for nome in "${nomes[@]}"; do
    padrao+="|$(printf '%s' "$nome" | sed 's/\./\\./g')"
  done
  padrao+=')/$'
  git -C "$1" status --porcelain --ignored=matching --untracked-files=all 2>/dev/null \
    | grep -v -E "$padrao"
}

# Lista os pendentes de uma worktree: até 20 caminhos, com o total. Pendente de Spec ou
# documento não versionado vira RASCUNHO. Só caminhos e estados são impressos.
detalhar_pendentes() {
  local repo="$1" slug="$2" caminho="$3" branch="$4" linha rel total
  total=$(pendentes_worktree "$caminho" | wc -l | tr -d ' ')
  pendentes_worktree "$caminho" | head -20 \
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
        '!! '*)
          echo "    pendente: $rel (ignorado pelo .gitignore)" ;;
        *)
          echo "    pendente: $rel (${linha:0:2})" ;;
      esac
    done
  if [ "$total" -gt 20 ]; then
    echo "    ... e mais $((total - 20)) pendente(s), não listados."
  fi
}

# Chave de execução de teste, <pid>-<8 hex>, lida do fim do nome (vazia se não houver).
chave_execucao() {
  printf '%s\n' "$1" | sed -nE 's/.*-([0-9]+-[0-9a-f]{8})$/\1/p'
}

# Recursos Docker de execuções de teste (R10). Containers, volumes e redes são agrupados pela
# chave de execução, lida do nome ou do projeto do compose. Volume montado por um container do
# grupo entra no grupo mesmo sem chave. Grupo com PID morto é DOCKER_ORFAO (candidato à
# remoção pela lista aprovada); com PID vivo, DOCKER_ATIVO (só informativo).
avaliar_docker() {
  if ! docker ps -a --format '{{.Names}}' >/dev/null 2>&1; then
    echo "  DOCKER: indisponível (sem daemon ou sem permissão). Nada a classificar."
    return
  fi
  local nome estado proj v r m k pid classe situacao
  declare -A grupo_c grupo_v grupo_r grupo_vm todas
  while IFS='|' read -r nome estado proj; do
    [ -n "$nome" ] || continue
    k=$(chave_execucao "$nome")
    [ -n "$k" ] || k=$(chave_execucao "$proj")
    [ -n "$k" ] || continue
    grupo_c[$k]+="$nome ($estado)"$'\n'
    while IFS= read -r m; do
      [ -n "$m" ] && grupo_vm[$k]+="$m"$'\n'
    done < <(docker inspect --format '{{range .Mounts}}{{if .Name}}{{.Name}}{{"\n"}}{{end}}{{end}}' "$nome" 2>/dev/null)
  done < <(docker ps -a --format '{{.Names}}|{{.State}}|{{.Label "com.docker.compose.project"}}' 2>/dev/null)

  while IFS= read -r v; do
    [ -n "$v" ] || continue
    k=$(chave_execucao "$v")
    [ -n "$k" ] && grupo_v[$k]+="$v"$'\n'
  done < <(docker volume ls --format '{{.Name}}' 2>/dev/null)

  for k in "${!grupo_vm[@]}"; do
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      printf '%s' "${grupo_v[$k]:-}" | grep -qxF "$m" || grupo_v[$k]+="$m"$'\n'
    done <<< "${grupo_vm[$k]}"
  done

  while IFS= read -r r; do
    [ -n "$r" ] || continue
    k=$(chave_execucao "$r")
    [ -n "$k" ] && grupo_r[$k]+="$r"$'\n'
  done < <(docker network ls --format '{{.Name}}' 2>/dev/null)

  for k in "${!grupo_c[@]}" "${!grupo_v[@]}" "${!grupo_r[@]}"; do todas[$k]=1; done
  for k in $(printf '%s\n' "${!todas[@]}" | sort); do
    pid=${k%%-*}
    if ps -p "$pid" >/dev/null 2>&1; then
      classe=DOCKER_ATIVO; situacao="PID $pid está vivo"
    else
      classe=DOCKER_ORFAO; situacao="PID $pid não está vivo"
      LISTA_APROVACAO+=("$(printf 'DOCKER_ORFAO\tdocker\t-\t%s' "$k")")
    fi
    echo "  $classe: execução $k ($situacao)"
    printf '%s' "${grupo_c[$k]:-}" | sed '/^$/d; s/^/    container: /'
    printf '%s' "${grupo_v[$k]:-}" | sed '/^$/d; s/^/    volume: /'
    printf '%s' "${grupo_r[$k]:-}" | sed '/^$/d; s/^/    rede: /'
  done
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

# ---- Modo --remover (R13) ------------------------------------------------------------------
# Aplica só a lista aprovada (TSV: CLASSE, TIPO, REPO, ALVO). Cada item é revalidado no momento
# da remoção, e o que não for seguro é recusado. Nunca usa --force, nunca apaga branch remota,
# nunca age sobre item que não esteja na lista.

recusar() {
  echo "RECUSADO: $1 $2: $3"
}

# 0 se a worktree $1 contém submódulo (entrada de gitlink no índice). O git recusa removê-la.
tem_submodulo() {
  git -C "$1" ls-files -s 2>/dev/null | awk '$1 == 160000 { achou = 1 } END { exit !achou }'
}

# 0 se outros usuários podem entrar em $1: todo diretório do caminho tem execução para outros, para
# o grupo, ou tem ACL (que não se lê aqui, então conta como alcance). Se um diretório não tem nada
# disso, nenhum outro usuário passa por ele. Erro de stat conta como alcance.
alcancavel_por_outros() {
  local d="$1" perm modo
  while [ "$d" != "/" ]; do
    perm=$(stat -c %a "$d" 2>/dev/null) || return 0
    # ls mostra o '+' de ACL; stat -c %A não mostra. Um único diretório, sem listar conteúdo.
    # shellcheck disable=SC2012
    modo=$(ls -ld -- "$d" 2>/dev/null | awk '{print $1}') || return 0
    [ -n "$modo" ] || return 0
    if [ $(( ${perm: -1} & 1 )) -eq 0 ] && [ $(( ${perm: -2:1} & 1 )) -eq 0 ] \
      && [ "${modo: -1}" != "+" ]; then
      return 1
    fi
    d=$(dirname "$d")
  done
  return 0
}

# 0 se algum processo tem o diretório atual dentro de $1, 1 se nenhum tem, 2 se não foi possível
# verificar (sem /proc e sem lsof, ou cwd ilegível de processo que pode alcançar $1). Só 1 libera a
# remoção. HIGIENE_TESTE_PROC troca a raiz do /proc (usado nos testes).
processo_dentro() {
  local alvo="$1" p c cmd dono eu nao_verificado=0 raiz="${HIGIENE_TESTE_PROC:-/proc}"
  eu=$(id -u)
  if [ -d "$raiz/self" ]; then
    for p in "$raiz"/[0-9]*; do
      c=$(readlink "$p/cwd" 2>/dev/null) || {
        # Thread do kernel e zumbi não têm cmdline e não estão em diretório nenhum.
        cmd=$(tr -d '\0' 2>/dev/null < "$p/cmdline")
        [ -n "$cmd" ] || continue
        dono=$(stat -c %u "$p" 2>/dev/null) || continue
        # Root: pode estar em qualquer lugar e não se verifica sem privilégio. Risco aceito pelo
        # mantenedor (ver SKILL, Plataforma). Outro usuário só conta se alcança o alvo.
        # O próprio usuário conta sempre: um processo seu dentro do alvo deve bloquear.
        case "$dono" in
          0) ;;
          "$eu") nao_verificado=1 ;;
          *) if alcancavel_por_outros "$alvo"; then nao_verificado=1; fi ;;
        esac
        continue
      }
      case "$c" in
        "$alvo"|"$alvo"/*) return 0 ;;
      esac
    done
    [ "$nao_verificado" -eq 1 ] && return 2
    return 1
  fi
  if command -v lsof >/dev/null 2>&1; then
    lsof -a -d cwd -Fn 2>/dev/null | awk -v a="$alvo" '
      substr($0, 1, 1) == "n" { p = substr($0, 2); if (p == a || index(p, a "/") == 1) found = 1 }
      END { exit !found }'
    return $?
  fi
  return 2
}

# Arquivos de .agent/ numa worktree. São registro de trabalho e não versionados (o git ignora a
# pasta), então contam como pendência, mesmo que o status esteja limpo.
agent_pendente() {
  find "$1/.agent" -type f 2>/dev/null | wc -l | tr -d ' '
}

remover_worktree() {
  local repo="$1" alvo="$2" sujo branch ponta slug integrada rc
  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    recusar worktree "$alvo" "repositório $repo inexistente"; return 1
  fi
  if [ "$alvo" = "$repo" ] || ! git -C "$repo" worktree list --porcelain | grep -qxF "worktree $alvo"; then
    recusar worktree "$alvo" "não é worktree registrada de $repo"; return 1
  fi
  if [ ! -d "$alvo" ]; then
    recusar worktree "$alvo" "diretório não existe"; return 1
  fi
  sujo=$(pendentes_worktree "$alvo" | wc -l | tr -d ' ')
  if [ "$sujo" != "0" ]; then
    recusar worktree "$alvo" "alterações pendentes ($sujo)"; return 1
  fi
  if tem_submodulo "$alvo"; then
    recusar worktree "$alvo" "contém submódulo: procedimento em docs/PROCESSO.md (Worktrees e branches), com confirmação"; return 1
  fi
  if [ "$(agent_pendente "$alvo")" != "0" ]; then
    recusar worktree "$alvo" "registro .agent com $(agent_pendente "$alvo") arquivo(s) não versionado(s)"; return 1
  fi
  ponta=$(git -C "$alvo" rev-parse HEAD 2>/dev/null)
  branch=$(git -C "$alvo" symbolic-ref --short -q HEAD 2>/dev/null)
  slug=$(slug_github "$repo")
  if git -C "$repo" merge-base --is-ancestor "$ponta" origin/main 2>/dev/null; then
    integrada=1
  elif [ -n "$branch" ] && [ "$(integrada_por_squash "$slug" "$branch" "$ponta")" = "SIM" ]; then
    integrada=1
  else
    integrada=0
  fi
  if [ "$integrada" -ne 1 ]; then
    recusar worktree "$alvo" "trabalho não integrado"; return 1
  fi
  processo_dentro "$alvo"
  rc=$?
  if [ "$rc" -ne 1 ]; then
    recusar worktree "$alvo" "processo com diretório dentro, ou não verificado (código $rc)"; return 1
  fi
  if ! git -C "$repo" worktree remove "$alvo" >/dev/null 2>&1; then
    recusar worktree "$alvo" "git worktree remove falhou"; return 1
  fi
  rmdir "$(dirname "$alvo")" 2>/dev/null
  echo "REMOVIDO: worktree $alvo"
}

remover_branch() {
  local repo="$1" branch="$2" tip modo
  if ! git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
    recusar branch "$branch" "branch inexistente"; return 1
  fi
  if git -C "$repo" worktree list --porcelain | grep -qxF "branch refs/heads/$branch"; then
    recusar branch "$branch" "em uso em worktree"; return 1
  fi
  if [ "$(git -C "$repo" symbolic-ref --short -q HEAD 2>/dev/null)" = "$branch" ]; then
    recusar branch "$branch" "está no checkout principal"; return 1
  fi
  tip=$(git -C "$repo" rev-parse "refs/heads/$branch")
  if git -C "$repo" merge-base --is-ancestor "$tip" origin/main 2>/dev/null; then
    modo=-d
  elif [ "$(integrada_por_squash "$(slug_github "$repo")" "$branch" "$tip")" = "SIM" ]; then
    modo=-D
  else
    recusar branch "$branch" "não integrada (sem PR mesclada por squash conferida)"; return 1
  fi
  if ! git -C "$repo" branch "$modo" "$branch" >/dev/null 2>&1; then
    recusar branch "$branch" "git branch $modo falhou"; return 1
  fi
  echo "REMOVIDO: branch $branch ($modo)"
}

remover_lixo() {
  local repo="$1" alvo="$2" rel base
  case "$alvo" in
    "$repo"/*) ;;
    *) recusar lixo "$alvo" "fora do repositório"; return 1 ;;
  esac
  rel="${alvo#"$repo"/}"
  base="${rel##*/}"
  case "$base" in
    _tmp*|*.log|tmp-verif-*) ;;
    *) recusar lixo "$rel" "nome não é de LIXO"; return 1 ;;
  esac
  if [ ! -e "$alvo" ]; then
    recusar lixo "$rel" "não existe"; return 1
  fi
  if git -C "$repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    recusar lixo "$rel" "versionado"; return 1
  fi
  if [ -d "$alvo" ]; then
    if [ -e "$alvo/.git" ]; then
      recusar lixo "$rel" "contém repositório"; return 1
    fi
    rm -r -- "$alvo"
  else
    rm -f -- "$alvo"
  fi
  echo "REMOVIDO: lixo $rel"
}

remover_docker() {
  local k="$1" pid nome estado proj v r m
  local -a conts=() vols=() nets=()
  if ! printf '%s\n' "$k" | grep -qE '^[0-9]+-[0-9a-f]{8}$'; then
    recusar docker "$k" "chave de execução inválida"; return 1
  fi
  pid=${k%%-*}
  if ps -p "$pid" >/dev/null 2>&1; then
    recusar docker "$k" "PID $pid está vivo (execução ativa)"; return 1
  fi
  while IFS='|' read -r nome estado proj; do
    [ -n "$nome" ] || continue
    if [ "$(chave_execucao "$nome")" = "$k" ] || [ "$(chave_execucao "$proj")" = "$k" ]; then
      conts+=("$nome")
    fi
  done < <(docker ps -a --format '{{.Names}}|{{.State}}|{{.Label "com.docker.compose.project"}}' 2>/dev/null)
  while IFS= read -r v; do
    [ -n "$v" ] && [ "$(chave_execucao "$v")" = "$k" ] && vols+=("$v")
  done < <(docker volume ls --format '{{.Name}}' 2>/dev/null)
  while IFS= read -r r; do
    [ -n "$r" ] && [ "$(chave_execucao "$r")" = "$k" ] && nets+=("$r")
  done < <(docker network ls --format '{{.Name}}' 2>/dev/null)
  for nome in ${conts[@]+"${conts[@]}"}; do
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      case " ${vols[*]+${vols[*]}} " in
        *" $m "*) ;;
        *) vols+=("$m") ;;
      esac
    done < <(docker inspect --format '{{range .Mounts}}{{if .Name}}{{.Name}}{{"\n"}}{{end}}{{end}}' "$nome" 2>/dev/null)
  done
  if [ "${#conts[@]}" -eq 0 ] && [ "${#vols[@]}" -eq 0 ] && [ "${#nets[@]}" -eq 0 ]; then
    echo "NADA: docker $k já não tem recursos"; return 4
  fi
  for nome in ${conts[@]+"${conts[@]}"}; do
    docker stop "$nome" >/dev/null 2>&1
    if ! docker rm "$nome" >/dev/null 2>&1; then
      recusar docker "$k" "docker rm $nome falhou"; return 1
    fi
  done
  for v in ${vols[@]+"${vols[@]}"}; do
    if ! docker volume rm "$v" >/dev/null 2>&1; then
      recusar docker "$k" "docker volume rm $v falhou"; return 1
    fi
  done
  for r in ${nets[@]+"${nets[@]}"}; do
    if ! docker network rm "$r" >/dev/null 2>&1; then
      recusar docker "$k" "docker network rm $r falhou"; return 1
    fi
  done
  echo "REMOVIDO: docker execução $k (containers: ${#conts[@]}, volumes: ${#vols[@]}, redes: ${#nets[@]})"
}

# Aplica a lista aprovada linha a linha. Código 0 se tudo que foi pedido foi removido, 3 se algo foi recusado.
remover_lista() {
  local arq="$1" linha classe tipo repo alvo extra esperado recusados=0 removidos=0
  if [ "$arq" = "-" ]; then
    arq=/dev/stdin
  fi
  while IFS= read -r linha || [ -n "$linha" ]; do
    [ -n "$linha" ] || continue
    IFS=$'\t' read -r classe tipo repo alvo extra <<< "$linha"
    if [ -z "$alvo" ] || [ -n "$extra" ]; then
      echo "RECUSADO: linha malformada, precisa de 4 campos: ${linha:0:60}"
      recusados=$((recusados + 1)); continue
    fi
    case "$tipo" in
      worktree|branch) esperado=SEGURO_REMOVER ;;
      lixo) esperado=LIXO ;;
      docker) esperado=DOCKER_ORFAO ;;
      *)
        recusar "$tipo" "$alvo" "tipo desconhecido"
        recusados=$((recusados + 1)); continue ;;
    esac
    if [ "$classe" != "$esperado" ]; then
      recusar "$tipo" "$alvo" "classe $classe não corresponde ao tipo (esperado $esperado)"
      recusados=$((recusados + 1)); continue
    fi
    case "$tipo" in
      worktree) remover_worktree "$repo" "$alvo" ;;
      branch) remover_branch "$repo" "$alvo" ;;
      lixo) remover_lixo "$repo" "$alvo" ;;
      docker) remover_docker "$alvo" ;;
    esac
    case "$?" in
      0) removidos=$((removidos + 1)) ;;
      4) ;;
      *) recusados=$((recusados + 1)) ;;
    esac
  done < "$arq"
  echo "== RESUMO: $removidos removido(s), $recusados recusado(s). Nada fora da lista foi tocado."
  if [ "$recusados" -gt 0 ]; then
    return 3
  fi
  return 0
}

if [ "${1:-}" = "--remover" ]; then
  if [ -z "${2:-}" ]; then
    echo "Uso: inventario.sh --remover <lista.tsv | ->" >&2
    exit 64
  fi
  remover_lista "$2"
  exit $?
fi

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
      sujo=$(( $(pendentes_worktree "$caminho" | wc -l | tr -d ' ') + $(agent_pendente "$caminho") ))
      tamanho=$(du -sh "$caminho" 2>/dev/null | cut -f1)
      if [ "$branch" = "DETACHED" ]; then
        ref=$(git -C "$caminho" rev-parse HEAD 2>/dev/null)
        if [ "$sujo" -eq 0 ] && ! tem_submodulo "$caminho" && git -C "$repo" merge-base --is-ancestor "$ref" "$base_ref" 2>/dev/null; then
          REMOVIVEIS+=("$caminho")
          LISTA_APROVACAO+=("$(printf 'SEGURO_REMOVER\tworktree\t%s\t%s' "$repo" "$caminho")")
          echo "  SEGURO_REMOVER: worktree $caminho (HEAD solto já integrado, limpa, libera $(espaco_liberavel "$caminho"))"
          aviso_store "$caminho"
        else
          echo "  REQUER_DECISAO: worktree $caminho (HEAD solto, alterações pendentes: $sujo, $tamanho)"
          if tem_submodulo "$caminho"; then
            echo "    SUBMODULO: a worktree contém submódulo. Use o procedimento de docs/PROCESSO.md (Worktrees e branches), com confirmação."
          fi
        fi
        continue
      fi
      integrada=0
      if git -C "$repo" merge-base --is-ancestor "$branch" "$base_ref" 2>/dev/null; then
        integrada=1
      elif [ "$(integrada_por_squash "$slug" "$branch" "$(git -C "$caminho" rev-parse HEAD 2>/dev/null)")" = "SIM" ]; then
        integrada=1
      fi
      if [ "$integrada" -eq 1 ] && [ "$sujo" -eq 0 ] && ! tem_submodulo "$caminho"; then
        REMOVIVEIS+=("$caminho")
        LISTA_APROVACAO+=("$(printf 'SEGURO_REMOVER\tworktree\t%s\t%s' "$repo" "$caminho")")
        echo "  SEGURO_REMOVER: worktree $caminho (branch $branch integrada, limpa, libera $(espaco_liberavel "$caminho"))"
        aviso_store "$caminho"
      else
        echo "  REQUER_DECISAO: worktree $caminho (branch $branch, integrada: $integrada, alterações pendentes: $sujo, $tamanho)"
        if tem_submodulo "$caminho"; then
          echo "    SUBMODULO: a worktree contém submódulo. Use o procedimento de docs/PROCESSO.md (Worktrees e branches), com confirmação."
        fi
        detalhar_pendentes "$repo" "$slug" "$caminho" "$branch"
      fi
  done < <(listar_worktrees "$repo")

  # Branches locais.
  while IFS= read -r branch; do
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
      LISTA_APROVACAO+=("$(printf 'SEGURO_REMOVER\tbranch\t%s\t%s' "$repo" "$branch")")
      echo "  SEGURO_REMOVER: branch $branch integrada (ancestral de origin/main, ou PR mesclada por squash com ponta conferida), sem worktree"
    elif [ "$no_remoto" -eq 1 ]; then
      echo "  REQUER_DECISAO: branch $branch com ponta publicada e sem PR mesclada (PR: ${estado:-?})"
    elif [ "$(commit_no_github "$slug" "$sha")" = "SIM" ]; then
      echo "  REQUER_DECISAO: branch $branch sem PR mesclada, mas o commit $sha já existe no GitHub (nada a resgatar)"
    else
      echo "  RESGATAR: branch $branch com commits ($sha) fora do remoto vivo e sem PR mesclada (PR: ${estado:-INDETERMINADO}). Não remover."
    fi
  done < <(git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads)

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
    LISTA_APROVACAO+=("$(printf 'LIXO\tlixo\t%s\t%s' "$repo" "$item")")
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

echo "== DOCKER"
avaliar_docker

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
echo "== LISTA PARA APROVAÇÃO"
echo "# Apague as linhas que não aprova e passe o arquivo a: inventario.sh --remover <arquivo>"
if [ "${#LISTA_APROVACAO[@]}" -gt 0 ]; then
  printf '%s\n' "${LISTA_APROVACAO[@]}"
fi
echo "== FIM. Nada foi alterado. Remoções exigem lista aprovada pelo mantenedor."
exit 0
