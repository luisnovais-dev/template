---
name: spec-issue
description: Analisa uma issue e o código relacionado e produz a Spec de implementação, as Tasks ordenadas, os Requisitos de Segurança aplicáveis e a matriz de rastreabilidade, sem implementar. Use antes de qualquer implementação, quando a issue ainda não tiver Spec aprovada.
---

# Especificação de issue

Produz a Spec que será a fonte de verdade da implementação. Não implementa nada.

## Entrada

- URL ou número da issue.
- Documentos de contexto citados pela issue.

## Procedimento

1. Leia a issue inteira, incluindo comentários.
2. Leia o código relacionado o suficiente para entender o contexto, não só as linhas citadas.
3. Leia `AGENTS.md`, `docs/PROCESSO.md` e os documentos de arquitetura do projeto, se existirem.
4. Escreva a Spec com:
   - requisitos funcionais e não funcionais;
   - comportamento esperado e regras de negócio;
   - decisões técnicas, com alternativas descartadas e motivo;
   - critérios de aceite verificáveis (cada um testável);
   - casos de erro e invariantes;
   - Requisitos de Segurança aplicáveis (ver seção abaixo);
   - premissas explícitas e o que não está no escopo.
5. Decomponha em Tasks pequenas e ordenadas. Cada Task tem objetivo, arquivos ou componentes envolvidos, dependências, critérios de conclusão e testes necessários.
6. Proponha testes automatizados adicionais necessários: unitários, integração, E2E e validação visual, quando a mudança tocar interface. Use os comandos da configuração em `docs/PROCESSO.md`.
7. Termine com a matriz: Requirement → Acceptance Criterion → Task → Teste planejado.

## Requisitos de Segurança

Para cada item abaixo, a Spec declara se ele se aplica à mudança. Quando se aplicar, descreve **como o repositório deve atendê-lo** nessa mudança, com a camada responsável (frontend, backend, configuração, infraestrutura) e o teste que comprova. Quando não se aplicar, a Spec registra "não aplicável" com a justificativa. Nenhum item é omitido em silêncio.

1. **Proteção contra exposição de `.env`:** arquivos de ambiente com valores reais ficam fora do versionamento e fora de qualquer rota pública ou estática. Apenas um modelo sem valores reais (`.env.example`) é versionado.
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
12. **Sem vazamento de informações (info leakage):** respostas de erro não expõem stack trace, consultas, caminhos internos, versões ou detalhes de existência de recursos. Logs registram o necessário sem dados sensíveis.
13. **IPs vulneráveis protegidos:** endereços internos, painéis administrativos e serviços de infraestrutura não ficam expostos publicamente. O acesso passa por controle de rede ou autenticação adicional.
14. **Tokens otimizados e com expiração:** tokens têm escopo mínimo, tempo de vida curto e renovação controlada. Não carregam dados sensíveis além do necessário.
15. **Rate limiting:** endpoints públicos e de autenticação têm limite de requisições por origem e por conta, com resposta padronizada ao excedente.
16. **Segredos nunca expostos no código:** chaves, tokens e senhas não aparecem no código, nos testes, nos logs, nas issues ou nas PRs. Segredos vêm do ambiente de execução, e varreduras de segredos são usadas antes do commit.
17. **Proteção contra SSRF:** requisições feitas pelo servidor a URLs informadas por usuário passam por lista de destinos permitidos, com bloqueio de endereços internos e de metadados de nuvem, e sem seguir redirecionamentos para destinos não permitidos.
18. **Cookies seguros (HttpOnly, Secure, SameSite):** cookies de sessão usam `HttpOnly`, `Secure` e `SameSite` adequado ao fluxo, com escopo de domínio e caminho mínimos.
19. **CORS configurado restritivamente:** apenas origens explicitamente listadas recebem cabeçalhos CORS. Não se usa `*` com credenciais nem reflexão livre da origem da requisição.

A Spec que não aplica um item cita a justificativa. O revisor independente confere a lista na etapa de review.

## Gate

A Spec não é comentada na issue nem recebe o label `status:approved` nesta skill. Esses passos acontecem só depois da aprovação explícita do mantenedor, na conversa. Se a Spec depender de uma decisão de produto que a issue não tem, pare e pergunte.

## Saída

- Spec, Tasks, Requisitos de Segurança e matriz, como texto para revisão do mantenedor.
- Lista de decisões que precisam de aprovação.

## Não faça

- Não altere código.
- Não crie branch nem worktree.
- Não invente requisitos que a issue não sustenta.
- Não declare um Requisito de Segurança como atendido sem o teste ou a verificação que o comprova.
