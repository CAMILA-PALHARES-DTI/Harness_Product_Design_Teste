---
name: create-spec
description: Gera a especificação de desenvolvimento de uma feature (Specs com User Stories), agrupando várias User Stories em Specs do tamanho de uma entrega de desenvolvimento (feature-sized), a partir do briefing funcional da feature — com ou sem protótipo/artefato visual. Quando há protótipo (HTML, React ou similar), extrai comportamentos, estados de tela e navegação dele; quando não há, parte do briefing e das demais fontes da base e marca como lacuna o que um protótipo mostraria. Cada US dentro da Spec mantém o mesmo nível de detalhe: edge cases mapeados (volume, concorrência, falha de integração, navegação atípica, dado inconsistente), critério de aceite sempre em BDD (Dado/Quando/Então), Perguntas Abertas da sabatina e um bloco YAML pronto para IA de desenvolvimento. Acione quando o usuário invocar /create-spec ou pedir para gerar as Specs de uma feature, quebrar uma feature em US e specs de desenvolvimento, mapear edge cases, ou preparar entregas prontas para uma IA implementar — tendo ou não um protótipo.
---

# create-spec

Esta skill responde uma pergunta específica: **dado o briefing funcional de uma feature (e, se existir, o protótipo que a materializa), quais Specs de desenvolvimento compõem essa entrega — cada uma agrupando as User Stories que o desenvolvimento vai construir juntas — e o que cada US precisa ter documentado para que um desenvolvedor consiga enviar a Spec para uma IA e sair com a funcionalidade pronta?**

A unidade de **quebra** é a **Spec**: do tamanho de uma feature, ou de uma fatia dela que o desenvolvimento entrega de uma vez. A unidade de **detalhamento** continua sendo a **User Story**: dentro de cada Spec, toda US tem o mesmo nível de detalhe de sempre. Juntar várias US numa Spec muda o tamanho do pedido ao desenvolvimento, não a profundidade da especificação.

Produz três coisas por US: (1) uma especificação detalhada — comportamento, estados, dados, validações, navegação — extraída do protótipo (quando houver) e cruzada com o briefing; (2) um mapeamento sistemático de edge cases (volume, concorrência, falha de integração, navegação atípica, dado inconsistente) e como cada um deveria ser tratado; (3) uma lista de Perguntas Abertas geradas pela sabatina e pelos edge cases sem resposta, que existe especificamente para pegar o que falta antes que o desenvolvimento comece. Por Spec, soma o que é comum às US dela: ordem de implementação, regras transversais e dependências entre elas.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e objetivo.

**Rótulos que os sensores leem:** títulos de seção, rótulos em linha, nomes de coluna e valores de frontmatter listados em `scripts/rotulos.txt` são escritos com o texto da coluna do idioma configurado (português ou inglês), exatamente como no dicionário e sem inventar variações — os sensores só reconhecem essas variantes. Rótulos que o `CLAUDE.md` mantém fixos (`Dado`/`Quando`/`Então`, `Cenário`, IDs, marcadores) não mudam de idioma.

---

## Princípio fundamental

Esta skill fica entre a especificação funcional (`intent`) e a implementação. Ela não decide:

- **Se a feature deve existir ou o que ela resolve** — isso já está fechado no briefing funcional, fonte de verdade do "porquê" e do "o quê" em nível de produto.
- **Como a tela deve parecer visualmente** — quando há protótipo, ele já é a decisão de design e esta skill lê o que ele mostra; quando não há, esta skill não inventa o visual: registra o comportamento esperado e marca como lacuna o que só um design resolveria.
- **Arquitetura real do sistema** — quando o comportamento exige saber algo do backend real (contrato de API, nome de campo, regra de validação existente), a skill levanta a dúvida como hipótese ou Pergunta Aberta, e só consulta `Repositório/` com autorização explícita (ver Passo 5).

O que ela decide, de fato:
- **Como recortar a feature em unidades de entrega testáveis** (US) e **como agrupar essas US em Specs** que o desenvolvimento constrói juntas — usando o briefing para saber o que é valor de negócio e, quando existir, o protótipo para saber o que é uma unidade coerente de tela/fluxo/interação.
- **O nível de detalhe de cada US dentro da Spec** — deliberadamente mais técnico e mais granular que `intent` (que é funcional) e mais fundo que `define-deliverables` (que só gera nome + uma frase). Aqui a spec precisa ser suficiente para desenvolvimento autônomo assistido por IA.

Duas categorias de conteúdo nunca podem se misturar:
1. **Comportamento observado** — o que o protótipo efetivamente faz/mostra (quando houver), ou o que o briefing e as demais fontes da base confirmam. Vem com referência (arquivo do protótipo + trecho, ou seção do briefing/fonte).
2. **Hipótese/lacuna levantada pela sabatina** — algo que nem o protótipo (se houver) nem o briefing resolveram, mas que o desenvolvimento não pode começar sem decidir. Vira Pergunta Aberta, nunca resposta inventada.

---

## Gatilho

Acionada quando o usuário invoca `/create-spec` ou pede para: gerar as Specs de uma feature, quebrar uma feature em User Stories e Specs de desenvolvimento, preparar entregas para enviar para uma IA implementar, ou detalhar tecnicamente uma feature — **tenha ou não um protótipo pronto**.

Normalmente roda **depois que** existe um briefing funcional da feature (`intent`). O protótipo/artefato visual (HTML, React ou outra tecnologia) é **opcional**: se existir, a skill extrai dele o comportamento; se não existir, parte só do briefing e das demais fontes da base. Se faltar o briefing, ver Passo 1.

---

## Passo 1 — Identificar a feature, o briefing e o protótipo (se houver)

Sempre pergunte estas três coisas antes de começar, mesmo que o usuário já tenha mandado parte da informação (no máximo 1 rodada de perguntas, agrupada):

1. **Qual é a funcionalidade/feature?** (nome — para localizar ou nomear os arquivos gerados)
2. **Qual é o briefing funcional dela?** — caminho do arquivo em `conhecimento/desenvolvimento/briefings-funcionais/`, ou, se ainda não existe, peça para rodar `intent` antes (não gere Spec sem uma base funcional — sem ela, a skill fica adivinhando o "porquê" de cada comportamento)
3. **Existe um protótipo/artefato visual? Se sim, em qual pasta?** — caminho relativo dentro do repositório de trabalho (ex: `documentos/gerados/prototipo-[feature]-2026-08-20.html`, ou uma pasta com múltiplos arquivos de um app React). Se **não existe**, tudo bem: registre "sem protótipo" e siga — a spec é gerada só a partir do briefing e das demais fontes.

Se o usuário não souber o caminho exato do briefing, procure por nome da feature em `conhecimento/desenvolvimento/briefings-funcionais/index.md` antes de perguntar de novo.

Não prossiga para o Passo 2 sem a feature e o briefing confirmados e sem a resposta sobre o protótipo (existe / não existe) — sem o briefing não há como validar o que é intencional; sem saber se há protótipo, não dá para escolher o caminho do Passo 3.

---

## Passo 2 — Ler o briefing funcional por completo

Leia o arquivo de especificação funcional indicado no Passo 1, sem resumir por cima. Preste atenção especial em:

- **Regras e Comportamentos Funcionais** — vai virar a base de comparação com o que o artefato mostra
- **Especificação Técnica Superficial** — limites técnicos já mapeados (paginação, origem de dado) que toda US que tocar esse dado precisa herdar
- **Necessidades para Prototipação** — estados de tela e casos de borda que o briefing já esperava ver no artefato
- **Restrições** — não-negociáveis que nenhuma US pode contradizer
- **Perguntas Abertas** já existentes — se ainda não foram respondidas, elas provavelmente continuam abertas aqui, e não devem ser silenciosamente resolvidas por uma suposição da IA ao ler o protótipo
- **Direcionador para o Protótipo (YAML)** — se há protótipo gerado a partir desse bloco, ele é o contrato original e divergências entre o YAML e o protótipo real são o primeiro lugar para checar no Passo 4; se **não há** protótipo, esse bloco é a melhor descrição estruturada de telas, campos e estados que o briefing oferece, e vira a base do inventário do Passo 3

---

## Passo 3 — Extrair comportamento e navegação (do protótipo ou do briefing)

### 3A — Com protótipo

Leia o artefato indicado no Passo 1 (arquivo único ou pasta) usando Read/Glob/Grep — não confie em memória de artefatos vistos antes na conversa, releia agora. Se for uma pasta com múltiplos arquivos (ex: projeto React), mapeie primeiro a estrutura (Glob) antes de entrar arquivo por arquivo.

Para cada tela/rota/componente relevante, extraia e registre:

| O que procurar | Onde tipicamente aparece |
|---|---|
| **Telas/rotas existentes** | Componentes de página, definições de rota (`react-router`, `<a href>`, `window.location`), seções/`<section>` com IDs distintos em HTML único |
| **Navegação entre telas** | Links, botões com handler de navegação, abas, modais que abrem sobre a tela atual, breadcrumbs |
| **Campos e formulários** | `<input>`, `<select>`, componentes de formulário — nome, tipo aparente, se tem `required`/validação inline, mensagens de erro já escritas no HTML/JS |
| **Estados de tela** | Classes/condicionais que indicam vazio, carregando, erro, sucesso, parcial — geralmente em `if`/ternário no React, ou em blocos ocultos por classe no HTML |
| **Ações do usuário** | Todo botão/ícone clicável — o que ele parece disparar (submit, abrir detalhe, filtrar, exportar, cancelar) |
| **Dados exibidos e sua origem aparente** | Dado hardcoded/mock vs. dado claramente vindo de uma variável/prop/fetch — sinaliza o que a US real precisa conectar a uma fonte de verdade |
| **Interações de listagem** | Ordenação, paginação, busca, filtro — se o artefato já simula isso (ainda que com dado mock), é comportamento a especificar, não a inventar |
| **Microcopy definida** | Textos de botão, título, mensagem de vazio/erro já escritos no artefato — viram fonte direta para "Regras e Comportamentos", evitando reinvenção de copy pela IA de desenvolvimento depois |

Monte uma lista bruta de "telas/fluxos observados no artefato" antes de seguir — é o inventário que vira a base da quebra em US no Passo 4.

Se o artefato for ambíguo num ponto (ex: um botão sem handler claro, um estado que não está implementado no protótipo), **não infira o comportamento** — marque como `[comportamento não implementado no artefato — a confirmar]` e deixe para a sabatina do Passo 6 decidir se vira Pergunta Aberta.

**Protótipo gerado pela skill `create-prototype`** (`documentos/gerados/prototipo-[slug]-[data].html`): ele segue uma estrutura previsível — use-a para extrair mais rápido e com menos ambiguidade:

- **Telas:** cada `<section class="screen" id="SCR-NN">` é uma tela. Mantenha o ID `SCR-NN` na coluna de referência de cada US (ex: `Referência: prototipo-x.html · SCR-02`) e no campo `tela_referencia` do YAML. Se existir o inventário `documentos/gerados/inventario-telas-[slug]-[data].md` (gerado por `screen-planner`), leia-o também: ele traz hierarquia, componentes do DS, estados e destinos por `SCR-NN`.
- **Estados:** os blocos `data-screen="SCR-NN" data-state="default|loading|empty|error|success"` são os estados de cada tela; a ausência de um deles numa tela com envio ou lista é lacuna, não decisão.
- **Navegação:** `navigateTo('SCR-NN')` nos atributos `onclick` e no script define destinos; a barra `#debug-nav` é só apoio do protótipo, **não** vira funcionalidade.
- **Marcadores:** `[a confirmar]` e `[a11y: a revisar]` no texto do protótipo são lacunas conhecidas — nunca as resolva em silêncio; viram `[comportamento não implementado no artefato — a confirmar]` ou Pergunta Aberta. `[sugestão: Heurística N]` é uma sugestão do designer que **não** foi aprovada como escopo: trate como hipótese a validar, não como comportamento confirmado.

### 3B — Sem protótipo

Sem artefato visual, o inventário é montado a partir do que a base já sabe, nesta ordem de fonte: (1) o briefing funcional (Regras e Comportamentos, Necessidades para Prototipação e o bloco "Direcionador para o Protótipo"); (2) `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md` e os fluxos em `conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/`, se a feature aparecer neles; (3) reuniões e decisões aprovadas citadas no mapa de fontes do briefing. Registre a mesma lista de "telas/fluxos/ações/campos/estados" do 3A, só que cada item cita a **seção do briefing ou a fonte** em vez de um trecho de código.

Regras específicas deste caminho:

- **Não existe "o que o protótipo mostra" para desempatar.** Se o briefing não define um estado, uma mensagem de erro, a ordem das ações ou um campo, isso é lacuna: marque `[sem protótipo e sem definição no briefing — a confirmar]` e deixe para a sabatina do Passo 6. Nunca preencha com o que "faria sentido visualmente".
- **Marque a ausência de referência visual, não a esconda.** Todo comportamento derivado só do briefing leva `[sem referência visual]` ao lado da fonte, para o time de design saber o que ainda precisa ser desenhado.
- **A sabatina fica mais pesada, não mais leve.** Sem protótipo, mais itens do Passo 6 (estados de tela, microcopy, destino da ação) vão cair como Pergunta Aberta ou hipótese — isso é esperado e é o valor da skill nesse cenário.

---

## Passo 4 — Cruzar fontes, propor a quebra em US e agrupar em Specs

Compare o inventário do Passo 3 com o briefing do Passo 2:

- **Com protótipo:** todo comportamento do briefing tem uma representação no artefato? Se o briefing descreveu uma regra que o artefato não mostra (ex: um estado de erro previsto mas não prototipado), registre a lacuna — ela ainda vira US, só que sem referência visual direta. E todo comportamento do artefato está coberto pelo briefing? Se o artefato tem algo que o briefing não previu (comum quando design resolveu um detalhe sozinho), sinalize como `[decisão de design não registrada no briefing]` — não é erro, só precisa virar fato registrado explicitamente, não silenciosamente assumido.
- **Sem protótipo:** o inventário já nasce do briefing, então o cruzamento é com as demais fontes (fluxos, reuniões, decisões): há contradição entre elas? Algo citado numa reunião que o briefing não consolidou? Registre como `[divergência entre fontes — a confirmar]`, nunca escolha um lado em silêncio.

### 4.1 — Quebra em User Stories

Proponha primeiro a quebra em User Stories. Critério de corte: cada US é um **incremento de valor testável do ponto de vista de quem usa** — normalmente um fluxo completo (ex: "buscar e visualizar resultado"), um estado significativo isolável (ex: "tratar erro de busca sem resultado"), ou uma ação isolada com valor próprio (ex: "exportar resultado em PDF"). Não quebre por componente técnico (ex: "criar o botão X" não é uma US).

### 4.2 — Agrupamento em Specs (o nível de quebra)

Depois, **agrupe as US em Specs**. Uma Spec é o pacote que o desenvolvimento recebe e constrói de uma vez — do tamanho de uma feature, ou de uma fatia coerente dela. Agrupe US que:

- compartilham o mesmo fluxo, a mesma tela/área ou os mesmos dados (construir separadas geraria retrabalho ou conflito);
- só fazem sentido entregues juntas (ex: "listar resultados", "filtrar", "exportar" sobre a mesma listagem);
- partilham regras de negócio, estados de tela ou integrações que seria redundante repetir em specs separadas.

Separe em Specs diferentes quando houver partes independentes entre si (podem ser construídas e liberadas em momentos distintos), integrações ou donos técnicos diferentes, ou quando a Spec ficaria grande demais para uma única entrega. Uma feature pequena pode ser uma Spec só, com 2 ou 3 US; uma feature grande pode gerar várias Specs.

Apresente a proposta ao usuário assim, e aguarde validação antes de detalhar qualquer coisa:

```
Proposta de quebra — [Feature]
Protótipo: [caminho | sem protótipo — base: briefing e fontes da base]

SPEC-1 — [Nome da Spec] — [uma frase da entrega]
  US-1.1 — [Nome da US] — [uma frase do valor entregue]
           Referência: [tela/fluxo no protótipo | seção do briefing]
  US-1.2 — [...]
SPEC-2 — [Nome da Spec] — [uma frase]
  US-2.1 — [...]

Confirma esse agrupamento, quer juntar/separar Specs, mover alguma US de lugar ou renomear algo antes de eu detalhar cada US?
```

Só siga para o Passo 5 depois da confirmação.

---

## Passo 5 — Consultar o repositório (só com autorização explícita)

Se, ao escrever a spec de uma US, surgir uma dúvida que só o código real resolve (ex: "esse endpoint já existe?", "esse campo já existe na entidade?", "qual o nome real da rota/controller equivalente?"), pergunte antes de abrir `Repositório/`:

```
Para detalhar [US específica], eu preciso consultar o código em Repositório/[caminho aproximado, se souber].
Posso consultar? (só vou ler, nunca alterar — o que encontrar entra como achado técnico rastreado à fonte "código", não substitui uma decisão de produto ainda não tomada)
```

Só leia depois de autorização explícita, e só o trecho relevante à dúvida daquela US — não é varredura livre. Um achado técnico (ex: "o endpoint `GetPedidos` já pagina de 20 em 20") é fato técnico citável; decidir se a US deve usar esse comportamento tal como está ainda pode ser Pergunta Aberta de produto.

---

## Passo 6 — Sabatina: questionar cada US antes de fechar

Este é o passo que garante que a spec sirva para desenvolvimento autônomo por IA. Para **cada** US da quebra confirmada, faça a si mesmo esta checklist antes de considerá-la pronta — nunca pule esta etapa, mesmo que a US pareça simples:

- **Toda ação do usuário tem um destino técnico definido?** (endpoint, rota, função — real se consultado no Passo 5, hipótese caso contrário) Se não, Pergunta Aberta.
- **Todo campo de entrada tem tipo, obrigatoriedade e validação explícitos?** Um campo sem regra de validação declarada não pode assumir "sem validação" silenciosamente — pergunte ou marque `[a confirmar]`.
- **Todo estado de tela (vazio, carregando, erro, sucesso, parcial) está coberto?** Se o protótipo não implementou um desses estados (ou não há protótipo), a US ainda precisa de uma decisão sobre o que exibir — não deixe a IA de desenvolvimento inventar isso sozinha depois.
- **Toda mensagem de erro/confirmação está com texto definido, ou pelo menos com o gatilho e o tom esperado?**
- **Existe regra de permissão/perfil de acesso para essa ação?** (quem pode ver/fazer isso) Se o briefing e o protótipo (se houver) não disserem, isso é Pergunta Aberta — nunca assuma acesso livre por omissão.
- **O que acontece depois que a ação principal da US é concluída?** (navegação, atualização de tela, notificação) Se não estiver claro, é lacuna.
- **Essa US depende de outra US ou de algo externo ainda não resolvido** (dependência do `dependencias.md`, decisão pendente)? Marque a dependência explicitamente, com ID se houver.
- **Dado que aparece na tela: qual a origem real, e o que acontece se ela falhar ou demorar?** Herdado da Especificação Técnica Superficial do briefing quando existir; senão, hipótese ou Pergunta Aberta.
- **Existe algum critério objetivo para considerar a US pronta**, escrito em Dado/Quando/Então verificável sem interpretação, além de "a tela parece com o protótipo"?

Cada resposta "não sei" ou "não está definido em nenhuma fonte" vira uma linha em **Perguntas Abertas** daquela US — formatada como pergunta objetiva, não afirmação vaga, com o dono natural sugerido quando possível inferir (dev, produto, arquitetura, negócio do cliente).

Não invente resposta para fechar a checklist artificialmente. O valor desta etapa está exatamente em deixar visível o que falta — uma US com 5 Perguntas Abertas é um resultado válido e esperado, não uma falha da skill.

---

## Passo 7 — Mapear edge cases e como lidar com eles

A sabatina do Passo 6 garante que o **caminho principal** de cada US está completo. Este passo existe para ir além: pensar ativamente em cenários **fora do caminho principal** que o artefato normalmente não prototipa e o briefing normalmente não descreve, mas que vão acontecer em produção — e decidir, para cada um, se já há resposta, se dá para propor uma hipótese razoável, ou se é preciso perguntar.

Para **cada** US, percorra as sete categorias abaixo. Nem toda categoria se aplica a toda US — pule a que for genuinamente irrelevante (ex: uma US somente-leitura não tem edge case de concorrência de escrita), mas registre essa decisão de pular, não apenas omita em silêncio.

| Categoria | Pergunta a fazer | Exemplos de gatilho |
|---|---|---|
| **Volume e cardinalidade** | O que acontece nos extremos de quantidade? | Zero itens, exatamente um item, volume no limite exato do teto técnico, volume acima do teto, campo de lista vazio vs. nulo |
| **Entrada de dados** | O que acontece com dado fora do padrão esperado? | Campo vazio, valor no limite mínimo/máximo, caracteres especiais/acentuação/emoji, formato inválido vindo de integração (não digitado pelo usuário), campo obrigatório ausente por falha upstream |
| **Concorrência e repetição** | O que acontece se a mesma ação acontecer mais de uma vez ou ao mesmo tempo? | Duplo clique/duplo submit, duas abas do mesmo usuário abertas na mesma US, duas pessoas agindo sobre o mesmo item ao mesmo tempo, repetir a mesma ação já concluída (idempotência) |
| **Mudança de estado durante a interação** | O que acontece se o mundo mudar enquanto o usuário está no meio do fluxo? | Item muda de status enquanto está selecionado/aberto/sendo processado, sessão expira no meio da ação, permissão do usuário muda no meio da sessão |
| **Falhas de integração** | O que a tela mostra quando a dependência externa falha de formas diferentes de "erro genérico"? | Timeout, resposta parcial/truncada, erro de negócio vs. erro técnico, integração fora do ar, resposta em formato inesperado |
| **Navegação atípica** | O que acontece fora do fluxo linear que o protótipo assume? | Botão "voltar" do navegador, atualizar a página (F5) no meio do fluxo, abrir link direto (deep link) para uma tela que depende de estado de uma tela anterior que não existe |
| **Dados inconsistentes ou órfãos** | O que acontece quando o dado real não é tão limpo quanto o mock? | Referência quebrada (ex: item aponta para um registro que não existe mais), combinação de campos que a regra de negócio diz que não deveria existir, mas que dado sujo pode produzir |

Para cada cenário concreto identificado (não a categoria em si — o cenário específico daquela US), registre:

1. **O que acontece** — descrição objetiva do gatilho e do que se espera ver.
2. **Como é tratado hoje** — três respostas possíveis, sempre rastreáveis:
   - **Confirmado** — o protótipo (se houver) já implementa isso, ou o briefing já responde. Cite a fonte.
   - **Hipótese proposta** — nem protótipo (se houver) nem briefing resolvem, mas a lógica de domínio ou o padrão já usado em outras partes do artefato sugere uma resposta razoável. Marque `[hipótese — a validar]` e explique o raciocínio em uma frase.
   - **Pergunta Aberta** — genuinamente indefinido e relevante o bastante para travar ou distorcer a implementação se ignorado. Vai para a lista de Perguntas Abertas da US (mesma lista do Passo 6, não uma lista separada), com dono sugerido.

Não gere edge case por gerar. O critério de relevância é: **se esse cenário acontecer em produção sem tratamento definido, o comportamento resultante seria ruim o suficiente para importar?** Se a resposta é não (ex: “o que acontece se o usuário redimensionar a janela para 1px” raramente importa), não registre. Se a resposta é sim mesmo sendo raro (ex: “o que acontece se dois usuários exportarem o mesmo pedido ao mesmo tempo”), registre.

Edge cases marcados como Pergunta Aberta contam para `status_prontidao` da US exatamente como as Perguntas Abertas do Passo 6 — uma US com edge case crítico sem resposta não é `pronta_para_dev`.

---

## Passo 8 — Montar cada Spec: cabeçalho da Spec + detalhamento de cada US

Cada Spec tem duas camadas: um **cabeçalho** com o que é comum ao pacote e, em seguida, uma seção **completa e independente para cada US** dela — com exatamente o mesmo nível de detalhe de uma spec de US isolada.

### Cabeçalho da Spec

```
## SPEC-N — [Nome da Spec]

**Objetivo da Spec:** [uma ou duas frases — o que o desenvolvimento entrega ao construir este pacote]
**US incluídas:** [lista US-N.M — nome]
**Ordem sugerida de implementação:** [US-N.1 → US-N.2 …, com o motivo de qualquer dependência entre elas]
**Regras transversais:** [regras de negócio, estados de tela, limites técnicos e integrações que valem para várias US da Spec — escritas uma vez aqui; as US citam "ver regra transversal" em vez de repetir]
**Dependências externas à Spec:** [outras Specs, itens de `dependencias.md` com ID, decisões pendentes]
**Fora de escopo da Spec:** [o que não entra neste pacote]
**Status da Spec:** pronta_para_dev | bloqueada_por_perguntas_abertas — `pronta_para_dev` só se **todas** as US dela forem `pronta_para_dev`
**Item no board:** [ID/chave | não cadastrado]
```

### Seção de cada US (`### US-N.M — [Nome]`)

**Como** [tipo de usuário] **quero** [ação] **para** [valor/motivo] — no formato padrão de US, extraído do briefing/artefato.

**Referência:** [com protótipo: caminho do arquivo + nome da tela/componente] [sem protótipo: seção do briefing ou fonte da base + `[sem referência visual]`]

**Comportamento detalhado:**
Passo a passo do fluxo, incluindo toda interação, validação e navegação relevante — específico o bastante para orientar implementação, sem decidir arquitetura de código. Separe por sub-fluxo/estado quando a US cobrir mais de um caminho (ex: caminho feliz, caminho de erro).

**Campos e dados:**
| Campo | Tipo | Obrigatório | Validação | Origem do dado |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |

**Estados de tela:** [lista — vazio, carregando, erro, sucesso, parcial, e o que cada um exibe]

**Ações e destino técnico:** [para cada ação do usuário, o endpoint/rota/função associada — real ou hipótese, sempre marcado como tal]

**Regras de negócio aplicáveis:** [herdadas do briefing, citando a seção de origem; as regras que valem para toda a Spec ficam no cabeçalho e aqui só se cita "ver regra transversal"]

**Fora de escopo desta US:** [o que não entra aqui — evita a IA de desenvolvimento expandir escopo sozinha]

**Edge Cases Mapeados:**
| Categoria | Cenário | Como tratar | Status |
|---|---|---|---|
| [ex: Volume] | [ex: lista retorna zero itens] | [o que a tela deve fazer] | Confirmado (fonte) \| Hipótese — a validar \| Pergunta Aberta |

**Critério de aceite (BDD):** todo critério de aceite nasce em formato **Dado / Quando / Então** — nunca uma frase solta. Um bloco por cenário:
- [ ] **Cenário:** [nome curto do cenário]
  **Dado** [pré-condição/contexto observável]
  **Quando** [ação do usuário ou evento do sistema]
  **Então** [resultado esperado, verificável sem interpretação]
- [ ] **Cenário:** [...]
  ...

Inclua pelo menos um cenário cobrindo o edge case mais crítico mapeado no Passo 7, quando houver. "Dado" descreve estado, nunca uma ação; "Quando" é sempre um evento único e disparável; "Então" nunca usa adjetivo sem quantificação (ver Passo 6) — se o resultado esperado não dá para verificar sim/não sem interpretar, o cenário ainda não está pronto.

**Perguntas Abertas desta US:** [geradas no Passo 6 + edge cases do Passo 7 marcados como Pergunta Aberta — objetivas, com dono sugerido]

**Bloco para IA de desenvolvimento:**
```yaml
spec: [SPEC-N — nome da Spec]
user_story: [US-N.M — nome]
objetivo: [uma frase]
tela_referencia: [caminho do protótipo | "nenhuma — sem protótipo (fonte: seção X do briefing)"]
endpoints:
  - acao: [ex: buscar resultado]
    destino: [rota/endpoint — ou "a confirmar"]
    metodo: [GET | POST | PUT | DELETE | a confirmar]
campos:
  - nome: [...]
    tipo: [...]
    obrigatorio: true | false
    validacao: [...]
estados_de_tela: [...]
regras_de_negocio: [...]
edge_cases:
  - categoria: [ex: Concorrência e repetição]
    cenario: [ex: duplo clique no botão Exportar]
    tratamento: [o que deve acontecer]
    status: confirmado | hipotese | pergunta_aberta
fora_de_escopo: [...]
perguntas_abertas: [...]
status_prontidao: pronta_para_dev | bloqueada_por_perguntas_abertas
```

Cada US tem o seu próprio bloco YAML. Para enviar uma Spec inteira a uma IA de desenvolvimento, mande o cabeçalho da Spec + todas as seções de US dela + os blocos YAML correspondentes, na ordem de implementação sugerida.

Mantenha `status_prontidao` honesto: se a US tiver qualquer Pergunta Aberta que impeça o início do desenvolvimento (não apenas um detalhe cosmético), marque `bloqueada_por_perguntas_abertas` — não `pronta_para_dev`.

---

## Passo 9 — Confirmação com o usuário

Apresente todas as Specs e US detalhadas e pergunte:

```
Geradas [N] Specs com [N] US no total. [N] US prontas para dev, [N] bloqueadas por Perguntas Abertas ([N] Specs prontas, [N] bloqueadas). [N] edge cases mapeados no total ([N] confirmados, [N] hipóteses, [N] viraram Pergunta Aberta).
[Se sem protótipo:] Sem protótipo: [N] itens ficaram marcados "sem referência visual".

Você pode:
- Aprovar e eu salvo o arquivo
- Pedir ajuste em qualquer Spec ou US (agrupamento, comportamento, campos, critério de aceite)
- Responder alguma das Perguntas Abertas agora (movo para fato confirmado antes de salvar)
- Apontar algo que eu li errado no protótipo ou no briefing

O que deseja alterar antes de eu salvar?
```

Não salve sem aprovação explícita. Se o usuário responder uma Pergunta Aberta, mova-a da US para "fato confirmado" citando `[confirmado pelo usuário em YYYY-MM-DD]` e reavalie `status_prontidao`.

---

## Passo 10 — Geração do arquivo final

Nome do arquivo: `spec-[slug-da-feature]-[YYYY-MM-DD].md` (um arquivo por feature, contendo uma ou mais Specs)

```markdown
---
tipo: spec
feature: [nome da feature]
briefing-fonte: [caminho do arquivo de briefing funcional usado]
artefato-visual: [caminho do artefato/pasta consultado | não]
gerado-em: [YYYY-MM-DD]
quantidade-specs: [N]
quantidade-us: [N]
specs-prontas-para-dev: [N]
specs-bloqueadas: [N]
us-prontas-para-dev: [N]
us-bloqueadas: [N]
edge-cases-mapeados: [N]
edge-cases-como-pergunta-aberta: [N]
repositorio-consultado: sim | não
board: azure-devops | jira | não
feature-board-id: [ID/chave do item-pai da feature ou "não cadastrado"]
---

# Specs de Desenvolvimento — [Nome da feature]

## Fontes
- Briefing funcional: [caminho]
- Artefato visual: [caminho | sem protótipo — spec derivada do briefing e das demais fontes da base]
- Repositório consultado: [sim/não — se sim, quais trechos]

## SPEC-1 — [Nome da Spec]
[cabeçalho da Spec]

### US-1.1 — [Nome]
[...]

### US-1.2 — [Nome]
[...]

## SPEC-2 — [Nome da Spec]
[...]
```

Antes de salvar, rode `powershell -File scripts/validar-referencias.ps1 -Arquivo <caminho do arquivo>` sobre o conteúdo já escrito. Se apontar algum ID citado que não existe em nenhum guide, corrija antes de prosseguir.

Rode também `powershell -File scripts/lint-yaml-bloco.ps1 -Arquivo <caminho do arquivo> -Esquema create-spec` sobre os "Blocos para IA de desenvolvimento" (um por US) — ele confere sintaxe (bloco fechado, indentação, placeholder de template esquecido) e estrutura (campo obrigatório presente, enum válido em `metodo`/`obrigatorio`/`status`/`status_prontidao`). Corrija qualquer achado de severidade Alta antes de marcar a US como `pronta_para_dev` — um YAML malformado nesse bloco é exatamente o tipo de erro que só aparece depois, quando a IA de desenvolvimento tentar consumi-lo.

Rode também `powershell -File scripts/validar-links-frontmatter.ps1 -Arquivo <caminho do arquivo>` — confere se `briefing-fonte` e `artefato-visual` no frontmatter apontam para algo que realmente existe (`artefato-visual: não` é válido quando não há protótipo) (uma citação de `Repositório/` não é checada, por ser código clonado git-ignored). Corrija antes de prosseguir.

Rode também `powershell -File scripts/validar-bdd.ps1 -Arquivo <caminho do arquivo>` — confere, por US, que todo cenário `- [ ] **Cenário:**` do Critério de Aceite (as seções `### US-N.M` dentro de cada `## SPEC-N`) tem as três linhas `**Dado**`/`**Quando**`/`**Então**` presentes, preenchidas e na ordem certa, e que nenhuma US ficou com a seção de Critério de Aceite sem nenhum cenário dentro. Corrija qualquer achado de severidade Alta antes de marcar a US como `pronta_para_dev` — o sensor confere só a estrutura (linha existe? tem texto?); qualidade do conteúdo (adjetivo vago, "Dado" que na verdade descreve uma ação) continua sendo julgamento da sabatina desta skill ou de `audit-spec`.

Salve em `conhecimento/desenvolvimento/specs/` e atualize `conhecimento/desenvolvimento/specs/index.md` (crie o índice, seguindo o padrão de `conhecimento/desenvolvimento/briefings-funcionais/index.md`, se ainda não existir).

---

## Passo 11 — Cadastrar as Specs no board (opcional — Azure DevOps ou Jira)

Depois que o arquivo estiver salvo, pergunte:

```
Quer que eu já cadastre essas Specs no board, ou prefere só o registro em markdown por agora?
Se sim: o time usa Azure DevOps ou Jira?
```

Só escreva no board via MCP após confirmação explícita — nunca crie item sem esse aceite direto. Se o usuário preferir só o markdown, deixe isso explícito no frontmatter (`board: não`) e encerre aqui.

**Ferramenta sem MCP conectado nesta sessão:** se a ferramenta escolhida não tiver MCP disponível (ou for outra, como Linear ou Trello), não tente escrever. Avise e ofereça o texto de cada item (título, descrição, critérios de aceite) pronto para colar manualmente, mantendo `board: não`. Descubra os nomes exatos das ferramentas do MCP na própria sessão (ex: via busca de ferramentas) — não presuma nomes. O servidor do Azure DevOps vem configurado em `.mcp.json`; o do Jira (Atlassian) precisa estar conectado pelo time.

**Regra de mapeamento (vale nas duas ferramentas):** **cada Spec vira um item do tipo User Story no board, mesmo tendo tamanho de feature.** As US internas (`US-N.M`) **não** viram itens próprios: continuam detalhadas no markdown e entram no item da Spec como lista (na descrição) e como critérios de aceite consolidados. O item-pai da Spec é a feature.

| Conceito | Azure DevOps | Jira |
|---|---|---|
| Spec | `User Story` | `Story` |
| Feature (pai da Spec) | `Feature` (hierarquia Epic → Feature → User Story, mesma taxonomia de `define-deliverables`) | O Jira não tem "Feature" nativo: **pergunte** qual tipo o time usa acima de Story para a feature (em geral `Epic`; em instâncias customizadas, `Initiative`/`Feature`). Nunca assuma. |
| Critério de aceite | Campo de critério de aceite do item | Sem campo nativo: seção "Critérios de aceite" na descrição, ou o campo customizado do time, se existir (pergunte) |
| Sinal de bloqueio | Tag `Bloqueada` | Label `Bloqueada` |
| Comentário | Comentário do work item | Comentário da issue |

### 11.1 — Localizar ou criar o item-pai da feature

Antes de criar qualquer Spec:

1. Consulte o board (Azure DevOps: consulta WIQL/backlog; Jira: busca JQL) pelo item correspondente a esta feature — busque por nome exato e por sinônimos (confira `glossario.md`), e pelo Epic indicado no briefing funcional ou no backlog já existente (`conhecimento/planejamento/backlogs/`), se houver.
2. **Se já existir:** use o ID/chave encontrado como pai — não crie uma duplicata. Confirme com o usuário se houver mais de um resultado plausível ("encontrei 2 itens parecidos: [ID] e [ID] — qual é o pai correto?").
3. **Se não existir:** avise o usuário antes de criar —
   ```
   Não encontrei um item já cadastrado para a feature [nome]. Vou criar "[nome]" como [Feature | Epic | tipo escolhido] pai das Specs — confirma?
   ```
   Após confirmação, crie o item com nome igual ao nome da feature usado no briefing, vinculado ao nível superior correspondente se ele já existir e for identificável (mesma lógica de busca do item 1); se nenhum for identificável, crie sem pai e sinalize ao usuário como pendência ("item criado sem pai — vincule manualmente quando existir").

### 11.2 — Criar um item por Spec

Para cada Spec do arquivo, crie um item do tipo da tabela acima, vinculado ao item-pai do 11.1, com:

- **Título:** nome da Spec
- **Descrição:** objetivo da Spec + a lista das US incluídas (nome e história "Como... quero... para...") + a ordem sugerida de implementação + link/caminho do arquivo salvo no Passo 10, para rastreabilidade até a spec completa (o board não precisa reproduzir a spec inteira — a fonte de verdade continua o markdown)
- **Critério de aceite:** os cenários Dado/Quando/Então de todas as US da Spec, agrupados por US
- **Tag/label:** `Bloqueada` se a **Spec** estiver `bloqueada_por_perguntas_abertas`; nenhuma extra se `pronta_para_dev`
- Se a Spec estiver bloqueada, inclua as Perguntas Abertas das US dela como comentário do item, não só no markdown — quem for olhar o board precisa ver o motivo do bloqueio sem precisar abrir o arquivo

Não crie Task, Subtask nem estimativa nesta etapa — esta skill detalha a Spec e suas US (critério de aceite e especificação detalhada), mas a quebra em Tasks e a estimativa ficam para o planejamento do time, fora desta skill.

### 11.3 — Atualizar o arquivo com os IDs reais

Depois de criar os itens, edite o arquivo salvo no Passo 10: preencha o campo **Item no board** do cabeçalho de cada Spec com o ID/chave criado, registre o item-pai, e atualize o frontmatter (`board: azure-devops | jira`, `feature-board-id`). Atualize também `conhecimento/desenvolvimento/specs/index.md` com a mesma informação, se a tabela do índice tiver coluna para isso.

---

## Diretrizes de comportamento

- **O protótipo é opcional; o briefing não.** Nunca gere Spec sem um briefing funcional de base. Se não existir, oriente o usuário a rodar `intent` primeiro — sem isso, a skill fica adivinhando o "porquê", e o resultado tende a formalizar suposições como se fossem decisão.
- **Sem protótipo, não invente o visual.** Todo comportamento sem referência visual leva a marca `[sem referência visual]` e toda lacuna que um design resolveria vira Pergunta Aberta ou hipótese rastreada — nunca é preenchida com "o que faria sentido".
- **Specs agrupam, US detalham.** Agrupar várias US numa Spec nunca é motivo para reduzir o detalhamento: toda US dentro da Spec leva comportamento, campos, estados, edge cases, critério BDD, Perguntas Abertas e bloco YAML completos. Regra transversal escrita uma vez no cabeçalho da Spec não dispensa a US de citá-la.
- **Releia o artefato agora, não confie em memória de conversa** (quando houver protótipo). Artefatos mudam entre versões; sempre extraia do arquivo atual no momento da execução.
- **Nunca preencha uma lacuna do artefato com uma suposição de design.** Se o protótipo não implementou um estado/comportamento, isso é lacuna a sabatinar — não é a skill que decide o que "faria sentido" visualmente.
- **A sabatina do Passo 6 não é opcional nem pode ser superficial.** Rode a checklist completa em toda US, mesmo em US que pareçam óbvias — é aqui que a skill evita entregar uma spec "pronta" que na prática trava o desenvolvimento na primeira dúvida.
- **O mapeamento de edge cases do Passo 7 também não é opcional.** Percorra as sete categorias em toda US — mesmo quando a conclusão for "não se aplica", essa conclusão precisa ser deliberada, não uma omissão por preguiça. Edge case sem tratamento definido tratado como fato "óbvio" é exatamente o tipo de suposição que gera retrabalho na implementação.
- **Edge case tratado como fato precisa da mesma rastreabilidade que qualquer regra.** `Confirmado` sem citar a fonte, ou `Hipótese` sem explicar o raciocínio de domínio por trás, não deveriam existir na spec.
- **`status_prontidao: pronta_para_dev` é uma promessa — e a Spec só é `pronta_para_dev` se todas as US dela forem.** Só marque assim se de fato não sobrar nenhuma Pergunta Aberta bloqueante — incluindo as que vieram de edge cases do Passo 7 — do contrário o rótulo engana quem for repassar a US para a IA de desenvolvimento.
- **Nunca leia `Repositório/` sem autorização explícita para a dúvida específica daquela US.** Mesma regra de `intent`: só leitura, nunca edição, e sempre com pergunta anterior.
- **Distinga achado técnico de decisão de produto.** Um endpoint existente é fato; usar aquele endpoint tal como está numa US pode ainda ser uma decisão em aberto.
- **Todo campo/comportamento/ação já fora de escopo não aparece em "Comportamento detalhado" nem no bloco YAML** — só em "Fora de escopo desta US", uma vez.
- **Critério de aceite é sempre BDD (Dado/Quando/Então), nunca frase solta.** Uma US sem nenhum cenário Dado/Quando/Então não está com o critério de aceite pronto — reescreva antes de considerar a US fechada.
- **Nunca crie o arquivo sem aprovação explícita do rascunho completo.**
- **Nunca cadastre no board (Azure DevOps ou Jira) sem confirmação explícita do Passo 11** — o markdown salvo no Passo 10 é o combinado; escrever no board é uma ação separada que precisa de aceite direto. Pergunte qual ferramenta o time usa; nunca presuma Azure DevOps.
- **Nunca duplique o item-pai da feature.** Busque antes de criar; se houver ambiguidade entre itens existentes, pergunte ao usuário em vez de escolher sozinho ou criar um novo por segurança. No Jira, não assuma qual tipo de issue faz o papel de "Feature" — pergunte.
- **Uma Spec = um item User Story no board.** As US internas não viram itens separados; entram na descrição e nos critérios de aceite do item da Spec.
- **Bloqueio visível no board, não só no markdown.** Toda Spec criada como `Bloqueada` precisa ter as Perguntas Abertas das US dela registradas como comentário no próprio item — quem olha o board não deve precisar abrir o arquivo para saber por que está travada.

---

## Orientação ao final

Após salvar a especificação, informe o usuário:

> **Specs salvas.**
> - Arquivo: `conhecimento/desenvolvimento/specs/[nome-do-arquivo].md`
> - Feature: [nome] · Briefing-fonte: [caminho] · Artefato: [caminho | sem protótipo]
> - [N] Specs ([N] prontas, [N] bloqueadas) com [N] US no total — [N] US prontas para desenvolvimento, [N] bloqueadas por Perguntas Abertas
> - [N] edge cases mapeados no total — [N] confirmados, [N] hipóteses a validar, [N] viraram Pergunta Aberta
> - [N] Perguntas Abertas no total (sabatina + edge cases) — [liste os donos naturais identificados, se houver]
> - Repositório consultado: [sim/não]
> - Cadastrado no board: [azure-devops/jira/não/parcial] · [N] itens User Story criados (um por Spec) · Item-pai da feature: [ID/chave + nome, ou "não cadastrado"]
>
> **Próximo passo sugerido:** rodar `audit-spec` neste arquivo para auditar o que esta skill não tem como foco cobrir a fundo (atributos não-funcionais, referências de design/Figma, terminologia, testabilidade do critério de aceite) antes de considerar as US realmente prontas; depois, resolver as Perguntas Abertas das US bloqueadas antes de repassá-las para desenvolvimento — as Specs `pronta_para_dev` podem ser enviadas, uma por vez, para uma IA de desenvolvimento junto com os blocos YAML das US dela. Se ainda não foi feito, rode o Passo 11 desta skill para cadastrar as Specs no board (Azure DevOps ou Jira).
