# <PROJETO>

<!-- Uma linha: o que o projeto faz e para quem. -->

Este é um repositório de template para padronização dos projetos da organização [@onluis-dev](https://github.com/onluis-dev). Ele reúne regras de processo, skills e modelos de issue e PR, sem código de sistema. O README deste repositório será escrito conforme o projeto a ser desenvolvido a partir dele.

## Documentação

| Para quê | Onde |
|---|---|
| Regras invariantes para agentes de IA | [`AGENTS.md`](AGENTS.md) |
| Processo de trabalho, da issue ao merge, com a Configuração | [`docs/PROCESSO.md`](docs/PROCESSO.md) |
| Histórico de versões e notas de migração | [`CHANGELOG.md`](CHANGELOG.md) |
| Skills de cada etapa | [`skills/`](skills/) |

## Instalação das skills

As skills são instaladas por máquina, por links, e não copiadas para os projetos. Para instalar ou atualizar:

```bash
skills/instalar-processo/scripts/instalar.sh
```

O comando mostra o plano sem alterar nada. Use `--aplicar` para aplicar e `--atualizar` para atualizar o clone do template antes.

## Manutenção do template

Antes de cada commit no template, rode a verificação de consistência:

```bash
scripts/verificar-template.sh
```

Ela confere links relativos, YAML dos formulários e do manifesto de labels, frontmatter das skills, links simbólicos de `.claude/skills`, `.env` versionado, valores do `.env.example`, padrões de segredo e a conformidade dos labels dos formulários com `.github/labels.yml`.

Para adotar o processo em um projeto, use a skill `adotar-processo`. Ela segue o manifesto em `skills/adotar-processo/manifesto.txt`.
