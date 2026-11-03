#!/usr/bin/env bash
# Fixture dos testes da higiene-maquina. Nada aqui toca o HOME real, o GitHub, o Docker
# nem repositórios do usuário: tudo vive numa pasta temporária, removida ao sair, inclusive
# quando o teste é interrompido por INT, TERM ou HUP.
#
# Uso num teste:
#   . "$(dirname "$0")/lib/fixture.sh"
#   fixture_iniciar
#   fixture_repo_novo meu-repo          # cria origem bare e clone de trabalho
#   ...
#   afirmar_contem "$saida" "REMOVIDO" "remove a branch"
#
# Os stubs de gh e df leem os dados de $FX_DADOS (arquivos em texto). Um comando não previsto
# pelo stub falha alto, para que um teste nunca passe por engano.

FX_DIR=""

fixture_limpar() {
  if [ -n "$FX_DIR" ] && [ -d "$FX_DIR" ]; then
    rm -rf "$FX_DIR"
  fi
}

fixture_iniciar() {
  FX_DIR=$(mktemp -d "${TMPDIR:-/tmp}/higiene-teste.XXXXXX") || exit 1
  trap fixture_limpar EXIT
  trap 'fixture_limpar; exit 130' INT
  trap 'fixture_limpar; exit 143' TERM
  trap 'fixture_limpar; exit 129' HUP

  export HOME="$FX_DIR/home"
  export FX_DADOS="$FX_DIR/dados"
  export GIT_CONFIG_GLOBAL="$FX_DIR/gitconfig"
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME="Teste" GIT_AUTHOR_EMAIL="teste@example.invalid"
  export GIT_COMMITTER_NAME="Teste" GIT_COMMITTER_EMAIL="teste@example.invalid"
  export HIGIENE_DONOS="teste"
  mkdir -p "$HOME" "$FX_DADOS" "$FX_DIR/bin" "$FX_DIR/remotos" "$FX_DIR/trabalho"
  : > "$GIT_CONFIG_GLOBAL"

  # Dono e usuário do gh reconhecidos nos testes.
  echo "teste" > "$FX_DADOS/gh_login"
  : > "$FX_DADOS/gh_orgs"
  # Sem PR, sem commit e sem comparação: o estado padrão é explícito, não "arquivo ausente".
  : > "$FX_DADOS/gh_pr_merged"
  : > "$FX_DADOS/gh_pr_open"
  : > "$FX_DADOS/gh_commits"
  : > "$FX_DADOS/gh_compare"

  # Stub de gh: responde a partir de arquivos em $FX_DADOS. Formatos:
  #   gh_pr_merged  linhas "<branch> <headRefOid>" (PR mesclada)
  #   gh_pr_open    linhas "<branch>" (PR aberta)
  #   gh_commits    um SHA por linha (commit existente no GitHub)
  #   gh_compare    linhas "<base>...<head> <status>"
  cat > "$FX_DIR/bin/gh" <<'STUB'
#!/usr/bin/env bash
# Stub de gh para testes. Sem rede.
d="${FX_DADOS:?}"
args="$*"
case "$args" in
  "api user --jq .login")
    cat "$d/gh_login" 2>/dev/null || exit 1 ;;
  "api user/orgs"*)
    cat "$d/gh_orgs" 2>/dev/null ;;
  "pr list --repo "*"--state merged --head "*)
    branch="${args##*--head }"; branch="${branch%% *}"
    if [[ "$args" == *"--jq length"* ]]; then
      awk -v b="$branch" '$1 == b {n++} END {print n + 0}' "$d/gh_pr_merged" 2>/dev/null
    else
      awk -v b="$branch" '$1 == b {print $2; exit}' "$d/gh_pr_merged" 2>/dev/null
    fi ;;
  "pr list --repo "*"--state open --head "*)
    branch="${args##*--head }"; branch="${branch%% *}"
    if [[ "$args" == *"--jq length"* ]]; then
      awk -v b="$branch" '$1 == b {n++} END {print n + 0}' "$d/gh_pr_open" 2>/dev/null
    else
      awk -v b="$branch" '$1 == b {print; exit}' "$d/gh_pr_open" 2>/dev/null
    fi ;;
  "api repos/"*"/commits/"*)
    sha="${args##*/commits/}"; sha="${sha%% *}"
    if grep -qx "$sha" "$d/gh_commits" 2>/dev/null; then
      echo "$sha"
    else
      echo '{"message":"No commit found"}'; exit 1
    fi ;;
  "api repos/"*"/compare/"*)
    par="${args##*/compare/}"; par="${par%% *}"
    awk -v p="$par" '$1 == p {print $2; found=1; exit} END {if (!found) exit 1}' "$d/gh_compare" 2>/dev/null ;;
  "issue view "*)
    # Texto (corpo e comentários) de uma issue, em $FX_DADOS/gh_issue_<n>.txt.
    n=$(printf '%s' "$args" | awk '{print $3}')
    cat "$d/gh_issue_$n.txt" 2>/dev/null || exit 1 ;;
  *)
    echo "stub gh: comando não previsto: $args" >&2
    exit 1 ;;
esac
STUB

  # Stub de df: uso fixo dado por $FX_DADOS/df_uso (padrão 10%), no formato POSIX (-P).
  cat > "$FX_DIR/bin/df" <<'STUB'
#!/usr/bin/env bash
u=$(cat "${FX_DADOS:?}/df_uso" 2>/dev/null || echo 10)
printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\n'
printf 'stub 100 %s %s %s%% %s\n' "$u" "$((100 - u))" "$u" "${2:-/}"
STUB
  # Stub de docker, a partir de $FX_DADOS. Sem docker_ps, o daemon é tratado como indisponível.
  # Formatos: docker_ps (nome|estado|projeto), docker_volumes, docker_redes (um nome por linha),
  # docker_mounts_<nome> (volumes montados por um container).
  cat > "$FX_DIR/bin/docker" <<'STUB'
#!/usr/bin/env bash
d="${FX_DADOS:?}"
if [ ! -f "$d/docker_ps" ]; then
  echo "stub docker: daemon indisponível" >&2
  exit 1
fi
case "$*" in
  "ps -a --format "*) cat "$d/docker_ps" ;;
  "volume ls --format "*) cat "$d/docker_volumes" 2>/dev/null ;;
  "network ls --format "*) cat "$d/docker_redes" 2>/dev/null ;;
  "inspect --format "*)
    nome="${*: -1}"
    cat "$d/docker_mounts_$nome" 2>/dev/null ;;
  "stop "*|"rm "*|"volume rm "*|"network rm "*)
    # Comandos de remoção: registrados em docker_log, sem efeito real.
    echo "$*" >> "$d/docker_log" ;;
  "system df")
    echo "TYPE TOTAL ACTIVE SIZE RECLAIMABLE"
    echo "Images 0 0 0B 0B" ;;
  *)
    echo "stub docker: comando não previsto: $*" >&2
    exit 1 ;;
esac
STUB
  chmod +x "$FX_DIR/bin/gh" "$FX_DIR/bin/df" "$FX_DIR/bin/docker"
  export PATH="$FX_DIR/bin:$PATH"
  # Árvore de processos falsa: sem processos reais, que podem estar dentro de uma worktree de teste.
  export HIGIENE_TESTE_PROC="$FX_DIR/proc"
  mkdir -p "$HIGIENE_TESTE_PROC/self"
}

# Cria um repositório de teste com origem bare e clone de trabalho. O clone de trabalho
# aponta o origin para https://github.com/teste/<nome>.git, reescrito para a origem bare
# local por insteadOf. Assim, o inventário enxerga um slug de GitHub e o git funciona offline.
# Resultado: $FX_DIR/trabalho/<nome> (clone) e a branch main com um commit.
fixture_repo_novo() {
  local nome="$1" bare="$FX_DIR/remotos/$1.git" trabalho="$FX_DIR/trabalho/$1"
  git init -q --bare -b main "$bare"
  git config --global url."$bare".insteadOf "https://github.com/teste/$nome.git"
  git init -q -b main "$trabalho"
  git -C "$trabalho" remote add origin "https://github.com/teste/$nome.git"
  echo "base" > "$trabalho/README.md"
  git -C "$trabalho" add README.md
  git -C "$trabalho" commit -q -m "base"
  git -C "$trabalho" push -q -u origin main
  git -C "$trabalho" remote set-head origin main >/dev/null 2>&1 || true
  git -C "$trabalho" fetch -q origin
}

# Afirmações. A primeira falha encerra o teste com código 1.
afirmar_igual() {
  if [ "$1" != "$2" ]; then
    echo "FALHA ($3): esperado '$1', obtido '$2'"
    exit 1
  fi
}

afirmar_contem() {
  case "$1" in
    *"$2"*) ;;
    *) echo "FALHA ($3): a saída não contém '$2'"; exit 1 ;;
  esac
}

afirmar_nao_contem() {
  case "$1" in
    *"$2"*) echo "FALHA ($3): a saída contém '$2'"; exit 1 ;;
  esac
}
