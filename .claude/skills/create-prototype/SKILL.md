---
name: create-prototype
description: Gera um protótipo navegável em um único arquivo HTML a partir dos artefatos da feature, de preferência o briefing do /intent, o fluxo do /flow-mapping e o inventário de telas do /screen-planner, mas aceita qualquer outro material de base (PRD, user stories, rascunhos, prints, anotações). Cada tela vira uma seção navegável, com estados (default, loading, empty, error, success) alternáveis e copy real, seguindo o Design System do projeto e os guias de Heurísticas de Nielsen e WCAG 2.2 AA, e passa por sensores computacionais e inferenciais antes da entrega. Pergunta antes se é web (responsivo ou não) ou app. Acione quando o usuário invocar /create-prototype ou pedir para prototipar, gerar protótipo, montar protótipo navegável ou transformar briefing, fluxo ou telas em telas clicáveis.
---

# create-prototype

> **Skill da Camada de Agentes**
> Esta skill é chamada quando o time quer ver uma feature em telas clicáveis. O caminho recomendado é partir do briefing funcional (`/intent`), do fluxo de usuário (`/flow-mapping`) e, opcionalmente, do inventário de telas (`/screen-planner`), mas qualquer material que descreva a feature serve de base. Ela lê o que foi enviado, confirma a plataforma (web responsivo, web não responsivo ou app), identifica o Design System do projeto, deriva as telas e gera um protótipo navegável em um único arquivo HTML que segue os **Guias de qualidade** (Heurísticas de Nielsen e WCAG 2.2 AA). Antes da entrega, o protótipo passa pelos **Sensores**, que verificam se os guias foram de fato cumpridos. O resultado é validado pelo Product Designer antes de seguir para `/create-spec`.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e objetivo.

---

## Arquivos de apoio (leitura obrigatória nos passos indicados)

Esta skill tem arquivos de apoio na mesma pasta. **Leia-os com a ferramenta Read nos passos indicados — não trabalhe de memória.**

| Arquivo | Leia no… | O que contém |
|---|---|---|
| `.claude/skills/create-prototype/estrutura-html.md` | Passo 4 | Esqueleto HTML mínimo, textos fixos por idioma e as regras técnicas do arquivo |
| `.claude/skills/create-prototype/guias-qualidade.md` | Passo 4 | Guia A (10 Heurísticas de Nielsen) e Guia B (WCAG 2.2 AA), mais a tabela de como cada estado aplica os guias |
| `.claude/skills/create-prototype/sensores.md` | Passo 4.1 | Mapa sensores × guias, severidade, como rodar SC e SI, rubrica do revisor, laço de correção e exceções aceitas |
| `.claude/skills/create-prototype/sensores-prototipo.mjs` | Passo 4.1 | Script dos sensores computacionais SC-01 a SC-09 (Node + Puppeteer). **Não edite** para fazer um sensor passar |

---

## Onde esta skill fica no processo

```
/intent  →  /flow-mapping  →  [ /screen-planner ]  →  [ /create-prototype ]  →  /create-spec  →  /audit-spec
(briefing)   (user flow)       (OPCIONAL: inventário)   (protótipo navegável)    (US + spec)       (sabatina)
                   └──────────────── caminho direto ────────────────▲
```

---

## Idioma do protótipo

O idioma da conversa segue o `CLAUDE.md`. O **idioma do protótipo** (copy, labels, mensagens de erro, dados mock) é uma decisão separada, como em qualquer documento voltado a terceiros. Identifique nesta ordem:

1. Pedido explícito do usuário (ex: "protótipo em inglês")
2. Idioma dos materiais de base (briefing, fluxo, inventário etc.)
3. Idioma do produto/Design System do projeto, se houver produto existente
4. Na falta de sinal claro, o idioma de resposta configurado no `CLAUDE.md`

Se os sinais conflitarem, **pergunte** junto com a confirmação da lista de telas (Passo 3). Copy vinda de materiais em outro idioma é traduzida para o idioma do protótipo, mantendo termos de negócio e nomes próprios.

O atributo `<html lang>` acompanha o idioma do protótipo (ex: `pt-BR`, `en`, `es`). Textos fixos (skip link, barra de debug), formato de data e de número: ver `estrutura-html.md`. **Marcadores sempre iguais, em qualquer idioma:** `[a confirmar]`, `[sugestão: Heurística N]` e `[a11y: a revisar]`.

---

## Plataforma

Antes de gerar qualquer tela, a plataforma do protótipo precisa estar definida (Passo 2.1). São três opções:

| | Web responsivo | Web não responsivo | App |
|---|---|---|---|
| **Layout** | Fluido, de 320px até desktop, usando os breakpoints do DS | Largura de desktop (conteúdo pensado para ≥ 1024px), sem adaptação para celular | Tela de celular (ex: 390×844) dentro de uma moldura de dispositivo centralizada; em telas pequenas, ocupa a tela toda |
| **Navegação** | Header/menu web; o menu colapsa em telas pequenas | Header e/ou sidebar web | Padrões de app: barra superior com voltar, tab bar inferior ou a navegação de app do DS |
| **Interação** | Mouse, teclado e toque | Mouse e teclado | Toque (com teclado ainda funcional); alvos de toque ≥ 44×44 px |
| **Barra de debug** | Fixa no rodapé | Fixa no rodapé | Fora da moldura do dispositivo |
| **Sensores (`--platform`)** | `web-responsive` | `web-desktop` | `app` |
| **WCAG 1.4.10 (Reflow)** | Obrigatório | Não atendido por decisão de plataforma → registrar como exceção no relatório | Obrigatório (testado a 320px) |

Para **app**, siga os componentes de app do Design System do projeto. Se o DS for específico de iOS ou de Android, siga as convenções dessa plataforma. O protótipo continua sendo um único arquivo HTML que abre no navegador.

---

## Passo 0 — Ler a base de conhecimento

Antes de qualquer outra coisa, leia:

| Arquivo | Para quê |
|---|---|
| `conhecimento/produto/contexto-de-negocio.md` | Entender o produto, o negócio e o vocabulário do cliente |
| `conhecimento/produto/glossario.md` | **Fonte da copy.** Use os termos do projeto nos labels, botões e mensagens (Heurística 2) |
| `conhecimento/produto/dores-de-processo.md` | Entender quem sofre a dor que a feature resolve — **ainda não existe documento de personas**, então a persona/usuário vem do briefing, do fluxo e destas dores |

Se a persona não estiver clara nesses materiais, **não invente**: ajuste o tom da copy de forma neutra e marque `[a confirmar]` onde a persona mudaria a decisão (ex: nível de detalhe técnico de uma mensagem).

---

## Passo 1 — Reunir os materiais de base

Procure nos arquivos do projeto antes de perguntar. **Recomendamos** partir destes três artefatos:

| Artefato | Skill | Onde procurar | O que traz para o protótipo |
|---|---|---|---|
| Briefing funcional | `/intent` | `conhecimento/desenvolvimento/briefings-funcionais/` (comece pelo `index.md`) | Problema, solução, critérios de sucesso, regras, restrições, perguntas abertas e o bloco **Direcionador para o Protótipo** (YAML por tela) |
| Fluxo de usuário | `/flow-mapping` | `conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/futuros/` (to-be) ou `.../existentes/` (as-is); o catálogo `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md` lista os fluxos com ID `FLXxxx` | Passos, decisões, caminhos de erro, início e fim |
| Inventário de telas | `/screen-planner` (opcional) | `documentos/gerados/inventario-telas-*.md` | Telas com ID `SCR-XX`, hierarquia, componentes, estados, ações e destinos |

**Nenhum deles é obrigatório.** Se a pessoa tiver outros arquivos — PRD, user stories, especificação, rascunhos, wireframes, prints, anotações de reunião, transcrições — use o que ela enviar. Pode haver também decisões relevantes em `conhecimento/planejamento/decisoes-aprovadas.md`: consulte se a feature aparecer lá.

Se não encontrar nada no projeto, peça os materiais ao usuário (caminho ou conteúdo colado), listando os três recomendados e deixando claro que os demais tipos de material também servem.

**Quando faltar um artefato recomendado**, não bloqueie. Gere a partir do que existe e, no relatório do Passo 5, diga em uma linha o que faltou e qual skill ajudaria (ex: "Sem fluxo mapeado — a navegação foi inferida do briefing; `/flow-mapping` deixaria os caminhos de erro mais completos"). Só pare e peça mais material se o que foi enviado não permitir identificar **nem o objetivo da feature nem quais telas existem**.

---

## Passo 2 — Extrair o que o protótipo precisa

Independentemente da origem do material, extraia de onde estiver:

| O que o protótipo precisa | Fonte preferencial | Fontes alternativas | Uso no protótipo |
|---|---|---|---|
| Objetivo da feature e problema que resolve | Briefing: *Visão Geral da Feature*, *Declaração do Problema* | PRD, user stories | Define o que cada tela precisa deixar claro |
| Usuário / persona | Briefing, fluxo e `dores-de-processo.md` | PRD, pesquisa, user stories ("Como [persona]...") | Tom da copy, vocabulário, nível de detalhe (Heurística 2) |
| Solução e valor entregue | Briefing: *Solução Proposta*, *Critérios de Sucesso* | PRD, critérios de aceite | Qual ação é a principal em cada tela (CTA de destaque) |
| Regras e comportamentos | Briefing: *Regras e Comportamentos Funcionais*, YAML `comportamentos` | Decisões aprovadas, reuniões | Validações, mensagens, comportamento de listas e formulários |
| Dados exibidos e limites técnicos | Briefing: *Especificação Técnica Superficial*, YAML `campos` (`nome`, `tipo`, `obrigatorio`, `origem`, `validacao`) e `regras_visuais_derivadas_de_limite_tecnico` | Reuniões, `Repositório/` | Campos dos formulários, colunas de tabelas, paginação ou scroll incremental |
| O que o protótipo precisa simular | Briefing: *Necessidades para Prototipação* | — | Dados mock, casos de borda, estados obrigatórios |
| Estados de cada tela | YAML `estados_de_tela`; inventário (`Estados da tela`) | Fluxo, critérios de aceite | Estados `default`, `loading`, `empty`, `error`, `success` |
| Restrições e fora de escopo | Briefing: *Restrições* | PRD | O que **não** prototipar |
| Pendências conhecidas | Briefing: *Perguntas Abertas*; YAML `perguntas_abertas_relacionadas`; marcas `[GAP]` do fluxo | — | Viram `[a confirmar]` no ponto da tela afetado. **Nunca resolva uma pergunta aberta por conta própria** |
| Passos, decisões e caminhos de erro | Fluxo mapeado (diagrama Mermaid) | Briefing, user stories, rascunhos | Navegação, botões com destinos diferentes, estados de erro (Heurísticas 5 e 9) |
| Início e fim do fluxo | Fluxo mapeado | Briefing, user stories | Tela inicial e tela/estado final |
| Lista de telas, hierarquia, componentes, ações | Inventário de telas (`SCR-XX`) | Um bloco YAML do briefing por tela, wireframes, prints | Estrutura de cada tela e IDs `SCR-XX` |

**Hierarquia de fontes:** quando o mesmo ponto aparece em mais de um material, os artefatos das skills (briefing, fluxo, inventário) prevalecem sobre materiais livres, e materiais mais recentes prevalecem sobre mais antigos. Se houver contradição relevante entre fontes, **mostre a divergência e pergunte** antes de gerar.

Se algo necessário não estiver em nenhum material (ex: um texto, um campo, uma regra), use `[a confirmar]` no próprio protótipo — não invente regra de negócio. O **glossário** é fonte de terminologia, não de regra: serve para escolher as palavras da copy, não para criar telas ou comportamentos.

> Os guias orientam **como** a tela é construída (feedback, foco, contraste, mensagens de erro), não **o que** ela contém. Se um guia pedir algo que os materiais não preveem (ex: botão de desfazer, confirmação antes de excluir), inclua como sugestão marcada `[sugestão: Heurística N]` e liste no Passo 5 — o PD decide.

---

## Passo 2.1 — Definir a plataforma

**Sempre pergunte antes de listar as telas** — a plataforma muda a navegação, os componentes e o layout de cada tela (use a ferramenta de perguntas de múltipla escolha, se houver):

```
Antes de montar o protótipo, preciso definir a plataforma:

1. O protótipo é para **web** ou para **app**?
2. Se for web: deve ser **responsivo** (se adapta do desktop ao celular) ou **não responsivo** (só desktop)?
```

- Se os materiais já indicarem a plataforma, apresente como sugestão para confirmar: "Pelos materiais, parece ser [web responsivo / web não responsivo / app]. Confirma?" — mas não assuma sem a confirmação.
- Se a resposta for **web**, a pergunta 2 é obrigatória. Se for **app**, não pergunte sobre responsividade.
- Registre a escolha: ela define o layout, o valor de `--platform` nos sensores e entra no relatório do Passo 5.

---

## Passo 2.2 — Identificar o Design System

Siga os componentes e tokens do Design System **do projeto em que você está trabalhando** — componentes, cores, tipografia, espaçamentos, raios, ícones e padrões de interação. Não importe nem invente outra biblioteca de componentes. **Não use o MCP do Figma** como fonte de DS.

Onde procurar, nesta ordem:

1. A seção **"Aplicações do ecossistema"** do `CLAUDE.md` (o DS/biblioteca de componentes costuma estar descrito lá, com o nome do repositório).
2. O inventário de telas, se existir (frontmatter `design-system`).
3. A pasta `Repositório/`, onde cada time sobe o código dos seus produtos. **Leia livremente, somente leitura — nunca edite.** Não precisa de autorização.

Se não der para localizar o DS por esses caminhos, faça **uma pergunta** ao usuário: *"Em qual pasta de `Repositório/` está o Design System (componentes e tokens)?"*. Com a resposta, leia os tokens (cores, tipografia, espaçamento) e os componentes que as telas vão usar e reproduza-os no CSS do protótipo.

- Se `Repositório/` estiver vazia ou o DS não existir, diga isso ao usuário, use tokens e componentes neutros e registre no relatório do Passo 5 que o protótipo **não** segue um DS real.
- Nunca invente um token ou componente como se existisse no DS. Na dúvida, `[a confirmar]`.
- **Quando o DS conflita com um guia** (ex: um par de cores do DS não atinge o contraste mínimo, ou um componente não tem estado de foco): use o token do DS que mais se aproxima e cumpre o guia. Se nenhum token cumpre, mantenha o DS, marque `[a11y: a revisar]` no protótipo e liste no relatório do Passo 5.

---

## Passo 3 — Listar as telas

- **Se houver inventário de telas (`/screen-planner`):** use-o como está, preservando os IDs `SCR-XX`, nomes, estados e destinos. Só aponte telas que pareçam faltar em relação ao fluxo ou aos outros materiais. Se o inventário for **parcial**, prototipe só as telas "com protótipo"; as demais entram, no máximo, como destino de navegação sinalizado.
- **Se não houver:** derive as telas do fluxo (ou, na falta dele, do briefing — um bloco do YAML "Direcionador para o Protótipo" por tela — e dos materiais enviados), em ordem, com IDs sequenciais `SCR-01`, `SCR-02`... Modais e drawers com conteúdo e ações próprias contam como telas.

Apresente a lista ao usuário antes de gerar:

```
Telas do protótipo ([web responsivo / web não responsivo / app]):

SCR-01 — [Nome] — [origem: passo do fluxo / tela do inventário / bloco do briefing / material]
SCR-02 — [Nome] — [origem]
...

Confirma essa lista antes de eu gerar o protótipo?
[Se o idioma do protótipo não estiver claro: O protótipo deve ser em português ou inglês?]
```

Só gere depois da confirmação.

---

## Passo 4 — Gerar o protótipo (rascunho)

**Antes de escrever o HTML, leia com Read `.claude/skills/create-prototype/estrutura-html.md` e `.claude/skills/create-prototype/guias-qualidade.md`.** Os dois guias são obrigatórios em toda tela e todo estado.

O resultado é um **único arquivo `.html`** auto-contido que:

1. Renderiza todas as telas confirmadas no Passo 3
2. Permite navegar entre elas exatamente como o fluxo descrito nos materiais prevê
3. Mostra os estados de cada tela (default, loading, empty, error e success quando houver ação de envio) via alternância
4. Segue a plataforma definida no Passo 2.1 (ver seção Plataforma)
5. Segue o Design System do projeto (Passo 2.2)
6. Aplica o Guia A (Heurísticas de Nielsen) e o Guia B (WCAG 2.2 AA) — e passa nos Sensores (Passo 4.1)
7. Abre com duplo clique — sem instalação e sem servidor

**Grave durante o trabalho só o rascunho:** `documentos/gerados/.rascunho-prototipo-[slug-da-feature].html` (arquivo git-ignored). Todo ciclo de sensores e de ajustes acontece sobre ele. O arquivo final só é criado depois da aprovação explícita do PD (Passo 5).

---

## Passo 4.1 — Rodar os sensores e corrigir

**Leia com Read `.claude/skills/create-prototype/sensores.md`** e execute: `--check` do ambiente, os sensores computacionais (`sensores-prototipo.mjs`) sobre o rascunho, a validação de IDs (`scripts/validar-sequencia-id.ps1 -Telas`), os sensores inferenciais e o **laço de correção**. Só avance para o Passo 5 quando:

- os sensores computacionais não tiverem BLOQUEANTE aberto (ou só tiverem exceções aceitas e registradas) — `APROVADO PARCIAL` só permite avançar se o relatório listar SC-06 a SC-09 como checagem manual, e
- os sensores inferenciais não tiverem BLOQUEANTE aberto (idem).

Se o ambiente de sensores estiver incompleto (Puppeteer ausente), **avise o usuário antes de continuar** e registre no relatório que os sensores computacionais precisam de checagem manual.

---

## Passo 5 — Validação com o Product Designer

Apresente o rascunho (caminho do arquivo) e peça a validação:

```
Protótipo gerado: [N] telas, [N] estados. Plataforma: [web responsivo / web não responsivo / app]. Idioma do protótipo: [idioma].
Design System: [nome e onde foi lido em Repositório/ | não encontrado — tokens neutros].
[N] pontos marcados como [a confirmar].
[N] sugestões marcadas como [sugestão: Heurística N].
[N] pontos marcados como [a11y: a revisar].

Materiais usados: [lista]. Artefatos recomendados que faltaram: [nenhum / quais e qual skill ajudaria].

Sensores ([N] rodadas):
- Computacionais: SC-01 a SC-10 → [APROVADO / APROVADO PARCIAL / REPROVADO] — [N] alertas
  [Se APROVADO PARCIAL ou ambiente incompleto: ⚠ SC-06 a SC-09 NÃO rodaram (motivo: ...). Checar manualmente: reflow a 320px, contraste, tamanho de alvo e foco por teclado.]
- Inferenciais: SI-01 a SI-05 → [APROVADO / REPROVADO] — [revisor separado / autoavaliação]
- Exceções aceitas: [nenhuma / sensor + motivo]
- Alertas em aberto: [lista curta]

Checklist:
- [ ] Todas as telas do fluxo / inventário estão representadas?
- [ ] A navegação segue o fluxo descrito nos materiais, incluindo decisões e caminhos de erro?
- [ ] A ação principal de cada tela reflete o objetivo da feature?
- [ ] O protótipo segue a plataforma escolhida?
- [ ] Os estados (loading, empty, error, success) dão feedback claro e são anunciados?
- [ ] Mensagens de erro dizem o que houve e como resolver?
- [ ] Todo o fluxo é operável só pelo teclado, com foco visível?
- [ ] Contrastes atendem 4.5:1 (texto) e 3:1 (texto grande e elementos de interface)?
- [ ] Os componentes e tokens do projeto foram seguidos?
- [ ] As sugestões [sugestão: Heurística N] entram ou saem?

O que ajustar? Posso salvar o arquivo final?
```

Repita os ajustes até a aprovação explícita. Ao revisar, edite o **rascunho** e preserve os IDs das telas — não gere um novo do zero. Todo ajuste continua sujeito aos Guias A e B e **passa de novo pelos Sensores** antes de voltar ao PD.

**Só depois da aprovação explícita do PD**, salve o arquivo final:

1. Mova o rascunho para `documentos/gerados/prototipo-[slug-da-feature]-[YYYY-MM-DD].html` (`mv`, sem recriar o conteúdo).
2. Rode `bash .claude/skills/create-prototype/validar-output.sh` sobre o arquivo final (passando o caminho via JSON no stdin, como o hook faz: `echo '{"tool_input":{"file_path":"<caminho>"}}' | bash .claude/skills/create-prototype/validar-output.sh`) e `powershell -File scripts/validar-sequencia-id.ps1 -Telas -Arquivo <caminho> [-Inventario <inventário>]`. Corrija qualquer erro.
3. `documentos/` não é indexado — não há `index.md` nem `gerar-indice-geral` a rodar. Informe o caminho ao usuário: o `/create-spec` pergunta por ele.

---

## Comportamentos esperados

- **Os materiais enviados são a única fonte de conteúdo.** Nada de telas, regras ou textos que não venham deles ou do glossário (terminologia) — o que faltar é `[a confirmar]`.
- **Artefatos recomendados, não obrigatórios.** `/intent`, `/flow-mapping` e `/screen-planner` são o caminho ideal, mas qualquer material de base serve. Nunca bloqueie por falta deles — gere e sinalize o que faltou.
- **Perguntas abertas do briefing continuam abertas.** Viram `[a confirmar]` na tela afetada; nunca são decididas pelo protótipo.
- **Guias são a fonte de qualidade.** Heurísticas de Nielsen e WCAG 2.2 AA se aplicam a toda tela e todo estado, sem exceção.
- **Guia não cria escopo.** O que um guia sugere e o fluxo não prevê entra como `[sugestão: Heurística N]`, nunca como funcionalidade definitiva.
- **Guia sem sensor é intenção sem verificação.** Nunca entregue sem rodar os sensores, nunca entregue com BLOQUEANTE aberto fora das exceções, e nunca afrouxe um sensor para ele passar.
- **Transparência sobre lacunas.** Conflito entre DS e acessibilidade é reportado, não escondido.
- **Plataforma sempre confirmada.** Nunca gere telas sem saber se é web responsivo, web não responsivo ou app.
- **Procure antes de perguntar.** Busque os arquivos no projeto antes de pedir material ao usuário, e não repita perguntas já respondidas na conversa.
- **Confirme a lista de telas antes de gerar.** Evita retrabalho no HTML inteiro.
- **Nunca salve o arquivo final sem aprovação explícita.** Até lá, só o rascunho `.rascunho-prototipo-*` existe.
- **Design System do projeto, sempre.** Leia-o em `Repositório/` (somente leitura); nunca troque por outro e nunca use o Figma MCP como fonte de DS.
- **IDs estáveis.** `SCR-01`, `SCR-02`... são reutilizados nas etapas seguintes, a começar pelo `/create-spec`.

---

## Próximo passo

Depois da aprovação explícita do Product Designer e do arquivo salvo, encerre indicando o próximo passo:

> **Próximo passo:** com o protótipo finalizado, invoque `/create-spec` para gerar a especificação a partir das telas aprovadas. Informe o caminho `documentos/gerados/prototipo-[slug]-[data].html` como artefato visual (e o briefing da feature). Os IDs `SCR-XX`, os estados `data-state` e os marcadores `[a confirmar]` / `[sugestão: Heurística N]` / `[a11y: a revisar]` do protótipo serão lidos pela spec.
