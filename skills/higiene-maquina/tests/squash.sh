#!/usr/bin/env bash
# T3 (R9): branch integrada por squash só é SEGURO_REMOVER com PR mesclada, ponta igual ou
# atrás do headRefOid da PR, sem PR aberta e com o commit da ponta existente no GitHub.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo sq
R="$FX_DIR/trabalho/sq"

# Cria uma branch com um commit, publicada no origin, e volta para main.
branch_publicada() {
  git -C "$R" checkout -q -b "$1" main
  echo "$1" > "$R/$1.txt"
  git -C "$R" add "$1.txt"
  git -C "$R" commit -q -m "$1"
  git -C "$R" push -q origin "$1"
  git -C "$R" checkout -q main
}

for b in sq-a sq-b sq-c sq-d sq-e sq-f; do branch_publicada "$b"; done

# "Squash" na main: a main passa a ter um commit que não é ancestral das branches.
echo "squash" > "$R/squash.txt"
git -C "$R" add squash.txt
git -C "$R" commit -q -m "squash das PRs"
git -C "$R" push -q origin main

tip() { git -C "$R" rev-parse "$1"; }
: > "$FX_DADOS/gh_pr_merged"; : > "$FX_DADOS/gh_pr_open"; : > "$FX_DADOS/gh_commits"; : > "$FX_DADOS/gh_compare"

# sq-a: PR mesclada, ponta igual ao headRefOid, commit no GitHub -> SEGURO.
echo "sq-a $(tip sq-a)" >> "$FX_DADOS/gh_pr_merged"
echo "$(tip sq-a)...$(tip sq-a) identical" >> "$FX_DADOS/gh_compare"
tip sq-a >> "$FX_DADOS/gh_commits"

# sq-b: sem PR mesclada -> não é seguro.

# sq-c: ponta à frente do headRefOid (commits locais além da PR) -> não é seguro.
echo "sq-c $(tip sq-c)" >> "$FX_DADOS/gh_pr_merged"
echo "$(tip sq-c)...$(tip sq-c) ahead" >> "$FX_DADOS/gh_compare"
tip sq-c >> "$FX_DADOS/gh_commits"

# sq-d: ponta atrás do headRefOid (a PR tem commits que a ponta local não tem) -> seguro.
echo "sq-d $(tip sq-d)" >> "$FX_DADOS/gh_pr_merged"
echo "$(tip sq-d)...$(tip sq-d) behind" >> "$FX_DADOS/gh_compare"
tip sq-d >> "$FX_DADOS/gh_commits"

# sq-e: PR mesclada, mas também há PR aberta para a mesma branch -> não é seguro.
echo "sq-e $(tip sq-e)" >> "$FX_DADOS/gh_pr_merged"
echo "sq-e" >> "$FX_DADOS/gh_pr_open"
echo "$(tip sq-e)...$(tip sq-e) identical" >> "$FX_DADOS/gh_compare"
tip sq-e >> "$FX_DADOS/gh_commits"

# sq-f: PR mesclada e ponta igual, mas o commit não existe no GitHub -> não é seguro.
echo "sq-f $(tip sq-f)" >> "$FX_DADOS/gh_pr_merged"
echo "$(tip sq-f)...$(tip sq-f) identical" >> "$FX_DADOS/gh_compare"

saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)

afirmar_contem "$saida" "SEGURO_REMOVER: branch sq-a " "squash com PR mesclada, ponta igual e commit no GitHub"
afirmar_contem "$saida" "SEGURO_REMOVER: branch sq-d " "ponta atrás do headRefOid também é seguro"
afirmar_nao_contem "$saida" "SEGURO_REMOVER: branch sq-b " "sem PR mesclada não é seguro"
afirmar_nao_contem "$saida" "SEGURO_REMOVER: branch sq-c " "ponta à frente do headRefOid não é seguro"
afirmar_nao_contem "$saida" "SEGURO_REMOVER: branch sq-e " "PR aberta impede SEGURO_REMOVER"
afirmar_nao_contem "$saida" "SEGURO_REMOVER: branch sq-f " "commit ausente do GitHub impede SEGURO_REMOVER"
