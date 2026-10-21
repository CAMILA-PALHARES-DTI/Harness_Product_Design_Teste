---
name: insert-knowledge
description: Absorve conteúdo bruto sobre o projeto (atas e resumos de reuniões, ações pendentes, briefings, anotações, descrições de produto, informações sobre stakeholders, decisões, dependências e riscos), identifica o que é relevante para cada guide da base de conhecimento e gera os blocos formatados para o usuário confirmar antes de salvar. Também detecta e registra decisões formais, dependências, riscos e fluxos/jornadas, e gera a ata da reunião e as ações pendentes. Acione sempre que o usuário enviar qualquer conteúdo para ser absorvido pela base ou invocar /insert-knowledge.
---

# insert-knowledge

> **Skill da Camada de Agentes**
> Esta skill é chamada quando o usuário envia um texto, arquivo ou anotação com informações sobre o projeto que precisam ser absorvidas e registradas nos guides de conhecimento. Ela lê o conteúdo, identifica o que é relevante para cada guide e gera os blocos formatados para o usuário confirmar antes de salvar.

---

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e objetivo.

**Rótulos que os sensores leem:** títulos de seção, rótulos em linha (`**Definição:**`, `**Status:**`), nomes de coluna dos índices dos guides (`Título`/`Title`, `Objetivo`/`Goal`, `Status`) e valores de status que constam em `scripts/rotulos.txt` são escritos com o texto da coluna do idioma configurado (português ou inglês), exatamente como no dicionário e sem inventar variações — os sensores só reconhecem essas variantes. Os guides já existentes mantêm o idioma e os rótulos que já usam; rótulos que o `CLAUDE.md` mantém fixos (IDs, marcadores) não mudam de idioma.

---

## Quando usar esta skill

Use esta skill sempre que o usuário enviar:

- Anotações ou resumos de reuniões com o cliente
- Documentos de briefing ou onboarding do projeto
- Descrições informais sobre o produto, seus módulos ou regras
- Informações sobre stakeholders
- Textos com termos ou conceitos específicos do cliente
- Qualquer conteúdo bruto que contenha conhecimento relevante sobre o projeto

---

## O que esta skill não faz diretamente

| Guide | Comportamento |
|---|---|
| `user-stories.md` | Não alimentado aqui. US tem estrutura rígida e fluxo de aprovação próprio — use a skill `create-spec`. |

Todos os demais guides — incluindo `conhecimento/planejamento/decisoes-aprovadas.md` e `conhecimento/planejamento/dependencias.md` — são alimentados diretamente por esta skill, sem chamar outra skill.

---

## Passo a passo

### Passo 1 — Leitura e extração

Leia o conteúdo enviado na íntegra. Identifique e classifique cada informação relevante segundo os guides que ela deve alimentar:

| Guide | O que buscar no conteúdo |
|---|---|
| `conhecimento/produto/contexto-de-negocio.md` | Descrições do produto, regras de funcionamento, restrições, integrações, contexto de negócio |
| `conhecimento/produto/mapa-stakeholders.md` | Nomes, cargos, papéis, estilos de comunicação, características de pessoas do cliente |
| `conhecimento/cliente/reunioes/` (ata + `acoes-pendentes.md`) | Pautas, participantes, alinhamentos, encaminhamentos, datas, ações com responsável e prazo — ver checagem 6 do Passo 2 |
| `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md` | Descrições de fluxos, etapas de processos, jornadas narradas — ver checagem 7 do Passo 2 |
| `conhecimento/produto/glossario.md` | Termos, siglas ou conceitos específicos do cliente ou do produto |
| `conhecimento/produto/dores-de-processo.md` | Menções a fricções, problemas operacionais, ineficiências, trabalho manual excessivo, riscos de processo, reclamações, limitações do produto ou situações que o cliente quer melhorar |
| `conhecimento/planejamento/decisoes-aprovadas.md` | Decisões formais — ver critério de detecção no Passo 2 |
| `conhecimento/planejamento/dependencias.md` | Dependências, bloqueios ou condicionantes — ver critério de detecção no Passo 2 |
| `conhecimento/planejamento/riscos.md` | Riscos — eventos incertos com potencial de impacto futuro — ver critério de detecção no Passo 2 |

---

### Passo 2 — Decisões, dependências, riscos, dores de processo, US, reuniões/ações e fluxos

Antes de gerar qualquer bloco, rode obrigatoriamente as sete checagens abaixo sobre o conteúdo recebido. Nunca pule as checagens de decisão, dependência e risco silenciosamente — mesmo que o conteúdo pareça não conter nenhuma delas, a checagem deve ser feita e só então omitida da resposta se não encontrar nada.

**1. Decisões**

Avalie se o conteúdo descreve uma decisão formal:

- **Sinais fortes — registrar:** verbos/expressões de fechamento — "decidimos", "ficou definido", "ficou acordado", "optamos por", "foi aprovado", "descartamos [X] em favor de [Y]", "seguimos com [X]" — combinados com uma alternativa escolhida entre opções (explícitas ou implícitas) por alguém com autoridade (PO, cliente, arquitetura, liderança).
- **Não conta como decisão:** tarefas/ações pontuais (ex: "fulano vai enviar X até sexta" — isso é ação pendente — registrada pela checagem 6 em `conhecimento/cliente/reunioes/acoes-pendentes.md`, não como decisão); opiniões ou hipóteses sem aprovação explícita; fatos de negócio já existentes sendo apenas descritos (isso é `contexto-de-negocio.md`).
- **Confirmação ou esclarecimento de algo que já funciona assim.** Mesmo quando o texto apresenta uma "alternativa considerada" e usa linguagem de fechamento ("ficou confirmado", "foi esclarecido"), isso não é decisão se não houver uma mudança real de rumo — é a explicação de um mecanismo, regra ou equivalência que já existia. Dois padrões comuns:
  - **Confirmação de fato/mecanismo existente** → pertence a `contexto-de-negocio.md` como regra do produto (ex: "esse fluxo fiscal já funciona assim e não gera problema X").
  - **Equivalência ou definição de termos** (ex: "o termo A do sistema X é o mesmo conceito que o termo B do sistema Y") → pertence a `glossario.md`, não a uma decisão.
  - **Teste rápido:** reescreva a "decisão" como uma frase no presente ("X já funciona assim", "X e Y são a mesma coisa"). Se nada se perde na reescrita, não é decisão — é fato ou termo. Se a reescrita apagar uma escolha real entre caminhos distintos que o produto poderia ter seguido, é decisão de fato.
- Em caso de dúvida, só trate como decisão se houver escolha explícita entre alternativas reais — caso contrário, não gere bloco e liste a dúvida no Passo 6.

Se identificar uma decisão, extraia os campos abaixo. Se algum campo não estiver disponível, marque `[a confirmar]` — nunca registre uma decisão sem aprovador identificado ou `[a confirmar]`.

| Campo | O que buscar |
|---|---|
| **Título curto** | Nome objetivo da decisão — máximo 8 palavras |
| **Produto** | A qual produto(s) a decisão se aplica |
| **Área** | Tema ou módulo afetado (ex: Arquitetura, Faturamento, Cadastro) |
| **Aprovado por** | Quem tomou ou homologou a decisão |
| **Origem** | Onde a decisão foi tomada (reunião, alinhamento, documento) |
| **Contexto** | Por que a decisão precisou ser tomada |
| **Decisão** | O que foi decidido, de forma clara e objetiva — deve ser possível ler só esse campo e entender exatamente o que foi decidido |
| **Alternativas consideradas** | O que mais estava na mesa e por que foi descartado — se não houver info, `[a confirmar]`, nunca invente |
| **Impacto** | O que muda a partir dessa decisão |

Não calcule o próximo ID de cabeça — rode `powershell -File scripts/validar-sequencia-id.ps1 -ProximoId -Prefixo D` e use o valor devolvido (comece em `D001` se o script indicar que o guide está vazio). Gere dois fragmentos:

```
| D00X | [título curto] | [Produto] | [Área] | Ativa | AAAA-MM-DD |
```

```
### D00X — [Título curto da decisão]

- **Data:** AAAA-MM-DD
- **Status:** Ativa
- **Produto:** [P1, P2 | Todos]
- **Área:** [ex: Arquitetura, Faturamento]
- **Aprovado por:** [nome e cargo — ou "a confirmar"]
- **Origem:** [ex: Alinhamento interno | Reunião AAAA-MM-DD | Documentação técnica]

**Contexto**
[Por que essa decisão precisou ser tomada?]

**Decisão**
[O que foi decidido.]

**Alternativas consideradas**
[O que mais estava na mesa e por que foi descartado. Se não houver info, marcar como "a confirmar".]

**Impacto**
[O que muda a partir dessa decisão.]

**Decisões relacionadas:** [IDs ou "—"]
**Substituída por:** —
```

Vincule a "Decisões relacionadas" a outras decisões do índice quando houver relação clara.

**2. Dependências**

Critério de detecção — abrangente: qualquer menção a sistema, API, time ou serviço externo em relação de dependência ou condicionante com o que está sendo construído. Sinais a buscar: nomes de sistemas/integrações (ERP, CRM, gateway de pagamento, barramento de integração, APIs nomeadas...), condicionais como "somente se", "depende de", "após", "requer", "antes de", "aguardando", "bloqueado por", timeouts/SLAs críticos, e também menções mais soltas a "o time X", "o sistema Y", "precisa do Z" — mesmo sem uma palavra-condicional explícita.

Como o critério é amplo, é esperado gerar entradas com campos `[a confirmar]` (Produto, Responsável, Prazo) quando o conteúdo não deixar claro — isso é aceitável, a qualidade é filtrada na confirmação do usuário, não na extração.

Para cada dependência identificada:
- Leia o índice de `conhecimento/planejamento/dependencias.md` para checar duplicata óbvia por título/sistema já catalogado. Para o ID, não calcule de cabeça — rode `powershell -File scripts/validar-sequencia-id.ps1 -ProximoId -Prefixo DEP` e use o valor devolvido.
- Se já existe entrada equivalente, não gere bloco — liste como "já catalogada" no Passo 4.
- Classifique o tipo: `Interna`, `Externa — cliente` ou `Externa — sistema`.
- Defina status inicial como `Aguardando`, a menos que haja indício claro de bloqueio ativo (`Bloqueando`).
- Se o produto ou outro campo não puder ser determinado, marque `[a confirmar]`.

Gere o bloco no formato de `conhecimento/planejamento/dependencias.md`:

```
### [DEPxxx] — [Título curto da dependência]

- **Data:** AAAA-MM-DD
- **Status:** Bloqueando | Em andamento | Aguardando | Resolvida
- **Tipo:** Interna | Externa — cliente | Externa — sistema
- **Produto:** P1, P2 | Todos
- **Feature / US relacionada:** [nome da feature ou ID da US]
- **Depende de:** [nome do time, sistema, área ou serviço]
- **Responsável pelo acompanhamento:** [nome]
- **Prazo esperado:** AAAA-MM-DD | Indefinido

**Descrição**
[O que precisa acontecer para essa dependência ser resolvida? Qual é o bloqueio ou condicionante?]

**Impacto se não resolvida**
[O que fica travado? Qual o risco para o produto, para a US ou para o time?]

**Histórico**
- AAAA-MM-DD — [atualização de status ou encaminhamento]
```

E a linha correspondente para o índice:

```
| DEPxxx | [Título] | [Tipo] | [Produto] | [Feature/US] | Aguardando | AAAA-MM-DD |
```

**3. Riscos**

Avalie se o conteúdo descreve um risco: um evento **incerto** que ainda não aconteceu, mas que pode acontecer e comprometer prazo, qualidade, operação ou negócio. Ver `conhecimento/planejamento/riscos.md` para a distinção completa entre risco, dependência e dor.

- **Sinais fortes — registrar:** "risco de", "pode acontecer", "existe a chance de", "se isso não for resolvido a tempo", "corremos o risco de", preocupações levantadas sobre algo que ainda não ocorreu, alertas sobre resistência de usuários, prazos apertados, capacidade insuficiente do time, ou dependências não resolvidas que ameaçam uma data.
- **Não conta como risco:** algo que já está acontecendo hoje na operação (isso é dor — `dores-de-processo.md`); um bloqueio concreto e já identificado que precisa ser resolvido para avançar (isso é dependência — `dependencias.md`, embora uma dependência crítica sem prazo definido também possa gerar um risco relacionado de atraso).
- Um risco pode nascer de uma dependência já registrada (ex: "se a integração com o sistema X não estiver pronta a tempo, o go-live atrasa") — nesse caso, gere o risco e vincule-o à dependência de origem em "Dependências relacionadas".

Se identificar um risco, extraia os campos abaixo. Se algum campo não estiver disponível, marque `[a confirmar]`.

| Campo | O que buscar |
|---|---|
| **Título curto** | Nome objetivo do risco — máximo 8 palavras |
| **Tipo** | Técnico, Operacional, Negócio, Prazo/Cronograma, Adoção/Mudança ou Segurança/Compliance |
| **Probabilidade** | Alta, Média ou Baixa — com base em sinais concretos ou ausência deles no conteúdo |
| **Impacto** | Alto, Médio ou Baixo — com base na gravidade descrita ou implícita |
| **Nível de risco** | Combine Probabilidade x Impacto conforme a matriz do guia (Crítico, Alto, Médio, Baixo) |
| **Produto** | A qual produto(s) o risco se aplica |
| **Dono/Responsável** | Quem deveria acompanhar — ou `[a confirmar]` |
| **Descrição** | O que pode acontecer e por que é uma possibilidade real |
| **Sinais de alerta** | O que indicaria que o risco está se materializando — se não houver info, `[a confirmar]` |
| **Plano de mitigação / contingência** | Se mencionado no conteúdo; caso contrário, `[a confirmar]` — nunca invente um plano |

Leia o índice de `conhecimento/planejamento/riscos.md` para checar duplicata óbvia. Para o ID, não calcule de cabeça — rode `powershell -File scripts/validar-sequencia-id.ps1 -ProximoId -Prefixo RIS` e use o valor devolvido (comece em `RIS001` se o script indicar que o guide está vazio). Defina status inicial como `Identificado`, a menos que o conteúdo já mencione ação de mitigação em curso (`Mitigando`) ou apenas acompanhamento (`Monitorando`).

Gere o bloco no formato de `conhecimento/planejamento/riscos.md`:

```
### [RISxxx] — [Título curto do risco]

- **Data:** AAAA-MM-DD
- **Status:** Identificado | Monitorando | Mitigando
- **Tipo:** Técnico | Operacional | Negócio | Prazo / Cronograma | Adoção / Mudança | Segurança / Compliance
- **Probabilidade:** Alta | Média | Baixa
- **Impacto:** Alto | Médio | Baixo
- **Nível de risco:** Crítico | Alto | Médio | Baixo
- **Produto:** P1, P2 | Todos
- **Dono / Responsável pelo acompanhamento:** [nome ou "a confirmar"]
- **Fonte:** [onde este risco foi identificado]

**Descrição**
[O que pode acontecer e por que é uma possibilidade real.]

**Sinais de alerta**
[O que observar para saber que o risco está começando a se materializar.]

**Plano de mitigação**
[O que está sendo feito ou pode ser feito. Se não houver, marcar "a confirmar".]

**Plano de contingência**
[O que fazer se o risco se materializar mesmo assim. Se não houver, marcar "a confirmar".]

**Dores relacionadas:** [IDs de dores-de-processo.md ou "—"]
**Fluxos relacionados:** [IDs de fluxos-e-jornadas.md ou "—"]
**Features / módulos relacionados:** [nome da feature/módulo ou "—"]
**Dependências relacionadas:** [IDs de dependencias.md ou "—"]
**Decisões relacionadas:** [IDs de decisoes-aprovadas.md ou "—"]

**Histórico**
- AAAA-MM-DD — [registro ou atualização de status]
```

E a linha correspondente para o índice:

```
| RISxxx | [Título] | [Tipo] | [Probabilidade] | [Impacto] | [Nível] | [Produto] | Identificado | AAAA-MM-DD |
```

Relacione dores, fluxos, features, dependências e decisões apenas quando houver base clara no conteúdo — não force uma relação. Ao vincular, se o item relacionado (ex: um FLXxxx ou DORxxx) já existir no índice do guide correspondente, use o ID exato; se for uma menção livre a uma feature/módulo sem ID formal, use o nome descritivo.

**4. Dores de processo**

Se identificar dores de processo — fricções operacionais, ineficiências, trabalho manual excessivo, riscos de processo, reclamações ou limitações do produto — gere o bloco correspondente para `conhecimento/produto/dores-de-processo.md` e inclua-o na resposta junto com os demais guides. Use o formato definido no guia. Não sinalize nem pergunte ao usuário antes de gerar — execute diretamente e apresente o resultado. Se a dor for ambígua ou incompleta, preencha os campos com `[a confirmar]` e sinalize as dúvidas ao final.

**5. Histórias de usuário**

Se identificar US, sinalize ao usuário — elas não são processadas aqui:

```
⚠️ Identifiquei histórias de usuário no conteúdo enviado.
Esses itens não são registrados por esta skill — use a skill `create-spec`.
Deseja que eu liste o que encontrei?
```

**6. Reunião e ações pendentes**

Avalie se o conteúdo é uma **ata, resumo ou anotação de reunião** (sinais: data da reunião, participantes, pauta, encaminhamentos) ou se cita **ações com responsável** ("fulano vai enviar X até sexta", "ficou combinado que a área Y fará Z"). Se sim, gere dois tipos de registro — sempre com `[a confirmar]` onde o conteúdo não disser, nunca inventando:

*a) A ata* — um arquivo por reunião em `conhecimento/cliente/reunioes/AAAA-MM-DD-[slug-do-tema].md` (convenção já registrada no `index.md` da pasta). A data é a **da reunião**, não a de hoje: se o conteúdo não disser, pergunte antes de nomear o arquivo. Se o conteúdo cobrir mais de uma reunião, gere uma ata por reunião. Se já existir ata com a mesma data e tema, avise e pergunte se é a mesma reunião (complementar) ou outra. Estrutura:

```markdown
---
tipo: ata-reuniao
data: AAAA-MM-DD
tema: [tema da reunião]
participantes: [nomes — ou "a confirmar"]
registros-gerados: [IDs de decisões, dependências, riscos e dores criados a partir desta ata — ou "nenhum"]
---

# [Tema] — AAAA-MM-DD

## Participantes
| Nome | Papel / área |
|---|---|
| [nome] | [papel — ou "a confirmar"] |

## Pauta
[Assuntos previstos ou tratados — em tópicos.]

## Resumo
[Duas a cinco frases com o que foi tratado e o que ficou combinado.]

## Pontos discutidos
[Tópicos relevantes, fiéis ao conteúdo recebido. Decisões, dependências e riscos aparecem aqui só como referência ao ID registrado pelas checagens 1 a 3 (ex: "ver D00X") — não repita o bloco inteiro.]

## Encaminhamentos e ações
| Ação | Responsável | Prazo | Status |
|---|---|---|---|
| [ação] | [nome — ou "a confirmar"] | [AAAA-MM-DD — ou "a confirmar"] | Em aberto |

## Pontos em aberto
[Dúvidas ou temas que ficaram sem resposta na reunião — ou "nenhum".]
```

*b) As ações pendentes* — uma linha por ação em `conhecimento/cliente/reunioes/acoes-pendentes.md`, no formato da tabela do próprio arquivo (`Ação | Reunião de origem | Responsável | Prazo | Status`), com `Reunião de origem` = data da ata e status inicial `Em aberto`. Antes de gerar:
- Leia `acoes-pendentes.md` e não duplique: se a ação já está registrada, liste-a como "já registrada" (como nas dependências) em vez de gerar linha nova.
- Se a tabela só tiver a linha de exemplo entre colchetes (`[descrição da ação]`), a primeira linha real a **substitui**.
- Ação sem responsável ou sem prazo é registrada com `[a confirmar]` — isso é esperado e a triagem acontece na confirmação do usuário.
- Se o conteúdo disser que uma ação já registrada foi **concluída**, não gere linha nova: proponha mover a linha existente para a seção "Ações concluídas" do mesmo arquivo, com a data de conclusão.
- Ação pontual **não** é decisão (ver checagem 1): não gere bloco de decisão para ela.

Também proponha a linha correspondente no índice de `conhecimento/cliente/reunioes/index.md` (`Arquivo | Data | Tema`), ordenada da mais recente para a mais antiga, conforme a convenção da pasta. Conteúdo que **não** é de reunião (ex: um documento de briefing) não gera ata — mas ações com responsável citadas nele ainda vão para `acoes-pendentes.md`, com a fonte indicada na coluna "Reunião de origem" (ex: nome do documento).

**7. Fluxos e jornadas**

Avalie se o conteúdo descreve um **fluxo ou jornada**: uma sequência de etapas, telas ou ações de um processo de negócio, de um perfil de usuário ou do comportamento do sistema ("o usuário entra, escolhe X e então Y", "o processo passa por A, depois B, depois C", uma jornada narrada com pontos de contato). **Não conta como fluxo:** uma regra isolada (isso é `contexto-de-negocio.md`), a definição de um termo (`glossario.md`), uma ação pontual (checagem 6) ou uma fricção já acontecendo (`dores-de-processo.md`).

Esta checagem registra a **descrição textual** do fluxo no catálogo `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md`. Se o usuário quiser um **diagrama** (Mermaid) a partir de pesquisa ou documentação, a skill `flow-mapping` é a indicada — ela mesma sugere incorporar o resultado ao catálogo.

Para cada fluxo identificado:
- Leia o índice do catálogo para checar duplicata por título/processo. Se já existir entrada equivalente, não gere bloco novo: liste como "já catalogado" no Passo 4 e, se o conteúdo trouxer detalhes que mudam o fluxo, leve ao Passo 3 como divergência (a revisão pode virar status `Revisado` + nova entrada).
- Para o ID, não calcule de cabeça — rode `powershell -File scripts/validar-sequencia-id.ps1 -ProximoId -Prefixo FLX` e use o valor devolvido (comece em `FLX001` se o catálogo estiver vazio).
- **Status:** `Ativo` se o conteúdo descreve como o produto funciona hoje; `Proposto` se for um fluxo desejado ou em discussão; `[a confirmar]` se não ficar claro — nunca decida sozinho.
- **Tipo:** Jornada de usuário, Fluxo de tela, Fluxo de processo ou Fluxo de produto — inferido do conteúdo, ou `[a confirmar]`.
- **Diagrama:** se já existir um fluxo mapeado equivalente em `conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/`, referencie o arquivo; se não, escreva `[sem diagrama — use /flow-mapping para gerar]` e use `Sem diagrama` na coluna "Representação" do índice.
- **Pré-condições, fluxo principal (passos numerados), variações e exceções, pós-condições e pontos de atenção:** só o que o conteúdo disser; o resto fica `[a confirmar]` — nunca invente passos.
- **Decisões relacionadas / US relacionadas / Produto / Perfil envolvido:** só com base clara, senão `—` ou `[a confirmar]`.

Gere dois fragmentos, no formato do próprio catálogo:

```
| FLXxxx | [título curto] | [Tipo] | [Produto] | [Status] | [Representação] | AAAA-MM-DD |
```

```
### FLXxxx — [Título curto do fluxo]

- **Data:** AAAA-MM-DD
- **Status:** Ativo | Proposto | Revisado | Descontinuado
- **Tipo:** Jornada de usuário | Fluxo de tela | Fluxo de processo | Fluxo de produto
- **Produto:** [P1, P2 | Todos]
- **Perfil envolvido:** [quem executa ou experiencia esse fluxo — ou "a confirmar"]
- **Decisões relacionadas:** [IDs ou "—"]
- **US relacionadas:** [IDs ou "—"]
- **Substituído por:** —

**Contexto**
[Por que esse fluxo existe? Qual necessidade ou processo ele atende?]

**Diagrama**
[referência ao arquivo mapeado | "[sem diagrama — use /flow-mapping para gerar]"]

**Pré-condições**
[O que precisa ser verdade para o fluxo começar.]

**Fluxo principal**
1. [Passo 1]
2. [Passo 2]

**Variações e exceções**
- [Nome]: [quando ocorre e como o fluxo se comporta.]

**Pós-condições**
[Estado do sistema ou do usuário ao final.]

**Pontos de atenção**
[Fricções conhecidas, riscos ou aspectos sensíveis — ou "—".]
```

---

### Passo 3 — Checagem de divergências

Antes de gerar qualquer bloco, leia os guides que serão atualizados e compare o conteúdo recebido com o que já está registrado. Busque ativamente por:

**Sensor para termos de glossário (computacional + inferencial):** sempre que o conteúdo recebido incluir um termo novo destinado a `glossario.md`, não confie só na releitura manual do arquivo — rode `powershell -File scripts/validar-glossario.ps1 -Termo "<termo>" -Definicao "<definição proposta>"` (ou `-ArquivoNovosTermos <arquivo>` se houver vários termos de uma vez, no mesmo formato "### Termo" usado pelo próprio glossário). O script faz a parte computacional: acha o termo (por nome exato ou como sinônimo de um termo já existente) e mede a similaridade entre a definição atual e a proposta. Ele **nunca decide** se é conflito real — isso é sempre seu, com base no que ele devolve:
- Similaridade alta (Baixa/severidade) → provável duplicata exata, não vale gerar bloco novo.
- Similaridade média (Media) → provável paráfrase/complemento — ainda assim, compare as duas definições antes de decidir.
- Similaridade baixa (Alta) → possível conflito real — sempre leve ao usuário como divergência (ver formato abaixo), nunca resolva sozinho qual definição vale.
- "Já existe como sinônimo de outro termo" → risco de duplicar o mesmo conceito com dois nomes — considere registrar como sinônimo do termo existente em vez de criar uma entrada nova.

Para as demais divergências (decisões, dependências, riscos, contexto de negócio, fluxos), a checagem continua manual — busque ativamente por:

- **Contradições diretas** — o novo conteúdo afirma algo diferente do que já está salvo (ex: definição de termo, regra de negócio, etapa de fluxo)
- **Sobreposições parciais** — o novo conteúdo cobre o mesmo assunto com detalhes diferentes ou complementares
- **Inconsistências entre guides** — informação nova que conflita com algo registrado em um guide diferente do que será atualizado

Se identificar divergências, apresente antes dos blocos:

```
⚠️ Identifiquei divergências entre o conteúdo recebido e o que já está registrado:

| Guide | Item | Registrado atualmente | Novo conteúdo | Ação sugerida |
|---|---|---|---|---|
| glossario.md | [termo] | "[definição atual]" | "[nova definição]" | Substituir / Complementar / Revisar |

Como deseja proceder antes de eu gerar os blocos?
- Ajustar o bloco novo para alinhar com o que já está registrado
- Substituir o que está registrado pelo novo conteúdo
- Manter os dois e sinalizar para validação posterior
```

Se não houver divergências, continue para o próximo passo sem mencionar a checagem.

---

### Passo 4 — Geração dos blocos

Para cada guide que receberá informações, gere o bloco formatado pronto para ser colado no arquivo correspondente. Use exatamente o formato definido em cada guide.

Apresente os blocos organizados por guide, com o nome do arquivo como título de seção:

```
## conhecimento/produto/contexto-de-negocio.md

[bloco gerado]

---

## conhecimento/produto/glossario.md

[bloco gerado]

---

## conhecimento/planejamento/decisoes-aprovadas.md

[bloco gerado — apenas se decisões foram identificadas]

---

## conhecimento/planejamento/dependencias.md

[bloco(s) gerado(s) — apenas se dependências novas foram identificadas]

[se houver dependências já catalogadas, liste-as à parte:]
Já catalogadas — não duplicadas:
- DEPxxx — [título]: já registrada em dependencias.md

---

## conhecimento/planejamento/riscos.md

[bloco(s) gerado(s) — apenas se riscos foram identificados]
```

```
## conhecimento/cliente/reunioes/AAAA-MM-DD-[slug-do-tema].md

[ata completa — apenas se o conteúdo for uma reunião]

---

## conhecimento/cliente/reunioes/acoes-pendentes.md

[linhas novas da tabela — apenas se houver ações]

[se houver ações já registradas, liste-as à parte:]
Já registradas — não duplicadas:
- [ação]: já está em acoes-pendentes.md

[se houver ações concluídas: a linha existente a mover para "Ações concluídas", com a data]

---

## conhecimento/cliente/reunioes/index.md

[linha nova do índice — apenas se houver ata]

---

## conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md

[bloco(s) gerado(s) — apenas se fluxos ou jornadas foram identificados]

[se houver fluxos já catalogados, liste-os à parte:]
Já catalogados — não duplicados:
- FLXxxx — [título]: já registrado em fluxos-e-jornadas.md
```

Se nenhuma informação relevante for encontrada para um guide, não inclua a seção.

---

### Passo 5 — Confirmação com o usuário

Após apresentar todos os blocos (guides de conhecimento + decisões + dependências + riscos, se houver), pergunte:

```
Esses registros estão corretos? Confirmar salva tudo de uma vez:
- Guides de conhecimento atualizados
- conhecimento/cliente/reunioes/ — a ata, `acoes-pendentes.md` e `index.md` (se o conteúdo for uma reunião ou tiver ações)
- conhecimento/planejamento/decisoes-aprovadas.md (se houver decisões identificadas)
- conhecimento/planejamento/dependencias.md (se houver dependências identificadas)
- conhecimento/planejamento/riscos.md (se houver riscos identificados)
- conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md (se houver fluxos ou jornadas identificados)

Você pode:
- Confirmar todos
- Pedir ajuste em algum bloco antes de salvar
- Descartar blocos que não fazem sentido
```

Não salve nada sem confirmação explícita do usuário.

**Ordem ao salvar:** primeiro os guides (decisões, dependências, riscos, dores), depois a ata e `acoes-pendentes.md`, por último o `index.md` da pasta. Preencha `registros-gerados` na ata com os IDs que acabaram de ser gravados. Depois de salvar a ata, rode `powershell -File scripts/validar-referencias.ps1 -Arquivo <caminho da ata>` — confere se todo ID citado nela existe de fato nos guides — e `powershell -File scripts/gerar-indice-geral.ps1` (regra geral do `CLAUDE.md` para qualquer arquivo novo em `conhecimento/`). Corrija antes de encerrar qualquer ID apontado como inexistente. (Se o script avisar "Nenhum ID canônico encontrado", os guides ainda estão só com o template e a ata não cita IDs reais — não há o que conferir, siga em frente.)

---

### Passo 6 — Sensor de integridade (quando o status de um item já existente mudou)

Depois de salvar, se algum bloco confirmado **atualizou o status** de uma decisão, dependência, risco ou OKR **que já existia** (não um item novo criado agora — ex: o conteúdo recebido dizia "a dependência DEP019 foi resolvida" e isso mudou o `Status` de `DEP019` no arquivo), acione a skill `check-integrity` focada nesse(s) ID(s), sem perguntar antes de rodar.

Se o resultado apontar achado de severidade Alta ou Média (ex: um roadmap ainda marca `[BLOQUEADO até DEP019]`), reporte ao usuário antes de encerrar:

```
⚠️ DEP019 mudou de status para "Resolvida". Encontrei referências desatualizadas em:
- roadmap-mvp-AAAA-MM-DD.md:42 — ainda marca [BLOQUEADO até DEP019]

Quer que eu já corrija esses trechos?
```

Se a varredura não encontrar nada, não é preciso mencionar que ela rodou — siga para a Orientação ao final normalmente.

Isso não se aplica quando o item é **criado agora pela primeira vez** — nesse caso não existe nenhuma citação anterior para ficar desatualizada.

---

### Passo 7 — Orientação para itens descartados ou pendentes

Se o usuário descartar algum bloco ou se houver informações que não se encaixaram em nenhum guide, informe:

```
Os seguintes itens não foram registrados:
- [item]: [motivo ou guide sugerido]

Deseja revisá-los agora ou guardar para depois?
```

---

## Comportamentos esperados

- **Nunca invente informações.** Registre apenas o que está explícito ou claramente implícito no conteúdo enviado.
- **Prefira menos com precisão a mais com ruído.** Se uma informação for ambígua, pergunte ao usuário antes de classificar.
- **Mantenha o formato dos guides.** Os blocos gerados devem seguir exatamente a estrutura definida em cada guide — o usuário deve poder colar diretamente sem editar o formato.
- **Sinalize lacunas.** Se o conteúdo mencionar algo que deveria estar em um guide mas falta contexto para preencher (ex: nome de stakeholder sem cargo), gere o bloco com o campo marcado como `[a confirmar]` e sinalize ao usuário.
- **Nunca pule a checagem de decisão, dependência e risco.** Rode as três em toda chamada da skill — mesmo que o conteúdo pareça não ter nenhuma delas — e só omita a seção correspondente da resposta se de fato não encontrar nada.
- **Nunca registre uma decisão sem aprovador identificado ou `[a confirmar]`.** Decisões sem rastreabilidade perdem valor.
- **Dependências: prefira volume com `[a confirmar]` a perder um sinal.** O critério de detecção é amplo por design — a triagem fina acontece na confirmação do usuário, não na extração.
- **Riscos: não confunda com dependência ou dor.** Risco é incerto e futuro; dependência é um bloqueio concreto já identificado; dor já está acontecendo hoje. Releia a distinção em `riscos.md` sempre que houver dúvida.
- **Fluxos: descrição, não diagrama.** Registre só os passos que o conteúdo descreve, sem completar etapas "óbvias". Para um diagrama Mermaid, indique `/flow-mapping` — e não confunda fluxo com regra isolada, termo ou ação pontual.
- **Ata fiel, nunca criativa.** A ata registra o que o conteúdo diz: participante, prazo ou responsável que não aparecem ficam `[a confirmar]`. Não "complete" uma ata com o que parece provável.
- **Toda ação precisa de um dono visível.** Ação sem responsável entra com `[a confirmar]` e é sinalizada na confirmação — não deixe uma ação sem dono parecer resolvida.
- **Ata referencia, não duplica.** Decisões, dependências e riscos ficam nos próprios guides; a ata só cita o ID.
- **Riscos: relacione só com base clara.** Vincule a dores, fluxos, features, dependências ou decisões apenas quando o conteúdo (ou o guide já registrado) sustentar a relação — não force vínculo especulativo.
