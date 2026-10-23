---
name: relato-para-issue
description: Transforma um relato de problema, dor, história ou necessidade em uma issue publicada no GitHub, com capacidade, cenários e tipo de entrega, sem alterar código. Use quando o usuário descrever um problema, um pedido ou uma dor e quiser registrá-lo como issue.
---

# Relato para issue

Converte um relato em uma issue acionável. Não altera código nem cria branch.

## Entrada

- Relato em linguagem livre, com ou sem exemplos. Pode ser queixa, dor, história de uso ou pedido.
- Autorização explícita para publicar na invocação (por exemplo: "abra a issue").

## Procedimento

1. Leia `AGENTS.md` e `docs/PROCESSO.md` (seções Hierarquia e Configuração).
2. Traduza o relato em:
   - **pessoa e situação:** quem é e em que contexto acontece;
   - **dor:** o que dá errado ou o que custa hoje;
   - **contorno atual:** como a pessoa resolve hoje;
   - **resultado esperado:** o que ela passaria a conseguir;
   - **capacidade:** "Como <perfil>, consigo <ação> para <resultado>";
   - **cenários derivados:** Given/When/Then, um por caminho relevante;
   - **tipo:** `bug` (comportamento incorreto), `ticket` (uma entrega) ou `épico` (várias entregas que, juntas, formam uma capacidade que o usuário consegue usar do início ao fim. Podem ser entregues em PRs separados, em tickets que se dependem).
3. Hipóteses viram pergunta em aberto. Não as apresente como fato.
4. Temas misturados são separados em issues distintas.
5. Busque duplicatas: `gh issue list --state all --search "<termos>"`. Se houver duplicata aberta, pare e reporte. Se houver duplicata fechada relevante, cite-a.
6. Localize no código apenas o necessário para entender o problema. Não corrija nada.
7. Escreva a issue com o formulário do tipo:
   - bug: `bug.yml`;
   - ticket de funcionalidade: `feature.yml`; ticket de melhoria: `melhoria.yml`;
   - épico: `epic.yml`.
   Os textos ficam em pt-BR. Os critérios de aceite são verificáveis. Não invente critérios que o relato não sustenta; marque-os como pergunta em aberto.
8. Escolha exatamente um label `type:*` correspondente ao formulário. Use labels do manifesto `.github/labels.yml`.
9. Se o tipo for épico:
   - crie o épico com o label `type:epic`, com a checklist de itens;
   - crie cada item como issue filha, com a linha `Parte de: #<épico>` no corpo;
   - atualize a checklist do épico com o número de cada filha;
   - itens mencionados que não pertencem ao tema ficam como issues separadas, citadas em "Fora do épico".
   Um relato com uma única entrega não vira épico. Criar o label `type:epic` pela primeira vez exige autorização explícita na invocação.
10. Mostre o texto final ao mantenedor e aguarde a instrução de publicação, se ela não estiver na invocação.
11. Publique com `gh issue create` usando arquivo de corpo, não string inline.

## Saída

- URL da issue publicada (ou das issues, no caso de épico).
- Lista de duplicatas consideradas.
- Perguntas em aberto que ficaram na issue.

## Não faça

- Não publique sem autorização na invocação.
- Não inclua segredos, dados pessoais reais ou dumps de banco no texto.
- Não transforme hipótese em fato.
- Não crie issue para ajuste cosmético.
