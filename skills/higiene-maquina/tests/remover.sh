#!/usr/bin/env bash
# T7 (R13): o modo --remover aplica só a lista aprovada, revalida cada item e recusa o que não
# for seguro. Um arquivo de lista é o que o inventário propõe, com linhas inseguras acrescentadas
# de propósito. Código 3 quando algo é recusado.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo rm
R="$FX_DIR/trabalho/rm"
W="$FX_DIR/wt"
mkdir -p "$W/grupoA" "$W/grupoB"

# Branch com commit que será integrada por squash (PR mesclada) ou não integrada.
branch_com_commit() {
  git -C "$R" checkout -q -b "$1" main
  echo "$1" > "$R/$1.txt"
  git -C "$R" add "$1.txt"
  git -C "$R" commit -q -m "$1"
  git -C "$R" push -q origin "$1"
  git -C "$R" checkout -q main
}
branch_com_commit feat-e
branch_com_commit feat-f

# Versionado: um log que bate com o padrão de LIXO e não deve ser apagado.
echo "registro" > "$R/debug.log"
git -C "$R" add debug.log
git -C "$R" commit -q -m "log versionado"
git -C "$R" push -q origin main

# "Squash" na main: as branches de commit acima deixam de ser ancestrais.
echo squash > "$R/squash.txt"
git -C "$R" add squash.txt
git -C "$R" commit -q -m "squash"
git -C "$R" push -q origin main

# Integradas (ancestrais da main) e limpas.
git -C "$R" branch feat/6-d main
git -C "$R" worktree add -q -b feat/6-a "$W/grupoA/x" main
git -C "$R" worktree add -q -b feat/6-b "$W/grupoB/y" main
git -C "$R" worktree add -q -b feat/6-c "$W/grupoB/z" main
# Suja: com arquivo não commitado (não é SEGURO, mas uma lista errada pode apontar para ela).
git -C "$R" worktree add -q -b feat/6-h "$W/h" main
echo sujo > "$W/h/nao-commitado.txt"

# Processo com o diretório dentro da worktree C: ela não pode ser removida.
( cd "$W/grupoB/z" && exec sleep 15 ) &
PID_C=$!

# Lixo não versionado dentro do repositório, e um que deve sobrar porque não está na lista.
echo tmp > "$R/_tmp1"
echo tmp > "$R/_tmp2"

# Docker: uma execução de teste com PID morto.
printf 'tests-app-3999991-0b6ae018|exited|\n' > "$FX_DADOS/docker_ps"
: > "$FX_DADOS/docker_volumes"
: > "$FX_DADOS/docker_redes"

# Dados do gh: feat-e tem PR mesclada por squash com a ponta igual (integrada); feat-f não tem PR.
printf 'feat-e %s\n' "$(git -C "$R" rev-parse feat-e)" > "$FX_DADOS/gh_pr_merged"
printf '%s\n' "$(git -C "$R" rev-parse feat-e)" > "$FX_DADOS/gh_commits"
printf '%s...%s identical\n' "$(git -C "$R" rev-parse feat-e)" "$(git -C "$R" rev-parse feat-e)" > "$FX_DADOS/gh_compare"

# O inventário propõe a lista. As linhas abaixo são o que um erro de mão ou uma lista antiga traria.
saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)
# _tmp2 fica de fora da lista de propósito: o inventário o propõe, e a lista aprovada não.
lista=$(printf '%s\n' "$saida" | awk -F'\t' 'NF == 4' | grep -v '_tmp2')
afirmar_contem "$lista" "SEGURO_REMOVER"$'\t'"worktree"$'\t'"$R"$'\t'"$W/grupoA/x" "o inventário propõe a worktree integrada"
afirmar_contem "$lista" "SEGURO_REMOVER"$'\t'"branch"$'\t'"$R"$'\t'"feat-e" "o inventário propõe a branch squash-integrada"
{
  printf '%s\n' "$lista"
  printf 'SEGURO_REMOVER\tworktree\t%s\t%s\n' "$R" "$W/h"
  printf 'SEGURO_REMOVER\tbranch\t%s\tfeat-f\n' "$R"
  printf 'LIXO\tlixo\t%s\t%s\n' "$R" "$R/debug.log"
  printf 'SEGURO_REMOVER\tbranch\t%s\tbranch-inexistente\n' "$R"
  printf 'LIXO\tbranch\t%s\tfeat/6-d\n' "$R"
  printf 'SEGURO_REMOVER\tbranch\tlinha-com-poucos-campos\n'
  printf 'SEGURO_REMOVER\tbranch\t%s\tfeat/6-d\tcampo-extra\n' "$R"
} > "$FX_DADOS/lista.tsv"

rc=0
saida_rm=$(bash "$INV" --remover "$FX_DADOS/lista.tsv" 2>&1) || rc=$?

afirmar_igual "$rc" "3" "lista com itens recusados sai com código 3"
afirmar_contem "$saida_rm" "REMOVIDO: worktree $W/grupoA/x" "worktree integrada e limpa é removida"
afirmar_contem "$saida_rm" "REMOVIDO: worktree $W/grupoB/y" "segunda worktree integrada é removida"
afirmar_contem "$saida_rm" "RECUSADO: worktree $W/grupoB/z: processo com diretório dentro" "processo dentro da worktree impede a remoção"
afirmar_contem "$saida_rm" "RECUSADO: worktree $W/h: alterações pendentes" "worktree suja é recusada"
afirmar_contem "$saida_rm" "REMOVIDO: branch feat/6-d (-d)" "branch integrada por ancestral sai com -d"
afirmar_contem "$saida_rm" "REMOVIDO: branch feat-e (-D)" "branch integrada por squash sai com -D"
afirmar_contem "$saida_rm" "RECUSADO: branch feat-f: não integrada" "branch sem PR mesclada é recusada"
afirmar_contem "$saida_rm" "RECUSADO: lixo debug.log: versionado" "arquivo versionado nunca é removido"
afirmar_contem "$saida_rm" "REMOVIDO: lixo _tmp1" "temporário não versionado da lista é removido"
afirmar_contem "$saida_rm" "RECUSADO: branch branch-inexistente: branch inexistente" "branch que não existe é recusada"
afirmar_contem "$saida_rm" "RECUSADO: branch feat/6-d: classe LIXO não corresponde" "classe que não casa com o tipo é recusada"
afirmar_contem "$saida_rm" "linha malformada" "linha com campos errados é recusada"
afirmar_contem "$saida_rm" "REMOVIDO: docker execução 3999991-0b6ae018" "execução Docker órfã é removida"
afirmar_contem "$saida_rm" "== RESUMO" "o modo termina com resumo"
afirmar_nao_contem "$saida_rm" "== REPOSITÓRIO" "o modo --remover não imprime o inventário"

afirmar_igual "$([ -e "$W/grupoA" ] && echo existe || echo removida)" "removida" "pasta-mãe vazia é removida"
afirmar_igual "$([ -d "$W/grupoB/z" ] && echo existe || echo removida)" "existe" "worktree recusada continua no lugar"
afirmar_igual "$([ -d "$W/grupoB" ] && echo existe || echo removida)" "existe" "pasta-mãe não vazia é preservada"
afirmar_igual "$([ -e "$R/_tmp1" ] && echo existe || echo removida)" "removida" "lixo da lista sai"
afirmar_igual "$([ -e "$R/_tmp2" ] && echo existe || echo removida)" "existe" "lixo fora da lista não é tocado"
afirmar_igual "$([ -n "$(git -C "$R" branch --list feat-e)" ] && echo existe || echo removida)" "removida" "branch squash removida do repositório"
afirmar_igual "$([ -n "$(git -C "$R" branch --list feat/6-d)" ] && echo existe || echo removida)" "removida" "branch integrada removida do repositório"
afirmar_igual "$([ -n "$(git -C "$R" branch --list feat-f)" ] && echo existe || echo removida)" "existe" "branch recusada continua no repositório"
afirmar_contem "$(cat "$FX_DADOS/docker_log" 2>/dev/null)" "rm tests-app-3999991-0b6ae018" "docker rm é chamado para o container órfão"

kill "$PID_C" 2>/dev/null
wait "$PID_C" 2>/dev/null
exit 0
