#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
# Prova que a fixture funciona: HOME temporário, stubs no PATH, repositório de teste com
# origem bare, e limpeza da pasta temporária ao sair, inclusive por TERM.
# shellcheck source=lib/fixture.sh
. "$(dirname "$0")/lib/fixture.sh"

fixture_iniciar
caminho_fx="$FX_DIR"

afirmar_igual "$HOME" "$caminho_fx/home" "HOME temporário"
afirmar_igual "$(command -v gh)" "$caminho_fx/bin/gh" "gh é o stub"
afirmar_igual "$(gh api user --jq .login)" "teste" "stub de gh responde o login"
afirmar_igual "$(df -P / | tail -1 | awk '{print $5}')" "10%" "stub de df responde o uso padrão"

fixture_repo_novo repo
afirmar_igual "$(git -C "$FX_DIR/trabalho/repo" rev-parse --abbrev-ref HEAD)" "main" "clone em main"
afirmar_igual "$(git -C "$FX_DIR/trabalho/repo" rev-parse origin/main)" \
  "$(git -C "$FX_DIR/trabalho/repo" rev-parse HEAD)" "origin/main aponta para o commit de base"
afirmar_igual "$(git -C "$FX_DIR/trabalho/repo" config remote.origin.url)" \
  "https://github.com/teste/repo.git" "origin guarda URL de GitHub"
afirmar_igual "$(git -C "$FX_DIR/trabalho/repo" remote get-url origin)" \
  "$FX_DIR/remotos/repo.git" "a URL de GitHub é reescrita para a origem local"
