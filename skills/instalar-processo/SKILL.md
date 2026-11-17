---
name: instalar-processo
description: Instala ou atualiza, nesta máquina, as skills do processo de trabalho por links a partir de um clone do template, para Claude, Codex, OpenCode e Hermes. Mostra o plano antes e não altera nada sem confirmação. Use para instalar o processo numa máquina nova ou para atualizar as skills já instaladas.
---

# Instalar processo

Instala as skills do processo por máquina, sem copiá-las para os projetos. Os harnesses leem o mesmo caminho comum.

## Entrada

- Pedido explícito para instalar ou atualizar o processo na máquina.
- Confirmação do mantenedor para aplicar o plano.

## Caminhos

- Clone do instalador: `~/.local/share/onluis-dev/template` (configurável por `ONLUIS_TEMPLATE_DIR`). É um clone separado. Não é o checkout de trabalho do template, que muda de branch.
- Destinos: `~/.agents/skills` (Codex, OpenCode e Hermes) e `~/.claude/skills` (Claude). Cada skill é um link para `skills/<nome>` do clone.
- Hermes: `~/.hermes/config.yaml` precisa listar `~/.agents/skills` em `skills.external_dirs`. O instalador nunca altera esse arquivo; só mostra o trecho a incluir.

## Procedimento

1. Rode o plano, que não altera nada:
   ```bash
   skills/instalar-processo/scripts/instalar.sh
   ```
2. Leia o plano. Ele lista o que será criado, os conflitos e a contagem das skills de fora do processo.
3. Se houver **conflito**, pare. Um conflito é uma skill de mesmo nome que já existe no destino e não é link deste clone. O script não sobrescreve nada e sai com código 2. Mostre o conflito ao mantenedor e pergunte o que fazer: manter a skill existente (e não instalar a do processo com esse nome) ou o mantenedor resolver manualmente.
4. O script conta, por diretório, as skills que não são do processo (`~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`, `~/.config/opencode/skills` e `~/.hermes/skills`). A contagem é só informativa. Essas skills podem ser do próprio harness (Codex e Hermes trazem as suas) ou de outros pacotes, e o instalador nunca as copia, move ou remove. Desinstalar outro pacote de skills é decisão manual do mantenedor.
5. Com o plano aprovado, aplique:
   ```bash
   skills/instalar-processo/scripts/instalar.sh --aplicar
   ```
6. Para atualizar o clone e os links depois de uma mudança no template:
   ```bash
   skills/instalar-processo/scripts/instalar.sh --atualizar
   ```
   A atualização só avança o clone em fast-forward. Se o clone divergir, o script para sem alterar nada. Além de criar os links que faltam, `--atualizar` lista os **links órfãos**: links nos destinos que apontam para o clone do template e para uma pasta que não é mais skill de `skills/` (por exemplo, `auditar-spec` depois de sair do processo). Eles aparecem como `Órfão:` no plano.
7. Para remover os links órfãos listados, com o plano aprovado:
   ```bash
   skills/instalar-processo/scripts/instalar.sh --atualizar --aplicar
   ```
   Só o link é removido, nunca o destino. Links que apontam para fora do clone, pastas comuns e skills atuais não são tocados.
8. Se o Hermes estiver instalado e a configuração não listar `~/.agents/skills`, mostre o trecho e peça que o mantenedor o inclua.

## Saída

- Modo usado e caminho do clone.
- Links criados, já existentes e pulados por harness ausente.
- Links órfãos listados (com `--atualizar`) e removidos (com `--atualizar --aplicar`).
- Conflitos encontrados, se houver.
- Contagem das skills de fora do processo, por diretório (informativa).
- Trecho do Hermes, se for necessário.

## Regras

- Nada é alterado sem confirmação. O padrão é o plano.
- Nunca sobrescreva ou apague skill existente.
- Harness ausente é pulado e informado, sem erro.
- Não imprima valores de segredo. O script mostra só caminhos e contagens.
- O script é POSIX/bash e somente de leitura até `--aplicar`.

## Testes

Teste com `HOME` e `ONLUIS_TEMPLATE_DIR` temporários. Nunca rode testes contra o `HOME` real. Verificados: plano sem alteração, aplicação, reexecução sem erro, conflito que para antes de alterar, configuração do Hermes que não muda, e atualização. `tests/orfaos.sh` prova que `--atualizar` lista e `--atualizar --aplicar` remove só o link órfão do clone, e preserva link externo, link quebrado de fora do clone, pasta comum e skill atual. Não verificado: atualização com clone realmente divergente do remoto (o caminho de falha de fast-forward existe no script, mas não foi exercitado).

## Não faça

- Não copie as skills para os projetos.
- Não altere `~/.hermes/config.yaml`.
- Não copie, mova nem remova skill de fora do processo.
