# conhecimento/produto/fluxos-e-jornadas/

Fluxos e jornadas do produto: o catálogo oficial (um guide com IDs `FLXxxx`) e os mapeamentos em Mermaid gerados pela skill `flow-mapping`, um arquivo por fluxo.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `fluxos-e-jornadas.md` | Catálogo oficial de fluxos e jornadas, com ID `FLXxxx`, tipo, status (Ativo, Proposto, Revisado, Descontinuado), fluxo principal, variações e pontos de atenção. Alimentado pela skill `insert-knowledge` ou incorporando um fluxo mapeado |
| `fluxos-mapeados/` | Fluxos de usuário mapeados pela skill `flow-mapping`, em Mermaid, um arquivo por fluxo — rascunhos separados por modo (existentes e futuros) — ver `fluxos-mapeados/index.md` |

## Como se relacionam

Um fluxo nasce em `fluxos-mapeados/` como rascunho (a partir de achados de pesquisa ou de documentação). Ao final do mapeamento, a `flow-mapping` sugere **incorporá-lo ao `fluxos-e-jornadas.md`**: o fluxo ganha um ID `FLXxxx`, e a entrada do catálogo aponta para o arquivo mapeado (o diagrama). Só fluxos com ID podem ser citados em riscos, dores e decisões.

## Quando consultar

Consulte ao receber descrições de fluxos, processos ou jornadas, e antes de propor uma solução para um fluxo que já foi mapeado ou catalogado.
