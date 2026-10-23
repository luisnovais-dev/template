---
name: ambiente-dev
description: Esqueleto para subir e verificar o ambiente de desenvolvimento local de um projeto, com conferência do alvo e identidade de teste. Preencha as seções com os comandos do projeto antes de usar. Use quando outra skill precisar de um ambiente local em execução.
---

# Ambiente de desenvolvimento

> **Esqueleto.** Este arquivo define o que precisa ser documentado. Os comandos e valores são do projeto que usar este template e devem ser preenchidos antes do primeiro uso. Enquanto houver placeholder, a skill pede o valor em vez de assumi-lo.

## Entrada

- Pedido explícito para preparar ou verificar o ambiente local.

## Seções a preencher

1. **Pré-requisitos:** ferramentas, versões e instalações necessárias. Placeholder: `<ferramenta> <versão>`.
2. **Instalação de dependências:** comando e lockfile do projeto. Placeholder: `<comando de instalação>`.
3. **Variáveis de ambiente:** nome das variáveis, de onde vêm e qual o modelo versionado. O `.env` fica na raiz do checkout principal, com prefixos por ambiente. Preencha o `.env` com `op inject` a partir do `.env.example`. Valores reais nunca entram no repositório. Placeholder: `<comando de op inject>`.
4. **Conferência de chaves:** comando `env:check` (chave `env_check` da Configuração), que confere a presença das chaves sem exibir valores. Placeholder: `<comando env:check>`.
5. **Serviços locais:** banco, filas, armazenamento ou outros serviços e como iniciá-los. Placeholder: `<comando para iniciar serviços>`.
6. **Dados de desenvolvimento:** como preparar dados sintéticos. Placeholder: `<comando de seed ou fixture>`.
7. **Identidade de teste:** usuários sintéticos por perfil, como a sessão de teste é obtida sem interação, e o teste que prova a indisponibilidade em produção. Placeholder: `<usuários e comando de sessão>`.
8. **Execução:** comando que sobe a aplicação em modo de desenvolvimento. Placeholder: `<comando de execução>`, com a URL local resultante.
9. **Verificação:** comandos de lint, testes, tipos e build, idênticos aos da seção Configuração de `docs/PROCESSO.md`.

## Regras

- Antes de executar testes ou qualquer comando que escreva dados, confira o alvo: host, porta e nome do banco ou serviço. Nunca aponte para produção.
- A matriz de ambientes da Configuração (`ambientes` em `docs/PROCESSO.md`) define o que o agente pode fazer em cada ambiente. Ambiente sem permissão na matriz exige instrução explícita.
- Serviços e dados de teste são isolados do ambiente de desenvolvimento compartilhado.
- Não registre segredos, tokens ou credenciais ao documentar os passos.
- Nunca use credencial real de pessoa para testar.

## Saída

- Estado de cada serviço e da aplicação: em execução, parado ou com erro.
- Alvo conferido antes de cada comando de escrita.
- Comandos executados e resultados. Falha de ambiente é reportada como tal, nunca como resultado de teste.
