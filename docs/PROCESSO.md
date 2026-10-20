# Processo de trabalho

Este documento define como uma mudança passa de issue até o main remoto. Regras compartilhadas por qualquer agente estão em [`AGENTS.md`](../AGENTS.md).

As etapas abaixo são executadas pelas skills em `skills/`. A configuração que as skills leem fica na seção [Configuração](#configuração).

## Regras não negociáveis

1. O main remoto não é branch de desenvolvimento.
2. Cada mudança nasce em uma branch e em uma worktree próprias.
3. Nenhum segredo, arquivo `.env`, cookie, backup, log, coverage ou arquivo temporário entra em commit.
4. Nenhuma ação em ambiente de produção é executada sem revisão, aprovação humana e instrução explícita na invocação.
5. Nenhum conflito, falha de check ou divergência é resolvido por tentativa silenciosa.
6. O gerenciador de dependências e o lockfile são os definidos na seção Configuração de [`AGENTS.md`](../AGENTS.md#configuração-de-stack).

## Fluxo

| Etapa | Skill | Entrada | Saída |
|---|---|---|---|
| 0. Relato | `relato-para-issue` | Relato em linguagem livre | Issue publicada no GitHub, com escopo e critérios de aceite |
| 1. Especificação | `spec-issue` | Issue e código relacionado | Spec, Tasks, Requisitos de Segurança e matriz de rastreabilidade, comentadas na issue |
| 1a. Aprovação | (humana) | Spec | Aprovação explícita na conversa, seguida do label de aprovação |
| 2. Implementação | `implementar-spec` | Spec aprovada | Commits atômicos na branch, com testes e documentação |
| 3. Auditoria | `auditar-spec` | Implementação | Relatório PASS/PARTIAL/FAIL/NOT TESTED por Requirement, Acceptance Criterion e Task |
| 3a. Aceite local | (humana) | Relatório | Aceite do mantenedor, validado localmente |
| 4. Pull request | `abrir-pr` | Branch auditada | PR com o template, vinculada à issue |
| 5. Review independente | `review-pr` | PR | Review em contexto novo, com findings classificados |
| 5.2. Remediação | `tratar-findings` | Findings | Correções com TDD, respostas a cada finding |
| 5.3. Re-review | `review-pr` (modo re-review) | Correções | Status de cada finding e nova verificação do diff |
| 6. Merge gate | `merge-gate` | PR com review verde | Squash merge, branch e worktree limpas |

### Etapa 0: relato para issue

Antes de abrir uma issue, a busca por duplicatas abertas e fechadas é obrigatória. A issue usa o formulário YAML aplicável em `.github/ISSUE_TEMPLATE/`: `feature.yml` para funcionalidades, `bug.yml` para defeitos, `epic.yml` para épicos e `quality-baseline.yml` para falhas de gate já existentes no main remoto. Uma issue só entra em trabalho depois de aprovada.

### Etapa 1: especificação

A Spec contém requisitos funcionais e não funcionais, comportamento esperado, regras de negócio, decisões técnicas, Requisitos de Segurança aplicáveis, critérios de aceite verificáveis, casos de erro e invariantes. Ela é decomposta em Tasks pequenas e ordenadas. Cada Task informa objetivo, arquivos envolvidos, dependências, critérios de conclusão e testes necessários.

A Spec não é alterada silenciosamente para acomodar a implementação. Se uma premissa estiver errada, a etapa para e reporta o conflito.

### Etapa 1a: aprovação

A aprovação é dada pelo mantenedor na conversa. Só depois dela o agente comenta a Spec na issue e aplica o label de aprovação. Esse label é um controle do processo, não do código.

### Etapa 2: implementação

- Execução das Tasks na ordem da Spec, sem pausas entre Tasks, exceto por bloqueio real (decisão que a Spec não cobre).
- TDD para cada comportamento testável: RED (teste que falha pelo motivo esperado), GREEN (implementação mínima), REFACTOR (com testes verdes). Falha de configuração, import ou fixture não conta como RED válido.
- Commits pequenos e atômicos, cada um deixando o código consistente. Tasks não são commits.
- Ao concluir uma Task, o registro de progresso em `.agent/progresso.md` (não versionado) recebe comportamentos, testes, resultados, commits e desvios.
- Sem squash durante o desenvolvimento.

### Etapa 3: auditoria

Os comandos de verificação configurados são executados, assim como os testes de integração e os cenários E2E que a configuração definir. Cada Requirement, Acceptance Criterion e Task recebe PASS, PARTIAL, FAIL ou NOT TESTED com evidência. A auditoria também confirma: Tasks concluídas, critérios cobertos, Requisitos de Segurança atendidos, alterações fora do escopo, alterações de esquema ou de dados não previstas e riscos residuais.

Mudanças de interface passam por [validação visual](#validação-visual) antes de sair da etapa.

### Etapa 4: pull request

A PR usa o template em `.github/pull_request_template.md`. Ela referencia a Spec, lista as Tasks marcadas apenas quando satisfeitas e registra a verificação com resultados reais. Testes não executados não são marcados como aprovados.

Regras da PR:

- Vinculada a uma issue, com `Closes #<n>`.
- Exatamente um label `type:*`.
- Abaixo do teto de linhas, ou com o label de exceção de tamanho (ver [Tamanho de PR](#tamanho-de-pr)).
- Não cria PR sem a instrução explícita do mantenedor na invocação.

### Etapa 5: review independente

O revisor não participou da implementação e roda em contexto novo, de preferência com modelo diferente. Ele não altera código. Ele avalia correção, aderência à issue e à Spec, critérios de aceite, invariantes, regressões, validação de entrada, autorização, tratamento de erros, segurança (incluindo os Requisitos de Segurança declarados), concorrência, consistência entre frontend e backend, consistência de renderização quando aplicável, performance de consultas, testes ausentes ou frágeis e alterações fora de escopo.

Os findings são classificados como:

- **BLOCKING:** CRITICAL, HIGH ou MEDIUM. Precisam de correção antes do merge.
- **NON-BLOCKING:** LOW ou NIT. Também são corrigidos, por decisão do mantenedor. Só viram issue de follow-up o que o mantenedor decidir não corrigir.
- **ACCEPTED / DOCUMENTED RISKS:** limitações já registradas na Spec ou na PR. Não são findings da implementação.

Cada finding traz severidade, arquivo e linha, comportamento observado, comportamento esperado, justificativa, cenário que reproduz e sugestão de correção. Findings especulativos não são registrados.

### Etapa 5.2: remediação

Todo finding aplicável é tratado, bloqueante ou não. Para cada bug confirmado, vale o TDD da etapa 2. Não se resolve finding sem evidência de correção. Ao final, cada finding recebe resposta na PR com: causa, correção, teste que reproduziu, teste que comprova a correção e commit correspondente.

### Etapa 5.3: re-review

O revisor confirma cada finding como RESOLVED, PARTIALLY RESOLVED ou UNRESOLVED, revisa o diff incremental em busca de regressões introduzidas pela correção e faz a verificação final contra a issue e a Spec.

### Etapa 6: merge gate

O merge gate verifica: HEAD revisado contra o HEAD atual da PR, estado dos checks obrigatórios, conflitos com o main remoto, commits inesperados, segredos ou arquivos de ambiente no diff e limitações conhecidas.

Resultados possíveis:

- **READY FOR SQUASH MERGE:** sem blockers concretos. Pode fazer o squash.
- **NOT READY FOR MERGE:** somente com blockers concretos identificados.

`NOT VERIFIED` não equivale a FAIL. Um review em estado COMMENTED não é tratado como bloqueio automaticamente.

A invocação da etapa 6 é a autorização do squash, se o gate estiver verde. Depois do merge, a branch remota e a worktree são limpas (ver [Worktrees e branches](#worktrees-e-branches)).

## Autorização

- **A autorização vale para a invocação.** Quem invoca uma skill com a ação explícita já autorizou aquela ação. Nenhum arquivo versionado concede autorização permanente.
- **Ações que exigem a instrução explícita na invocação:** publicar issue, abrir PR, aplicar label de aprovação, criar label, squash merge, apagar branch remota ou local, remover worktree, remover arquivos e qualquer ação em produção.
- **Bypass de proteção de branch ou de checks obrigatórios** só acontece com autorização explícita do mantenedor na própria invocação, e somente se a plataforma oferecer esse mecanismo ao usuário. O agente não contorna proteção por conta própria.
- **O bypass administrativo nunca cobre** checks obrigatórios, conflitos, achados pendentes ou mudanças destrutivas.
- Se o GitHub exigir aprovação de outra pessoa, o autor da PR não consegue satisfazer esse requisito com a própria autorização. Nesse caso, a skill registra o bloqueio e pede decisão. Ver [Bloqueios da plataforma](#bloqueios-da-plataforma).

## Labels

| Label | Uso |
|---|---|
| `type:feature` | Funcionalidade nova |
| `type:bug` | Correção de comportamento incorreto |
| `type:docs` | Mudança somente de documentação |
| `type:epic` | Agrupamento de entregas independentes |
| `type:enhancement` | Melhoria de funcionalidade existente |
| `status:approved` | Spec aprovada pelo mantenedor |
| `size:exception` | PR acima do teto de tamanho, com justificativa |

Cada PR tem exatamente um `type:*`. Labels não são criados no GitHub sem autorização explícita na invocação.

## Bloqueios da plataforma

Quando o GitHub exige revisão de pessoa diferente do autor:

1. solicitar a revisão de outro colaborador, se houver;
2. se o mantenedor for administrador do repositório e a mudança não envolver ação em produção nem alteração destrutiva, registrar na PR a autorização explícita e o bloqueio de autoaprovação, e usar o mecanismo administrativo somente para esse gate;
3. se a plataforma não oferecer esse mecanismo, parar e registrar o bloqueio.

A autorização do mantenedor não concede ao agente uma capacidade que a plataforma não disponibilizou.

## Validação visual

Mudanças que alteram interface (UX/UI) passam por validação visual antes de concluir a etapa 3:

- capturas em desktop e mobile das telas alteradas;
- comparação com o baseline aprovado, quando existir;
- aceite humano registrado na PR.

Enquanto o projeto não tiver ferramenta automatizada de captura, a validação é manual e as capturas são anexadas à PR. O procedimento está na skill `validacao-visual`.

## Tamanho de PR

- **Teto:** 2.000 linhas alteradas (adições mais remoções), excluindo arquivos gerados (lockfile, snapshots e código gerado). O teto pode ser ajustado na seção Configuração.
- Acima do teto, a PR exige o label `size:exception` e a justificativa na descrição.
- O label `size:exception` é o único registro de exceção. Uma PR acima do teto sem o label não passa na etapa 4.

## Qualidade e baseline

Falhas de gate confirmadas em um checkout limpo do main remoto são registradas em uma issue `Quality baseline` (formulário `quality-baseline.yml`). A baseline explica por que um gate já falha, mas não aprova regressões novas. A PR precisa demonstrar que não introduz erros nos arquivos e comportamentos que altera.

## Worktrees e branches

Worktree é temporária. Ela é criada para uma mudança e removida ao fim do trabalho.

- Prefixos de branch: `feat/`, `fix/` e `docs/`.
- O diretório da worktree depende da ferramenta que a criou. Claude usa `.claude/worktrees/<nome>`. Codex usa `~/.codex/worktrees/<nome>`, fixo pela ferramenta. OpenCode usa o diretório do checkout, conforme a configuração local.
- Antes de criar uma worktree, atualize as referências: `git fetch origin --prune`.
- Antes de editar, confirme `git status` limpo, a branch atual e a relação com o main remoto.
- Ao concluir, a worktree é removida se estiver limpa e a branch estiver mesclada ou descartada. `git worktree list` mostra todas, independentemente da localização.
- Branch remota de feature é apagada após o squash merge. Branch local é apagada após o merge, se não houver trabalho não publicado.
- Nenhuma worktree ou branch é removida sem confirmação de que não há trabalho ativo. A skill `higiene-git` lista o estado e pede confirmação.

## Identidade GitHub

O processo usa a sessão `gh` ativa (`gh auth status`). A conta pode variar por colaborador e não é fixada neste documento. Commits usam a identidade dessa sessão, com o e-mail de noreply do GitHub.

## Configuração

Bloco lido pelas skills. Cada projeto que adote o processo preenche os valores. Enquanto houver placeholder, a skill que depende do valor deve pedir a informação em vez de assumi-la.

```yaml
branch_base: <!-- main remoto, ex.: main -->
prefixos_branch: [feat/, fix/, docs/]
label_tipo: <!-- label type:* escolhido para a PR, exatamente um -->
label_aprovacao: <!-- label de aprovação da Spec -->
teto_pr_linhas: 2000
label_excecao_tamanho: <!-- label de exceção de tamanho de PR -->
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
```
