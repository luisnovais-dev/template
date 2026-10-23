# Processo de trabalho

Este documento é o dono do procedimento: como uma mudança passa de um relato até o main remoto, quais são as regras de autorização, de worktree, de ambiente e de documentação, e onde ficam os valores de configuração. As regras invariantes para qualquer agente estão em [`AGENTS.md`](../AGENTS.md). As etapas são executadas pelas skills em `skills/`. Os valores que as skills leem estão na seção [Configuração](#configuração).

Cada regra tem um único dono. As demais seções e arquivos citam a chave, não repetem o texto.

## Regras não negociáveis

1. O main remoto não é branch de desenvolvimento.
2. Cada mudança nasce em uma branch e em uma worktree próprias.
3. Nenhum segredo, arquivo `.env`, cookie, backup, log, coverage ou arquivo temporário entra em commit.
4. Nenhuma ação em produção é executada sem revisão, aprovação humana e instrução explícita na invocação.
5. Nenhum conflito, falha de check ou divergência é resolvido por tentativa silenciosa.
6. O gerenciador de dependências e o lockfile são os definidos em [Configuração](#configuração).

## Hierarquia

O trabalho é fatiado por capacidade do usuário (vertical), não por camada técnica.

| Nível | O que é | Onde vive | Regra |
|---|---|---|---|
| **Épico** | Uma capacidade que o usuário consegue usar do início ao fim | Issue `epic.yml` | Tem plano, dono, cenários Given/When/Then, grafo de tickets por papel e suíte de aceite. É demonstrável pelo consumidor real. Épico só de backend exige justificativa e consumidor declarado. |
| **Ticket** | Uma entrega com Spec e aprovação | Issue `feature.yml` ou `melhoria.yml` | Declara "Parte de #", "Bloqueado por #", "Paralelizável com #" e as áreas ou arquivos que toca. |
| **PR** | Uma unidade revisável | Pull request | Uma por ticket, por padrão. Fatias opcionais usam `Refs #n`, e a última usa `Closes #n`. |
| **Tarefa** | Passo da Spec | Checklist da Spec | Ordenada, com critério de conclusão e teste. Tarefa não é commit. |

Não há número fixo de tickets por épico, nem estimativa em unidades de tempo. Dependências entre tickets usam sub-issues e dependências nativas do GitHub quando disponíveis. Tickets só são paralelizáveis quando não tocam os mesmos arquivos.

## Fluxo

| Etapa | Skill | Entrada | Saída |
|---|---|---|---|
| 0. Relato | `relato-para-issue` | Queixa, dor, história ou pedido em linguagem livre | Issue publicada, com capacidade, cenários e tipo (bug, ticket ou épico) |
| 1. Especificação | `spec-issue` | Issue e código relacionado | Spec, Tasks, Requisitos de Segurança, matriz de rastreabilidade, comentadas na issue |
| 1a. Aprovação | (humana) | Spec | Aprovação explícita na conversa, seguida do label de aprovação |
| 2. Implementação | `implementar-spec` | Spec aprovada | Commits atômicos na branch, com testes, documentação e validação visual quando houver interface |
| 3. Auditoria | `auditar-spec` | Implementação | Relatório PASS, PARTIAL, FAIL ou NOT TESTED por Requirement, Acceptance Criterion e Task |
| 3a. Aceite local | (humana) | Relatório e roteiro de aceite manual | Aceite do mantenedor, validado localmente |
| 4. Pull request | `abrir-pr` | Branch auditada | PR com o template, vinculada à issue |
| 5. Review independente | `review-pr` | PR | Review em contexto novo, com findings classificados e marcador |
| 5.2. Remediação | `tratar-findings` | Findings | Correções com TDD e resposta a cada finding |
| 5.3. Re-review | `review-pr` (modo re-review) | Correções | Status de cada finding e nova verificação do diff incremental |
| 6. Merge gate | `merge-gate` | PR com review válido | Squash merge, branch e worktree limpas |

### Etapa 0: relato para issue

A skill `relato-para-issue` traduz o relato em: pessoa e situação, dor, contorno atual, resultado esperado, capacidade, cenários derivados e tipo. Hipóteses viram pergunta. Temas misturados são separados em issues distintas. Antes de publicar, a busca por duplicatas abertas e fechadas é obrigatória. A issue usa o formulário YAML de `.github/ISSUE_TEMPLATE/`. Uma issue só entra em trabalho depois de aprovada.

### Etapa 1: especificação

A Spec contém requisitos funcionais e não funcionais, comportamento esperado, regras de negócio, decisões técnicas, Requisitos de Segurança aplicáveis, critérios de aceite verificáveis, casos de erro e invariantes. Ela é decomposta em Tasks pequenas e ordenadas, cada uma com objetivo, arquivos, dependências, critérios de conclusão e testes.

A Spec só é aprovável no gate **Spec pronta**, verificado pela `spec-issue`:

- as investigações foram feitas antes da aprovação, e nenhuma Task é de tipo "verificar" ou "obter aceite";
- o mapa de telas, o contrato visual e o contrato de API, quando houver, estão aceitos com a Spec;
- toda premissa foi verificada. Premissa não verificada torna a Spec não aprovável;
- falta de acesso vira pendência bloqueante, pedida no planejamento.

A Spec lista os documentos afetados, classifica o risco como **comum** ou **sensível** (sensível: autenticação, dados pessoais, financeiro, migração destrutiva ou produção) e propõe ADR quando houver decisão transversal.

Quando há fronteira entre front e back, a Spec traz o contrato da interface, com verificação automática de divergência (ver [Contrato](#contrato-e-testes)).

### Etapa 1a: aprovação

A aprovação é dada pelo mantenedor na conversa. Só depois dela o agente comenta a Spec na issue e aplica o label de aprovação (`label_aprovacao`). Esse label é um controle do processo, não do código.

### Etapa 2: implementação

- Execução das Tasks na ordem da Spec, sem pausas entre elas, exceto por bloqueio real (decisão que a Spec não cobre).
- TDD para cada comportamento testável, em dois níveis: teste de aceitação do épico (ver [Contrato e testes](#contrato-e-testes)) e teste unitário do ticket. RED: teste que falha pelo motivo esperado. GREEN: implementação mínima. REFACTOR: com testes verdes. Falha de configuração, import, fixture ou ambiente não conta como RED válido.
- Antes de criar um mecanismo de teste ou verificação, o agente procura o que já existe. O mecanismo criado é versionado, declarado na Configuração, documentado e genérico. Scripts ou configurações por PR ou issue são proibidos.
- Commits pequenos e atômicos, cada um deixando o código consistente. Tasks não são commits.
- Decisões que surgirem durante a implementação são classificadas: **produto** (emenda da Spec na issue, com aceite do mantenedor), **técnica local** (registrada na PR) ou **transversal** (ADR em `docs/adr/`). A auditoria conta as emendas.
- Ao concluir uma Task, o registro de progresso em `.agent/progresso.md` (não versionado) recebe comportamentos, testes, resultados, commits e desvios.
- Mudança de interface segue o [ciclo de validação visual](#validação-visual) dentro do próprio ticket.
- Sem squash durante o desenvolvimento.

### Etapa 3: auditoria

Os comandos de verificação configurados são executados, assim como os testes de integração e os cenários E2E que a Configuração definir. Cada Requirement, Acceptance Criterion e Task recebe PASS, PARTIAL, FAIL ou NOT TESTED com evidência. A auditoria também confirma: Tasks concluídas, critérios cobertos, Requisitos de Segurança atendidos (ou marcados como não aplicáveis), alterações fora do escopo, alterações de esquema ou de dados não previstas, documentação afetada atualizada, emendas da Spec e riscos residuais.

Ticket de interface sem a evidência do ciclo visual é bloqueado nesta etapa. A auditoria também produz o **roteiro de aceite manual** (ver [Roteiro de aceite](#roteiro-de-aceite-manual)).

### Etapa 4: pull request

A PR usa o template em `.github/pull_request_template.md`. Ela referencia a Spec, lista as Tasks marcadas apenas quando satisfeitas e registra a verificação com resultados reais. Testes não executados não são marcados como aprovados.

Regras da PR:

- Vinculada a uma issue, com `Closes #<n>` na última fatia, ou `Refs #<n>` nas fatias intermediárias.
- Exatamente um label `type:*`.
- Abaixo do teto de linhas, ou com o label de exceção de tamanho (ver [Tamanho de PR](#tamanho-de-pr)).
- Seção "Documentação" preenchida (ver [Gate de documentação](#gate-de-documentação)).
- Seção "Roteiro de aceite manual" preenchida.
- Não há criação de PR sem a instrução explícita do mantenedor na invocação.

### Etapa 5: review independente

O revisor não participou da implementação e roda em contexto novo, de preferência com modelo diferente. Ele não altera código. Ele avalia correção, aderência à issue e à Spec, critérios de aceite, invariantes, regressões, validação de entrada, autorização por perfil, isolamento entre clientes, tratamento de erros, segurança (incluindo os Requisitos de Segurança declarados), concorrência, consistência entre frontend e backend, consistência de renderização quando aplicável, performance de consultas, testes ausentes ou frágeis, documentação e alterações fora de escopo.

Os findings são classificados como:

- **BLOCKING:** CRITICAL, HIGH ou MEDIUM. Precisam de correção antes do merge.
- **NON-BLOCKING:** LOW ou NIT. Também são corrigidos, por decisão do mantenedor. Só viram issue de follow-up o que o mantenedor decidir não corrigir.
- **ACCEPTED / DOCUMENTED RISKS:** limitações já registradas na Spec ou na PR. Não são findings da implementação.

Cada finding traz severidade, arquivo e linha, comportamento observado, comportamento esperado, justificativa, cenário que reproduz e sugestão de correção. Findings especulativos não são registrados.

O review é publicado com o marcador descrito em [Review como comentário](#review-como-comentário).

### Etapa 5.2: remediação

Todo finding aplicável é tratado, bloqueante ou não. Para cada bug confirmado, vale o TDD da etapa 2. Não se resolve finding sem evidência de correção. Ao final, cada finding recebe resposta na PR com: causa, correção, teste que reproduziu, teste que comprova a correção e commit correspondente.

### Etapa 5.3: re-review

O revisor confirma cada finding como RESOLVED, PARTIALLY RESOLVED ou UNRESOLVED, revisa o diff incremental em busca de regressões introduzidas pela correção e faz a verificação final contra a issue e a Spec. Um marcador com SHA diferente do HEAD atual exige re-review.

### Etapa 6: merge gate

O merge gate verifica: HEAD revisado contra o HEAD atual da PR, estado dos checks obrigatórios, conflitos com o main remoto, commits inesperados, segredos ou arquivos de ambiente no diff, documentação conferida, suíte de aceite do épico (quando a PR fecha o épico) e limitações conhecidas.

Resultados possíveis:

- **READY FOR SQUASH MERGE:** sem blockers concretos. Pode fazer o squash.
- **NOT READY FOR MERGE:** somente com blockers concretos identificados.

`NOT VERIFIED` não equivale a FAIL. Um review em estado COMMENTED não é tratado como bloqueio automaticamente, mas o [review válido](#review-como-comentário) é lido de três fontes.

A invocação da etapa 6 é a autorização do squash, se o gate estiver verde. Depois do merge, a branch remota e a worktree são limpas (ver [Worktrees e branches](#worktrees-e-branches)).

## Contrato e testes

### Épico e suíte de aceite

- O plano do épico tem cenários Given/When/Then, o grafo de tickets por papel (contrato, persistência, regra, interface, integração e aceite) e, quando houver fronteira entre front e back, o esboço do contrato.
- A suíte de aceite do épico é escrita no primeiro ticket, marcada como pendente com a tag do épico, e ativada no ticket que fecha o épico.
- O épico só fecha com a suíte verde na `main` integrada. O `merge-gate` não fecha o épico sem ela.

### Contrato

Quando há fronteira entre front e back, existe uma fonte única da interface, com verificação automática de divergência. O mecanismo (tipos gerados, validação em runtime ou contract test) fica a critério da stack, e é declarado na Configuração.

### Feature flag

Feature flag é obrigatório quando código mesclado expõe ao usuário um comportamento incompleto. O flag fica desligado em produção, ligado em local e em preview, e é removido no ticket que fecha o épico.

## Ambientes

A matriz de ambientes fica na [Configuração](#configuração), chave `ambientes`. Ela define, para cada ambiente, se o agente pode ler, testar, escrever dados e fazer deploy sem pedir nova autorização na invocação.

- **Local, DEV, STAGING e CLONE_PROD** podem ser pré-autorizados pela matriz, quando configurados como tal.
- **PROD** nunca é pré-autorizado para escrita, teste ou deploy. Leitura só ocorre por acesso somente leitura configurado e com pedido explícito.
- Testes e comandos de escrita conferem o alvo antes de executar (invariante 5 de [`AGENTS.md`](../AGENTS.md)).

### Preview

Preview tem build igual ao de produção, dados sintéticos, segredos próprios, acesso protegido e usuários de teste. Mudança sensível exige aceite no preview, ou o flag desligado quando não houver preview.

### Identidade de teste

- Usuários sintéticos por perfil existem em local e em preview. A sessão de teste é obtida sem interação para o agente.
- Há um teste que prova a indisponibilidade desses usuários em produção.
- O agente nunca usa credencial real de pessoa.

### Clone de produção

O clone de produção é o ambiente de ensaio de migrações. Ele é isolado, nunca é escrito pelo E2E automático, é recriado sob demanda e tem os definers removidos. Antes de migração, a reversão é planejada por tipo:

- **aditiva:** reversão é remover o que foi adicionado, sem perda de dados;
- **transformadora:** reversão exige backup verificado e rotina de conversão inversa;
- **destrutiva:** exige aprovação explícita e backup verificado antes da execução.

O baseline de schema fica numa PR própria, e a CI verifica paridade entre o schema e o baseline.

## Segredos

- Um `.env` por projeto, na raiz do checkout principal, compartilhado pelas worktrees por link ou caminho, com prefixos por ambiente.
- `.env.example` versionado contém somente referências `op://` do 1Password, preenchidas por `op inject`.
- O comando `env:check` (chave `env_check` da Configuração) confere a presença das chaves sem exibir valores.
- Nenhum arquivo de segredo é versionado, nem criptografado.
- Segredos não aparecem em skills, exemplos, issues, PRs, logs ou saídas de script.

## Requisitos de Segurança

A Spec lista os Requisitos de Segurança acionados pela superfície da mudança. Mudança sem superfície registra "não aplicável" numa linha. Itens aplicáveis quando houver a superfície:

- autorização por perfil e isolamento entre clientes;
- trilha de auditoria para ações sensíveis;
- cabeçalhos de segurança em respostas HTTP;
- guarda do modo de teste, que impede ativar identidade de teste em produção;
- plano de reversão de schema, conforme [Clone de produção](#clone-de-produção).

## Interface

### Contrato visual

Imagem ou referência enviada pelo usuário pode ser a fonte de verdade. A Spec traz o inventário de elementos, classificados como adotado, adaptado (com motivo), descartado ou divergente entre imagens, e a fidelidade (próxima ou inspiração). O repositório é a única fonte de verdade da interface. Claude Design é opcional e tem uma direção só.

### Validação visual

Ciclo dentro do ticket de interface, sem ticket separado:

1. captura automática das telas alteradas, em desktop e mobile;
2. autoavaliação por modelo de visão, comparando com o inventário da Spec;
3. correção dos desvios;
4. E2E do fluxo alterado.

A evidência (capturas e resultado da autoavaliação) vai para a PR. A auditoria bloqueia o ticket sem ela. Quando não houver ferramenta de captura configurada, a captura é feita manualmente e anexada.

### Roteiro de aceite manual

A PR e a mensagem final trazem o roteiro: o que foi entregue (funções, telas e rotas), onde testar, conta de teste (pela referência de [Identidade de teste](#identidade-de-teste)), cenários com o resultado esperado e o que já foi verificado automaticamente.

## Gate de documentação

Toda mudança de funcionalidade atualiza a documentação existente, ou cria a seção que falta, antes da abertura da PR. O gate é verificado de ponta a ponta:

- **Spec:** lista os documentos afetados;
- **implementação:** escreve a documentação junto da mudança;
- **auditoria e review:** conferem a documentação contra a Spec;
- **PR:** a seção "Documentação" lista o que foi atualizado;
- **merge-gate:** bloqueia a PR sem a seção preenchida ou sem a atualização.

Quando a mudança altera o que o projeto faz, para quem serve ou o seu status, a linha de descrição do README e a descrição do repositório no GitHub são atualizadas na mesma PR.

### Estrutura de documentação

| Arquivo ou pasta | Conteúdo |
|---|---|
| `docs/PROCESSO.md` | Este documento |
| `docs/adr/` | Decisões transversais, uma por arquivo |
| `docs/dominio.md` | Glossário do domínio |
| `docs/arquitetura.md` | Visão da arquitetura |
| `docs/ambientes.md` | Ambientes, preview e identidade de teste |
| `docs/funcionalidades/` | Uma página por funcionalidade entregue |
| `docs/design-system/` | Tokens e componentes, quando houver interface |
| `docs/referencias/<épico-ou-issue>/` | Referências enviadas pelo usuário, com manifesto |
| `README.md` | Índice de entrada do repositório |

A Spec fica na issue, não em `docs/`. Logs ficam em `.agent/`, que não é versionado. README de pasta só existe como índice.

### Idioma

Texto da organização em pt-BR. Identificadores (código, pastas, tokens, chaves de label e de configuração) em inglês. Um idioma por repositório, e outro só por ADR. O glossário de domínio fica em `docs/dominio.md`.

## Autorização

- **A autorização vale para a invocação.** Quem invoca uma skill com a ação explícita já autorizou aquela ação. Nenhum arquivo versionado concede autorização permanente.
- **Ações que exigem instrução explícita na invocação:** publicar issue, publicar comentário, abrir PR, aplicar label de aprovação, criar label, squash merge, merge, apagar branch remota ou local, remover worktree, remover arquivos, qualquer ação em produção e qualquer deploy fora da matriz de ambientes.
- **Ambientes pré-autorizados** pela [matriz](#ambientes) dispensam nova autorização para a ação que a matriz cobre. Produção nunca é pré-autorizada.
- **Bypass de proteção de branch ou de checks obrigatórios** só acontece com autorização explícita do mantenedor na própria invocação, e somente se a plataforma oferecer esse mecanismo ao usuário. O agente não contorna proteção por conta própria.
- **O bypass administrativo nunca cobre** checks obrigatórios, conflitos, achados pendentes ou mudanças destrutivas.
- Uma etapa autorizada é executada até o fim, sem pausas por cautela, exceto por bloqueio real (decisão que a Spec não cobre).

### Bloqueios da plataforma

Quando o GitHub exige revisão de pessoa diferente do autor:

1. solicitar a revisão de outro colaborador, se houver;
2. se o mantenedor for administrador do repositório e a mudança não envolver ação em produção nem alteração destrutiva, registrar na PR a autorização explícita e o bloqueio de autoaprovação, e usar o mecanismo administrativo somente para esse gate;
3. se a plataforma não oferecer esse mecanismo, parar e registrar o bloqueio.

`REVIEW_REQUIRED` é um bloqueio da plataforma e segue este procedimento. A autorização do mantenedor não concede ao agente uma capacidade que a plataforma não disponibilizou.

## Review como comentário

O `review-pr` publica o review com um marcador HTML na primeira linha e uma linha de status:

```text
<!-- review-pr mode=<review|re-review> sha=<sha> -->
REVIEW STATUS: <estado>
```

`merge-gate` e `tratar-findings` leem três fontes: reviews formais da PR, comentários da PR e comentários inline. Um review é válido se:

- for formal, de identidade diferente da do autor da PR; ou
- tiver o marcador, de qualquer identidade; ou
- o mantenedor declarar o comentário como review.

## Labels

Os labels são definidos no manifesto `.github/labels.yml`. Cada projeto cria o mesmo conjunto com `adotar-processo`.

| Label | Uso |
|---|---|
| `type:feature` | Funcionalidade nova |
| `type:bug` | Correção de comportamento incorreto |
| `type:docs` | Mudança somente de documentação |
| `type:epic` | Agrupamento de entregas que formam uma capacidade |
| `type:enhancement` | Melhoria de funcionalidade existente |
| `status:approved` | Spec aprovada pelo mantenedor |
| `size:exception` | PR acima do teto de tamanho, com justificativa |

Cada PR tem exatamente um `type:*`. Labels não são criados nem alterados no GitHub sem instrução explícita na invocação.

**Normalização.** Um label em uso que não existe no conjunto final é remarcado para o label correto, e só depois é removido. Nenhum label em uso é removido antes da remarcação.

**Branches.** `delete_branch_on_merge` fica ligado no repositório. Branches com PR mesclada são removidas. Branches sem PR são listadas para decisão.

## Tamanho de PR

- **Teto:** `teto_pr_linhas` da Configuração, padrão 2.000 linhas alteradas (adições mais remoções), excluindo arquivos gerados (lockfile, snapshots e código gerado).
- Acima do teto, a PR exige o label `label_excecao_tamanho` e a justificativa na descrição.
- O label de exceção é o único registro de exceção. Uma PR acima do teto sem o label não passa na etapa 4.
- Fatiar é opcional. Quando a Spec prevê tamanho acima do teto, a exceção é decidida na Spec.

## Qualidade e baseline

Falhas de gate confirmadas em um checkout limpo do main remoto são registradas em uma issue `Quality baseline` (formulário `quality-baseline.yml`). A baseline explica por que um gate já falha, mas não aprova regressões novas. A PR precisa demonstrar que não introduz erros nos arquivos e comportamentos que altera.

## Acúmulo

Artefatos antigos (specs, relatórios, skills copiadas e código sem uso) são retirados do repositório. A cópia vai para a raiz de aposentados, fora do repositório. Código legado só sai com prova de não uso.

## Worktrees e branches

Worktree é temporária. Ela é criada para uma mudança e removida ao fim do trabalho, se estiver limpa.

- Prefixos de branch: `prefixos_branch` da Configuração.
- O diretório da worktree depende da ferramenta que a criou. Claude usa `.claude/worktrees/<nome>`. Codex usa `~/.codex/worktrees/<nome>`, fixo pela ferramenta. OpenCode usa o diretório do checkout, conforme a configuração local. Não crie worktree fora do diretório que a ferramenta usa.
- Antes de criar uma worktree, atualize as referências: `git fetch origin --prune`.
- Antes de editar, confirme `git status` limpo, a branch atual e a relação com o main remoto.
- Antes de remover, confirme que não há trabalho não publicado. Não remova worktree de outra sessão.
- Use `git worktree list` para inspecionar, independentemente da localização.
- Branch remota de feature é apagada após o squash merge. Branch local é apagada após o merge, se não houver trabalho não publicado.
- Nenhuma worktree ou branch é removida sem confirmação de que não há trabalho ativo. A skill `higiene-maquina` lista o estado e pede confirmação.

## Estado local

Não limpe branches, worktrees ou artefatos de outra sessão automaticamente. Liste o alvo, confirme que não está associado a trabalho ativo e peça confirmação antes de remover.

## Identidade GitHub

O processo usa a sessão `gh` ativa (`gh auth status`). A conta pode variar por colaborador e não é fixada neste documento. Commits usam a identidade dessa sessão, com o e-mail de noreply do GitHub.

## Manutenção do template

O template tem uma verificação própria: `scripts/verificar-template.sh`. Ela confere links relativos, YAML dos formulários e do manifesto de labels, frontmatter das skills, links simbólicos de `.claude/skills`, `.env` versionado, valores do `.env.example` e padrões de segredo. Rode-a antes de cada commit no template. Ela não vai para os projetos.

## Skills

As etapas do processo estão em `skills/`. Cada skill é um procedimento com entrada, saída e gates. Claude as carrega por `.claude/skills/`, que aponta para cada pasta em `skills/`. Outras ferramentas leem as skills por `~/.agents/skills` (ver `instalar-processo`). A pasta `skills/` não é copiada para os projetos.

## Configuração

Bloco lido pelas skills. Cada projeto que adote o processo preenche os valores, com `adotar-processo`. Enquanto houver placeholder, a skill que depende do valor deve pedir a informação em vez de assumi-la.

```yaml
processo_versao: 2
branch_base: <!-- main remoto, ex.: main -->
prefixos_branch: [feat/, fix/, docs/]
label_tipo: <!-- label type:* escolhido para a PR, exatamente um -->
label_aprovacao: status:approved
label_excecao_tamanho: size:exception
teto_pr_linhas: 2000
env_check: <!-- comando que confere as chaves do .env sem exibir valores, ou vazio -->
comandos:
  lint: <!-- comando de lint -->
  test: <!-- comando de testes unitários -->
  integracao: <!-- comando de testes de integração, ou vazio -->
  typecheck: <!-- comando de verificação de tipos, ou vazio -->
  build: <!-- comando de build, ou vazio -->
  smoke: <!-- comando de verificação de fumaça, ou vazio -->
  e2e: <!-- comando de testes E2E, ou pendente -->
  visual: <!-- ferramenta de validação visual, ou manual -->
ambiente_local: <!-- comando para subir o ambiente local, ou referência à skill ambiente-dev -->
ambientes:
  # Matriz: sim = pré-autorizado na invocação; nao = exige instrução explícita.
  # PROD: leitura só com acesso somente leitura configurado e com pedido.
  local:       {ler: sim, testar: sim, escrever_dados: sim, deploy: nao}
  dev:         {ler: sim, testar: <!-- sim ou nao -->, escrever_dados: <!-- sim ou nao -->, deploy: <!-- sim ou nao -->}
  staging:     {ler: sim, testar: <!-- sim ou nao -->, escrever_dados: <!-- sim ou nao -->, deploy: <!-- sim ou nao -->}
  clone_prod:  {ler: sim, testar: sim, escrever_dados: sim, deploy: nao}
  prod:        {ler: nao, testar: nao, escrever_dados: nao, deploy: nao}
stack:
  gerenciador_pacotes: <!-- ex.: nome do gerenciador -->
  lockfile: <!-- arquivo único de lock -->
  linguagens: <!-- ex.: linguagem e versão -->
  frameworks: <!-- ex.: frameworks principais -->
  servicos_locais: <!-- ex.: banco, fila, armazenamento -->
  regras_adicionais: <!-- regras de stack que valem para todos os agentes -->
```

Os valores de `comandos`, `ambientes` e `stack` são específicos de cada projeto. O template não os preenche.
