---
name: validacao-visual
description: Valida visualmente uma mudança de interface (UX/UI) dentro do ticket, com captura desktop e mobile, autoavaliação contra o inventário visual da Spec, correção, E2E do fluxo e aceite humano. Use quando a mudança alterar telas, componentes visuais ou estilos.
---

# Validação visual

Confirma que a interface alterada cumpre o contrato visual da Spec. Faz parte do ticket, não é um ticket separado. Sem a evidência deste ciclo, a auditoria bloqueia o ticket.

## Entrada

- Lista de telas ou rotas alteradas.
- Inventário visual da Spec (adotado, adaptado, descartado, divergente) e a fidelidade declarada (próxima ou inspiração).
- URL do ambiente local em execução, com os dados necessários à tela.

## Pré-condições

- Ambiente em execução (DEV ou STAGING), conforme a skill `ambiente-dev`.
- Dados sintéticos em DEV, ou a conta de teste do sandbox em STAGING. Nunca dado pessoal real nas capturas.
- Usuários de teste do perfil da tela, conforme a identidade de teste de `docs/PROCESSO.md`.
- Referência visual enviada pelo usuário, quando houver, registrada em `docs/referencias/<épico-ou-issue>/` com manifesto.

## Procedimento

1. Identifique as telas afetadas a partir do diff e das rotas do projeto.
2. Capture em DEV sempre que a tela mostrar dado pessoal. Captura em STAGING só com a conta de teste do sandbox e sem dado pessoal visível. Para cada tela, capture em duas larguras: desktop (1280 px) e mobile (390 px). Use a ferramenta configurada em `visual` na Configuração. Se for `manual`, capture à mão e anexe.
3. Autoavalie cada captura por modelo de visão, comparando com o inventário da Spec. Para cada elemento, registre: conforme, desviado (com o desvio) ou ausente. Estados vazios, de erro e de carregamento entram no inventário.
4. Corrija os desvios no próprio ticket. Repita as capturas e a autoavaliação até não restar desvio sem justificativa na Spec.
5. Execute o E2E do fluxo alterado, quando a Configuração o definir.
6. Verifique acessibilidade pertinente: contraste, foco visível e rótulos de campos.
7. Compare com o baseline aprovado, se existir. Se não existir, a captura aprovada vira candidata a baseline.
8. Apresente as capturas, a autoavaliação e as diferenças ao mantenedor. Ele decide se aceita, se pede ajuste ou se rejeita.
9. Registre a evidência na PR, com as capturas desktop e mobile anexadas e o resultado da autoavaliação.

## Saída

- Capturas por tela e largura.
- Resultado da autoavaliação contra o inventário: conforme, desviado ou ausente, por elemento.
- Desvios corrigidos e desvios aceitos com justificativa.
- Resultado do E2E do fluxo.
- Aceite humano registrado: ACEITO, AJUSTAR ou REJEITADO.

## Estado atual

O modelo não define ferramenta automatizada de captura nem baseline versionado. Enquanto o projeto não configurar essa infraestrutura, a captura é manual e anexada à PR. Quando houver ferramenta, ela é declarada no campo `visual` da Configuração de `docs/PROCESSO.md`.

## Não faça

- Não aceite a própria captura nem a própria autoavaliação como aprovação humana.
- Não atualize o baseline sem aceite explícito do mantenedor.
- Não crie ticket separado de validação visual.
- Não use dados reais de produção nas capturas.
