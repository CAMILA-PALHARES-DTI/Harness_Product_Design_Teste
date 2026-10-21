---
name: define-okrs
description: Gera OKRs (objetivos e key results) para um ciclo específico do projeto, a partir das dores de processo, contexto de negócio, decisões aprovadas, riscos e dependências da base de conhecimento. Faz perguntas quando faltam informações críticas antes de gerar. Acione quando o usuário invocar /define-okrs ou pedir para gerar, propor ou atualizar OKRs de um ciclo (MVP, trimestre, semestre), ou construir objetivos a partir das dores mapeadas.
---

# define-okrs

> **Skill da Camada de Agentes**
> Esta skill é chamada quando o usuário quer gerar OKRs para um ciclo específico do projeto. Ela lê as dores de processo priorizadas, o contexto do produto, as decisões aprovadas, riscos e dependências para propor objetivos e key results alinhados ao que o time precisa resolver. Faz perguntas quando faltam informações críticas antes de gerar.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e objetivo.

**Rótulos que os sensores leem:** títulos de seção, rótulos em linha, nomes de coluna e valores de frontmatter listados em `scripts/rotulos.txt` são escritos com o texto da coluna do idioma configurado (português ou inglês), exatamente como no dicionário e sem inventar variações — os sensores só reconhecem essas variantes. Rótulos que o `CLAUDE.md` mantém fixos (`Dado`/`Quando`/`Então`, `Cenário`, IDs, marcadores) não mudam de idioma.

---

## Quando usar esta skill

Use esta skill quando o usuário quiser:

- Gerar OKRs para um ciclo de produto (MVP, trimestre, semestre, etc.)
- Construir objetivos a partir das dores mapeadas no projeto
- Ter uma proposta inicial de OKR para discutir com o time ou com o cliente

### Parâmetro de foco (opcional)

O usuário pode direcionar o foco ao chamar a skill:

| Exemplo de comando | O que a skill faz |
|---|---|
| `/define-okrs` | Pergunta o ciclo e escopo antes de gerar |
| `/define-okrs MVP do produto` | Gera OKRs focados no MVP do produto |
| `/define-okrs Q3 2026 — todos os produtos` | Gera OKRs para o trimestre cobrindo todos os produtos |
| `/define-okrs com base nas dores DOR001 DOR003 DOR009` | Gera OKRs focados nas dores indicadas |

---

## O que esta skill não faz

- Não registra User Stories — use a skill `create-spec`
- Não registra dependências — elas são registradas pela skill `insert-knowledge`
- Não define a priorização das dores — isso deve vir do usuário ou do time de produto
- Não garante metas numéricas precisas quando os guides não têm baseline — nesses casos, gera com `[a confirmar]` e sinaliza

---

## Passo a passo

### Passo 1 — Leitura dos guides

Leia sempre:

| Arquivo | Por quê |
|---|---|
| `conhecimento/produto/dores-de-processo.md` | Fonte principal — cada dor é candidata a um objetivo ou KR |
| `conhecimento/produto/contexto-de-negocio.md` | Para entender o produto, os usuários e o contexto estratégico |
| `conhecimento/planejamento/decisoes-aprovadas.md` | Para não propor objetivos que contrariem decisões já tomadas |
| `conhecimento/planejamento/riscos.md` | Um risco ativo (ex: prazo, adoção) também pode justificar um objetivo — não só dores |
| `conhecimento/planejamento/dependencias.md` | Para não propor um Key Result cuja meta dependa de uma dependência **Bloqueando** ainda sem solução |

Se existir algum roadmap em `conhecimento/planejamento/roadmaps/` (veja o `index.md` da pasta) cobrindo o mesmo recorte/período do ciclo pedido, leia também — use-o para:
- Alinhar o prazo do ciclo com as janelas de tempo já sequenciadas (não proponha uma meta cujo prazo contradiga uma etapa do roadmap).
- Identificar quais dores/decisões/riscos já têm etapa associada no roadmap, o que reforça que são prioridade real para o período — não apenas uma dor mapeada em aberto.
- Sinalizar se o objetivo proposto depende de uma etapa do roadmap ainda não concluída (nesse caso, trate como faria com uma dependência **Bloqueando**: marque `[BLOQUEADO até a etapa N do roadmap ser concluída]`).

Se não existir roadmap para o recorte, prossiga normalmente sem essa checagem — não é uma leitura obrigatória, apenas usada quando disponível.

Se existir `conhecimento/planejamento/okrs.md`, leia também para:
- Evitar duplicar OKRs já registrados para o mesmo ciclo/tema.
- Determinar o próximo ID sequencial: não calcule de cabeça — rode `powershell -File scripts/validar-sequencia-id.ps1 -ProximoId -Prefixo OKR` e use o valor devolvido (será `OKR-1` se o arquivo não existir ou estiver vazio). Nunca reutilize ou pule um número.

**Baseline também pode vir de outros documentos reais do projeto, não só dos guides.** Se existir um artefato já gerado (ex: um plano salvo em `documentos/gerados/`) com dado quantitativo relevante para o ciclo (volume, contagem, impacto), use-o como baseline — desde que seja um número real já produzido em uma análise do projeto, e cite a fonte explicitamente (nome do arquivo e data). Isso não conta como "inventar número"; conta como invenção só quando não existe nenhum documento real por trás do valor.

Se `conhecimento/planejamento/okrs.md` ainda não existir, ele será criado no Passo 7 com a seguinte estrutura mínima antes do primeiro bloco de OKR:

```markdown
# okrs.md

> **Base de Conhecimento — Planejamento**
> Registra os OKRs propostos e ativos do projeto, por ciclo. Gerado e mantido pela skill `define-okrs`.

---

## Índice

| ID | Ciclo | Produto | Objetivo | Status | Data |
|---|---|---|---|---|---|
```

---

### Passo 2 — Identificar ciclo, escopo e priorização

A partir do comando do usuário e dos guides lidos, identifique:

1. **Ciclo:** Qual é o nome e a duração do ciclo? (ex: "MVP do produto", "Q3 2026 — jul a set")
2. **Produto/escopo:** Quais produtos ou áreas são foco? (P1, P2, P3, todos)
3. **Dores prioritárias:** Quais dores são mais críticas para este ciclo?
4. **Baseline:** Existem métricas atuais conhecidas nos guides para essas dores?
5. **Roadmap:** Existe um roadmap salvo que cobre este ciclo? Se sim, quais etapas caem dentro do período — elas confirmam ou contradizem a prioridade que está sendo assumida aqui?

---

### Passo 3 — Perguntas de clarificação

Se o comando do usuário não contiver informações suficientes para gerar OKRs com qualidade, faça as perguntas **antes** de gerar qualquer bloco. Agrupe tudo em uma única mensagem:

```
Para gerar os OKRs, preciso de algumas informações:

1. **Ciclo:** Qual é o nome e a duração? (ex: "MVP do produto — até dez/2026", "Q3 2026 — jul a set")
2. **Escopo de produto:** Quais produtos são foco? (ex: [Produto A], [Produto B], [Produto C], todos)
3. **Priorização:** Há uma lista de dores priorizadas para este ciclo? Se sim, quais são as top 3–5?
   → Se não houver priorização definida, posso sugerir com base nas dores com maior impacto operacional mapeadas.
4. **Baseline:** Existem métricas ou números atuais que devo usar nos Key Results?
   → Se não houver, gero os KRs com [a confirmar] e sinalizarei o que precisa ser medido.
```

Só faça perguntas que não possam ser respondidas lendo os guides. Se o ciclo estiver claro no comando e houver dores mapeadas suficientes, prossiga direto para o Passo 4.

Perguntas opcionais — faça apenas se relevante para o ciclo informado:
- Quem é o time ou responsável pelos OKRs?
- Existe alguma dor que **não** deve entrar nos OKRs deste ciclo?

---

### Passo 4 — Agrupamento das dores por tema estratégico

Antes de gerar os objetivos, agrupe as dores priorizadas por afinidade temática. Cada grupo vira um candidato a objetivo:

| Grupo temático | Exemplos de dores que se encaixam |
|---|---|
| Operacional / triagem | Retrabalho, etapas manuais repetitivas, trabalho manual em volume |
| Rastreabilidade | Falta de visibilidade do andamento, ausência de registro do que foi feito |
| Onboarding / migração de clientes | Resistência à mudança de processo, base de dados desatualizada |
| Experiência do cliente | Fragmentação entre canais, ausência de funcionalidades essenciais |
| Dados / qualidade cadastral | Base de clientes sem saneamento, tabela de correspondência (de-para) desatualizada |

Dores que não se encaixam em nenhum grupo existente formam um grupo próprio. Dores sem prioridade alta para o ciclo são listadas ao final como "não incluídas".

**Checagem de posse — antes de transformar um grupo em objetivo:** confirme quem de fato executa e controla o resultado. Um OKR só faz sentido para o time que o está definindo se esse time consegue mover o resultado com as próprias mãos. Se a execução pertence inteiramente a outro time (ex: uma equipe de cadastro interna do cliente, uma área jurídica, um fornecedor externo), não vire esse grupo em OKR — mantenha-o como dor/risco/dependência rastreada nos guides, e sinalize ao usuário que esse tema pode merecer um OKR próprio do time responsável, mas não deste ciclo. Isso vale mesmo que o tema seja crítico para o produto — criticidade não é o mesmo que posse.

---

### Passo 5 — Geração dos OKRs

Para cada grupo temático priorizado, gere um bloco OKR seguindo o formato abaixo:

```markdown
### OKR-[N] — [Título]

- **Ciclo:** [nome e período]
- **Produto:** [P1 | P2 | P3 | Todos]
- **Dores relacionadas:** [DOR00X — título curto da dor; DOR00Y — título curto, ou "—"]
- **Riscos relacionados:** [RISxxx — título curto do risco, ou "—"]
- **Decisões relacionadas:** [Dxxx — título curto da decisão, ou "—"]
- **Responsável:** [nome ou time — ou [a confirmar]]
- **Status:** Rascunho

**Objetivo**
> [Uma frase só, curta e direta — o tipo de frase que alguém sem contexto nenhum entende de cara. Aspiracional, mas ancorada no ganho real: reflita o que efetivamente muda e para quem — confira o campo "Quem sente" da dor antes de escrever, porque o ganho pode ser interno à operação, não do cliente final (e a mudança pode até gerar mais trabalho para quem "sente" a dor hoje — não maquie isso). Evite verbos de prova absoluta ("provar", "garantir"); prefira "validar", "reduzir", "eliminar". Detalhe, número e nuance vão no Contexto e na Hipótese, não espremidos nesta frase.]

**Contexto** (inclua quando houver dado quantitativo real disponível)
[Cite a dor (ID) e um dado real de volume/impacto que dá peso ao objetivo — ex: quantos clientes, pedidos ou reais estão em jogo. Fonte pode ser qualquer guide ou outro documento real do projeto já gerado (cite o arquivo e a data).]

**Key Results**

| # | Key Result | Baseline | Meta | Como medir |
|---|---|---|---|---|
| KR1 | [o que muda — mensurável] | [valor atual ou [a confirmar]] | [valor alvo] | [métrica ou fonte] |
| KR2 | [o que muda — mensurável] | [valor atual ou [a confirmar]] | [valor alvo] | [métrica ou fonte] |
| KR3 | [o que muda — mensurável] | [valor atual ou [a confirmar]] | [valor alvo] | [métrica ou fonte] |

**Hipótese**
[Afirmação causal direta — não uma condicional vaga. Formato: "[o produto/a mudança] reduz/elimina [a dor] porque [o mecanismo específico]." É o "porquê" que explica por que os KRs deveriam se mover se a aposta estiver certa. Riscos que ameaçam essa hipótese (dependências em aberto, resistência à mudança) entram aqui como contexto a observar — nunca como KR.]
```

Se o usuário fornecer literalmente a frase que quer usar como título ou objetivo, use exatamente essa frase — não parafraseie por conta própria.

**Nunca cite um ID sozinho — sempre junto do título curto.** Toda referência a uma dor, risco, decisão ou dependência (no header, no Contexto, na Hipótese, nas notas de KR ou em qualquer texto gerado) deve vir como `DOR00X — título curto`, nunca só `DOR00X`. O objetivo é que o leitor entenda do que se trata sem precisar abrir o guide correspondente. Isso vale para o markdown salvo e para qualquer visão HTML gerada a partir dele.

**Regras de geração:**
- Máximo de 3 OKRs por ciclo (salvo instrução explícita do usuário para mais).
- Cada objetivo deve ter entre 2 e 4 Key Results.
- Key Results devem ser mensuráveis — não use verbos sem métrica (ex: "melhorar a experiência" sem número não é um KR válido).
- Se não houver baseline disponível nos guides, use `[a confirmar]` e sinalize no Passo 6.
- Não invente números. Use apenas dados explícitos nos guides.
- Vincule "Riscos relacionados" e "Decisões relacionadas" apenas quando houver base clara no conteúdo lido — não force uma relação especulativa. Use os IDs exatos já existentes em `riscos.md`/`decisoes-aprovadas.md`.
- Se um Key Result depender de uma dependência **Bloqueando** sem solução conhecida (`dependencias.md`), não proponha a meta como se fosse alcançável no ciclo — marque `[BLOQUEADO até DEPxxx ser resolvida]` junto ao KR.
- **KR nunca é uma dependência ou pendência renomeada.** "Resolver a dependência X" não é um indicador de sucesso — é um pré-requisito. Um KR mede o quanto o objetivo avançou; uma dependência resolvida pode ser condição para isso, mas fica registrada na Hipótese/Contexto como algo a observar, não como linha da tabela de Key Results. Se todos os candidatos a KR de um objetivo forem, no fundo, dependências disfarçadas, o objetivo provavelmente ainda não tem um resultado real para medir — pergunte ao usuário antes de forçar a tabela.
- **Prefira KRs de valor/resultado real a KRs de progresso de processo.** "% desenvolvido", "% homologado" são úteis quando o resultado real (uso de verdade, redução de dor observada) genuinamente não é alcançável dentro do ciclo — mas sempre que o ciclo permitir validar o resultado de fato (ex: rodar um piloto real com um cliente), prefira medir o resultado, não o processo que leva a ele. Se a estimativa de viabilidade mudar no meio da conversa (o usuário percebe que algo antes arriscado agora é possível), ofereça recentrar os KRs em valor real antes de manter os de progresso.
- **Métrica nova que mede o mesmo efeito de um KR existente, só que em outra unidade** (ex: um KR já mede "% de redução"; o usuário quer também acompanhar "horas economizadas" e "custo evitado" do mesmo efeito) não vira um KR novo — registre como "Métricas complementares" logo abaixo da tabela, atrelada ao KR que ela reforça. Isso evita estourar o limite de KRs com métricas redundantes.
- **Antes de propor um KR de redução, confira se algum risco já registrado (`riscos.md`) prevê o efeito oposto pelo mesmo mecanismo.** Se houver essa tensão, não escolha uma direção silenciosamente — flagueie explicitamente ao usuário antes de gerar o KR. Se o usuário confirmar que quer acompanhar mesmo assim, estruture como uma métrica de saldo/balanço (ex: segmentada por causa) em vez de assumir que o resultado final será positivo.
- **Ao repensar KRs de um objetivo já existente, avalie se falta um indicador líder além do indicador de resultado.** Um indicador de resultado mostra o quanto a dor caiu; um indicador líder mostra se o mecanismo da hipótese está de fato acontecendo (ex: "a nova etapa de validação está sendo usada em cada pedido?" é líder; "o retrabalho caiu X%?" é de resultado). Ofereça o indicador líder como KR adicional quando fizer sentido testar a hipótese diretamente, e deixe o usuário decidir se mantém os dois ou só um — não decida isso sozinho.

---

### Passo 6 — Sinalização de métricas ausentes

Após os blocos gerados, se houver campos `[a confirmar]`, apresente:

```
⚠️ Métricas que precisam ser levantadas para consolidar os OKRs:

| OKR | KR | O que medir | Sugestão de fonte |
|---|---|---|---|
| OKR-1 | KR2 | [métrica ausente] | [quem pode fornecer] |
```

Se não houver lacunas de baseline, omita esta seção.

---

### Passo 7 — Confirmação com o usuário

```
Os OKRs acima são uma proposta inicial com base nas dores mapeadas e no ciclo informado. Antes de salvar:

- Há algum objetivo que não faz sentido para este ciclo?
- Algum Key Result precisa de ajuste (meta, baseline, forma de medir)?
- Falta alguma dor que deveria estar representada?

Confirmar salva os OKRs em `conhecimento/planejamento/okrs.md`.
```

Não salve nada sem confirmação explícita do usuário. Ao salvar, acrescente uma linha por OKR gerado no bloco "Índice" do arquivo (ID, Ciclo, Produto, Objetivo, Status, Data) além do bloco completo.

---

### Passo 8 — Dores não incluídas no ciclo

Ao final, liste as dores que não entraram nos OKRs gerados:

```
**Dores não incluídas neste ciclo:**
- DOR00X — [título]: [motivo — ex: fora do escopo do MVP, baseline indisponível, prioridade baixa]
- DOR00Y — [título]: [motivo]

Deseja incluir alguma delas ou guardar para o próximo ciclo?
```

---

## Iterando sobre OKRs já salvos

Quando o usuário voltar para atualizar um ciclo existente — mudar status, reportar progresso de um KR, encerrar ou revisar um objetivo — não gere um novo bloco do zero. Em vez disso:

- **Leia o bloco existente em `okrs.md`** pelo ID informado (ou pelo ciclo, se o ID não for citado) antes de editar.
- **Atualize o campo `Status`** conforme o ciclo avança: `Rascunho` → `Ativo` → `Concluído` | `Abandonado`. Só marque `Concluído` se o usuário confirmar que os Key Results foram de fato atingidos (ou explicar o resultado real).
- **Atualize a coluna `Baseline` ou adicione uma coluna de progresso atual** na tabela de Key Results quando o usuário informar um número novo — não sobrescreva a meta original, registre o valor atual ao lado dela.
- **Atualize a linha correspondente no Índice** do arquivo (Status e, se relevante, Data) — nunca deixe o índice divergente do bloco detalhado.
- **Resuma o que mudou**, não reapresente o OKR inteiro — o usuário já conhece a versão anterior.
- Se o progresso reportado revelar uma dependência ou risco novo travando o Key Result, registre-o formalmente primeiro (`/insert-knowledge`) e só então referencie o ID no OKR.
- **Depois de salvar uma mudança de `Status`**, acione a skill `check-integrity` focada nesse `OKR-N`, sem perguntar antes de rodar. Se houver achado de severidade Alta ou Média (ex: uma apresentação ou roadmap ainda cita o OKR como `Rascunho` depois de ele já ter virado `Concluído`), reporte ao usuário antes de encerrar; se não houver nada, siga sem mencionar.

---

## Comportamentos esperados

- **Nunca invente métricas ou números.** Se não há baseline nos guides, use `[a confirmar]`.
- **Pergunte antes de gerar se faltam informações críticas** — ciclo, escopo, priorização. Não gere OKRs genéricos por falta de contexto.
- **Conecte cada objetivo a dores reais.** Todo OKR deve ter pelo menos uma dor de processo como âncora — não gere objetivos sem raiz nos guides.
- **Respeite as decisões aprovadas.** Não proponha OKRs que contrariem o que está registrado em `conhecimento/planejamento/decisoes-aprovadas.md`.
- **Máximo 3 OKRs por ciclo** — salvo instrução explícita. Volume alto dilui foco.
- **Um ciclo por execução.** Se o usuário pedir OKRs para múltiplos ciclos de uma vez, gere para um ciclo por vez e pergunte se quer continuar para o próximo.
- **Nunca reutilize ou pule um ID de OKR.** Sempre confira o índice de `okrs.md` antes de atribuir o próximo `OKR-N`.
- **Riscos e dependências entram como contexto, não como desculpa.** Um risco ou dependência bloqueante pode justificar ou limitar um objetivo, mas nunca vira motivo para gerar um OKR vago — a conexão precisa ser explícita e com ID.
- **Atualização é iteração, não recriação.** Ao lidar com um ciclo já salvo, edite o bloco e o índice existentes — nunca gere um OKR duplicado para o mesmo ciclo/tema.
- **Roadmap existente sempre é consultado, quando existir, antes de fixar prazo.** Se houver um roadmap salvo cobrindo o período do ciclo, o prazo dos Key Results deve ser compatível com as janelas de tempo já sequenciadas nele — não proponha uma meta que ignore uma etapa ou dependência já mapeada no roadmap.
- **Um OKR só pertence ao time que o está definindo se esse time controla o resultado.** Não proponha objetivo (nem KR) para algo que a execução real pertence a outro time — sinalize e deixe de fora.
- **O ganho descrito no Objetivo tem que ser atribuído a quem de fato o sente.** Não assuma por padrão que é o cliente/usuário final — confira "Quem sente" na dor de origem. Um ganho interno (ex: menos retrabalho na operação) não deve ser escrito como se fosse uma melhoria de experiência para quem, na real, está assumindo mais trabalho.
- **ID sozinho nunca é suficiente.** Toda menção a DORxxx, RISxxx, Dxxx ou DEPxxx no texto gerado vem acompanhada do título curto — ninguém deveria precisar abrir `dores-de-processo.md`/`riscos.md`/`decisoes-aprovadas.md`/`dependencias.md` só para saber do que se trata uma referência no OKR.
