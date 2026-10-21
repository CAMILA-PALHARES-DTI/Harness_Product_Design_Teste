---
name: screen-planner
description: Etapa OPCIONAL que transforma um user flow aprovado (mais briefing do /intent e US, se houver) em um inventário de telas que alimenta a prototipação, do fluxo inteiro ou só das telas que vão ter protótipo, podendo ser pulada indo direto para /create-prototype. Por tela traz ID, objetivo, hierarquia, componentes do Design System, estados, ações e responsividade, além do mapa de navegação e dos componentes reutilizáveis. Acione com /screen-planner ou pedidos como planejar telas, montar inventário de telas, listar telas e estados de um fluxo.
---

# screen-planner

> **Skill da Camada de Agentes**
> Esta skill é uma **etapa opcional**. Ela é chamada quando o time já tem um fluxo de usuário aprovado e quer decidir, tela a tela, o que será prototipado — no fluxo inteiro ou só nas telas que precisam de protótipo. Ela lê o fluxo, o briefing e as User Stories, identifica o Design System do projeto e gera um inventário de telas com objetivo, hierarquia, componentes, estados, ações, responsividade, mapa de navegação e componentes reutilizáveis. O resultado é validado pelo Product Designer antes de seguir para a prototipação.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** O inventário é escrito nesse mesmo idioma. Tom direto e objetivo.

**Rótulos que os sensores leem:** títulos de seção, rótulos em linha, nomes de coluna e valores de frontmatter listados em `scripts/rotulos.txt` são escritos com o texto da coluna do idioma configurado (português ou inglês), exatamente como no dicionário e sem inventar variações — os sensores só reconhecem essas variantes. Rótulos que o `CLAUDE.md` mantém fixos (`Dado`/`Quando`/`Então`, `Cenário`, IDs, marcadores) não mudam de idioma.

Permanecem sempre iguais, em qualquer idioma: os IDs (`SCR-01`, `US-N.M`), os nomes dos estados (`default`, `loading`, `empty`, `error`, `success`), as chaves do frontmatter, o marcador `[a confirmar]` e os nomes reais de componentes do Design System.

---

## Quando usar esta skill

Use esta skill quando o usuário quiser:

- Transformar um user flow aprovado em uma lista concreta de telas
- Montar o briefing de telas que vai orientar wireframe ou protótipo
- Garantir que nenhuma tela ou estado (loading, vazio, erro) fique de fora antes de prototipar
- Identificar componentes que se repetem entre telas e o que já existe no Design System

| Exemplo de comando | O que a skill faz |
|---|---|
| `/screen-planner` | Procura o fluxo, o briefing e as US na base e pergunta só o que faltar |
| `/screen-planner checkout` | Procura o fluxo e o briefing da feature "checkout" e pergunta só o que faltar |
| `/screen-planner só as telas de pagamento` | Entra no modo parcial com o recorte indicado |

### Onde esta skill fica no processo

```
/intent  →  /flow-mapping  →  [ /screen-planner ]  →  /create-prototype  →  /create-spec  →  /audit-spec
(briefing)   (user flow)       (OPCIONAL:              (protótipo            (US + spec       (sabatina
                                inventário de telas)    navegável)            técnica)         da spec)
                   └─────────────── caminho direto ────────────▲
```

O `/create-prototype` funciona com ou sem o inventário. Esta skill acrescenta detalhamento antes de prototipar; não é um pré-requisito.

---

## Etapa opcional: usar, usar em parte ou pular

A pessoa decide se e como usar esta skill. Há três modos:

| Modo | Quando faz sentido | O que a skill faz |
|---|---|---|
| **Completo** | Fluxo com muitas telas, estados complexos, vários designers no mesmo projeto, ou quando é importante mapear o reaproveitamento de componentes do DS | Inventário de todas as telas do fluxo |
| **Parcial** | Só algumas telas precisam de protótipo (telas novas, telas que mudaram, telas de maior risco ou dúvida); as demais já existem ou não precisam de protótipo | Inventário detalhado só das telas escolhidas; as outras aparecem numa lista curta de "telas sem protótipo", com o motivo |
| **Pular** | Feature simples, poucas telas, ou o time prefere ir direto para o protótipo | Não gera inventário; indica `/create-prototype` passando o fluxo e o briefing |

Como conduzir:

- **Se a pessoa já disse o que quer** (ex: "só as telas de pagamento", "planeja tudo", "quero pular essa etapa"), siga direto, sem perguntar de novo.
- **Se não estiver claro**, pergunte o modo. Não force o modo completo.
- **Se ela quiser pular**, respeite sem insistir. Se o fluxo for grande ou complexo, você pode mencionar uma vez, em uma frase, que o modo parcial pode ajudar nas telas mais críticas — e seguir com a escolha dela.
- **Se ela chegou aqui sem querer** (ex: queria prototipar), explique em uma frase que esta etapa é opcional e ofereça ir direto para `/create-prototype`.

---

## O que esta skill não faz

- **Não é obrigatória.** Nenhuma etapa seguinte depende dela; nunca bloqueie o processo por falta de inventário.
- **Não desenha o fluxo.** Se ainda não houver um user flow aprovado, oriente o usuário a mapear o fluxo primeiro com `/flow-mapping`.
- **Não especifica a feature.** Se não houver briefing e o fluxo deixar muitas lacunas, sugira rodar `/intent` antes.
- **Não prototipa nem desenha telas.** Ela produz o briefing de telas; o visual vem na etapa seguinte, com `/create-prototype`.
- **Não escolhe o Design System do projeto.** Usa o que o projeto já adota; se não houver, trabalha com nomes genéricos de componentes e sinaliza.
- **Não inventa regras de negócio.** Comportamento que não está no fluxo, no briefing ou nas US vira `[a confirmar]`.

---

## Passo 0 — Ler a base de conhecimento

Antes de gerar qualquer coisa, leia `conhecimento/produto/contexto-de-negocio.md`, `conhecimento/produto/glossario.md` (nomes das telas e labels usam o vocabulário do projeto) e `conhecimento/produto/dores-de-processo.md` (quem é o usuário e qual dor a feature resolve — não há documento de personas ainda).

---

## Passo 1 — Identificar as entradas

| Entrada | Obrigatória? | Onde procurar | Para quê |
|---|---|---|---|
| **User flow aprovado** | Sim | `conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/futuros/` (to-be) ou `.../existentes/` (as-is); o catálogo `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md` lista os fluxos com ID `FLXxxx` | Fonte de quais telas existem e como se conectam |
| **Briefing funcional** | Recomendada | `conhecimento/desenvolvimento/briefings-funcionais/` (comece pelo `index.md`) — inclui o YAML "Direcionador para o Protótipo" (`tela`, `campos`, `estados_de_tela`, `comportamentos`...) | Objetivo de cada tela, regras de negócio, restrições, perguntas abertas |
| **User Stories** | Recomendada | `conhecimento/planejamento/backlogs/` e `conhecimento/desenvolvimento/specs/` (IDs `US-N.M`) | Vincular cada tela às US que ela atende |
| **Design System do projeto** | Recomendada | Seção "Aplicações do ecossistema" do `CLAUDE.md` e pasta `Repositório/` (somente leitura) | Nomear os componentes reais |
| **Plataforma alvo** | Recomendada | Briefing, fluxo ou pergunta ao usuário | Web desktop, web responsivo, app mobile — muda os requisitos de responsividade |

**Procure primeiro nos arquivos do projeto** antes de perguntar, e não repita perguntas já respondidas na conversa. Se ainda faltar algo, pergunte só o que faltou:

```
Para planejar as telas, ainda preciso de:

1. **User flow:** onde está o fluxo aprovado? (arquivo, link ou cole aqui)
2. **Briefing e User Stories:** existem? Onde estão?
3. **Design System:** em qual pasta de `Repositório/` ele está (componentes e tokens)? Se não houver, uso nomes genéricos de componentes e sinalizo.
4. **Plataforma:** web desktop, web responsivo, app mobile ou mais de uma?
5. **Escopo** (só se não estiver claro): planejo todas as telas do fluxo, só as que vão ser prototipadas (quais?), ou prefere pular esta etapa e ir direto para o /create-prototype?
```

**Design System:** consulte `Repositório/` livremente (somente leitura, nunca edite; não precisa de autorização). Não use o MCP do Figma como fonte de DS.

Se a resposta for **pular**, encerre aqui: indique `/create-prototype` com o fluxo e o briefing como entrada e não gere nada.

Só o fluxo é bloqueante. Sem briefing ou US, siga em frente marcando as lacunas como `[a confirmar]` e avise o usuário no início da entrega.

---

## Passo 2 — Ler as fontes por completo

- **Fluxo:** liste cada passo, decisão e ramificação (o diagrama Mermaid). Cada ponto em que o usuário vê uma interface diferente é uma tela candidata. Modais, drawers e bottom sheets contam como telas próprias quando têm conteúdo e ações próprias. Marcas `[GAP]` do fluxo viram `[a confirmar]` na tela afetada.
- **Briefing:** extraia o objetivo do usuário em cada etapa (*Solução Proposta*, *Critérios de Sucesso*), regras de negócio (*Regras e Comportamentos Funcionais*), dados exibidos (*Especificação Técnica Superficial*), *Necessidades para Prototipação*, *Restrições* (o que **não** vira tela) e *Perguntas Abertas*. Para cada tela, aproveite o bloco YAML correspondente do "Direcionador para o Protótipo": `tela` → nome, `objetivo` → Objetivo, `campos` → componentes de entrada/exibição, `estados_de_tela` → Estados, `comportamentos` e `regras_visuais_derivadas_de_limite_tecnico` → Ações e Componentes (ex: paginação), `perguntas_abertas_relacionadas` → `[a confirmar]`.
- **User Stories:** mapeie qual US é atendida por qual passo do fluxo.
- **Design System:** localize como indicado no Passo 1 e leia os componentes e variantes que as telas vão usar, para citar nomes reais.

Se o fluxo e o briefing se contradisserem, **não escolha sozinho** — sinalize a divergência antes de gerar o inventário. Perguntas Abertas do briefing continuam abertas: nunca as resolva por conta própria.

---

## Passo 3 — Listar as telas e atribuir IDs

Monte a lista de **todas** as telas do fluxo, na ordem, e atribua IDs sequenciais: `SCR-01`, `SCR-02`, ... — mesmo no modo parcial, para que os IDs fiquem estáveis se outras telas forem detalhadas depois.

**No modo parcial:**

- Marque cada tela como **com protótipo** (entra no inventário detalhado) ou **sem protótipo**.
- Se a pessoa não disse quais telas quer, sugira um recorte com base no fluxo e no briefing (telas novas, telas que mudaram, telas com regras ou estados mais complexos) e peça confirmação antes de detalhar.
- Para as telas sem protótipo, registre só ID, nome e motivo (ex: "já existe em produção", "reaproveita SCR-03", "fora do recorte deste ciclo"):

```markdown
## Telas sem protótipo neste inventário

| ID | Tela | Motivo |
|---|---|---|
| SCR-01 | Home | Já existe em produção, sem mudança |
| SCR-04 | Edição | Mesmo layout de SCR-03 |
```

- Se já existir um inventário anterior da feature (`documentos/gerados/inventario-telas-*.md`), **continue a numeração** e reaproveite os IDs de telas que já existem — nunca reutilize um ID para uma tela diferente.
- Os IDs serão usados em todas as etapas seguintes (`/create-prototype`, `/create-spec`, `/audit-spec`, testes), então mantenha-os estáveis.

Apresente a lista rapidamente ao usuário se houver dúvida sobre o recorte (ex: "o modal de confirmação é uma tela própria ou estado da tela anterior?"). Caso o recorte esteja claro, siga direto.

---

## Passo 4 — Gerar o inventário de telas

Para **cada tela com protótipo** (todas, no modo completo), gere o bloco abaixo:

```markdown
## Tela: [Nome da tela]

**ID:** SCR-[número]
**US relacionada(s):** US-[N.M], US-[N.M] — ou [a confirmar]
**URL / rota sugerida:** /[path] — omita se for app nativo ou modal

### Objetivo

[O que o usuário precisa conseguir fazer nesta tela — 1 frase]

### Hierarquia de conteúdo (de cima para baixo)

1. [Elemento mais importante — ex: título + contexto]
2. [Segundo elemento — ex: formulário principal]
3. [Terceiro elemento — ex: ações secundárias]
4. [Rodapé / navegação]

### Componentes principais

| Componente | Design System | Notas |
|---|---|---|
| [Header de página] | [nome do componente no DS] | — |
| [Formulário de X] | [componentes do DS] | [dúvida ou decisão pendente, se houver] |
| [Botão primário] | [componente + variante] | Label: "[texto]" |
| [Lista de itens] | [componente de lista/tabela/grid] | [paginação, ordenação, filtro] |
| [Modal de confirmação] | [componente de modal/dialog] | [tamanho, botões] |

### Estados da tela

| Estado | Descrição | Elementos visíveis |
|---|---|---|
| **Default** | Tela com dados carregados | Todos |
| **Loading** | Carregando dados | Skeleton / spinner |
| **Empty** | Sem dados para mostrar | Mensagem + CTA |
| **Error** | Falha no carregamento | Mensagem + tentar novamente |
| **Success** | Ação concluída | Toast / feedback inline |

### Ações do usuário nesta tela

| Ação | Resultado | Destino |
|---|---|---|
| Clica em [X] | [Efeito] | SCR-[YY] |
| Submete formulário | Salva dados | SCR-[ZZ] (sucesso) ou estado Error |
| Clica em voltar | Retorna | SCR-[WW] |

### Responsividade

- **Desktop:** [ex: sidebar + conteúdo, grid de 3 colunas]
- **Mobile:** [ex: empilhado na vertical, filtros em drawer, ação principal fixa no rodapé]
```

**Labels e copy:** escreva os textos de interface (labels de botões, mensagens de empty/error) no idioma do produto, usando o vocabulário do `glossario.md`. Se o idioma do produto for diferente do idioma do inventário, sinalize e confirme com o usuário.

**Sobre a coluna "Design System":**
- Se o projeto tiver Design System (lido em `Repositório/`), use o **nome real** do componente e da variante (ex: `Button variant="filled"`, `<Modal size="sm">`, `DataTable`).
- Se não houver, use nomes genéricos (ex: "Botão primário", "Tabela paginada") e registre na entrega que os componentes precisam ser mapeados para o DS depois.
- Nunca invente um componente como se ele existisse no DS. Se não tiver certeza de que existe, marque `[verificar no DS]`.

---

## Passo 5 — Gerar o mapa de navegação

```markdown
## Mapa de navegação entre telas

SCR-01 (Home) → SCR-02 (Lista) → SCR-03 (Detalhe)
                               → SCR-04 (Edição)
SCR-03 → SCR-05 (Confirmação)
SCR-04 → SCR-05 (Confirmação)
SCR-05 → SCR-01 (Home)
```

No modo parcial, o mapa inclui também as telas sem protótipo que se conectam às telas detalhadas, marcadas com `(sem protótipo)`, para não perder o contexto de navegação.

Se o usuário preferir, gere também em Mermaid (`flowchart LR`) para visualização. O mapa precisa bater exatamente com a coluna "Destino" das tabelas de ações — confira antes de entregar.

---

## Passo 6 — Identificar componentes reutilizáveis

```markdown
## Componentes candidatos a reutilização

| Componente | Aparece em | Existe no DS? | Ação sugerida |
|---|---|---|---|
| Card de [item] | SCR-02, SCR-06, SCR-08 | Não | Criar novo componente |
| Header com filtros | SCR-02, SCR-07 | Parcial | Estender componente existente |
| Empty state padrão | SCR-02, SCR-03, SCR-05 | Sim | Usar existente |
```

Inclua apenas componentes que aparecem em **duas ou mais telas**. Quando "Existe no DS?" não puder ser confirmado, use `[verificar]` em vez de chutar.

---

## Passo 7 — Gate de validação com o Product Designer

Apresente o inventário completo e peça a validação do PD (ou de quem for responsável pelo design no projeto):

```
Inventário gerado ([completo | parcial]): [N] telas detalhadas, [N] sem protótipo, [N] componentes candidatos a reutilização.
[N] pontos marcados como [a confirmar].

Checklist de aprovação:
- [ ] Todas as telas do fluxo estão no inventário (detalhadas ou na lista "sem protótipo")?
- [ ] No modo parcial: o recorte de telas com protótipo está correto?
- [ ] Cada tela tem objetivo claro (1 frase)?
- [ ] Estados (loading, empty, error) estão cobertos?
- [ ] Componentes do Design System estão referenciados corretamente?
- [ ] Mapa de navegação é consistente com o fluxo?

O inventário cobre tudo? Alguma tela ou estado faltando? Posso salvar?
```

Repita o ciclo de ajustes quantas vezes for preciso. **Nunca salve o arquivo nem avance sem aprovação explícita.**

---

## Passo 8 — Salvar o inventário

Após aprovação explícita, salve o inventário:

- **Local:** `documentos/gerados/`
- **Nome:** `inventario-telas-[slug-da-feature]-[YYYY-MM-DD].md`
- **Frontmatter** (mantenha as chaves como estão, em qualquer idioma, para que as outras skills e os sensores consigam ler):

```markdown
---
tipo: inventario-de-telas
feature: [nome da feature]
fluxo-fonte: [caminho do fluxo em conhecimento/... | a confirmar]
briefing-fonte: [caminho do briefing em conhecimento/... | não]
design-system: [nome e pasta em Repositório/ | não definido]
plataforma: [web desktop | web responsivo | app mobile | ...]
escopo: [completo | parcial]
quantidade-telas: [N total no fluxo]
telas-com-prototipo: [SCR-02, SCR-03, ... | todas]
gerado-em: [YYYY-MM-DD]
status: aprovado
---
```

O inventário é **insumo descartável da prototipação**, não conhecimento do projeto: a fonte principal e duradoura do fluxo é `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md`, que deve ser atualizada de tempos em tempos. Por isso ele fica em `documentos/gerados/` e não é indexado. Se a feature mudar, regenere o inventário a partir do fluxo atualizado em vez de tratá-lo como registro.

Depois de salvar:

1. Rode `powershell -File scripts/validar-referencias.ps1 -Arquivo <caminho>` — se o inventário citar IDs de guides (ex: `FLXxxx`, `Dxxx`, `DEPxxx`), confere se existem. Se apontar ID inexistente, corrija antes de prosseguir. (O sensor não cobre IDs de US `US-N.M`.)
2. Rode `powershell -File scripts/validar-links-frontmatter.ps1 -Arquivo <caminho>` — confere se `fluxo-fonte` e `briefing-fonte` apontam para arquivos que existem.
3. Rode `powershell -File scripts/validar-sequencia-id.ps1 -Telas -Arquivo <caminho>` — confere IDs `SCR-NN` no padrão, sem duplicata, sem gap e sem destino de navegação indefinido. Corrija qualquer achado antes de seguir.
4. Não há `index.md` nem `gerar-indice-geral` a rodar (`documentos/` não é indexado).

---

## Regras

1. **Toda tela do fluxo aparece no inventário.** No modo completo, todas são detalhadas; no parcial, as que ficaram de fora vão para a lista "sem protótipo" com o motivo. Nenhuma some em silêncio.
2. **Estados obrigatórios em toda tela:** default, loading, empty e error. Success sempre que houver ação de envio ou confirmação. Se um estado não se aplica (ex: tela estática sem carregamento), escreva "não se aplica" e o motivo — não omita em silêncio.
3. **Referencie o Design System do projeto.** Use os nomes reais dos componentes quando houver DS; nomes genéricos quando não houver, sinalizando.
4. **Hierarquia de conteúdo é obrigatória.** Ela define a prioridade visual que o designer usa no wireframe.
5. **Responsividade definida por tela, não genérica.** "Responsivo" sem detalhe não ajuda.
6. **IDs consistentes e estáveis.** `SCR-01`, `SCR-02`... usados em todas as etapas seguintes.
7. **Nada inventado.** Regra, texto ou comportamento que não está no fluxo, no briefing ou nas US vira `[a confirmar]`.
8. **Um idioma por documento.** Não misture idiomas no mesmo inventário (exceto nomes de componentes, IDs, estados e comandos).

---

## Comportamentos esperados

- **Etapa opcional, decisão da pessoa.** Use o modo que ela escolher (completo, parcial ou pular) e não insista no completo.
- **Fluxo aprovado é pré-requisito.** Sem fluxo, não gere inventário — oriente a mapear o fluxo antes com `/flow-mapping`.
- **Ampliar depois é normal.** Se um inventário parcial já existir e a pessoa quiser detalhar mais telas, edite o mesmo arquivo: mova as telas da lista "sem protótipo" para o inventário detalhado, mantendo os IDs.
- **Procure antes de perguntar.** Busque nos arquivos do projeto e não repita perguntas já respondidas na conversa.
- **Nunca salve sem aprovação explícita.** O inventário só vai para `documentos/gerados/` depois do "pode salvar" do PD.
- **Sinalize contradições antes de gerar.** Se fluxo, briefing e US divergirem, mostre a divergência e deixe o usuário decidir.
- **Agnóstico de stack.** A skill funciona com qualquer Design System e qualquer plataforma — nunca assuma uma biblioteca específica sem confirmação.
- **Mapa e tabelas sempre consistentes.** Todo destino citado em "Ações do usuário" aparece no mapa de navegação, e vice-versa.
- **Iteração, não recriação.** Ao revisar um inventário já salvo, edite o arquivo existente, preserve os IDs e resuma o que mudou — não reapresente tudo do zero.

---

## Próximo passo

Após a aprovação e o salvamento, oriente o usuário:

> **Próximo passo:** com o inventário aprovado, use `/create-prototype` passando este arquivo (junto com o briefing do `/intent` e o fluxo do `/flow-mapping`) para gerar o protótipo navegável. No modo parcial, o protótipo cobre as telas detalhadas; as telas sem protótipo podem entrar só como referência de navegação. Depois do protótipo pronto, use `/create-spec` para transformar as telas em User Stories com spec técnica e, em seguida, `/audit-spec` para sabatinar a spec antes de mandar para desenvolvimento.
