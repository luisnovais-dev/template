---
name: relato-para-issue
description: Transforma um relato de problema ou necessidade em uma issue publicada no GitHub, sem alterar código. Use quando o usuário descrever um problema, um pedido ou uma dor e quiser registrá-lo como issue.
---

# Relato para issue

Converte um relato em uma issue acionável. Não altera código nem cria branch.

## Entrada

- Relato em linguagem livre, com ou sem exemplos.
- Autorização explícita para publicar na invocação (por exemplo: "abra a issue").

## Procedimento

1. Leia `AGENTS.md` e `docs/PROCESSO.md` (seção Configuração).
2. Busque duplicatas: `gh issue list --state all --search "<termos>"`. Se houver duplicata aberta, pare e reporte. Se houver duplicata fechada relevante, cite-a.
3. Localize no código o que for necessário para entender o problema. Não corrija nada.
4. Escreva a issue com: contexto (o que acontece e para quem), comportamento esperado, escopo, fora de escopo, critérios de aceite verificáveis e referências a arquivos e issues relacionadas.
5. Escolha exatamente um label `type:*` (ou o label do formulário aplicável). Épico usa `type:epic`, e as filhas usam o tipo da entrega.
5a. Decida se o relato é um épico. É épico quando o relato descreve um tema com várias entregas independentes, que podem ser feitas em PRs separados. Nesse caso:
   - crie o épico com o label `type:epic`, com uma lista de itens em checklist;
   - crie cada item como issue filha, com a linha `Parte de #<épico>` no corpo;
   - atualize a checklist do épico com o número de cada issue filha;
   - itens que o relato menciona mas não pertencem ao tema ficam como issues separadas, citadas no épico em "Fora do épico".
   Um relato com uma única entrega não vira épico. Criar o label `type:epic` pela primeira vez exige autorização explícita na invocação.
6. Mostre o texto final ao mantenedor e aguarde a instrução de publicação, se ela não estiver na invocação.
7. Publique com `gh issue create` usando arquivo de corpo, não string inline.

## Saída

- URL da issue publicada.
- Lista de duplicatas consideradas.

## Não faça

- Não publique sem autorização na invocação.
- Não inclua segredos, dados pessoais reais ou dumps de banco no texto.
- Não invente critérios de aceite que o relato não sustenta. Marque como pergunta em aberto.
