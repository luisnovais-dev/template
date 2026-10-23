---
name: pd-design-system
description: Cria, estende, valida e documenta design systems derivados de requisitos reais do produto, da arquitetura existente do projeto e de interfaces validadas. Use ao criar um design system do zero, extrair um a partir de referências visuais, auditar ou evoluir um existente, padronizar interfaces, alinhar Figma com o código ou documentar tokens e componentes.
---

# Product-Driven Design System

**Nome da skill:** `pd-design-system`
**Versão:** 1.0.0
**Tipo:** workflow reutilizável para agentes
**Compatibilidade:** Claude Code, OpenAI Codex e outros agentes de código

## Propósito

Criar, estender, validar e documentar design systems escaláveis, derivados de requisitos reais do produto, da arquitetura existente do projeto e de interfaces validadas.

O design system deve servir ao produto, e não ditar sua estrutura.

**Princípio central:** fundações primeiro. Interfaces reais em seguida. Componentes reutilizáveis por último.

Não gere uma biblioteca genérica de componentes antes de entender o produto.

## Quando usar

Ative esta skill quando a tarefa envolver:

- criar um design system do zero;
- extrair um design system de referências visuais;
- auditar ou evoluir um design system existente;
- padronizar interfaces inconsistentes;
- traduzir requisitos de produto em padrões de UI reutilizáveis;
- preparar designs para implementação;
- alinhar designs do Figma com uma base de código existente;
- documentar tokens de design, componentes e convenções de uso.

## Ferramentas por ambiente

- **Claude (Claude Code ou Claude desktop):** use as skills de design disponíveis, em especial `artifact-design` para qualquer página ou protótipo, `dataviz` para gráficos e painéis, e o **Claude Design** (tipo de Artifact `design`, com design system próprio) para fundações e telas. Carregue essas skills antes de gerar os artefatos da Fase 1 e da Fase 2.
- **Outros agentes (Codex e similares):** complemente com skills de design equivalentes, se o ambiente tiver. Se não houver, siga o procedimento e registre que a validação visual foi manual.
- Em qualquer ambiente, o procedimento e as regras abaixo valem igualmente. A ferramenta muda o meio, não o processo.

## Regras operacionais

1. Inspecione o projeto antes de propor soluções.
2. Reutilize as convenções existentes, a menos que haja motivo justificado para mudá-las.
3. Distinga fatos verificados, premissas e recomendações.
4. Nunca infira requisitos funcionais apenas a partir de referências visuais.
5. Use tokens de design como fonte de verdade para decisões visuais.
6. Derive componentes reutilizáveis de necessidades reais do produto.
7. Prefira estender componentes existentes a duplicá-los.
8. Evite abstrações especulativas e variantes desnecessárias.
9. Preserve o comportamento existente, salvo mudança explicitamente autorizada.
10. Solicite aprovação antes de decisões irreversíveis ou de alto impacto.
11. Nunca afirme validação sem executar as verificações correspondentes.
12. Não modifique código de produção fora do escopo autorizado.

## Fase 0: descoberta do projeto

**Objetivo:** entender o projeto, sua maturidade, seus usuários e suas restrições antes de definir o design system.

**Ações.** Inspecione as fontes disponíveis:

- documentação do projeto;
- estrutura do repositório;
- telas existentes da aplicação;
- referências de design;
- requisitos de produto;
- jornadas de usuário;
- tokens de design existentes;
- bibliotecas de componentes existentes;
- frameworks e dependências de UI;
- requisitos de acessibilidade e de localização.

Classifique o projeto como:

- **Greenfield:** sem design system;
- **Brownfield:** design system parcialmente estabelecido;
- **Maduro:** design system existente que exige refinamento ou extensão.

Identifique as plataformas-alvo e os requisitos de responsividade.

**Entregável:** um *Project Discovery Brief* com:

- finalidade do produto e fluxos principais;
- ativos e convenções de design existentes;
- restrições técnicas e de plataforma;
- requisitos confirmados;
- perguntas em aberto e premissas;
- oportunidades de reuso;
- telas ou fluxos representativos propostos.

**Gate 0:** não prossiga quando requisitos não resolvidos puderem alterar materialmente a arquitetura. Faça perguntas focadas.

## Fase 1: fundações de design

**Objetivo:** definir ou consolidar um conjunto coerente de tokens e convenções visuais.

**Categorias obrigatórias.**

*Cor:*

- paletas primitivas;
- aliases semânticos;
- fundos e superfícies;
- cores de tipografia;
- bordas;
- ações;
- feedback e status;
- cores semânticas de domínio, quando justificadas.

*Tipografia:*

- famílias tipográficas;
- tamanhos e pesos;
- alturas de linha;
- espaçamento entre letras;
- hierarquia de texto;
- estilos para números e exibição de dados.

*Layout:*

- escala de espaçamento;
- breakpoints responsivos, quando aplicável;
- restrições de contêiner;
- convenções de grid;
- áreas seguras;
- regras de densidade.

*Fundações adicionais:*

- raios de borda;
- sombras e elevação;
- iconografia;
- opacidade;
- indicadores de foco;
- movimento e transições;
- tamanhos mínimos de alvo interativo.

**Restrições.**

- Use tokens primitivos e aliases semânticos.
- Evite valores visuais crus quando já existir token adequado.
- Não introduza tokens pontuais sem documentar sua necessidade.
- Em projetos existentes, prefira compatibilidade e migração incremental a substituições desnecessárias.

**Entregável:** arquitetura de tokens documentada, compatível com o ambiente de design ou de implementação selecionado.

**Gate 1:** verifique consistência de nomes, clareza semântica, acessibilidade e adequação às interfaces representativas.

## Fase 2: interfaces representativas do produto

**Objetivo:** validar as fundações com telas e fluxos reais.

**Seleção de telas.** Por padrão, selecione cerca de três telas ou fluxos representativos, ajustando o número à complexidade do projeto. Priorize interfaces que, juntas, exercitem:

- navegação principal;
- ações principais do usuário;
- apresentação de dados;
- formulários e validação;
- estados de feedback;
- padrões de UI repetidos.

Não selecione automaticamente um painel, um formulário ou uma tela de configurações, a menos que sejam relevantes para o produto.

**Requisitos de cada tela.** Cada tela deve:

- refletir requisitos reais do produto;
- usar os tokens estabelecidos;
- respeitar as convenções da plataforma;
- tratar conteúdo realista;
- considerar o comportamento responsivo;
- prever estados de interação significativos;
- considerar estados vazios, de carregamento, de erro e de sucesso;
- respeitar requisitos de acessibilidade e localização.

Referências visuais são evidência estética, não especificações funcionais autoritativas.

**Entregável:** interfaces representativas com decisões de design documentadas e perguntas em aberto.

## Fase 3: validação

**Objetivo:** verificar se as fundações e as interfaces propostas são coerentes, utilizáveis e alinhadas ao produto.

**Dimensões de validação.**

- **Alinhamento funcional:** confirme que as interfaces suportam as jornadas e os requisitos de negócio.
- **Consistência visual:** verifique uso de tokens, tipografia, espaçamento, cores, hierarquia e padrões de componentes.
- **Acessibilidade:** alvo WCAG 2.2 AA, quando aplicável. Revise contraste, interação por teclado, estados de foco, rótulos, alvos de toque e preferências de movimento reduzido.
- **Comportamento responsivo:** valide os tamanhos de viewport suportados e as variações de conteúdo.
- **Integridade dos dados:** garanta que as visualizações representem fielmente os dados do domínio e não impliquem cálculos ou comportamentos sem suporte.

**Gate 3 — aprovação:** apresente os achados e as correções propostas. Se a aprovação do usuário for necessária, pare antes de extrair ou implementar uma biblioteca grande de componentes. A aprovação nunca é presumida.

## Fase 4: extração de componentes

**Objetivo:** identificar componentes reutilizáveis justificados pelas interfaces validadas.

**Processo.**

1. Identifique padrões visuais e comportamentais repetidos.
2. Procure na biblioteca existente componentes equivalentes.
3. Reutilize ou estenda componentes existentes quando couber.
4. Extraia novos componentes somente quando justificados.
5. Defina responsabilidades e limites de cada um.
6. Documente propriedades e variantes.
7. Especifique o comportamento de interação e de acessibilidade.

**Contrato do componente.** Cada componente define, quando relevante:

- nome e finalidade;
- anatomia;
- propriedades;
- variantes;
- estados de interação;
- dependências de tokens;
- comportamento de acessibilidade;
- comportamento responsivo;
- diretrizes de uso;
- anti-padrões.

Não crie variantes especulativas nem camadas de abstração desnecessárias. Um componente pode se justificar por um comportamento distinto e importante, mesmo que apareça uma única vez.

## Fase 5: documentação

**Objetivo:** tornar o design system compreensível e sustentável para designers, desenvolvedores e futuros agentes.

**Documente:**

- princípios de design;
- arquitetura de tokens;
- convenções de nomenclatura;
- regras de layout e tipografia;
- contratos de componentes;
- requisitos de acessibilidade;
- convenções responsivas;
- regras de localização;
- exemplos de uso;
- limitações conhecidas;
- orientação de migração, quando aplicável;
- decisões arquiteturais e trade-offs.

Escreva em pt-BR, com identificadores (tokens, componentes, chaves) em inglês. Os documentos ficam em `docs/design-system/`, conforme a estrutura de `docs/PROCESSO.md` (seção Gate de documentação). Se o projeto já tiver outra convenção, siga-a e registre a decisão numa ADR.

O Claude Design é opcional e tem uma direção só: ou o design é feito nele e importado para o repositório, ou é feito no repositório. Seu canvas não faz parte da definição de pronto. O repositório é a única fonte de verdade da interface. Referências visuais enviadas pelo usuário são registradas em `docs/referencias/<épico-ou-issue>/` com manifesto, e o design system não as substitui.

A documentação reflete decisões implementadas ou validadas, não funcionalidades planejadas apresentadas como concluídas.

## Fase 6: auditoria final

**Objetivo:** verificar consistência, completude e prontidão para a próxima etapa.

**Checklist.**

- Os requisitos de produto estão representados.
- Os ativos de design existentes foram considerados.
- Os tokens têm nomes e semântica consistentes.
- As interfaces representativas usam tokens estabelecidos.
- O comportamento responsivo foi revisado.
- Os requisitos de acessibilidade foram avaliados.
- Os componentes reutilizáveis são justificados.
- A duplicação desnecessária foi evitada.
- Os contratos de componentes estão documentados.
- As limitações conhecidas estão explícitas.
- Nenhuma mudança não autorizada foi feita.
- Os resultados de validação foram relatados com exatidão.

**Entregável final:**

1. resumo do trabalho concluído;
2. fundações de design criadas ou atualizadas;
3. interfaces representativas validadas;
4. componentes criados, reutilizados ou estendidos;
5. documentação produzida;
6. resultados de validação e riscos remanescentes;
7. próximos passos recomendados.

## Modos de execução

- **Modo A — Analisar:** inspeciona e relata, sem alterar artefatos do projeto.
- **Modo B — Projetar:** cria fundações e interfaces representativas no ambiente de design disponível.
- **Modo C — Estender:** evolui incrementalmente um design system existente, preservando a compatibilidade.
- **Modo D — Implementar:** traduz decisões de design aprovadas em código de produção. Ative somente quando explicitamente autorizado.
- **Modo E — Auditar:** avalia um design system existente e produz achados, sem alterar nada, salvo pedido explícito.

## Comportamento do agente

Antes da execução, estabeleça o escopo autorizado. Em cada fase:

1. revise as evidências disponíveis;
2. identifique informações faltantes;
3. declare premissas relevantes;
4. execute o trabalho autorizado;
5. valide o resultado;
6. relate decisões e limitações;
7. continue somente quando a fase seguinte estiver autorizada e seus pré-requisitos atendidos.

Use as ferramentas disponíveis em vez de fingir que integrações ou validações indisponíveis foram executadas.

Em projetos baseados em repositório, respeite as instruções do repositório, as políticas de branch, os testes existentes e os fluxos de desenvolvimento estabelecidos. Evite operações destrutivas e refatorações não relacionadas.

## Princípio final

Construa o design system a partir do produto, não o produto a partir de uma biblioteca de componentes preconcebida.

**Descoberta → Fundações → Interfaces reais → Validação → Componentes → Documentação → Auditoria.**
