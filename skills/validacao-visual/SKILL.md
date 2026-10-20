---
name: validacao-visual
description: Valida visualmente uma mudança de interface (UX/UI) gerando capturas em desktop e mobile, comparando com o baseline aprovado e pedindo aceite humano. Use quando a mudança alterar telas, componentes visuais ou estilos.
---

# Validação visual

Confirma que a interface alterada está correta antes de a etapa de auditoria ser concluída. Sem aceite humano, a etapa não conclui.

## Entrada

- Lista de telas ou rotas alteradas.
- URL do ambiente local em execução, com os dados necessários à tela.

## Pré-condições

- Ambiente local em execução, conforme a skill `ambiente-dev` e a configuração do projeto.
- Dados representativos no ambiente local, nunca dados reais de produção.

## Procedimento

1. Identifique as telas afetadas a partir do diff e das rotas do projeto.
2. Para cada tela, capture em duas larguras: desktop (1280 px) e mobile (390 px).
3. Compare com o baseline aprovado, se existir. Se não existir, a captura atual vira candidata a baseline.
4. Liste as diferenças visíveis: layout, texto, cor, espaçamento, estados vazios, estados de erro e comportamento responsivo.
5. Verifique acessibilidade pertinente: contraste, foco visível e rótulos de campos.
6. Apresente as capturas e as diferenças ao mantenedor. Ele decide se aceita, se pede ajuste ou se rejeita.
7. Registre o resultado com as capturas anexadas na PR.

## Saída

- Capturas por tela e largura.
- Lista de diferenças em relação ao baseline.
- Aceite humano registrado: ACEITO, AJUSTAR ou REJEITADO.

## Estado atual

O modelo não define ferramenta automatizada de captura nem baseline versionado. Enquanto o projeto não configurar essa infraestrutura, a validação é manual, e o procedimento acima é o que vale. Quando houver ferramenta, ela é declarada na seção Configuração de `docs/PROCESSO.md`.

## Não faça

- Não aceite a própria captura como aprovação.
- Não atualize o baseline sem aceite explícito do mantenedor.
