---
name: audit-spec
description: Audita a qualidade e a completude de uma especificação de desenvolvimento (Specs com suas US) já gerada pela skill `create-spec`, verificando cobertura em categorias que a geração original não teve como objetivo cobrir a fundo — atributos não-funcionais (performance, segurança, observabilidade, compliance), referências de design/Figma por tela e estado, terminologia consistente com o glossário, testabilidade do critério de aceite, adjetivos vagos sem quantificação e tradeoffs não registrados. Gera perguntas de esclarecimento só para as lacunas de alto impacto — sem cota fixa de quantidade, feitas uma de cada vez, nunca em lote, até esgotar as de alto impacto —, e ao final aplica cada resposta como fato confirmado na spec e sinaliza como Pergunta Aberta o que ficou crítico e sem resposta. Acione quando o usuário invocar /audit-spec ou pedir para sabatinar, auditar, revisar a qualidade de, ou checar a prontidão real de uma Spec já gerada por `create-spec` antes de mandar para desenvolvimento.
---

# audit-spec

Esta skill responde uma pergunta específica: **dada uma spec de US já gerada por `create-spec`, o que nela ainda está vago, ausente ou sem base testável — e, das lacunas que sobram, quais realmente valem uma pergunta ao usuário antes de considerar a US pronta?**

Não gera a spec do zero — audita uma spec que já existe, aponta o que falta, faz perguntas cirúrgicas só sobre o que for de **alto impacto** (sem cota fixa de quantidade — a linha de corte é impacto, não número), uma de cada vez, nunca em lote, e devolve a spec atualizada com o que foi respondido incorporado como fato e o que ficou sem resposta sinalizado como Pergunta Aberta.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e objetivo.

---

## Princípio fundamental

Esta skill roda **depois** de `create-spec`, nunca no lugar dela. Ela não decide:

- **Como quebrar a feature em US** — isso já está feito; esta skill audita as US como estão, não propõe reorganizá-las.
- **O comportamento funcional já coberto** (estados de tela, ações, campos, edge cases de volume/concorrência/navegação) — `create-spec` já cobre isso a fundo nos Passos 6 e 7 dela. Reabrir esse terreno aqui seria duplicar trabalho, não auditar.

O que ela faz, de fato, é olhar para categorias que **não são o foco central** de `create-spec` — atributos de qualidade não-funcionais, rastreabilidade de design, terminologia, testabilidade do critério de aceite, tradeoffs e ambiguidade de linguagem — e tratar cada uma com o mesmo rigor de rastreabilidade do resto da base: **Presente** (cita a fonte), **Parcial** (existe algo, mas incompleto — diz o que falta), ou **Ausente** (nada na spec resolve isso).

Toda categoria Parcial ou Ausente é candidata a pergunta — mas **nem toda candidata vira pergunta**. Uma pergunta só é feita se a resposta mudaria de fato arquitetura, modelagem de dado, quebra de tarefa, desenho de teste, comportamento de UX, prontidão operacional ou validação de compliance. O resto fica registrado como lacuna conhecida, não como pergunta — sabatinar não é interrogar por interrogar.

---

## Gatilho

Acionada quando o usuário invoca `/audit-spec` ou pede para: sabatinar, auditar, revisar a qualidade de, ou checar a prontidão real de uma Spec — normalmente depois que `create-spec` já gerou o arquivo, e antes de repassar as US para desenvolvimento (ou para o board, via `create-spec` Passo 11).

---

## Passo 1 — Identificar o alvo

Pergunte, se não vier claro no pedido (no máximo 1 rodada):

1. **Qual arquivo de Spec?** — caminho em `conhecimento/desenvolvimento/specs/`, ou nome da feature (procure em `conhecimento/desenvolvimento/specs/index.md` antes de perguntar de novo)
2. **Todas as US do arquivo, ou só algumas específicas?** — padrão: todas, exceto se o usuário apontar US específicas (ex: "só a US-1.3 e a US-2.1") ou uma Spec inteira (ex: "só a SPEC-2")

Não prossiga sem o arquivo identificado — esta skill audita uma spec que já existe, não tem o que fazer sem ela.

---

## Passo 2 — Ler a spec por completo (e as fontes que ela já cita)

Leia o arquivo de especificação indicado, sem resumir por cima. O arquivo agrupa as US em **Specs** (`## SPEC-N`, cada uma com um cabeçalho de regras transversais, ordem de implementação e dependências, seguido das seções `### US-N.M`); a auditoria é feita **por US**, e o cabeçalho da Spec é lido como contexto herdado por todas as US dela (uma regra transversal presente no cabeçalho conta como "Presente" para a US que a cita). Leia também o frontmatter (`status_prontidao` de cada US e o campo `artefato-visual`, se já houve sabatina anterior) e as seções já existentes de Perguntas Abertas e Edge Cases Mapeados de cada US (Passos 6 e 7 de `create-spec`).

Não releia o protótipo (quando houver) nem o briefing inteiros de novo — eles já foram processados por `create-spec`. Consulte-os pontualmente só quando precisar checar uma referência específica já citada na spec (ex: conferir se um link/nó de Figma citado existe, ou se um comportamento citado como "confirmado no artefato" realmente aparece lá).

---

## Passo 3 — Checklist de cobertura por categoria, por US

Para **cada** US do escopo definido no Passo 1, avalie as categorias abaixo. Marque **Presente** (cite onde), **Parcial** (diga o que falta) ou **Ausente**. Categorias já bem cobertas por `create-spec` (comportamento, campos, estados de tela, ações e destino técnico, edge cases de volume/concorrência/navegação) não precisam ser reauditadas do zero — olhe para elas só na medida em que faltarem os recortes específicos listados abaixo que `create-spec` não tem como objetivo cobrir.

| # | Categoria | O que checar especificamente (além do que `create-spec` já cobre) |
|---|---|---|
| 1 | **Escopo funcional e comportamento** | Critério de sucesso da US está declarado de forma verificável (não só "a tela funciona")? Diferenciação de papéis/personas explícita quando a US atende mais de um perfil de usuário? |
| 2 | **Domínio e modelo de dados** | Regras de unicidade/identidade dos dados-chave (ex: o que identifica um registro de forma única) estão explícitas? Volume/escala assumido está declarado (não só herdado do teto técnico já mapeado)? |
| 3 | **Interação e fluxo de UX** | Notas de acessibilidade (leitor de tela, navegação por teclado, contraste) ou de localização (idioma, formato de data/moeda) existem quando relevante? |
| 4 | **Referências de design/artefato** | Toda tela, componente ou estado citado (inclusive vazio/erro/carregando) tem uma referência rastreável — link/nó de Figma, ou caminho exato no protótipo — para implementação fiel? Aponte especificamente qual estado ficou sem referência, não a US inteira. Se a spec foi gerada **sem protótipo** (`artefato-visual: não`), a ausência de referência visual é esperada e já está marcada como `[sem referência visual]`: não repita a lacuna em cada US — trate-a uma vez, por Spec, e só eleve a Alto quando o estado/tela sem desenho puder distorcer a implementação. |
| 5 | **Atributos de qualidade não-funcionais** | Performance (latência/throughput esperados), escalabilidade, confiabilidade/disponibilidade, observabilidade (o que logar/medir/rastrear), segurança e privacidade (autenticação/autorização, proteção de dado), compliance/regulatório — algum desses foi sequer mencionado? |
| 6 | **Integração e dependências externas** | Modos de falha de cada serviço/API externo citado estão descritos (além do endpoint em si)? Formato de import/export de dado, se houver, está definido? Existe alguma suposição de versionamento de contrato/protocolo não declarada? |
| 7 | **Falhas específicas não cobertas pelos edge cases de `create-spec`** | Rate limiting/throttling da API consumida — existe suposição ou é ausente? Resolução de conflito em edição concorrente do mesmo registro (para além do "duplo clique" já mapeado) — tem regra definida? |
| 8 | **Restrições e tradeoffs** | Restrições técnicas explícitas (linguagem, storage, hospedagem) quando relevante à US. Algum tradeoff ou alternativa rejeitada foi mencionado, ou tudo está apresentado como se fosse a única opção possível? |
| 9 | **Terminologia e consistência** | Os termos usados na US batem com `conhecimento/produto/glossario.md`? Sinônimos ou termos já marcados como descontinuados no glossário aparecem na spec? |
| 10 | **Sinais de conclusão** | Cada item do Critério de Aceite é de fato testável (uma pessoa consegue verificar sim/não sem interpretação)? Existe algum indicador mensurável de Definition of Done, ou só descrição qualitativa? |
| 11 | **Diversos / placeholders** | Existem marcadores `TODO`, `[a confirmar]` sem dono, ou decisão citada como pendente sem estar em Perguntas Abertas? Existem adjetivos vagos sem quantificação (ex: "resposta rápida", "interface intuitiva", "robusto") que deveriam virar critério objetivo? |

Monte uma tabela de cobertura por US antes de seguir — é a base do Passo 4.

---

## Passo 4 — Filtrar candidatas e classificar impacto

Para cada célula **Parcial** ou **Ausente** do Passo 3, decida primeiro se vira candidata a pergunta. **Não vira** quando:

- É preferência estilística trivial, ou já foi respondida em algum lugar da spec/briefing (não repita pergunta já resolvida);
- É uma Pergunta Aberta que **já existe** na US (gerada por `create-spec`) — não duplique; se a categoria bater com uma pergunta já registrada, ela concorre na fila do Passo 5 pela mesma vaga, não gera uma segunda pergunta sobre o mesmo ponto.

Para cada candidata que sobrar, classifique o **impacto** em um dos três níveis — é essa classificação, e só ela, que decide se a pergunta é feita:

| Impacto | Critério |
|---|---|
| **Alto** | A resposta muda arquitetura, modelagem de dado, postura de segurança/compliance, ou destrava uma US inteira que hoje está `bloqueada_por_perguntas_abertas`. Também é Alto quando a ausência, se ignorada, provavelmente exige retrabalho depois (ex: critério de aceite não testável, referência de design ausente num estado crítico do fluxo). |
| **Médio** | Afeta qualidade ou robustez, mas não muda o comportamento observável nem trava a implementação — dá para seguir com uma hipótese razoável documentada sem grande risco. |
| **Baixo** | É mais apropriado adiar para a fase de planejamento/refinamento técnico (ex: escolha de biblioteca, detalhe de infraestrutura, terminologia cosmética) — registre como lacuna conhecida, nunca como pergunta. |

Só candidatas **Alto** avançam para a fila de perguntas do Passo 5. Médio e Baixo nunca viram pergunta nesta skill, independente de quantas sobrarem — ficam registrados como lacuna conhecida no relatório final (Passo 9), não porque uma cota estourou, mas porque o impacto não justifica interromper o usuário.

---

## Passo 5 — Montar a fila de perguntas de alto impacto (sem limite de quantidade)

A fila é **só** o conjunto de candidatas classificadas como Alto no Passo 4 — não existe número máximo de perguntas: a linha de corte é o impacto, não a quantidade. Se houver 2 candidatas Alto, pergunte 2; se houver 12, pergunte 12 — o volume nunca é motivo para deixar de perguntar algo que muda arquitetura, dado, segurança ou destrava uma US bloqueada.

Ordene a fila para perguntar primeiro o que tem maior **incerteza** (nada na spec/briefing/artefato aponta sequer uma direção provável) e para **alternar entre categorias diferentes** em vez de esgotar todas as perguntas de uma mesma categoria antes de passar para outra — assim, se a sessão for interrompida no meio, o que já foi perguntado cobre o leque mais amplo possível de riscos, não só um canto dele.

Cada pergunta da fila final precisa já nascer em um destes dois formatos, sem exceção:
- **Múltipla escolha**, 2 a 5 opções mutuamente exclusivas; ou
- **Resposta curta**, com a pergunta explicitamente dizendo *"Responda em até 5 palavras"*.

Nunca deixe uma pergunta aberta/dissertativa na fila — se a dúvida não cabe em nenhum dos dois formatos, ela provavelmente é grande demais para esta skill (pode ser matéria de uma reunião ou de `intent`, não de uma pergunta cirúrgica de sabatina).

---

## Passo 6 — Fazer as perguntas, uma de cada vez

Faça as perguntas da fila **uma por vez, nunca em lote** — depois de cada resposta, reavalie o restante da fila: uma resposta pode esclarecer, invalidar ou tornar redundante outra pergunta ainda não feita, reduzindo a fila antes do previsto. **Pare quando a fila de perguntas de alto impacto esvaziar** — não existe número-alvo a bater nem cota a preencher; se sobrar só uma de alto impacto depois das reavaliações, faça uma só, e se sobrarem muitas, faça todas.

Use múltipla escolha (com as opções já definidas no Passo 5) sempre que possível; reserve resposta curta só para o que genuinamente não se encaixa em opções fechadas. Identifique, em cada pergunta, a qual US e categoria ela se refere.

---

## Passo 7 — Aplicar as respostas como fato confirmado

Para cada pergunta respondida, incorpore a resposta na seção correta da US, citando `[confirmado pelo usuário em YYYY-MM-DD — sabatina de qualidade]`:

| Categoria da pergunta | Onde a resposta entra na US |
|---|---|
| Domínio e dados | Campos e dados / Comportamento detalhado |
| Referências de design | **Referência** da US (adicionar o link/nó faltante; se havia `[sem referência visual]`, remover a marca) |
| Não-funcionais | Nova subseção **Atributos de Qualidade** na US (criar se não existir) |
| Integração externa | Ações e destino técnico |
| Falhas/conflito | Edge Cases Mapeados (adicionar linha) |
| Terminologia | Ajustar o termo ao longo da US, citando o glossário |
| Sinais de conclusão | Critério de Aceite (reescrever o item para ficar testável) |
| Restrições/tradeoffs | Fora de escopo desta US, ou nova nota em Restrições, conforme o caso |

Atualize também o bloco YAML da US (novo campo `atributos_qualidade` quando aplicável, e os campos já existentes que a resposta esclareceu).

---

## Passo 8 — Sinalizar o que ficou crítico e sem resposta

Duas situações geram sinalização, não silêncio:

1. **Pergunta de alto impacto que ficou na fila sem ser feita** (ex: o usuário interrompeu a sabatina antes do fim da fila) — vira uma nova linha em Perguntas Abertas da US, com a categoria indicada e dono sugerido, mesmo sem ter sido perguntada.
2. **Pergunta feita mas sem resposta conclusiva** (usuário pulou, respondeu "não sei", ou a resposta não resolveu o suficiente) — permanece ou vira Perguntas Abertas, sem ficar registrada como fato.

Reavalie `status_prontidao` de cada US afetada: se a lacuna sinalizada é bloqueante, a US não pode ficar `pronta_para_dev`, mesmo que já estivesse assim antes da sabatina — uma sabatina pode **piorar** o status de uma US ao expor uma lacuna que passou despercebida, e isso é o comportamento certo, não um erro. Recalcule também o **Status da Spec** no cabeçalho: a Spec só é `pronta_para_dev` se todas as US dela forem.

---

## Passo 9 — Apresentar o resultado e confirmar antes de salvar

Apresente, por US:

```
Sabatina de qualidade — [nome do arquivo]

US-N — [nome]
Cobertura antes: [resumo Presente/Parcial/Ausente por categoria]
Perguntas feitas: [N] — [lista resposta aplicada]
Lacunas conhecidas não perguntadas (baixo impacto ou fora do escopo desta sabatina): [lista]
status_prontidao: [antes] → [depois]

Confirma as atualizações antes de eu salvar no arquivo?
```

Não edite o arquivo sem essa confirmação — mesma regra de toda skill desta base que grava conhecimento.

---

## Passo 10 — Salvar e atualizar o índice

Edite o arquivo de Spec in loco (não cria um novo arquivo — é a mesma spec, atualizada). Atualize o frontmatter com:

```
sabatinada-em: YYYY-MM-DD
sabatina-perguntas-feitas: [N]
sabatina-perguntas-pendentes: [N]
```

Atualize `conhecimento/desenvolvimento/specs/index.md` se a tabela do índice tiver coluna para status de sabatina; se não tiver, sugira adicionar uma.

---

## Diretrizes de comportamento

- **Nunca reaudite o que `create-spec` já cobre a fundo.** Duplicar a sabatina/edge-cases dela é desperdício — esta skill existe para o que sobra: NFR, design, terminologia, testabilidade, tradeoffs, ambiguidade de linguagem.
- **Nunca pergunte em lote.** Uma pergunta de cada vez, reavaliando a fila a cada resposta — é isso que evita perguntar algo que a resposta anterior já resolveu.
- **A linha de corte é impacto, não quantidade.** Não existe número máximo nem mínimo de perguntas — pergunte tudo que for classificado como Alto impacto no Passo 4, seja 1 pergunta ou sejam 15, e pare exatamente aí.
- **Nunca transforme uma lacuna de Médio ou Baixo impacto em pergunta.** Mesmo que a fila de Alto impacto esteja vazia ou pequena, não "complete" com perguntas de menor valor — sobrar poucas perguntas é sinal de spec madura, não motivo para forçar mais.
- **Toda pergunta nasce fechada** (múltipla escolha ou resposta curta ≤ 5 palavras). Se a dúvida não cabe nesse formato, ela não é desta skill.
- **Resposta aplicada é fato, com data e rastreio — nunca reescreva a US como se a informação sempre tivesse estado lá.**
- **Lacuna não perguntada nunca desaparece em silêncio.** Toda categoria Parcial/Ausente que não virou pergunta é listada no relatório final, mesmo que a decisão tenha sido "não vale perguntar".
- **Sabatina pode piorar `status_prontidao`, e isso é esperado.** Expor uma lacuna real que mudava uma US de `pronta_para_dev` para `bloqueada_por_perguntas_abertas` é o resultado correto da skill, não uma falha dela.
- **Nunca edite o arquivo sem aprovação explícita do Passo 9.**

---

## Orientação ao final

Após salvar, informe o usuário:

> **Sabatina de qualidade concluída.**
> - Arquivo: `conhecimento/desenvolvimento/specs/[nome-do-arquivo].md`
> - US auditadas: [N] · Perguntas de alto impacto feitas: [N] · Perguntas aplicadas como fato: [N]
> - `status_prontidao` alterado em: [lista de US que mudaram de status, se houver]
> - Lacunas conhecidas registradas sem pergunta (baixo impacto): [N]
>
> **Próximo passo sugerido:** resolver as Perguntas Abertas críticas antes de repassar as US ainda `bloqueada_por_perguntas_abertas`; as US `pronta_para_dev` já refletem a sabatina e podem seguir para desenvolvimento ou para o board (`create-spec`, Passo 11).
