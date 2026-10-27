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

## Uso no dia a dia

As skills são instaladas por máquina, por links, e não copiadas para os projetos. O repositório é privado: o `gh` precisa estar autenticado (`gh auth status`).

### Primeira instalação

```bash
gh repo clone onluis-dev/template ~/.local/share/onluis-dev/template
~/.local/share/onluis-dev/template/skills/instalar-processo/scripts/instalar.sh
~/.local/share/onluis-dev/template/skills/instalar-processo/scripts/instalar.sh --aplicar
```

O primeiro comando de instalação mostra o plano e não altera nada. O `--aplicar` cria os links em `~/.agents/skills` e `~/.claude/skills`.

Se o `git` pedir usuário e senha ao clonar ou atualizar, rode uma vez, por máquina: `gh auth setup-git`.

### Atualização

```bash
~/.local/share/onluis-dev/template/skills/instalar-processo/scripts/instalar.sh --atualizar
```

O comando avança o clone em fast-forward e reaplica os links. Se o clone tiver divergido, ele para sem alterar nada, e a resolução é manual.

### Higiene da máquina

Peça ao agente: "rode a higiene-maquina". Ou rode o inventário de qualquer pasta. Ele não altera nada:

```bash
~/.claude/skills/higiene-maquina/scripts/inventario.sh
```

Ao final, o inventário mostra a seção `LISTA PARA APROVAÇÃO` e o `ESPACO_LIBERAVEL`. Cada classe significa:

| Classe | O que é |
|---|---|
| `SEGURO_REMOVER` | Worktree limpa e integrada, ou branch integrada. Entra na lista. |
| `RESGATAR` | Branch com commits que não estão no GitHub. Não remover. |
| `REQUER_DECISAO` | Worktree suja, branch não integrada ou caso que pede decisão. Mostra os arquivos pendentes. |
| `RASCUNHO` | Spec ou documento nunca commitado, com a comparação com a `main` e com a issue. |
| `DOCKER_ORFAO` | Containers, volumes e redes de uma execução de teste cujo processo já morreu. Entra na lista. |
| `DOCKER_ATIVO` | O mesmo, com o processo ainda vivo. Só informativo. |
| `LIXO` | Arquivo temporário não versionado dentro do repositório. Entra na lista. |
| `PROGRESSO`, `RECURSO`, `REMOTO_LEGADO` | Só informativos. |

Para remover, copie as linhas da seção `LISTA PARA APROVAÇÃO` para um arquivo, apague as que você não aprova, e rode:

```bash
~/.claude/skills/higiene-maquina/scripts/inventario.sh --remover lista-aprovada.tsv
```

Cada item é revalidado antes de ser removido. O modo mostra `REMOVIDO:` ou `RECUSADO:` por item e sai com código 3 se algo foi recusado. Ele nunca remove arquivo versionado, branch remota, worktree suja, worktree com processo rodando dentro, nem branch que não esteja integrada.

Para inventariar outra máquina, sem copiar nada para lá:

```bash
ssh <host> 'bash -s' < ~/.local/share/onluis-dev/template/skills/higiene-maquina/scripts/inventario.sh
```

### Hermes

O Hermes lê as skills de `~/.agents/skills` quando `~/.hermes/config.yaml` lista esse diretório. O instalador não altera esse arquivo. Se faltar a entrada, ele mostra o trecho a incluir:

```yaml
skills:
  external_dirs:
    - ~/.agents/skills
```

## Manutenção do template

Antes de cada commit no template, rode a verificação de consistência e os testes automatizados:

```bash
scripts/verificar-template.sh
scripts/testar-template.sh
```

Ela confere links relativos, YAML dos formulários e do manifesto de labels, frontmatter das skills, links simbólicos de `.claude/skills`, `.env` versionado, valores do `.env.example`, padrões de segredo e a conformidade dos labels dos formulários com `.github/labels.yml`.

Regras de manutenção do próprio template:

- Edite as skills em `skills/`. A pasta `.claude/skills/` contém só links para elas, e não deve ser editada.
- Os arquivos que vão para os projetos estão listados em `skills/adotar-processo/manifesto.txt`. Alterar um deles é uma mudança que afeta todos os projetos, e deve vir com nota no `CHANGELOG.md`.
- `skills/` e `scripts/` não são copiados para os projetos.

Para adotar o processo em um projeto, use a skill `adotar-processo`. Ela segue o manifesto em `skills/adotar-processo/manifesto.txt`.
