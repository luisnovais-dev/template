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
2. Leia o plano. Ele lista o que será criado, os conflitos e as skills de usuário que existem fora do processo.
3. Se houver **conflito**, pare. Um conflito é uma skill de mesmo nome que já existe no destino e não é link deste clone. O script não sobrescreve nada e sai com código 2. Mostre o conflito ao mantenedor e pergunte o que fazer: manter a skill existente, aposentá-la, ou renomear.
4. O script varre também `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`, `~/.config/opencode/skills` e `~/.hermes/skills`, e lista as **outras skills de usuário** (por exemplo, da instalação GentleAI), que são candidatas a aposentar. No Hermes, as skills ficam em pastas de categoria e muitas vêm com o próprio Hermes. Por isso, uma skill do Hermes só é candidata quando o mesmo nome aparece também em outro diretório de skills de usuário, que é o sinal de um pacote instalado em vários harnesses. As demais são contadas e não são tocadas.
5. Aposentar é feito em dois passos, sempre depois de mostrar a lista ao mantenedor:
   - `--aplicar --aposentar` **copia** cada candidata para a raiz de aposentados (`raiz_aposentados`, padrão `~/.local/share/onluis-dev/aposentados`, ou `ONLUIS_APOSENTADOS_DIR`), mantendo a estrutura de pastas. Cópia existente não é sobrescrita.
   - Com a confirmação do mantenedor para a lista, `--aplicar --aposentar --remover-originais` remove do diretório ativo cada original cuja cópia foi conferida (conteúdo igual). Link simbólico é removido como link, sem tocar no destino. Original sem cópia conferida não é removido.
6. Com o plano aprovado, aplique:
   ```bash
   skills/instalar-processo/scripts/instalar.sh --aplicar
   ```
7. Para atualizar o clone e os links depois de uma mudança no template:
   ```bash
   skills/instalar-processo/scripts/instalar.sh --atualizar
   ```
   A atualização só avança o clone em fast-forward. Se o clone divergir, o script para sem alterar nada.
8. Se o Hermes estiver instalado e a configuração não listar `~/.agents/skills`, mostre o trecho e peça que o mantenedor o inclua.

## Saída

- Modo usado e caminho do clone.
- Links criados, já existentes e pulados por harness ausente.
- Conflitos encontrados, se houver.
- Skills de usuário fora do processo, para decisão.
- Trecho do Hermes, se for necessário.

## Regras

- Nada é alterado sem confirmação. O padrão é o plano.
- Nunca sobrescreva ou apague skill existente.
- Harness ausente é pulado e informado, sem erro.
- Não imprima valores de segredo. O script mostra só caminhos e contagens.
- O script é POSIX/bash e somente de leitura até `--aplicar`.

## Testes

Teste com `HOME` e `ONLUIS_TEMPLATE_DIR` temporários. Nunca rode testes contra o `HOME` real. Verificados: plano sem alteração, aplicação, reexecução sem erro, conflito que para antes de alterar, configuração do Hermes que não muda, e atualização. Não verificado: atualização com clone realmente divergente do remoto (o caminho de falha de fast-forward existe no script, mas não foi exercitado).

## Não faça

- Não copie as skills para os projetos.
- Não altere `~/.hermes/config.yaml`.
- Não remova skill de usuário sem lista, cópia conferida e confirmação do mantenedor.
