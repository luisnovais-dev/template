---
name: adotar-processo
description: Adota o processo de trabalho num projeto, em três modos. "novo" conduz a Fase 0 de um projeto do zero, "existente" adequa um projeto que já tem código e histórico, e "atualizar" leva um projeto já adotado para a versão atual do processo. Copia só os arquivos do manifesto, aplica os labels e a configuração de branch com confirmação, e evita burocracia. Use quando o mantenedor pedir para adotar, adequar ou atualizar o processo num projeto.
---

# Adotar processo

Leva o processo de trabalho para um projeto. Copia só o que está no manifesto (`manifesto.txt`, ao lado desta skill), preenche a Configuração com valores reais e registra a versão.

## Entrada

- Caminho do projeto e o modo: `novo`, `existente` ou `atualizar`.
- Autorização explícita na invocação para cada ação que altera o GitHub (labels, configuração de branch, issue).

## Pré-condições (todos os modos)

1. O projeto está num checkout limpo, com `git status` vazio. Se houver alteração pendente ou trabalho não publicado, **pare antes de qualquer mudança** e liste os caminhos.
2. Você está numa worktree própria do projeto, não no checkout principal, salvo quando o mantenedor disser o contrário.
3. Antes de editar, `git fetch origin --prune` e confirme a relação com o main remoto.

## Procedimento comum

1. Leia `manifesto.txt` e aplique cada linha:
   - `copy`: copie o arquivo do template. Se o projeto já tiver o arquivo com conteúdo diferente, pare e pergunte antes de sobrescrever.
   - `merge`: mescle as linhas do template ao arquivo do projeto, sem apagar linhas do projeto.
   - `new`: crie só se o projeto não tiver o arquivo.
2. Preencha a seção Configuração de `docs/PROCESSO.md` com os valores reais do projeto. Preencha `processo_versao` com a versão do template (ver `CHANGELOG.md`). Nunca deixe placeholder onde a skill que dependa dele seria executada. Os valores de `comandos`, `ambientes` e `stack` vêm do projeto, não do template.
3. Nunca copie `skills/` para o projeto, nem `scripts/verificar-template.sh`.
4. Adicione os arquivos por caminho explícito e revise o diff. Commit com mensagem descritiva.
5. Labels: liste os labels atuais do repositório (`gh label list`) e compare com `.github/labels.yml`. Criar ou alterar labels exige autorização na invocação. Normalização obrigatória: um label em uso que não existe no conjunto final é **remarcado** para o correto, e só depois é removido. Nenhum label em uso é removido antes da remarcação. Label sem equivalente vai para decisão do mantenedor.
6. Configuração de branch: com autorização, ligue `delete_branch_on_merge` no repositório. Branches com PR mesclada são removidas. Branches sem PR são listadas para decisão, nunca apagadas.
7. Abra **uma** PR com a adoção, usando `abrir-pr` com a seção de documentação preenchida. Não crie PR por arquivo.

## Modo `novo`: Fase 0 de projeto do zero

1. Pergunte, em um bloco só, o que a Configuração pede: gerenciador de pacotes, lockfile, linguagens, frameworks, serviços locais, comandos de lint, testes, integração, typecheck, build, smoke e E2E, ferramenta visual, comando de ambiente local e a matriz de ambientes. Diga o que for `pendente` quando o projeto ainda não tiver.
2. Crie a estrutura de `docs/` declarada em `docs/PROCESSO.md` (seção Gate de documentação), com `docs/dominio.md`, `docs/arquitetura.md` e `docs/ambientes.md` como esqueletos curtos, e `docs/adr/` com um README-índice.
3. Crie o `README.md` do projeto com o que o projeto faz, para quem e o status. Uma linha de descrição basta no início.
4. Não crie épicos ou tickets de adequação neste modo, a não ser que o mantenedor peça.

## Modo `existente`: adequação de projeto com código

1. Inventário somente leitura: stack, comandos reais (lint, testes, build), ambientes, pastas de documentação existentes e labels. Não altere nada nesta etapa.
2. Infira as decisões já tomadas (ADRs) a partir do código, do histórico e da documentação. Proponha a lista de ADRs para aprovação. Não escreva ADR sem aceite.
3. Preencha a Configuração com os comandos reais. Se um comando não existir, registre `pendente`.
4. Não reorganize o projeto em massa. Mudança cosmética, renomeação de pastas e reformatação não entram nesta adoção.
5. Trabalho real de adequação (por exemplo, criar a suíte de aceite, corrigir gate que falha, documentar uma ADR importante) vira **no máximo um épico de adequação**, com filhas escolhidas pelo mantenedor. Nada cosmético vira issue.
6. Se a adoção for só mecânica (manifesto, Configuração e labels), faça uma PR única.

## Modo `atualizar`: projeto já adotado

1. Leia `processo_versao` na Configuração do projeto e a versão atual do template em `CHANGELOG.md`.
2. Aplique, na ordem, as notas de migração de cada versão entre as duas. Cada nota diz o que mudou e o que fazer no projeto.
3. Atualize os arquivos do manifesto pelo modo de cada linha (`copy`, `merge` ou `new`), sem tocar no que é do projeto.
4. Atualize `processo_versao` para a versão atual.
5. Mudança mecânica numa PR única. Se uma nota de migração exigir decisão do projeto, pare e pergunte antes.

## Regras contra burocracia

- A adoção é mecânica sempre que possível. Não crie issue para ajuste de arquivo.
- Issue só para trabalho real. No máximo um épico de adequação por projeto.
- Não reorganize `docs/` nem renomeie arquivos sem pedido.
- Não transforme sugestão cosmética em finding ou issue.
- Não duplique regra do processo no projeto. Cite `docs/PROCESSO.md`.

## Saída

- Modo usado e versão de origem e de destino (`processo_versao`).
- Lista de arquivos copiados, mesclados e criados, com o modo de cada um.
- Labels criados, remarcados, removidos e pendentes de decisão.
- Configuração pendente, com o que falta preencher.
- ADRs propostas (modo `existente`).
- PR aberta, ou motivo de não abrir.

## Não faça

- Não copie `skills/` nem o script de verificação do template para o projeto.
- Não altere código de aplicação nesta skill.
- Não crie label, altere configuração de branch ou abra PR sem autorização na invocação.
- Não apague branch nem label sem lista e confirmação.
- Não deixe placeholder em `comandos` ou `ambientes` sem sinalizar.
