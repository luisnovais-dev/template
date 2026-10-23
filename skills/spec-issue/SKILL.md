---
name: spec-issue
description: Analisa uma issue e o código relacionado e produz a Spec de implementação, as Tasks ordenadas, os Requisitos de Segurança aplicáveis e a matriz de rastreabilidade, sem implementar. Verifica o gate "Spec pronta" antes de pedir aprovação. Use antes de qualquer implementação, quando a issue ainda não tiver Spec aprovada.
---

# Especificação de issue

Produz a Spec que será a fonte de verdade da implementação. Não implementa nada.

## Entrada

- URL ou número da issue.
- Documentos de contexto citados pela issue, e referências visuais enviadas pelo usuário, se houver.

## Procedimento

1. Leia a issue inteira, incluindo comentários. Se for ticket de épico, leia também o plano do épico e o grafo de tickets.
2. Leia o código relacionado o suficiente para entender o contexto, não só as linhas citadas.
3. Leia `AGENTS.md`, `docs/PROCESSO.md` (Configuração e a seção do processo que a mudança exige) e os documentos afetados em `docs/`.
4. Faça as investigações e os aceites **antes** da aprovação. Não deixe nenhuma Task de tipo "verificar" ou "obter aceite".
5. Escreva a Spec com:
   - requisitos funcionais e não funcionais;
   - comportamento esperado e regras de negócio;
   - decisões técnicas, com alternativas descartadas e motivo;
   - critérios de aceite verificáveis (cada um testável);
   - casos de erro e invariantes;
   - Requisitos de Segurança aplicáveis (ver seção abaixo);
   - classificação de risco: **comum** ou **sensível** (sensível: autenticação, dados pessoais, financeiro, migração destrutiva ou produção);
   - lista dos documentos afetados, que a implementação deve atualizar (gate de documentação);
   - proposta de ADR, quando houver decisão transversal;
   - premissas explícitas e o que não está no escopo.
6. Quando houver fronteira entre front e back, inclua o contrato da interface e a forma de verificar a divergência automaticamente.
7. Quando a mudança alterar interface, inclua:
   - mapa de telas afetadas;
   - contrato visual: inventário de elementos da referência, classificados como adotado, adaptado (com motivo), descartado ou divergente entre imagens, e a fidelidade (próxima ou inspiração);
   - a Task de ciclo visual dentro do próprio ticket (captura desktop e mobile, autoavaliação contra o inventário, correção e E2E do fluxo). Não crie ticket separado de validação visual.
8. Decomponha em Tasks pequenas e ordenadas. Cada Task tem objetivo, arquivos ou componentes envolvidos, dependências, critérios de conclusão e testes necessários.
9. Proponha testes automatizados adicionais: unitários, integração, E2E, e validação visual quando houver interface. Use os comandos da Configuração em `docs/PROCESSO.md`. Antes de propor um mecanismo de teste novo, verifique se já existe um no projeto. Mecanismo novo é versionado e genérico, nunca um script por PR.
10. Termine com a matriz: Requirement → Acceptance Criterion → Task → Teste planejado.
11. Liste as decisões que precisam de aprovação do mantenedor.

## Gate: Spec pronta

Antes de apresentar a Spec para aprovação, verifique cada item. Se algum falhar, a Spec não é aprovável, e o texto diz qual falta:

- as investigações estão feitas e nenhuma Task é de tipo "verificar" ou "obter aceite";
- o mapa de telas, o contrato visual e o contrato de API, quando houver, estão aceitos com a Spec;
- toda premissa foi verificada. Premissa não verificada torna a Spec não aprovável;
- falta de acesso (conta, ambiente, credencial de teste, dado) vira pendência bloqueante, pedida no planejamento, não no meio da implementação;
- os documentos afetados estão listados;
- a classificação de risco está declarada.

## Requisitos de Segurança

Para cada item abaixo, a Spec declara se ele se aplica à mudança. Quando se aplicar, descreve **como o repositório deve atendê-lo** nessa mudança, com a camada responsável (frontend, backend, configuração, infraestrutura) e o teste que comprova. Quando não se aplicar, a Spec registra "não aplicável" com a justificativa. Nenhum item é omitido em silêncio. Mudança sem superfície de ataque registra "não aplicável" em uma linha, para o conjunto inteiro.

1. **Proteção contra exposição de `.env`:** arquivos de ambiente com valores reais ficam fora do versionamento e fora de qualquer rota pública ou estática. Apenas um modelo sem valores reais (`.env.example`, com referências `op://`) é versionado.
2. **Validação no frontend:** entradas são validadas na interface para orientar o usuário. A validação é apoio de experiência, nunca a única barreira.
3. **Validação no backend:** toda entrada é validada no servidor (tipo, formato, tamanho, faixa e domínio) antes de qualquer uso, independentemente do frontend.
4. **Proteção contra SQL Injection:** consultas usam parâmetros vinculados ou a camada de acesso a dados do projeto. Nenhum valor de entrada é concatenado em SQL.
5. **Autenticação forte:** credenciais são verificadas no servidor, com política de senha definida na Spec, sessões identificadas por tokens não previsíveis e encerramento de sessão efetivo.
6. **Proteção contra IDOR:** cada acesso a um recurso por identificador verifica no servidor se o solicitante tem direito sobre aquele recurso específico, não apenas se está autenticado.
7. **Senhas armazenadas com hash (nunca texto puro):** senhas são guardadas com algoritmo de hash adaptativo e sal por senha. Nenhum log, resposta ou exportação contém senha.
8. **Proteção contra brute force:** tentativas de autenticação repetidas são limitadas por conta e por origem, com atraso ou bloqueio temporário e mensagem neutra.
9. **Bloqueio durante upload:** enquanto um upload não é validado e concluído, o recurso de destino não fica disponível nem é substituído de forma parcial.
10. **Proteção contra CSRF:** operações que alteram estado exigem token anti-CSRF ou verificação equivalente de origem, além do cookie de sessão.
11. **Upload de arquivos validado:** tipo, extensão, tamanho e conteúdo real são verificados no servidor. Nomes são gerados pelo sistema. Arquivos são armazenados fora do diretório executável ou servidos sem execução.
12. **Sem vazamento de informações:** respostas de erro não expõem stack trace, consultas, caminhos internos, versões ou detalhes de existência de recursos. Logs registram o necessário sem dados sensíveis.
13. **IPs vulneráveis protegidos:** endereços internos, painéis administrativos e serviços de infraestrutura não ficam expostos publicamente. O acesso passa por controle de rede ou autenticação adicional.
14. **Tokens com escopo mínimo e expiração:** tokens têm escopo mínimo, tempo de vida curto e renovação controlada. Não carregam dados sensíveis além do necessário.
15. **Rate limiting:** endpoints públicos e de autenticação têm limite de requisições por origem e por conta, com resposta padronizada ao excedente.
16. **Segredos nunca expostos no código:** chaves, tokens e senhas não aparecem no código, nos testes, nos logs, nas issues ou nas PRs. Segredos vêm do ambiente de execução, e varreduras de segredos são usadas antes do commit.
17. **Proteção contra SSRF:** requisições feitas pelo servidor a URLs informadas por usuário passam por lista de destinos permitidos, com bloqueio de endereços internos e de metadados de nuvem, e sem seguir redirecionamentos para destinos não permitidos.
18. **Cookies seguros (HttpOnly, Secure, SameSite):** cookies de sessão usam `HttpOnly`, `Secure` e `SameSite` adequado ao fluxo, com escopo de domínio e caminho mínimos.
19. **CORS configurado restritivamente:** apenas origens explicitamente listadas recebem cabeçalhos CORS. Não se usa `*` com credenciais nem reflexão livre da origem da requisição.
20. **Autorização por perfil e isolamento entre clientes:** cada perfil acessa somente as funções que lhe cabem, e dados de um cliente nunca são visíveis a outro. O teste cobre um acesso permitido e um negado para cada perfil.
21. **Trilha de auditoria:** ações sensíveis (autenticação, alteração de permissão, exclusão, exportação e dado financeiro) registram quem, quando, o quê e o resultado, sem dados sensíveis no registro.
22. **Cabeçalhos de segurança:** respostas HTTP definem política de conteúdo, proteção contra embutimento em outras origens, `X-Content-Type-Options` e política de referrer. O teste verifica os cabeçalhos na resposta.
23. **Guarda do modo de teste:** identidades e atalhos de teste só existem em local e em preview. Um teste prova que eles estão indisponíveis em produção (ver `docs/PROCESSO.md`, seção Ambientes).
24. **Plano de reversão de schema:** toda migração declara o tipo (aditiva, transformadora ou destrutiva), a reversão planejada e o ensaio no clone de produção, conforme `docs/PROCESSO.md`.

A Spec que não aplica um item cita a justificativa. O revisor independente confere a lista na etapa de review.

## Gate de aprovação

A Spec não é comentada na issue nem recebe o label de aprovação (`label_aprovacao`) nesta skill. Esses passos acontecem só depois da aprovação explícita do mantenedor, na conversa. Se a Spec depender de uma decisão de produto que a issue não tem, pare e pergunte.

Decisões que surgirem na implementação são classificadas assim, para a auditoria contar as emendas:

- **produto:** emenda da Spec na issue, com aceite do mantenedor;
- **técnica local:** registrada na PR;
- **transversal:** ADR em `docs/adr/`.

## Saída

- Spec, Tasks, Requisitos de Segurança e matriz, como texto para revisão do mantenedor.
- Resultado do gate "Spec pronta", item por item.
- Classificação de risco, documentos afetados e proposta de ADR, se houver.
- Lista de decisões que precisam de aprovação.

## Não faça

- Não altere código.
- Não crie branch nem worktree.
- Não invente requisitos que a issue não sustenta.
- Não declare um Requisito de Segurança como atendido sem o teste ou a verificação que o comprova.
- Não aprove a própria Spec.
