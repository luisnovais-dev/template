---
name: ambiente-dev
description: Esqueleto para subir e verificar o ambiente de desenvolvimento local de um projeto. Preencha as seções com os comandos do projeto antes de usar. Use quando outra skill precisar de um ambiente local em execução.
---

# Ambiente de desenvolvimento

> **Esqueleto.** Este arquivo define o que precisa ser documentado. Os comandos e valores são do projeto que usar este template e devem ser preenchidos antes do primeiro uso.

## Entrada

- Pedido explícito para preparar ou verificar o ambiente local.

## Seções a preencher

1. **Pré-requisitos:** ferramentas, versões e instalações necessárias. Placeholder: `<ferramenta> <versão>`.
2. **Instalação de dependências:** comando e lockfile do projeto. Placeholder: `<comando de instalação>`.
3. **Variáveis de ambiente:** nome das variáveis, de onde vêm e qual o modelo versionado. Valores reais nunca entram no repositório. Placeholder: `<arquivo de exemplo>`.
4. **Serviços locais:** banco, filas, armazenamento ou outros serviços e como iniciá-los. Placeholder: `<comando para iniciar serviços>`.
5. **Dados de desenvolvimento:** como preparar dados representativos, sem dados reais. Placeholder: `<comando de seed ou fixture>`.
6. **Execução:** comando que sobe a aplicação em modo de desenvolvimento. Placeholder: `<comando de execução>`, com a URL local resultante.
7. **Verificação:** comandos de lint, testes, tipos e build, idênticos aos da seção Configuração de `docs/PROCESSO.md`.

## Regras

- Antes de executar testes ou qualquer comando que escreva dados, confira o alvo: host, porta e nome do banco ou serviço. Nunca aponte para produção.
- Serviços e dados de teste são isolados do ambiente de desenvolvimento compartilhado.
- Não registre segredos, tokens ou credenciais ao documentar os passos.

## Saída

- Estado de cada serviço e da aplicação: em execução, parado ou com erro.
- Comandos executados e resultados. Falha de ambiente é reportada como tal, nunca como resultado de teste.
