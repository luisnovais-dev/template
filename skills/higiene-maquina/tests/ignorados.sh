#!/usr/bin/env bash
# F1 (review da PR #7): arquivo ignorado pelo .gitignore numa worktree é trabalho local, como um
# .env. Com conteúdo ignorado, a worktree é REQUER_DECISAO e o modo --remover a recusa. Dependência
# regenerável (node_modules) não impede a remoção.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"
INV="$(cd "$(dirname "$0")/.." && pwd)/scripts/inventario.sh"

fixture_iniciar
fixture_repo_novo ig
R="$FX_DIR/trabalho/ig"
mkdir -p "$FX_DIR/wt"
printf '.env\nnode_modules/\n' > "$R/.gitignore"
git -C "$R" add .gitignore
git -C "$R" commit -q -m "ignora segredos e dependências"
git -C "$R" push -q origin main

# Integrada, limpa, com .env ignorado: não é segura.
git -C "$R" worktree add -q -b feat/6-env "$FX_DIR/wt/env" main
W="$FX_DIR/wt/env"
echo "TOKEN=segredo" > "$W/.env"
# Integrada, limpa, só com dependência regenerável ignorada: é segura.
git -C "$R" worktree add -q -b feat/6-nm "$FX_DIR/wt/nm" main
N="$FX_DIR/wt/nm"
mkdir -p "$N/node_modules/pkg"
echo "x" > "$N/node_modules/pkg/index.js"

saida=$(bash "$INV" "$FX_DIR/trabalho" 2>&1)
afirmar_contem "$saida" "REQUER_DECISAO: worktree $W" "arquivo ignorado com conteúdo local impede SEGURO_REMOVER"
afirmar_contem "$saida" "pendente: .env" "o arquivo ignorado aparece na lista de pendências"
afirmar_nao_contem "$saida" "SEGURO_REMOVER: worktree $W" "a worktree com .env não é proposta para remoção"
afirmar_contem "$saida" "SEGURO_REMOVER: worktree $N" "node_modules ignorado não impede a remoção"

lista="$FX_DADOS/lista.tsv"
{
  printf 'SEGURO_REMOVER\tworktree\t%s\t%s\n' "$R" "$W"
  printf 'SEGURO_REMOVER\tworktree\t%s\t%s\n' "$R" "$N"
} > "$lista"
rc=0
saida_rm=$(bash "$INV" --remover "$lista" 2>&1) || rc=$?
afirmar_igual "$rc" "3" "o modo --remover recusa a worktree com conteúdo ignorado"
afirmar_contem "$saida_rm" "RECUSADO: worktree $W: alterações pendentes" "a recusa diz o motivo"
afirmar_contem "$saida_rm" "REMOVIDO: worktree $N" "a worktree só com dependência regenerável sai"
afirmar_igual "$(cat "$W/.env" 2>/dev/null)" "TOKEN=segredo" "o .env continua no disco"
exit 0
