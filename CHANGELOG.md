# Changelog do processo

Cada versão do processo tem uma entrada. O `adotar-processo`, no modo `atualizar`, lê as notas de migração entre a `processo_versao` do projeto e a versão atual, nesta ordem.

## 4

Orientação opcional de prontidão para sites, com avaliação de aplicabilidade, evidências e verificações além dos 20 elementos originais.

- `docs/PROCESSO.md` inclui uma checklist de itens recomendados e condicionais para projetos com site, com espaço para registrar estado e justificativa.
- A checklist esclarece que não é garantia de prontidão ou conformidade e acrescenta segurança, desempenho, testes automatizados, monitoramento, falhas de servidor e acessibilidade.

### Notas de migração desde a versão 3

1. Atualize `docs/PROCESSO.md` pelo manifesto (`copy`), preservando os valores específicos do projeto na seção Configuração: `comandos`, `ambientes` e `stack`.
2. Defina `processo_versao: 4` na Configuração do projeto. A checklist de prontidão para sites é usada quando pertinente e não torna todos os itens obrigatórios.

## 3

Ambientes reais (DEV, STAGING e PROD), higiene da máquina com lista aprovada e README de uso.

- Matriz de ambientes com três linhas: `dev`, `staging` e `prod`. `local` e `clone_prod` saem da Configuração. A máquina local segue a linha `dev`.
- STAGING é o preview e um clone sandbox de produção, com dados copiados de produção e sem dados sintéticos. O ensaio de migração acontece em STAGING.
- Identidade de teste: usuários sintéticos só em DEV. Em STAGING, uma conta criada no sandbox.
- Containers de desenvolvimento e de teste sobem sob demanda, sem `restart: unless-stopped` nem `always`. Mecanismos de teste removem o que criam, inclusive quando são interrompidos. Os nomes de recursos seguem `<projeto>-<finalidade>-<pid>-<8 hex>`.
- Estado real antes de agir: as skills de etapa conferem a issue e a PR no GitHub antes de agir, sem confiar só no `.agent/`.
- `higiene-maquina`: branch integrada por squash só é segura com PR mesclada e ponta conferida. Recursos Docker órfãos de execuções de teste são listados. O espaço mostrado é o realmente liberável. Há aviso acima de 90% de disco. RASCUNHO mostra a comparação com a `main` e com a issue. A remoção acontece pela lista aprovada, com revalidação (`--remover`). A máquina pode ser inventariada por entrada padrão via ssh.
- `scripts/testar-template.sh` roda os testes automatizados da higiene.
- README com a seção de uso no dia a dia.

### Notas de migração desde a versão 2

Para um projeto que já adotou a versão 2:

1. Na Configuração de `docs/PROCESSO.md` do projeto, substitua as linhas `local` e `clone_prod` pela matriz de três linhas: `dev`, `staging` e `prod`. Os valores de `dev` vêm do que era `local` (se o projeto confirmar), ou do que era `dev`. Os valores de `staging` são os de `staging`. `prod` fica sempre `nao`. Projeto sem staging marca `nao` e registra o motivo.
2. Atualize `docs/PROCESSO.md` pelo manifesto (modo `copy`), preservando a Configuração do projeto: recoloque os valores de `comandos`, `ambientes` e `stack`. Defina `processo_versao: 3`.
3. Atualize `docs/ambientes.md`: DEV tem os dados sintéticos e as identidades de teste. STAGING é o sandbox de produção, com a conta de teste criada nele. Remova do texto qualquer referência a preview com dados sintéticos ou a clone de produção.
4. Revise os compose de desenvolvimento e de teste. Retire `restart: unless-stopped` e `always`. Esse é um trabalho de adequação do projeto: não faça na adoção, e registre como ticket da adequação se houver muitos serviços.
5. Revise os mecanismos de teste que criam recursos (container, volume, rede, banco, pasta temporária). Eles precisam remover o que criaram também quando são interrompidos, e usar o nome `<projeto>-<finalidade>-<pid>-<8 hex>`. Também é trabalho de adequação do projeto.
6. Confirme que as skills de etapa do projeto estão instaladas (ver a seção Skills de `docs/PROCESSO.md`). A instalação por máquina traz as versões novas com `instalar-processo --atualizar`.

## 2

Reescrita do processo para fatias verticais, Spec pronta, validação dentro do ticket e distribuição por máquina.

- Hierarquia épico, ticket, PR e tarefa. Fatias com `Refs #` e a última com `Closes #`. Sem unidades de tempo.
- Suíte de aceite do épico, escrita no primeiro ticket e ativada no ticket que fecha o épico.
- Gate "Spec pronta" no `spec-issue`. Investigações antes da aprovação.
- Requisitos de Segurança acionados pela superfície, com itens novos.
- Ciclo de validação visual dentro do ticket de interface.
- Um dono por regra: `AGENTS.md` com invariantes e ponteiros, `docs/PROCESSO.md` com o procedimento e a Configuração.
- Matriz de ambientes, identidade de teste e clone de produção como ambiente de ensaio.
- Segredos com um `.env` por projeto e `.env.example` com referências `op://`.
- Labels pelo manifesto `.github/labels.yml`. Formulário `melhoria.yml`.
- Review com marcador `<!-- review-pr ... -->`, lido por `merge-gate` e `tratar-findings` nas três fontes.
- Skills novas: `instalar-processo`, `adotar-processo` e `higiene-maquina`. A `higiene-git` foi substituída.
- Formulários e template de PR em pt-BR.
- Label `type:chore` no conjunto final. `duplicate`, `invalid` e `wontfix` são mantidos.
- `delete_branch_on_merge` ligado no repositório. Branches com PR mesclada são removidas.
- `higiene-maquina` classifica branch integrada por PR mesclada por squash como seguro remover, e nunca como resgate quando o GitHub confirma a PR ou o commit. Reconhece as organizações do usuário como donas de remoto e classifica a branch em uso no checkout principal.
- `instalar-processo` varre `~/.codex/skills`, `~/.config/opencode/skills` e `~/.hermes/skills` e só conta as skills de fora do processo, sem copiá-las, movê-las ou removê-las. A desinstalação de outros pacotes de skills é manual.
- Cada issue tem uma só branch, com o número da issue no nome. Não se rastreia a `main`.
- Plano de reversão por tipo de migração: aditiva (backup do provedor recente), transformadora (expandir e contrair, dump das tabelas afetadas), destrutiva (ensaio no clone de produção, dump das tabelas afetadas).
- Invariante 8 do `AGENTS.md`: nada é resolvido por tentativa silenciosa.
- `accessibility` entra na lista de remoção após remarcação.
- Skills próprias do projeto ficam em `.agents/skills/` (com link em `.claude/skills/`) e nunca são removidas pela adoção.
- `scripts/verificar-template.sh` verifica links e segredos também em arquivos não rastreados (e não ignorados), antes do stage.

### Notas de migração desde a versão 1

Para um projeto que já adotou a versão 1:

1. Atualize `docs/PROCESSO.md` e `AGENTS.md` pelo manifesto (modo `copy`). Preserve a Configuração do projeto: copie só o procedimento e recoloque os valores de `comandos`, `ambientes` e `stack` depois.
2. Adicione `processo_versao: 2` à Configuração.
3. Substitua `.github/ISSUE_TEMPLATE/*.yml` e `.github/pull_request_template.md` pelos do template. O PR template passa a ter as seções Documentação e Roteiro de aceite manual.
4. Crie `.github/labels.yml` e aplique o conjunto final. Remarque os labels em uso antes de remover qualquer um, e peça autorização para criar ou alterar labels. Ligue `delete_branch_on_merge` (com autorização).
4a. Não remova `duplicate`, `invalid` nem `wontfix`. Remova `good first issue`, `help wanted` e `question` só com a lista confirmada pelo mantenedor.
5. Se o projeto tiver a skill `higiene-git` instalada na máquina, substitua-a pela `higiene-maquina` com `instalar-processo`.
6. Classifique as skills do projeto conforme `docs/PROCESSO.md` (seção Skills) e o passo 3a do `adotar-processo`. Remova as do processo, que agora são instaladas por máquina. Mova as próprias do projeto de `skills/` para `.agents/skills/`, com o link em `.claude/skills/`. Nunca remova uma skill própria. Ajuste o `CLAUDE.md` do projeto para o texto novo do manifesto (`@AGENTS.md` e a seção Claude Code). Os links de `.claude/skills/` das skills próprias continuam.
7. Abra uma PR única com a adoção, sem reorganizar o código nem a documentação.

## 1

Bootstrap do template de processo de trabalho: AGENTS, PROCESSO, skills de cada etapa e formulários de issue e PR.
