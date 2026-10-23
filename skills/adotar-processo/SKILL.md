---
name: adotar-processo
description: Adota o processo de trabalho num projeto, em três modos. "novo" cria o repositório e conduz a Fase 0 de um projeto do zero, "existente" adequa um projeto com código e histórico, e "atualizar" leva um projeto já adotado para a versão atual do processo. Copia só os arquivos do manifesto, aplica labels e configuração de branch com confirmação, e evita burocracia. Use quando o mantenedor pedir para adotar, adequar ou atualizar o processo num projeto.
---

# Adotar processo

Leva o processo de trabalho para um projeto. Copia só o que está no manifesto (`manifesto.txt`, ao lado desta skill), preenche a Configuração com valores reais e registra a versão.

## Entrada

- Caminho do projeto (ou nome, para o modo `novo`) e o modo: `novo`, `existente` ou `atualizar`.
- Autorização explícita na invocação para cada ação que altera o GitHub: criar repositório, criar ou alterar labels, configurar branch, abrir PR, e abrir issue.

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
5. Labels: liste os labels atuais (`gh label list`) e compare com `.github/labels.yml`. Criar ou alterar labels exige autorização na invocação. A normalização segue a seção `remarcar` do manifesto: um label em uso é **remarcado** para o correspondente e só depois removido. Os labels da seção `remover_apos_remarcacao` são removidos somente com lista confirmada. `duplicate`, `invalid` e `wontfix` são mantidos. Nenhum label em uso é removido antes da remarcação. Label sem correspondência vai para decisão do mantenedor.
6. Configuração de branch: com autorização, ligue `delete_branch_on_merge` no repositório. Branches com PR mesclada são removidas. Branches sem PR são listadas para decisão, nunca apagadas.
7. Abra **uma** PR com a adoção, usando `abrir-pr` com a seção de documentação preenchida. Não crie PR por arquivo.

## Modo `novo`: Fase 0 de projeto do zero

1. **Repositório.** Se a pasta não é git, rode `git init -b main`. Criar o repositório no GitHub exige autorização na invocação, com nome e visibilidade informados. Sem autorização, pare nesse ponto e peça.
2. **Configuração.** Pergunte, em um bloco só, o que a Configuração pede: gerenciador de pacotes, lockfile, linguagens, frameworks, serviços locais, comandos de lint, testes, integração, typecheck, build, smoke e E2E, ferramenta visual, comando de ambiente local, `env_check` e a matriz de ambientes. Diga o que for `pendente` quando o projeto ainda não tiver.
3. **Estrutura.** Crie a estrutura de `docs/` declarada em `docs/PROCESSO.md` (seção Gate de documentação): `docs/dominio.md`, `docs/arquitetura.md` e `docs/ambientes.md` como esqueletos curtos, e `docs/adr/` com um índice.
4. **README.** Crie o `README.md` com o que o projeto faz, para quem e o status, em uma linha no início.
5. **ADRs iniciais.** Proponha como ADRs, com status "Proposto", as decisões de stack, estrutura de pastas, autenticação, deploy e ambientes. Cada uma vai para `docs/adr/` como "Aceito" somente depois do aceite do mantenedor, na conversa.
6. **CI.** Proponha um workflow mínimo que roda os comandos configurados (lint, testes, build). Criá-lo exige aprovação do mantenedor. Se ainda não houver comandos, registre a CI como "não configurada", sem marcar nada como aprovado.
7. **Harness.** Garanta que o `CLAUDE.md` do projeto importe `AGENTS.md`. Oriente a instalação das skills por máquina com `instalar-processo`.
8. **Identidade de teste.** Documente em `docs/ambientes.md` os usuários sintéticos por perfil para local e preview, e o teste que prova a indisponibilidade em produção. Não crie usuário real nem credencial.
9. **Épico de walking skeleton.** Proponha um épico que entrega a fatia ponta a ponta mínima (uma tela ou rota, uma persistência, o deploy de preview), com a suíte de aceite pendente. Criá-lo exige autorização na invocação. As filhas são escolhidas pelo mantenedor.

## Modo `existente`: adequação de projeto com código

1. **Inventário somente leitura.** Stack, comandos reais (lint, testes, build), ambientes, pastas de documentação existentes, labels e acúmulo (branches antigas, arquivos de relatório, specs e skills copiadas). Não altere nada nesta etapa.
2. **ADRs inferidas.** Infira as decisões já tomadas a partir do código, do histórico e da documentação. Proponha a lista para aprovação. Não escreva ADR sem aceite.
3. **Configuração.** Preencha com os comandos reais. Se um comando não existir, registre `pendente`.
4. **Acúmulo.** Liste o acúmulo para decisão. A retirada segue o procedimento de `docs/PROCESSO.md` (seção Acúmulo): a cópia vai para `raiz_aposentados`, fora do repositório, e o original só é removido com lista e confirmação. Sem confirmação, nada sai.
5. **Sem reorganização em massa.** Mudança cosmética, renomeação de pastas e reformatação não entram nesta adoção.
6. **Trabalho real de adequação** (por exemplo, criar a suíte de aceite, corrigir gate que falha, documentar uma ADR importante) vira **no máximo um épico de adequação**, com filhas escolhidas pelo mantenedor. Nada cosmético vira issue.
7. Se a adoção for só mecânica (manifesto, Configuração e labels), faça uma PR única.

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
- ADRs propostas (modos `novo` e `existente`), e o que foi aceito.
- Acúmulo listado e o que foi copiado para a raiz de aposentados.
- PR aberta, ou motivo de não abrir.

## Não faça

- Não copie `skills/` nem o script de verificação do template para o projeto.
- Não altere código de aplicação nesta skill.
- Não crie repositório, label, configuração de branch, workflow ou PR sem autorização na invocação.
- Não apague branch, label ou arquivo sem lista e confirmação.
- Não deixe placeholder em `comandos` ou `ambientes` sem sinalizar.
- Não crie usuário real ou credencial de teste fora de local e preview.
