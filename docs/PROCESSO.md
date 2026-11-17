# Processo de trabalho

Este documento é o dono do procedimento: como uma mudança passa de um relato até o main remoto, quais são as regras de autorização, de worktree, de ambiente e de documentação, e onde ficam os valores de configuração. As regras invariantes para qualquer agente estão em [`AGENTS.md`](../AGENTS.md), e não são repetidas aqui. As etapas são executadas pelas skills, instaladas por máquina. Os valores que as skills leem estão na seção [Configuração](#configuração).

Cada regra tem um único dono. As demais seções e arquivos citam a chave, não repetem o texto.

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
| 2. Implementação | `implementar-spec` | Spec aprovada | Commits atômicos na branch da issue, com testes, documentação e validação visual quando houver interface |
| 3. Auditoria | `auditar-spec` | Implementação | Relatório PASS, PARTIAL, FAIL ou NOT TESTED por Requirement, Acceptance Criterion e Task |
| 3a. Aceite local | (humana) | Relatório e roteiro de aceite manual | Aceite do mantenedor, validado localmente |
| 4. Pull request | `abrir-pr` | Branch auditada | PR com o template, vinculada à issue |
| 5. Review independente | `review-pr` | PR | Review em contexto novo, com findings classificados e marcador |
| 5.2. Remediação | `tratar-findings` | Findings | Correções com TDD e resposta a cada finding |
| 5.3. Re-review | `review-pr` (modo re-review) | Correções | Status de cada finding e nova verificação do diff incremental |
| 6. Merge gate | `merge-gate` | PR com review válido | Squash merge, branch e worktree limpas, e fechamento do épico quando for o último ticket |

### Estado real antes de agir

Antes de cada etapa que age sobre a issue ou a PR (implementar, auditar, abrir PR, review, merge e tratar findings), a skill confere no GitHub o estado da issue e das PRs ligadas à branch. O registro local em `.agent/` não basta.

1. Estado da issue: `gh issue view <n> --json state`.
2. PRs da branch: `gh pr list --head <branch> --state all --json number,state`.
3. PRs e branches ligadas à issue: GraphQL `closedByPullRequestsReferences(includeClosedPrs: true)`, `gh issue develop --list <n>`, e `git ls-remote --heads origin` filtrado por `*/<n>-*`.

A skill para e reporta, sem agir, se a issue estiver fechada, se a PR da branch estiver mesclada ou fechada, ou se outra branch ou PR estiver ligada à issue. Em `implementar-spec`, a parada também acontece se já houver branch ou PR da issue no remoto.

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

Quando há fronteira entre front e back, a Spec traz o contrato da interface, com verificação automática de divergência (ver [Contrato e testes](#contrato-e-testes)).

### Etapa 1a: aprovação

A aprovação é dada pelo mantenedor na conversa. Só depois dela o agente comenta a Spec na issue e aplica o label de aprovação (`label_aprovacao`). Esse label registra a aprovação da Spec, não da PR.

### Etapa 2: implementação

- Execução das Tasks na ordem da Spec, sem pausas entre elas, exceto por bloqueio real (decisão que a Spec não cobre).
- Uma issue, uma branch e uma worktree (ver [Worktrees e branches](#worktrees-e-branches)).
- TDD para cada comportamento testável, em dois níveis: teste de aceitação do épico (ver [Contrato e testes](#contrato-e-testes)) e teste unitário do ticket. RED: teste que falha pelo motivo esperado. GREEN: implementação mínima. REFACTOR: com testes verdes. Falha de configuração, import, fixture ou ambiente não conta como RED válido.
- Antes de criar um mecanismo de teste ou verificação, o agente procura o que já existe. O mecanismo criado é versionado, declarado na Configuração, documentado e genérico. Scripts ou configurações por PR ou issue são proibidos.
- Commits pequenos e atômicos, cada um deixando o código consistente. Tarefas não são commits.
- Decisões que surgirem durante a implementação são classificadas: **produto** (emenda da Spec na issue, com aceite do mantenedor), **técnica local** (registrada na PR) ou **transversal** (ADR em `docs/adr/`). A auditoria conta as emendas.
- Ao concluir uma Tarefa, o registro de progresso em `.agent/progresso.md` (não versionado) recebe comportamentos, testes, resultados, commits e desvios.
- Mudança de interface segue o [ciclo de validação visual](#validação-visual) dentro do próprio ticket.
- Sem squash durante o desenvolvimento.

### Etapa 3: auditoria

Os comandos de verificação configurados são executados, assim como os testes de integração e os cenários E2E que a Configuração definir. Cada Requirement, Acceptance Criterion e Task recebe PASS, PARTIAL, FAIL ou NOT TESTED com evidência. A auditoria também confirma: Tarefas concluídas, critérios cobertos, Requisitos de Segurança atendidos (ou marcados como não aplicáveis), alterações fora do escopo, alterações de esquema ou de dados não previstas, documentação afetada atualizada, emendas da Spec e riscos residuais.

Ticket de interface sem a evidência do ciclo visual é bloqueado nesta etapa. A auditoria também produz o **roteiro de aceite manual** (ver [Roteiro de aceite manual](#roteiro-de-aceite-manual)).

### Etapa 4: pull request

A PR usa o template em `.github/pull_request_template.md`. Ela referencia a Spec, lista as Tarefas marcadas apenas quando satisfeitas e registra a verificação com resultados reais. Testes não executados não são marcados como aprovados.

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

O review é publicado com o marcador descrito em [Review como comentário](#review-como-comentário). Quando a identidade do revisor é diferente da do autor, o review é formal (aprovação ou solicitação de mudanças), conforme o resultado. Quando é a mesma, é comentário com o marcador.

### Etapa 5.2: remediação

Todo finding aplicável é tratado, bloqueante ou não. Para cada bug confirmado, vale o TDD da etapa 2. Não se resolve finding sem evidência de correção. Ao final, cada finding recebe resposta na PR com: causa, correção, teste que reproduziu, teste que comprova a correção e commit correspondente.

### Etapa 5.3: re-review

O revisor confirma cada finding como RESOLVED, PARTIALLY RESOLVED ou UNRESOLVED, revisa o diff incremental em busca de regressões introduzidas pela correção e faz a verificação final contra a issue e a Spec. Um marcador com SHA diferente do HEAD atual exige re-review.

### Etapa 6: merge gate

O merge gate verifica: HEAD revisado contra o HEAD atual da PR, estado dos checks obrigatórios, conflitos com o main remoto, commits inesperados, segredos ou arquivos de ambiente no diff, documentação conferida e limitações conhecidas.

Resultados possíveis:

- **READY FOR SQUASH MERGE:** sem blockers concretos. Pode fazer o squash.
- **NOT READY FOR MERGE:** somente com blockers concretos identificados.

`NOT VERIFIED` não equivale a FAIL. Um review em estado COMMENTED não é tratado como bloqueio automaticamente, mas o [review válido](#review-como-comentário) é lido de três fontes.

A invocação da etapa 6 é a autorização do squash, se o gate estiver verde. Depois do merge, a branch remota e a worktree são limpas (ver [Worktrees e branches](#worktrees-e-branches)).

**Fechamento do épico.** Quando a PR é o último ticket filho aberto do épico (todos os outros itens da checklist estão fechados), o merge gate faz mais uma verificação, antes de dar o resultado final:

1. a suíte de aceite do épico está ativada, na branch integrada, e verde;
2. o épico não tem item pendente na checklist;
3. o flag de feature (se houver) está desligado em produção ou será removido nesta PR, conforme o plano.

Se as três condições valem, o merge gate informa "fecha o épico" no resultado. O fechamento do épico é ação separada, e exige instrução explícita na invocação. Sem a suíte verde, o épico não fecha, mesmo com todos os tickets mesclados.

## Contrato e testes

### Épico e suíte de aceite

- O plano do épico tem cenários Given/When/Then, o grafo de tickets por papel (contrato, persistência, regra, interface, integração e aceite) e, quando houver fronteira entre front e back, o esboço do contrato.
- A suíte de aceite do épico é escrita no primeiro ticket, marcada como pendente com a tag do épico, e ativada no ticket que fecha o épico.
- O épico só fecha com a suíte verde na `main` integrada (ver [Etapa 6](#etapa-6-merge-gate)).

### Contrato

Quando há fronteira entre front e back, existe uma fonte única da interface, com verificação automática de divergência. O mecanismo (tipos gerados, validação em runtime ou contract test) fica a critério da stack, e é declarado na Configuração.

### Feature flag

Feature flag é obrigatório quando código mesclado expõe ao usuário um comportamento incompleto. O flag fica desligado em produção, ligado em DEV e em STAGING, e é removido no ticket que fecha o épico.

## Ambientes

A matriz de ambientes fica na [Configuração](#configuração), chave `ambientes`. Ela define, para cada ambiente, se o agente pode ler, testar, escrever dados e fazer deploy sem pedir nova autorização na invocação. É a única pré-autorização permanente que o processo admite, e só vale para as células marcadas como `sim`.

Os ambientes são três: DEV, STAGING e PROD.

- **DEV** é o desenvolvimento, com dados sintéticos. A máquina local de desenvolvimento segue a linha `dev` da matriz. Pode ser pré-autorizado pela matriz, conforme configurado.
- **STAGING** é o preview. É um clone sandbox de produção: dados copiados de produção, isolados dela. Não tem dados sintéticos. Segue a regra da matriz, conforme configurado, com as restrições de [STAGING](#staging).
- **PROD** nunca é pré-autorizado para escrita, teste ou deploy. Leitura só ocorre por acesso somente leitura configurado e com pedido explícito.
- Testes e comandos de escrita conferem o alvo antes de executar (invariante 5 de [`AGENTS.md`](../AGENTS.md)).

### STAGING

STAGING é o preview: build igual ao de produção, clone sandbox de produção, segredos próprios e acesso protegido. Mudança sensível exige aceite em STAGING, ou o flag desligado quando não houver STAGING.

Dados copiados de produção em STAGING:

- não saem do ambiente para chat, issue, PR, log ou arquivo do repositório;
- o E2E automático só escreve em STAGING se a matriz permitir (`staging.escrever_dados: sim`);
- a recriação do sandbox a partir de produção exige instrução explícita na invocação.

### Identidade de teste

- Usuários sintéticos por perfil e fixtures existem só em DEV. A sessão de teste em DEV é obtida sem interação para o agente.
- Em STAGING, a identidade de teste é uma conta criada no sandbox, recriada depois de cada recriação do sandbox. Nunca é credencial de pessoa real.
- Há um teste que prova a indisponibilidade desses usuários e atalhos em produção. Ele é obrigatório.
- O agente nunca usa credencial real de pessoa.

### Ensaio de migração em STAGING

O ensaio de migrações acontece em STAGING. Ele é isolado de produção, nunca é escrito pelo E2E automático e é recriado sob demanda, com instrução explícita. Antes de migração, a reversão é planejada por tipo:

- **aditiva** (coluna que aceita nulo, tabela nova, índice): conferir que o backup automático do provedor existe e é recente. Não exige dump. A reversão é remover o que foi adicionado.
- **transformadora** (troca de tipo, backfill, mudança de formato): expandir e contrair. A migração cria o novo ao lado do antigo, o backfill preenche o novo, o código passa a usar o novo, e o antigo só é removido em outra entrega. Antes, dump somente das tabelas afetadas.
- **destrutiva** (remoção de coluna, tabela ou dados): ensaio em STAGING, que mede a duração e valida a volta, e dump das tabelas afetadas antes da execução. Exige instrução explícita na invocação.

Dump completo do banco não é exigido em nenhum dos tipos.

O baseline de schema fica numa PR própria, e a CI verifica paridade entre o schema e o baseline.

### Serviços locais e mecanismos de teste

- Compose de desenvolvimento e de teste não usa `restart: unless-stopped` nem `always`. O serviço sobe quando o trabalho precisa dele (containers sob demanda). Esses restart policies fazem os containers religarem a cada boot.
- Mecanismo de teste que cria recurso (container, volume, rede, banco ou pasta temporária) o remove ao terminar, inclusive quando a execução é interrompida. Ele trata os sinais (INT, TERM, HUP), e não só o `finally`.
- O nome do recurso segue `<projeto>-<finalidade>-<pid>-<8 hex>`, em que `<pid>` é o PID do processo que coordena a execução. A [higiene da máquina](#skills) reconhece esse formato para separar órfão de ativo.

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
- plano de reversão de schema, conforme [Ensaio de migração em STAGING](#ensaio-de-migração-em-staging).

## Interface

### Contrato visual

Imagem ou referência enviada pelo usuário pode ser a fonte de verdade. A Spec traz o inventário de elementos, classificados como adotado, adaptado (com motivo), descartado ou divergente entre imagens, e a fidelidade (próxima ou inspiração). O repositório é a única fonte de verdade da interface. Claude Design é opcional, tem uma direção só, e o canvas dele não faz parte da definição de pronto: o que vale é o código no repositório validado pelo ciclo visual.

### Validação visual

Ciclo dentro do ticket de interface, sem ticket separado:

1. captura automática das telas alteradas, em cada superfície listada em `visual_superficies` da Configuração;
2. autoavaliação por modelo de visão, comparando com o inventário da Spec;
3. correção dos desvios;
4. E2E do fluxo alterado.

As superfícies são as larguras que o produto tem, declaradas em `visual_superficies`: `[desktop, mobile]`, `[mobile]` ou `[desktop]`. Uma superfície ausente do produto é marcada "não aplicável" na Spec, com justificativa de uma linha, e a auditoria aceita a marcação. Ticket de interface sem evidência das superfícies declaradas é bloqueado. A evidência (capturas e resultado da autoavaliação) vai para a PR. Quando não houver ferramenta de captura configurada, a captura é feita manualmente e anexada.

### Roteiro de aceite manual

A PR e a mensagem final trazem o roteiro: o que foi entregue (funções, telas e rotas), onde testar, conta de teste (pela referência de [Identidade de teste](#identidade-de-teste)), cenários com o resultado esperado e o que já foi verificado automaticamente.

## Prontidão de sites

Use esta checklist em projetos que oferecem um site. Ela ajuda a avaliar o que é pertinente ao contexto; não exige que todo projeto implemente todos os itens e não garante, sozinha, prontidão para produção ou conformidade legal. Decisões jurídicas dependem do tratamento de dados, do serviço e das obrigações aplicáveis.

Ao adaptar a checklist ao projeto, registre o estado de cada item e a evidência ou justificativa. Para itens condicionais ou não aplicáveis, explique a decisão. Não trate `robots.txt` como controle de segurança, nem suponha que um sitemap garanta indexação ou que mecanismos de busca exibam a meta description fornecida.

| # | Categoria | Elemento | Aplicabilidade e orientação | Estado no projeto | Evidência ou justificativa |
|---:|---|---|---|---|---|
| 1 | Experiência e acessibilidade | Página 404 personalizada | Recomendada quando o site tem rotas próprias; explique o erro e ofereça um caminho de retorno. | A preencher | A preencher |
| 2 | Conversão e marketing | CTA no topo da página | Condicional: use quando houver uma ação principal clara, como agendar ou pedir orçamento. | A preencher | A preencher |
| 3 | SEO e descoberta | Meta title por página | Recomendado para páginas públicas; descreva o conteúdo de cada página. | A preencher | A preencher |
| 4 | SEO e descoberta | Meta description por página | Recomendada para resumir páginas públicas; buscadores podem exibir outro texto. | A preencher | A preencher |
| 5 | SEO e descoberta | Imagem Open Graph | Recomendada para páginas que serão compartilhadas; forneça uma prévia coerente com a marca e o conteúdo. | A preencher | A preencher |
| 6 | Identidade e infraestrutura | Conjunto de favicons | Recomendado para identificar a marca em abas, favoritos e atalhos. | A preencher | A preencher |
| 7 | SEO e descoberta | `robots.txt` | Condicional: oriente rastreadores que respeitam o arquivo; ele não protege conteúdo nem substitui autorização. | A preencher | A preencher |
| 8 | SEO e descoberta | `sitemap.xml` | Recomendado quando há páginas públicas relevantes a descobrir; não garante indexação. | A preencher | A preencher |
| 9 | SEO e descoberta | Texto alternativo em imagens | Recomendado para imagens informativas, com descrição útil; imagens decorativas devem usar `alt=""`. Considere acessibilidade além de `alt`. | A preencher | A preencher |
| 10 | Experiência e acessibilidade | Versão mobile ajustada | Recomendada para todas as páginas; conteúdo e controles devem funcionar em telas estreitas. | A preencher | A preencher |
| 11 | Conversão e marketing | CTA fixo no celular | Condicional: só use se facilitar a ação principal sem cobrir conteúdo ou atrapalhar navegação. | A preencher | A preencher |
| 12 | Experiência e acessibilidade | Telas de carregamento | Use indicadores quando uma operação assíncrona ou demorada deixar o resultado temporariamente indisponível. | A preencher | A preencher |
| 13 | Experiência e acessibilidade | Erros de formulário | Condicional: formulários devem explicar o erro e orientar a correção junto ao campo afetado. | A preencher | A preencher |
| 14 | Conversão e marketing | Página de confirmação | Condicional: após uma ação concluída, confirme o resultado e explique os próximos passos. | A preencher | A preencher |
| 15 | Jurídico e transparência | Política de privacidade | Avalie quando houver tratamento de dados pessoais ou outra obrigação aplicável; descreva as práticas reais. | A preencher | A preencher |
| 16 | Jurídico e transparência | Termos de uso | Condicionais ao serviço e à relação com o usuário; descreva regras que realmente se aplicam. | A preencher | A preencher |
| 17 | Jurídico e transparência | Banner de cookies | Condicional: avalie as tecnologias usadas e as obrigações aplicáveis; banner de consentimento não é necessário em todos os sites. | A preencher | A preencher |
| 18 | Conversão e marketing | Analytics instalado | Condicional: adote quando houver uma pergunta de negócio e uma base apropriada para coleta e uso dos dados. | A preencher | A preencher |
| 19 | Jurídico e transparência | Endereço de contato real | Recomendado: disponibilize canais verdadeiros e acessíveis. Endereço físico depende do negócio e não é necessário em todo serviço digital. | A preencher | A preencher |
| 20 | Identidade e infraestrutura | Domínio próprio com HTTPS | HTTPS protege a conexão e é recomendado para todo site. Domínio próprio reforça a identidade da organização. | A preencher | A preencher |

### Verificações além da checklist

Os 20 elementos não cobrem todo o trabalho de produção. Avalie também, conforme a aplicação:

- **Segurança:** autenticação e autorização quando existirem contas, proteção de dados e segredos, dependências e configurações seguras.
- **Desempenho:** carregamento e resposta das páginas nos dispositivos e conexões esperados.
- **Testes automatizados:** fluxos críticos, validações e comportamento em falhas.
- **Monitoramento:** erros da aplicação, indisponibilidade e falhas do servidor, com alertas e tratamento apropriados.
- **Acessibilidade:** navegação por teclado, foco, estrutura semântica, contraste, ampliação de texto e comunicação de atualizações, além dos textos alternativos.

Registre os critérios e evidências pertinentes ao produto na Spec e na documentação do projeto. Use a matriz de risco e os [Requisitos de Segurança](#requisitos-de-segurança) quando aplicáveis.

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
| `docs/ambientes.md` | Ambientes (DEV, STAGING e PROD) e identidade de teste |
| `docs/funcionalidades/` | Uma página por funcionalidade entregue |
| `docs/design-system/` | Tokens e componentes, quando houver interface |
| `docs/referencias/<épico-ou-issue>/` | Referências enviadas pelo usuário, com manifesto |
| `README.md` | Índice de entrada do repositório |

A Spec fica na issue, não em `docs/`. Logs ficam em `.agent/`, que não é versionado. README de pasta só existe como índice.

### Idioma

Texto da organização em pt-BR. Identificadores (código, pastas, tokens, chaves de label e de configuração) em inglês. Um idioma por repositório, e outro só por ADR. O glossário de domínio fica em `docs/dominio.md`.

## Autorização

- **A autorização vale para a invocação.** Quem invoca uma skill com a ação explícita já autorizou aquela ação.
- **Única exceção permanente:** a matriz de ambientes da Configuração. Uma célula marcada como `sim` dispensa nova autorização para a ação correspondente, naquele ambiente. Nenhuma outra configuração versionada concede autorização. Produção nunca é pré-autorizada.
- **Ações que exigem instrução explícita na invocação:** publicar issue, publicar comentário, abrir PR, aplicar label de aprovação, criar ou alterar label, squash merge, fechar épico, apagar branch remota ou local, remover worktree, remover arquivos, qualquer ação em produção e qualquer deploy fora da matriz.
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

Os nomes, cores e descrições dos labels estão em `.github/labels.yml`, que é a fonte única desse conjunto. Este documento define as regras de uso:

- Cada PR tem exatamente um `type:*`.
- `status:approved` registra a aprovação da Spec. Nunca aprova a PR.
- `size:exception` é o único registro de exceção de tamanho.
- `duplicate`, `invalid` e `wontfix` fazem parte do conjunto final e não são removidos pela normalização.
- Labels não são criados nem alterados no GitHub sem instrução explícita na invocação.

**Normalização.** Um label em uso que não está no manifesto é remarcado para o correspondente (seção `remarcar` do manifesto) e só depois é removido. Os que não têm correspondente vão para decisão do mantenedor, com lista. Nenhum label em uso é removido antes da remarcação.

**Branches.** `delete_branch_on_merge` fica ligado no repositório. Branches com PR mesclada são removidas. Branches sem PR são listadas para decisão.

## Tamanho de PR

- **Teto:** `teto_pr_linhas` da Configuração, padrão 2.000 linhas alteradas (adições mais remoções), excluindo arquivos gerados (lockfile, snapshots e código gerado).
- Acima do teto, a PR exige o label `label_excecao_tamanho` e a justificativa na descrição.
- O label de exceção é o único registro de exceção. Uma PR acima do teto sem o label não passa na etapa 4.
- Fatiar é opcional. Quando a Spec prevê tamanho acima do teto, a exceção é decidida na Spec.

## Qualidade e baseline

Falhas de gate confirmadas em um checkout limpo do main remoto são registradas em uma issue `Quality baseline` (formulário `quality-baseline.yml`). A baseline explica por que um gate já falha, mas não aprova regressões novas. A PR precisa demonstrar que não introduz erros nos arquivos e comportamentos que altera.

## Acúmulo

Artefatos antigos (specs, relatórios, skills copiadas e código sem uso) são retirados do repositório. A cópia vai para a raiz de aposentados (`raiz_aposentados` da Configuração), fora do repositório, e o original só é removido com lista e confirmação. Código legado só sai com prova de não uso.

## Worktrees e branches

Worktree é temporária. Ela é criada para uma mudança e removida ao fim do trabalho, se estiver limpa.

- **Uma issue, uma branch, uma worktree.** Antes de criar, procure a branch e a worktree que já existem para a issue (`git worktree list` e busca pelo número da issue). Se existir, reutilize-a, depois de confirmar o estado. Não crie segunda branch para a mesma issue sem decisão do mantenedor.
- Nome da branch: prefixo de `prefixos_branch` seguido do número da issue, por exemplo `docs/2-processo-v2`.
- Ao criar, a branch não rastreia a `main`: use `--no-track` a partir de `origin/main`. Publique só a própria branch, com `git push -u origin <branch>`. Nunca faça push para a `main`.
- O diretório da worktree depende da ferramenta que a criou. Claude usa `.claude/worktrees/<nome>`. Codex usa `~/.codex/worktrees/<nome>`, fixo pela ferramenta. OpenCode usa o diretório do checkout, conforme a configuração local. Não crie worktree fora do diretório que a ferramenta usa.
- Antes de criar uma worktree, atualize as referências: `git fetch origin --prune`.
- Antes de editar, confirme `git status` limpo, a branch atual e a relação com o main remoto.
- Antes de remover, confirme que não há trabalho não publicado. Não remova worktree de outra sessão, nem limpe branch, worktree ou artefato de outra sessão automaticamente. Liste o alvo, confirme que não está associado a trabalho ativo e peça confirmação.
- Use `git worktree list` para inspecionar, independentemente da localização.
- Branch remota de feature é apagada após o squash merge. Branch local é apagada após o merge, se não houver trabalho não publicado.
- Nenhuma worktree ou branch é removida sem confirmação de que não há trabalho ativo. A skill `higiene-maquina` lista o estado e pede confirmação. A remoção acontece pela lista aprovada, com `inventario.sh --remover`, que revalida cada item antes de agir.

## Identidade GitHub

O processo usa a sessão `gh` ativa (`gh auth status`). A conta pode variar por colaborador e não é fixada neste documento. Commits usam a identidade dessa sessão, com o e-mail de noreply do GitHub.

## Skills

As etapas do processo são executadas por skills. Há duas classes:

- **Skill do processo:** uma pasta de `skills/` do template (e a antiga `higiene-git`). Não é copiada para os projetos: é instalada por máquina com `instalar-processo`, por links.
- **Skill própria do projeto:** qualquer outra skill que o projeto tenha, por exemplo um wrapper de deploy ou um roteiro de smoke. Fica no projeto, em `.agents/skills/<nome>/`, que Codex e OpenCode leem e o Hermes lê depois de `hermes skills trust`. Para o Claude, `.claude/skills/<nome>` é um link relativo para `../../.agents/skills/<nome>`.

A adoção nunca remove uma skill própria do projeto. Uma skill própria com o mesmo nome de uma skill do processo é conflito, e vai para decisão do mantenedor.

Se as skills não estiverem disponíveis no ambiente de execução (por exemplo, numa sessão na nuvem), leia o procedimento em `skills/<nome>/SKILL.md` no repositório do template, `onluis-dev/template`, antes de executar a etapa. Não invente o procedimento a partir da memória.

## Configuração

Bloco lido pelas skills. Cada projeto que adote o processo preenche os valores, com `adotar-processo`. Enquanto houver placeholder, a skill que depende do valor deve pedir a informação em vez de assumi-la.

```yaml
processo_versao: 4
branch_base: <!-- main remoto, ex.: main -->
prefixos_branch: [feat/, fix/, docs/]
label_tipo: <!-- label type:* escolhido para a PR, exatamente um -->
label_aprovacao: status:approved
label_excecao_tamanho: size:exception
teto_pr_linhas: 2000
visual_superficies: <!-- [desktop, mobile], [mobile] ou [desktop], conforme as superfícies do produto -->
raiz_aposentados: ~/.local/share/onluis-dev/aposentados
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
  # STAGING: escrita de ensaio de migração e recriação do sandbox exigem instrução na invocação, mesmo com sim.
  # PROD: leitura só com acesso somente leitura configurado e com pedido. Nunca pré-autorizado.
  dev:      {ler: sim, testar: <!-- sim ou nao -->, escrever_dados: <!-- sim ou nao -->, deploy: <!-- sim ou nao -->}
  staging:  {ler: sim, testar: <!-- sim ou nao -->, escrever_dados: <!-- sim ou nao -->, deploy: <!-- sim ou nao -->}
  prod:     {ler: nao, testar: nao, escrever_dados: nao, deploy: nao}
stack:
  gerenciador_pacotes: <!-- ex.: nome do gerenciador -->
  lockfile: <!-- arquivo único de lock -->
  linguagens: <!-- ex.: linguagem e versão -->
  frameworks: <!-- ex.: frameworks principais -->
  servicos_locais: <!-- ex.: banco, fila, armazenamento -->
  regras_adicionais: <!-- regras de stack que valem para todos os agentes -->
```

Os valores de `comandos`, `ambientes` e `stack` são específicos de cada projeto. O template não os preenche.
