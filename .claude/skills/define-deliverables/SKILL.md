---
name: define-deliverables
description: Quebra um direcionador maior já definido (roadmap macro, OKR, épico) nos itens de trabalho necessários para cumpri-lo — por nome e uma descrição de uma frase, sem refinar. Acione quando o usuário invocar /define-deliverables ou pedir para quebrar um roadmap/OKR/épico em backlog, entender o que precisa ser criado para um ciclo, montar a lista de entregáveis de um MVP, ou gerar os itens de desenvolvimento/deploy/ações necessários para fechar uma etapa ou objetivo.
---

# define-deliverables

Esta skill responde uma pergunta específica: **dado um direcionador já definido, quais itens de trabalho precisam existir para cumpri-lo?** Produz uma lista nova de itens — por nome e uma frase de descrição — organizados por tipo e hierarquia. Não estima, não detalha critério de aceite, não decide prioridade nem data.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e objetivo.

---

## Princípio fundamental

Esta skill faz a ponte entre "o que decidimos fazer" (roadmap, OKR, épico) e "o que precisa existir no backlog para isso acontecer". Ela não decide:

- **O quê priorizar entre os itens gerados** — isso é escopo da skill `prioritize-deliverables`, depois que os itens já existem.
- **Quando cada item acontece** — isso é escopo da skill `create-roadmap`, que já deve ter definido a etapa/janela de tempo antes desta skill rodar.
- **Como o item é feito** (critério de aceite, subtarefas técnicas, estimativa) — isso é escopo da skill `create-spec` (agrupa as User Stories em Specs do tamanho de uma feature e detalha cada US com critério de aceite e especificação detalhada), depois que o item já existe.

Esta skill decide apenas **quais itens precisam existir** e **de qual tipo** (Epic, Feature, User Story, Task, Ação, etc.), a partir de um direcionador que já foi decidido em outro lugar. Se o usuário pedir para esta skill decidir prioridade ou data, redirecione: "Isso é decidir prioridade/data, não quebrar em itens — quer que eu chame `prioritize-deliverables` ou `create-roadmap` primeiro?"

**Nunca refine além de nome + uma frase de descrição.** Se você notar que está detalhando critério de aceite, campos técnicos, ou subtarefas de um item, pare — isso pertence a um refinamento posterior, fora do escopo desta skill.

---

## Gatilho

Acionada quando o usuário invoca `/define-deliverables` ou pede para: quebrar um roadmap/OKR/épico em backlog, entender o que precisa ser criado para um ciclo ou etapa, montar a lista de entregáveis de um MVP, gerar os itens necessários (dev, deploy, ações, outros) para fechar uma etapa/objetivo, ou "quais itens preciso cadastrar no board para isso".

Normalmente roda **no início de um novo ciclo** (ex: início de uma nova PI, de um novo OKR, ou de uma etapa de roadmap que ainda não tem backlog).

---

## Passo 1 — Identificar o direcionador

Pergunte, se não vier claro no pedido (no máximo 2 perguntas):

- Qual é o direcionador de partida? Pode ser mais de um ao mesmo tempo:
  - Uma **etapa de roadmap macro** (`conhecimento/planejamento/roadmaps/`) — ex: "etapa 2 — Desenvolvimento do MVP"
  - Um **OKR/ciclo** (`conhecimento/planejamento/okrs.md`) — ex: "OKR-1, KR1 a KR4"
  - Um ou mais **épicos já definidos** (no board ou descritos pelo usuário)
- Qual é o recorte do ciclo atual? (ex: "só o MVP", "só até o fim do piloto")

Se o direcionador for uma etapa de roadmap que também está dentro da janela de um OKR ativo, leia os dois juntos — o roadmap dá o "o que entregar" em módulos, o OKR dá o "para quê" (a métrica que a entrega precisa mover). Isso ajuda a não esquecer itens que existem só para instrumentar a medição de um KR (ex: um item de "registrar evento X para medir KR2").

---

## Passo 2 — Ler o direcionador e o contexto necessário

Antes de gerar qualquer item, leia:

| Fonte | Por quê |
|---|---|
| O roadmap/OKR/épico apontado no Passo 1 | Fonte principal do escopo — módulos, KRs, critério de conclusão do ciclo |
| `conhecimento/planejamento/decisoes-aprovadas.md` | Decisões que travam ou detalham escopo (ex: uma decisão que define quais telas ou módulos entram no MVP) já indicam quais itens precisam existir |
| `conhecimento/planejamento/dependencias.md` | Dependências ainda abertas geram itens próprios (ex: "validar formalmente o acordo com a equipe X") ou travam um item até serem resolvidas |
| `conhecimento/produto/contexto-de-negocio.md` | Regras e estrutura de módulos já registradas ajudam a não esquecer sub-partes de um módulo (ex: os submódulos de um módulo maior) |
| `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md` | Um fluxo TO BE mapeado costuma indicar etapas que precisam virar item de desenvolvimento |

Se o direcionador citar um módulo ou regra que não está detalhado em nenhum guide, não invente a quebra — pergunte ao usuário ou marque o item como `[quebra a confirmar]`.

---

## Passo 3 — Checar o que já existe (evitar duplicar)

Antes de propor um item novo, verifique se ele já existe:

- Se houver MCP do board do time conectado nesta sessão (Azure DevOps: consulta WIQL; Jira: busca JQL), consulte o board pela área/etapa/tag/label do direcionador (ex: itens com a tag ou label da etapa, ou filhos do Epic/Feature já criado) para listar o que já está cadastrado. Descubra os nomes exatos das ferramentas do MCP na própria sessão — não presuma nomes. Se ainda não souber qual ferramenta o time usa, pergunte (Azure DevOps, Jira ou outra).
- Se não houver MCP conectado, ou o usuário preferir, peça que cole a lista do backlog atual (ex: export do board, ou os nomes já sabidos).

Separe o resultado em duas listas antes de apresentar:
- **Já existe** — itens do direcionador que já têm item criado no board (liste por ID/chave e nome, não gere de novo).
- **Falta criar** — o gap real entre o direcionador e o que já está no board. É só esse gap que a skill detalha no Passo 4.

Se não for possível checar (sem MCP, sem lista do usuário), diga isso explicitamente e gere a lista completa do direcionador, sinalizando: "não verifiquei duplicidade com o board — pode haver itens aqui que já existem."

---

## Passo 4 — Quebrar em itens de trabalho

Antes de gerar, **confirme a taxonomia real do board do time** — os tipos de item variam por ferramenta e por processo configurado (via MCP, consultando os tipos disponíveis, ou perguntando ao usuário). Use os tipos conceituais abaixo e mapeie para o tipo equivalente do time:

| Tipo | Quando usar nesta skill | Azure DevOps | Jira |
|---|---|---|---|
| **Epic** | Entrega grande, geralmente um módulo inteiro ou uma frente do roadmap (ex: "Cadastro e autenticação") | `Epic` | `Epic` |
| **Feature** | Parte substancial de um Epic, ainda maior que uma entrega única de usuário (ex: "Recuperação de senha") | `Feature` | Sem tipo nativo — **pergunte** qual tipo o time usa nesse nível (às vezes `Initiative`, às vezes só `Epic`); nunca assuma |
| **User Story** | Incremento de valor testável do ponto de vista de quem usa o produto | `User Story` | `Story` |
| **Task** | Unidade técnica de trabalho dentro de uma User Story — inclui desenvolvimento, configuração **e deploy** (se o processo do time não tem tipo próprio para deploy, ele é uma Task, marcada como tal no nome) | `Task` | `Task` (ou `Sub-task`, conforme o time) |
| **Ações** | Atividade que não é desenvolvimento de produto — discovery, decisão a tomar, levantamento, agenda com stakeholder, ajuste de processo | Tipo customizado do time, se existir; senão `Task` com prefixo `[Ação]` no nome | `Task` com prefixo `[Ação]` ou label, se não houver tipo próprio |
| **Bug** | Só se o direcionador for corrigir um defeito já identificado em produção/homologação — raro nesta skill, que trata de itens novos, não de correções | `Bug` | `Bug` |
| **Impedimento** | Obstáculo já identificado que trava outro item — use só se o direcionador já descrever um impedimento concreto, não para dependências gerais (essas continuam em `dependencias.md`) | `Issue` (nos processos que têm) | `Task`/`Bug` com label de impedimento, ou o mecanismo de "blocked" do time |

**Tipos que podem existir no processo do time mas não são criados por esta skill:**

| Tipo | Por que não |
|---|---|
| **Objetivo / KR** | Vêm de `define-okrs` — cite como referência (ex: "serve ao KR2"), nunca recrie |
| **Risco** | Se o time tem um tipo de item para riscos no board, a fonte de verdade de riscos deste projeto continua sendo `conhecimento/planejamento/riscos.md` (skill `insert-knowledge`). Se um risco relevante aparecer durante a quebra, registre lá primeiro; só espelhe no board se o usuário pedir explicitamente |
| **Test Plan / Test Suite / Shared Steps / Feedback Request** (ou equivalentes de gestão de teste) | Infraestrutura de gestão de teste e feedback, não itens de entrega — pertencem a um momento de planejamento de QA, não a esta quebra inicial |

Para cada item novo (gap do Passo 3), gere:

- **Tipo** (da tabela acima)
- **Nome** — objetivo, no máximo ~10 palavras
- **Descrição** — **uma frase só**, explicando o que é e por que existe. Nunca detalhe critério de aceite, campos, fluxo passo a passo ou subtarefas — isso é refinamento, fora do escopo.
- **Pai/relacionado** — a qual Epic/Feature ele pertence (se houver hierarquia), e a qual etapa de roadmap ou KR de OKR ele serve
- **Se depender de algo em aberto** (`dependencias.md`), marque `[BLOQUEADO até DEPxxx]` no item — não escreva a dependência em prosa livre sem o ID

Organize a apresentação por hierarquia (Epic → Feature → US/Task/Ação), não como lista plana — isso deixa visível a estrutura do backlog, não só a quantidade de itens.

Apresente a lista completa ao usuário e aguarde validação antes de salvar ou de oferecer criação no board. Ajuste o que for pedido.

---

## Passo 5 — Oferecer criação no board (opcional — Azure DevOps ou Jira)

Depois que a lista estiver validada, pergunte:

> Quer que eu já crie esses itens no board, ou prefere só o registro em markdown por agora? Se sim: o time usa Azure DevOps ou Jira?

Só crie os itens via MCP após confirmação explícita — nunca escreva no board sem essa confirmação. Se a ferramenta escolhida não tiver MCP conectado nesta sessão (ou for outra, como Linear ou Trello), não tente escrever: avise e ofereça o texto de cada item (tipo, nome, descrição, pai) pronto para colar manualmente. Ao criar:
- Respeite a hierarquia (crie Epics/Features antes de suas US/Tasks/Ações filhas, e vincule o pai). No Jira, use o tipo que o time confirmou para o nível "Feature" no Passo 4.
- Aplique a mesma tag (Azure DevOps) ou label (Jira) de etapa usada no board, se o direcionador for uma etapa de roadmap (ex: `Etapa 2`)
- Depois de criar, atualize a lista salva em markdown com os IDs/chaves reais gerados

Se o usuário preferir só o markdown por agora, deixe isso explícito no arquivo salvo (nenhum item foi criado no board ainda).

---

## Formato do arquivo salvo

Nome do arquivo: `backlog-[recorte]-[YYYY-MM-DD].md`

```markdown
---
tipo: backlog
direcionador: [ex: Roadmap — etapa 2 | OKR-1 | Epic Cadastro e autenticação]
recorte: [ex: MVP, ciclo do OKR-1]
gerado-em: [YYYY-MM-DD]
fontes-consultadas: [lista de guides/roadmap/OKR usados]
criado-no-board: sim | não | parcial
ferramenta-board: azure-devops | jira | outra | nenhuma
---

# Backlog — [Nome do recorte]

## Direcionador
[O que motivou esta quebra — etapa de roadmap, OKR, épico — e o critério de conclusão do ciclo]

## Já existente no board (não duplicado)
| ID | Tipo | Nome |
|---|---|---|
| ... | ... | ... |

## Itens propostos

### Epic — [Nome]
| Tipo | Nome | Descrição | Relacionado a |
|---|---|---|---|
| Feature | ... | ... | ... |
| User Story | ... | ... | ... |
| Ações | ... | ... | ... |

## Itens bloqueados
[Itens marcados `[BLOQUEADO até DEPxxx]` — o que falta para desbloquear]

## Pendências
[Itens marcados `[quebra a confirmar]` ou dúvidas levantadas durante a quebra]
```

Salve em `conhecimento/planejamento/backlogs/` e atualize `conhecimento/planejamento/backlogs/index.md` com uma nova linha (crie o índice, seguindo o padrão de `conhecimento/planejamento/roadmaps/index.md`, se ainda não existir).

---

## Diretrizes de comportamento

- **Nome + uma frase, nunca mais.** Se sentir a tentação de detalhar critério de aceite, campos ou subtarefas, pare — isso é para depois, na skill `create-spec`.
- **Sempre cheque duplicidade antes de propor.** Nunca gere um item que provavelmente já existe no board sem avisar que não foi possível confirmar isso.
- **Todo item nasce vinculado a um direcionador rastreável.** Nunca proponha um item "porque parece óbvio" sem apontar de qual etapa/KR/épico ele vem — se não tiver origem clara, marque `[quebra a confirmar]` e pergunte.
- **Bloqueio visível, não escondido.** Se um item depende de uma dependência `Bloqueando` ainda não resolvida, marque isso explicitamente no item, não posicione como se estivesse livre para começar.
- **Nunca decida prioridade ou data.** Isso é papel de `prioritize-deliverables` e `create-roadmap` — que já devem ter rodado antes ou vão rodar depois desta quebra.
- **Nunca crie no board (Azure DevOps ou Jira) sem confirmação explícita.** A lista em markdown é o combinado; a criação no board é uma ação write que precisa de aceite direto do usuário. Pergunte qual ferramenta o time usa e confirme a taxonomia de tipos — nunca presuma.
- **Recorte pequeno, resposta pequena.** Se o direcionador for uma única etapa pequena com 2-3 itens óbvios, não force a estrutura inteira de Epic → Feature → US.

---

## Orientação ao final

Após salvar o backlog, informe o usuário:

> **Backlog definido.**
> - Arquivo salvo em `conhecimento/planejamento/backlogs/[nome-do-arquivo].md`
> - Direcionador: [roadmap/OKR/épico usado]
> - [N] itens propostos ([N] Epics, [N] Features, [N] User Stories, [N] Ações) · [N] já existiam no board
> - [N] itens bloqueados por dependência em aberto
> - Criado no board: [sim/não/parcial] · Ferramenta: [azure-devops/jira/outra/nenhuma]
>
> **Próximos passos sugeridos:**
> - Se ainda não foi feito, rode `/prioritize-deliverables` para ordenar os itens propostos
> - Depois de priorizado, rode `/create-roadmap` para encaixar os itens na linha do tempo (se ainda não estiverem numa etapa)
> - Quando um item estiver perto de começar, use `/create-spec` para agrupar as User Stories em Specs e detalhar critério de aceite e a especificação detalhada das User Stories
