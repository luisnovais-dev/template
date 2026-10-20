---
name: auditar-spec
description: Audita uma implementação contra sua Spec, classificando cada Requirement, Acceptance Criterion e Task com evidência, e executa as verificações configuradas. Use depois de implementar e antes de abrir a PR.
---

# Auditar Spec

Verifica se a implementação cumpre a Spec. Não cria PR.

## Entrada

- Número da issue e a branch implementada.
- Autorização explícita para auditar na invocação.

## Procedimento

1. Leia a Spec aprovada, a matriz de rastreabilidade e o registro de progresso.
2. Execute as verificações definidas na seção Configuração de `docs/PROCESSO.md`. Cada comando configurado é executado como está escrito ali. Comando marcado como pendente ou vazio é registrado como NOT TESTED, com o motivo.
3. Execute os testes de integração e os cenários E2E pertinentes à mudança, quando a configuração os definir. Se não houver, registre NOT TESTED com a justificativa.
4. Se a mudança alterar interface, execute a skill `validacao-visual`.
5. Audite cada Requirement, Acceptance Criterion e Task. Classifique como PASS, PARTIAL, FAIL ou NOT TESTED, com evidência: arquivo, implementação e teste correspondentes. Verifique também os Requisitos de Segurança declarados na Spec.
6. Confirme:
   - Tasks concluídas e critérios cobertos;
   - alterações fora do escopo;
   - alterações de esquema ou de dados não previstas na Spec;
   - compatibilidade com comportamentos existentes;
   - riscos residuais e testes que não puderam ser executados.

## Saída

- Tabela de auditoria com a classificação de cada item e a evidência.
- Resultados de cada comando de verificação, separados. Falha preexistente é marcada como baseline.
- Conclusão explícita: pronto para aceite local do mantenedor, ou não pronto, com os motivos.

## Gate

A auditoria não conclui "pronto" com item FAIL ou sem evidência. Se o mantenedor pedir a PR, ela só é aberta depois do aceite local dele.

## Não faça

- Não crie PR.
- Não altere código para fazer a auditoria passar. Achados viram correção na implementação, em outra rodada.
- Não marque como aprovado o que não foi executado.
