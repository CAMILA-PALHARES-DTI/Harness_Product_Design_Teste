---
name: intent
description: Gera a especificação funcional (briefing) de uma feature a partir do que já foi decidido/discutido em reuniões, decisões aprovadas e demais fontes da base — detalhando regras, comportamentos e necessidades com nível de profundidade suficiente para servir de base à construção de protótipos visuais. Também antecipa lacunas que as fontes não cobriram (origem dos dados exibidos, limites técnicos que virem regra de negócio) e produz um bloco estruturado, legível por IA, para gerar propostas de protótipo depois. Acione quando o usuário invocar /intent ou pedir para especificar/detalhar/documentar uma feature, gerar um briefing funcional, ou preparar a base de informação para o design começar a prototipar algo.
---

# intent

Esta skill responde uma pergunta específica: **dado que já se falou sobre uma feature (em reuniões, decisões, dores, fluxos), o que já sabemos sobre como ela deve funcionar, o que ainda falta decidir — e o que ninguém perguntou ainda, mas devia?** Produz um documento único, rastreável até a fonte, pronto para ser lido por quem vai desenhar ou construir a feature, e um bloco final estruturado para ser lido pela própria IA quando chegar a hora de propor protótipos.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e objetivo.

---

## Princípio fundamental

Esta skill **consolida e organiza o que já existe** — não inventa comportamento nem toma decisão de design/produto que ainda não foi tomada. Ela faz a ponte entre "o que foi dito/decidido, espalhado em várias fontes" e "um único documento navegável que qualquer pessoa do time consegue usar para prototipar ou construir".

Mas ela também tem um segundo papel, igualmente importante: **pensar no que as fontes não pensaram.** PM e cliente nem sempre cobrem, em reunião, perguntas como "de onde vem esse dado?", "quantos registros isso pode ter?", "essa API aguenta isso?". Esta skill deve levantar essas lacunas ativamente — nunca como fato registrado, sempre como hipótese explícita a validar.

Ela não decide:
- **Se a feature deve existir ou quando** — isso já deve estar resolvido antes (roadmap, priorização, backlog).
- **Como a solução deve ser desenhada visualmente** — isso é trabalho de design/prototipação, que usa esta especificação como insumo, não o contrário.
- **O que fazer com uma pergunta em aberto** — a skill lista a pergunta em "Perguntas Abertas"; não arrisca uma resposta que ninguém deu.

Duas categorias de conteúdo nunca podem se misturar visualmente no documento:
1. **Fato registrado** — algo que uma fonte confirma. Vem com citação da fonte.
2. **Hipótese levantada pela skill** — algo que nenhuma fonte disse, mas que é razoável esperar dado como sistemas parecidos funcionam (ex: "a API provavelmente pagina, como as demais integrações do ecossistema"). Vem sempre marcada como `[hipótese — a validar]`, nunca como se fosse fato.

Se uma regra de comportamento não está clara em nenhuma fonte e não é possível levantar uma hipótese razoável, ela vai para **Perguntas Abertas**.

---

## Gatilho

Acionada quando o usuário invoca `/intent` ou pede para: especificar, detalhar ou documentar uma feature; gerar um briefing funcional; consolidar tudo que já se sabe sobre uma funcionalidade; preparar a base de informação para o design/prototipação começar.

Normalmente roda **depois que a feature já foi discutida** em uma ou mais reuniões, tem ao menos uma decisão ou dor associada, e **antes de** um protótipo visual ou refinamento técnico começar.

---

## Passo 1 — Identificar a feature e o que já existe

Pergunte, se não vier claro no pedido (no máximo 3 perguntas):

1. **Qual é a feature/funcionalidade?** (nome — se ainda não tem nome oficial, peça uma descrição de 1 frase)
2. **Você já sabe de fontes específicas que precisam entrar?** (ex: "a reunião de refinamento de [data]", "a decisão D0XX", "o documento de dimensionamento de [fornecedor/área]") — se sim, priorize essas, mas não se limite a elas
3. **A que produto ela pertence?** (P1/P2/P3, se não for óbvio pelo contexto)

Não pergunte profundidade ou formato — o objetivo desta skill é sempre o mesmo (detalhe suficiente para prototipar), e o formato de saída é sempre o markdown estruturado descrito no Passo 7.

---

## Passo 2 — Levantar todas as fontes relevantes

Busque a feature (por nome e por termos relacionados — confira sinônimos no glossário) em:

| Fonte | O que procurar |
|---|---|
| `conhecimento/produto/contexto-de-negocio.md` | Regras de negócio já registradas sobre o módulo/entidade da feature |
| `conhecimento/produto/glossario.md` | Termos usados pela feature — para usar a linguagem certa e não confundir conceitos parecidos |
| `conhecimento/produto/dores-de-processo.md` | A dor que a feature resolve (alimenta a Declaração do Problema) |
| `conhecimento/planejamento/decisoes-aprovadas.md` | Decisões formais que já travam parte do comportamento |
| `conhecimento/planejamento/dependencias.md` | Dependências que travam ou condicionam a feature |
| `conhecimento/planejamento/riscos.md` | Riscos já identificados associados à feature |
| `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md` | Fluxo AS IS ou TO BE já mapeado envolvendo a feature |
| `conhecimento/cliente/reunioes/index.md` + atas individuais | Discussões, comportamentos descritos ao vivo, exemplos concretos dados pelo cliente |
| `conhecimento/cliente/reunioes/acoes-pendentes.md` | Ações em aberto que podem gerar Perguntas Abertas |
| `conhecimento/planejamento/backlogs/` e `conhecimento/planejamento/priorizacoes/` | Se a feature já foi quebrada em itens ou priorizada, isso dá pistas de escopo já fechado |
| `conhecimento/produto/mapa-stakeholders.md` | Quem é a fonte de cada decisão/opinião (para citar corretamente no Mapa de Fontes) |
| `documentos/` (`transcricoes/`, `analises/` e demais arquivos brutos ainda não absorvidos pela base) | Conteúdo que ainda não foi processado pela skill `insert-knowledge` mas é diretamente relevante — leia se o nome do arquivo ou uma busca por palavra-chave indicar relação com a feature |
| `Repositório/` (código-fonte clonado) | **Só com autorização explícita do usuário** — ver Passo 4. Nunca leia por conta própria nesta etapa |

Se o usuário indicou fontes específicas no Passo 1, leia-as primeiro e por completo — não resuma por cima.

**Não pule nenhuma linha desta tabela silenciosamente.** Se uma fonte não tiver nada relevante, isso é esperado; só não omita a checagem.

---

## Passo 3 — Checar divergências entre fontes

Antes de montar o rascunho, compare o que as fontes dizem entre si. É comum uma reunião mais recente contradizer ou refinar o que uma reunião anterior tinha dito, ou uma decisão formal (`decisoes-aprovadas.md`) ter fechado algo que antes estava em aberto.

Se encontrar divergência real (não apenas complemento):

```
⚠️ Encontrei versões diferentes sobre [aspecto]:
- [Fonte A, data]: "[o que diz]"
- [Fonte B, data]: "[o que diz]"

Qual prevalece, ou isso ainda está em aberto? (se não houver resposta clara, vira Pergunta Aberta)
```

Se não houver divergência, siga sem mencionar a checagem. Prefira sempre a fonte mais recente/formal (decisão aprovada > reunião > hipótese informal) quando não houver indicação explícita de revisão.

---

## Passo 4 — Pensar no que ainda não foi pensado

Este é o passo que diferencia esta skill de um simples resumo de fontes. Antes de escrever o rascunho, pare e questione ativamente a feature como um PM sênior ou um arquiteto revisando o escopo perguntariam:

- **De onde vem cada dado que a tela vai exibir?** Qual sistema, API, tabela ou integração alimenta essa informação? As fontes disseram isso, ou é uma lacuna?
- **Que regra de negócio implícita ninguém declarou, mas que a lógica do domínio exige?** (ex: se existe "reenvio", provavelmente existe um limite de quantos reenvios um pedido aceita — mesmo que nenhuma fonte tenha dito o número)
- **Que volume/escala essa tela ou fluxo provavelmente vai enfrentar?** Puxe pistas de volumetria já registradas em outras partes da base (contexto de negócio, dores de processo com números) para estimar se a lista pode ter poucos ou muitos itens.
- **Existe algum limite técnico plausível que poderia se transformar em regra de negócio?** (ex: limite de payload de uma API, timeout, limite de linhas retornadas) — isso é o insumo da Especificação Técnica Superficial (Passo 5.6).
- **Que estados de erro/exceção são previsíveis para esse tipo de integração/fluxo**, mesmo que nenhuma fonte tenha mencionado um caso específico?
- **Toda listagem tem um "clique no item" — o que abre?** Se a feature tem uma lista/tabela, pergunte explicitamente: ao clicar num item, abre um detalhe? Quais campos aparecem nesse detalhe (mesmo que a listagem já mostre um resumo)? Existe alguma ação disponível só dentro do detalhe (baixar, editar, cancelar, imprimir, aprovar) que não está disponível na listagem? Não deixe esse nível de interação implícito — se nenhuma fonte descreveu o detalhe, é uma lacuna a preencher com hipótese de domínio ou Pergunta Aberta, nunca a omitir.

Registre cada achado deste passo já classificado como `[hipótese — a validar]` — eles vão alimentar as seções de Regras e Comportamentos Funcionais, Especificação Técnica Superficial e Necessidades para Prototipação no Passo 5, sempre distinguíveis do que é fato confirmado.

**Se, para responder a uma dessas perguntas, for necessário conferir o código real** (ex: "esse endpoint pagina? qual o limite de retorno?", "esse campo existe na tabela?") — **pergunte antes de abrir o `Repositório/`:**

```
Para esclarecer [pergunta específica], eu preciso consultar o código em Repositório/[caminho aproximado, se souber].
Posso consultar? (só vou ler, nunca alterar — e o que eu encontrar entra como achado técnico rastreado à fonte "código", não como decisão de produto)
```

Só leia o repositório depois de autorização explícita, e só o trecho relevante à dúvida — não é uma varredura livre. O que encontrar no código é uma **fonte técnica**, não substitui uma decisão de negócio que ainda não foi tomada (ex: encontrar que a API pagina de 20 em 20 é fato técnico; decidir se a tela deve mostrar 20 por vez ou carregar tudo de uma vez ainda pode ser uma Pergunta Aberta de produto).

---

## Passo 5 — Montar o rascunho

Monte o documento com as seções abaixo, nesta ordem. Cada afirmação de regra/comportamento deve ser rastreável — ao lado ou no rodapé da seção, indique a fonte (ex: `[Reunião AAAA-MM-DD]`, `[D0XX]`, `[DOR00X]`, `[hipótese — a validar]`, `[código — Repositório/...]`). Isso alimenta o Mapa de Fontes do Passo 5.10 automaticamente — não é trabalho duplicado, é o mesmo rastro sendo coletado enquanto o rascunho é escrito.

### 5.1 — Visão Geral da Feature
Antes de qualquer problema, solução ou regra: uma descrição curta e simples, em linguagem de negócio, do que é a feature e para quem ela existe — o tipo de frase que uma pessoa nova no projeto leria primeiro para se situar (ex: "A tela de [nome da feature] é onde [tipo de usuário] consulta [o que ela consulta]. Ela reflete [de onde vêm os dados exibidos]."). Não é o Problem Statement (a dor) nem a Solução Proposta (o conceito do cliente) — é só a orientação básica: o que é, quem usa, o que ela mostra/faz em uma frase ou duas. Se essa descrição básica não estiver clara em nenhuma fonte, pergunte ao usuário antes de montar o restante do rascunho — é a base para todo o resto.

### 5.2 — Declaração do Problema
O problema de negócio/usuário que a feature resolve. Não é a solução, é a dor. Puxe de `dores-de-processo.md` quando houver dor formal associada; complemente com o que o cliente disse ao vivo em reunião sobre o impacto do problema (números, frequência, quem sofre).

### 5.3 — Solução Proposta
O conceito da solução **como o cliente/negócio o descreveu** — não a solução técnica que o time vai construir. Se o cliente disse "queremos que o usuário final consiga X" ou desenhou um fluxo verbalmente numa reunião, é isso que entra aqui, com a redação o mais fiel possível à intenção original. Se o time (produto/arquitetura) já propôs uma abordagem técnica diferente da intenção do cliente, registre as duas, sinalizando qual é qual — nunca misture como se fossem a mesma coisa.

### 5.4 — Critérios de Sucesso
Resultados **medíveis** que o cliente espera — não "o time vai considerar sucesso se...", mas o que o próprio cliente/negócio declarou como expectativa. Se a feature está ligada a um KR de OKR (`okrs.md`), cite o KR. Se não há critério medível declarado em nenhuma fonte, não invente um — liste isso em Perguntas Abertas ("critério de sucesso não declarado por nenhuma fonte").

### 5.5 — Regras e Comportamentos Funcionais
O corpo principal da especificação — organizado por tela, fluxo ou entidade, o que fizer mais sentido para a feature. Para cada regra, seja específico o suficiente para prototipar: campos (nome, tipo, obrigatoriedade), validações, estados possíveis e suas transições, mensagens de erro/confirmação já definidas, comportamento em cada caminho (fluxo esperado e exceções já discutidas). Use os termos exatos do `glossario.md`. Inclua aqui as hipóteses de regra implícita levantadas no Passo 4, marcadas como tal.

**Toda tela com listagem/tabela precisa de uma subseção própria de detalhe (drill-down).** Nunca pare na regra de listagem — para cada tipo de item clicável, detalhe explicitamente:
- **Campos exibidos no detalhe** — não só os que já aparecem na listagem; o detalhe normalmente mostra mais informação do que a linha resumida
- **Ações disponíveis dentro do detalhe** — o que o usuário pode fazer ali que não pode fazer na listagem (baixar, editar, cancelar, imprimir, aprovar, responder algo)
- **Navegação de volta** — o que acontece ao fechar/voltar do detalhe (idealmente preservando o estado da listagem, se já for uma regra confirmada)

Liste só o que **vai** existir. Uma ação/campo já descartado de escopo (ex: "exportação em PDF não entra no MVP") não é repetido aqui — isso já está em Restrições; repetir por listagem/tela é ruído, não sinal (ver Diretrizes de comportamento).

Se nenhuma fonte descreveu o detalhe de um item clicável, não pule essa parte — registre os campos/ações mais prováveis como `[hipótese — a validar]` (baseando-se em telas de referência ou lógica de domínio) e liste a confirmação exata como Pergunta Aberta.

Se uma regra foi mencionada mas não detalhada (ex: "vai ter uma validação ali" sem dizer qual), registre a regra como existente e marque o detalhe faltante como `[a confirmar]`, listando em Perguntas Abertas.

### 5.6 — Especificação Técnica Superficial
Seção nova, alimentada pelo Passo 4: um raio-x técnico leve — não é desenho de arquitetura — que existe para capturar **limites técnicos que podem se transformar em regra de negócio ou em comportamento visual obrigatório**. Para cada dado ou operação relevante da feature, registre (quando souber ou puder levantar hipótese razoável):

- **Origem do dado exibido** — de qual sistema/API/tabela ele vem (ex: "lista de itens vem da API de Catálogo", "status do pedido vem do sistema legado via getPedidos")
- **Limite técnico conhecido ou hipotético** — payload máximo, paginação nativa da API, timeout, limite de linhas, rate limit
- **Consequência para a regra de negócio ou tela** — o que esse limite força a decidir (ex: "API retorna no máximo 50 registros por chamada → a tela precisa paginar ou usar scroll incremental, não pode assumir lista completa de uma vez")

Tudo aqui que não vier de uma fonte explícita é `[hipótese — a validar]`. Esta seção existe justamente para que produto/design não sejam pegos de surpresa depois — ela é oficialmente superficial, não substitui um desenho técnico real.

### 5.7 — Necessidades para Prototipação
Ponte explícita entre a especificação e quem vai desenhar. Liste:
- **Telas/estados necessários** (ex: vazio, preenchido, erro, sucesso, loading — inclua os que já têm indício nas fontes e os que a Especificação Técnica Superficial tornou necessários, ex: estado "carregando mais itens" se há paginação)
- **Dados de entrada/saída** que o protótipo precisa simular (campos, formatos, exemplos reais se houver)
- **Casos de borda já conhecidos** que o protótipo não pode ignorar (ex: "o que aparece quando a busca não retorna nada", "o que acontece se o campo X estiver vazio")
- **Comportamento visual exigido por limite técnico** (ex: "paginação obrigatória de X itens por página — decorre do limite da API, ver 5.6")

### 5.8 — Restrições
Não-negociáveis — técnicos, de negócio ou de compliance — que limitam a solução, independente de preferência de design. Puxe de `decisoes-aprovadas.md` (decisões já travadas), `dependencias.md` (o que precisa estar resolvido antes), `riscos.md` (riscos que forçam uma restrição preventiva), da Especificação Técnica Superficial (5.6, quando o limite for confirmado, não só hipótese) e qualquer restrição legal/regulatória mencionada (ex: LGPD, obrigação de manifesto de carga). Separe por tipo (Técnica / Negócio / Compliance) quando houver mais de uma de cada.

### 5.9 — Perguntas Abertas
Toda pergunta real que apareceu durante os Passos 2, 3 e 4 e não tem resposta em nenhuma fonte (incluindo hipóteses do Passo 4 que precisam de confirmação formal). Formate como pergunta objetiva, não como afirmação vaga — e indique quem parece ser o dono natural da resposta (PM, arquitetura, negócio do cliente) quando for possível inferir pelas fontes.

### 5.10 — Mapa de Fontes
Tabela de rastreabilidade — não uma lista de fontes lidas, mas **qual fonte sustenta qual decisão-chave** da especificação, incluindo as hipóteses da skill e eventuais achados de código:

| Decisão/Regra-chave | Fonte | Tipo de fonte |
|---|---|---|
| [ex: "documento obrigatório só após selecionar o tipo X"] | DEP0XX / Reunião de refinamento AAAA-MM-DD | Dependência + Reunião |
| [ex: "a listagem provavelmente pagina"] | Análise do endpoint em `Repositório/...` | Código (autorizado) |
| [ex: "provavelmente existe limite de reenvios por pedido"] | Inferência da skill, sem confirmação | Hipótese — a validar |

Inclua só as decisões/regras que de fato moldam a feature — não replique cada frase do documento inteiro nesta tabela.

### 5.11 — Direcionador para o Protótipo
Bloco final, estruturado, pensado para ser **lido por uma IA** no momento em que o usuário pedir para gerar propostas de protótipo a partir desta especificação — não é redundante com as seções acima, é a mesma informação reempacotada em formato consumível programaticamente. Use blocos YAML, um por tela/fluxo:

```yaml
tela: [Nome da tela ou fluxo]
objetivo: [uma frase — para que essa tela existe]
campos:
  - nome: [ex: nome_usuario]
    tipo: texto | numero | data | selecao | booleano | lista | arquivo
    obrigatorio: true | false
    origem: [sistema/API/tabela de onde o dado vem, ou "a confirmar"]
    validacao: [regra de validação conhecida, ou "nenhuma registrada"]
estados_de_tela:
  - [ex: vazio, carregando, erro, sucesso, parcial, carregando_mais]
comportamentos:
  - [ex: "busca com mínimo de 2 caracteres antes de acionar"]
  - [ex: "paginação de 20 itens por página"]
regras_visuais_derivadas_de_limite_tecnico:
  - origem: [ex: "limite de retorno da API de listagem"]
    comportamento_exigido: [ex: "paginação client-side ou scroll incremental"]
    status: confirmado | hipotese
perguntas_abertas_relacionadas:
  - [referência às perguntas do 5.8 que afetam esta tela, se houver]
```

Gere um bloco por tela/fluxo relevante da feature — não force um bloco único se a feature tiver múltiplas telas com formas diferentes. Mantenha os valores de `status` honestos: nunca marque `confirmado` algo que só apareceu como hipótese no Passo 4.

Este bloco descreve **só o que vai existir.** Nenhum campo, comportamento ou ação já descartada de escopo entra aqui (nem como "ausente" ou "não incluído") — isso é ruído para quem for gerar um protótipo a partir deste YAML. O que foi excluído já está em Restrições; não duplique.

---

## Passo 6 — Confirmação com o usuário

Apresente o rascunho completo (todas as 11 subseções) e pergunte:

```
Este é o rascunho da especificação. Você pode:
- Aprovar e eu salvo o arquivo
- Pedir ajuste em qualquer seção (adicionar, remover, reescrever)
- Apontar uma fonte que eu não usei ou usei errado
- Confirmar ou descartar alguma das hipóteses que levantei no Passo 4

O que deseja alterar antes de eu salvar?
```

Não salve sem aprovação explícita. Repita o ciclo de ajuste quantas vezes for necessário. Se o usuário confirmar uma hipótese como verdadeira, mova-a de `[hipótese — a validar]` para fato registrado (citando o próprio usuário como fonte: `[confirmado pelo usuário em 2026-08-17]`) antes de salvar.

---

## Passo 7 — Geração do arquivo final

Nome do arquivo: `briefing-[slug-da-feature]-[YYYY-MM-DD].md`

```markdown
---
tipo: briefing-funcional
feature: [nome da feature]
produto: [P1 | P2 | P3]
status: Rascunho | Validado
gerado-em: [YYYY-MM-DD]
fontes-consultadas: [lista de guides/reuniões/documentos usados]
repositorio-consultado: sim | não
---

# Especificação Funcional — [Nome da feature]

## Visão Geral da Feature
[...]

## Declaração do Problema
[...]

## Solução Proposta
[...]

## Critérios de Sucesso
[...]

## Regras e Comportamentos Funcionais
[...]

## Especificação Técnica Superficial
[...]

## Necessidades para Prototipação
[...]

## Restrições
[...]

## Perguntas Abertas
[...]

## Mapa de Fontes
[tabela]

## Direcionador para o Protótipo
[blocos YAML — um por tela/fluxo]
```

Antes de salvar, rode `powershell -File scripts/validar-referencias.ps1 -Arquivo <caminho do arquivo>` sobre o conteúdo já escrito (inclusive o Mapa de Fontes e o Direcionador para o Protótipo, que costumam citar IDs). Se apontar algum ID que não existe em nenhum guide, corrija antes de prosseguir.

Rode também `powershell -File scripts/lint-yaml-bloco.ps1 -Arquivo <caminho do arquivo> -Esquema intent` sobre os blocos YAML do Direcionador para o Protótipo (seção 5.11) — ele confere sintaxe (bloco fechado, indentação, placeholder de template esquecido) e estrutura (campo obrigatório presente, enum válido em `tipo`/`obrigatorio`/`status`). Corrija qualquer achado de severidade Alta antes de considerar o bloco pronto para alimentar uma prototipação — um YAML malformado ali quebra silenciosamente quem for consumi-lo depois.

Salve em `conhecimento/desenvolvimento/briefings-funcionais/` e atualize `conhecimento/desenvolvimento/briefings-funcionais/index.md` (crie o índice, seguindo o padrão de `conhecimento/planejamento/backlogs/index.md`, se ainda não existir).

---

## Diretrizes de comportamento

- **Nunca invente regra, número ou critério como se fosse fato.** Se nenhuma fonte disse, é `[hipótese — a validar]` (se você conseguir sustentar a hipótese com lógica de domínio) ou Pergunta Aberta (se nem isso for possível) — nunca preenchimento plausível apresentado como certeza.
- **Pense além do que foi perguntado.** O valor desta skill está em levantar o que ninguém pensou (origem de dado, limite técnico, regra implícita) — não se limite a repetir o que as fontes já disseram explicitamente.
- **Nunca leia `Repositório/` sem autorização explícita para aquela dúvida específica.** Pergunte antes, diga exatamente o que vai verificar e por quê. Nunca edite o repositório — é código-fonte clonado só para consulta.
- **Distinga intenção do cliente de decisão técnica do time.** "Solução Proposta" é a voz do cliente/negócio; uma decisão de arquitetura que resolve isso de outro jeito é `Restrição` ou nota lateral, não a mesma coisa.
- **O que já foi definido como fora de escopo não aparece na descrição da feature, nem em Regras e Comportamentos Funcionais, nem no Direcionador para o Protótipo.** Exclusão de escopo vive **só** em Restrições (e, se fizer sentido, no Mapa de Fontes). Não repita "isso não faz parte", "sem ação de X", "fora do MVP" em campos/comportamentos do YAML nem na Visão Geral — quem for ler a descrição ou o bloco estruturado deve ver só o que **vai** existir; o que não vai existir fica registrado uma única vez, no lugar certo.
- **Toda regra é rastreável — inclusive as hipóteses.** Se você não consegue apontar de qual fonte (ou de qual raciocínio) uma frase da especificação veio, ela não devia estar lá.
- **Prefira a fonte mais recente/formal em caso de conflito não resolvido**, mas sempre sinalize a divergência ao usuário antes (Passo 3) — nunca decida silenciosamente qual fonte "ganha".
- **Detalhe até o ponto de servir a um protótipo, não além.** Não decida paleta de cor, biblioteca de componente, nem microcopy final — isso é trabalho de design que vem depois, usando esta especificação como base.
- **O Direcionador para o Protótipo (5.11) precisa ser honesto sobre `status`.** Nunca marque como `confirmado` uma regra que só existe como hipótese da skill.
- **Nunca crie o arquivo sem aprovação explícita do rascunho.**

---

## Orientação ao final

Após salvar a especificação, informe o usuário:

> **Especificação salva.**
> - Arquivo: `conhecimento/desenvolvimento/briefings-funcionais/[nome-do-arquivo].md`
> - Feature: [nome] · Produto: [P1/P2/P3]
> - [N] fontes consolidadas ([N] reuniões, [N] decisões, [N] dependências, [N] outros)
> - [N] hipóteses levantadas pela skill ([N] confirmadas pelo usuário, [N] ainda a validar)
> - [N] Perguntas Abertas registradas — [liste os donos naturais identificados, se houver]
> - [N] blocos de Direcionador para o Protótipo (um por tela/fluxo)
>
> **Próximo passo sugerido:** usar esta especificação como base para prototipação visual (o bloco "Direcionador para o Protótipo" foi feito para isso), ou levar as Perguntas Abertas para quem for o dono de cada uma antes de prototipar o que depende delas. O caminho recomendado é `/flow-mapping` (fluxo de usuário), depois — opcionalmente — `/screen-planner` (inventário de telas) e `/create-prototype` (protótipo navegável); `/create-prototype` também funciona direto a partir deste briefing.
