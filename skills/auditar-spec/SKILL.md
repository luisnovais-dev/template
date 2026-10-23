---
name: auditar-spec
description: Audita uma implementação contra sua Spec, classificando cada Requirement, Acceptance Criterion e Task com evidência, executa as verificações configuradas, confere documentação e emendas, e produz o roteiro de aceite manual. Use depois de implementar e antes de abrir a PR.
---

# Auditar Spec

Verifica se a implementação cumpre a Spec. Não cria PR.

## Entrada

- Número da issue e a branch implementada.
- Autorização explícita para auditar na invocação.

## Procedimento

1. Leia a Spec aprovada, a matriz de rastreabilidade e o registro de progresso (`.agent/progresso.md`).
2. Execute as verificações definidas na Configuração de `docs/PROCESSO.md`. Cada comando configurado é executado como está escrito ali. Comando marcado como pendente ou vazio é registrado como NOT TESTED, com o motivo.
3. Execute os testes de integração e os cenários E2E pertinentes à mudança, quando a Configuração os definir. Se não houver, registre NOT TESTED com a justificativa.
4. Se o épico tiver suíte de aceite e este ticket for o que o fecha, confirme que o teste de aceitação está ativado e verde na branch integrada.
5. Se a mudança alterar interface, confirme a evidência do ciclo de validação visual (capturas desktop e mobile, autoavaliação contra o inventário da Spec, correção e E2E do fluxo). Sem essa evidência, o ticket é bloqueado. Depois, execute a skill `validacao-visual` para o aceite humano.
6. Audite cada Requirement, Acceptance Criterion e Task. Classifique como PASS, PARTIAL, FAIL ou NOT TESTED, com evidência: arquivo, implementação e teste correspondentes. Verifique também os Requisitos de Segurança declarados na Spec, incluindo os marcados como não aplicáveis, cuja justificativa precisa constar.
7. Confira a documentação:
   - a lista de documentos afetados da Spec foi atualizada;
   - a seção de documentação da PR terá o que foi atualizado;
   - a descrição do README foi atualizada se o que o projeto faz mudou.
8. Conte as emendas registradas no progresso, separadas por classe (produto, técnica local, transversal), e confirme que as de produto têm aceite do mantenedor.
9. Confirme:
   - Tasks concluídas e critérios cobertos;
   - alterações fora do escopo;
   - alterações de esquema ou de dados não previstas na Spec;
   - compatibilidade com comportamentos existentes;
   - riscos residuais e testes que não puderam ser executados.
10. Produza o roteiro de aceite manual, conforme `docs/PROCESSO.md` (seção Interface): o que foi entregue (funções, telas e rotas), onde testar, conta de teste pela referência de identidade, cenários com o resultado esperado e o que já foi verificado automaticamente.

## Saída

- Tabela de auditoria com a classificação de cada item e a evidência.
- Resultados de cada comando de verificação, separados. Falha preexistente é marcada como baseline.
- Resultado do gate de documentação e contagem das emendas.
- Roteiro de aceite manual.
- Conclusão explícita: pronto para aceite local do mantenedor, ou não pronto, com os motivos.

## Gate

A auditoria não conclui "pronto" com item FAIL, sem evidência, sem o ciclo visual em ticket de interface, sem a documentação atualizada ou com emenda de produto sem aceite. Se o mantenedor pedir a PR, ela só é aberta depois do aceite local dele.

## Não faça

- Não crie PR.
- Não altere código para fazer a auditoria passar. Achados viram correção na implementação, em outra rodada.
- Não marque como aprovado o que não foi executado.
- Não aceite a própria evidência visual como aceite humano.
