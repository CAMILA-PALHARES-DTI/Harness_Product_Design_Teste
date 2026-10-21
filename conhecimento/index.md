# conhecimento/

Base de conhecimento do projeto. Organizada por domínio.

## Domínios

| Pasta | Conteúdo |
|---|---|
| `produto/` | Contexto de negócio, glossário, mapa de stakeholders, dores de processo |
| `planejamento/` | Decisões aprovadas, dependências, OKRs |
| `desenvolvimento/` | Briefings funcionais e Specs de desenvolvimento |
| `cliente/` | Reuniões, encaminhamentos, ações pendentes |
| `pesquisa/` | Planos, artefatos, coleta de campo, notas estruturadas, relatórios |

## Arquivo gerado automaticamente

`INDICE-GERAL.md` — manifesto único de todo arquivo real da base, com resumo de uma linha por arquivo. Não existe no template: é criado por `scripts/gerar-indice-geral.ps1` (via hook) na primeira escrita em `conhecimento/`, e nunca é editado à mão.

## Regra de leitura

Leia `produto/contexto-de-negocio.md` e `produto/glossario.md` sempre — são a base de qualquer tarefa. Antes de uma busca ampla na base (não sabe em qual pasta algo está), confira `INDICE-GERAL.md` primeiro (se já existir). Os demais arquivos são consultados conforme o contexto da tarefa.
