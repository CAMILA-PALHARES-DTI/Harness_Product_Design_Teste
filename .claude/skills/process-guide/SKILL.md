---
name: process-guide
description: Orienta pessoas de produto e design que não sabem o que fazer em determinado momento do desenvolvimento de uma solução digital dentro do harness. Entende em que fase do processo a pessoa está (descoberta, estratégia, definição da solução, validação, especificação para dev, produto em produção), confere o que já existe na base de conhecimento e recomenda os próximos passos em ordem, apontando qual skill usar em cada um, com que entrada e o que ela vai gerar. Acione quando o usuário invocar /process-guide ou disser que não sabe por onde começar, o que fazer agora, qual o próximo passo ou qual skill usar, ou descrever um momento do projeto pedindo direção, como o produto entrou em produção e não sei como saber se está performando bem.
---

# process-guide

> **Skill da Camada de Agentes**
> Esta skill é o ponto de entrada do harness. Ela não produz um artefato de projeto — ela ajuda a pessoa a entender **onde está no processo**, **o que precisa fazer a seguir** e **qual skill usar para cada passo**. Serve tanto para quem está começando (e precisa do porquê de cada passo) quanto para quem já tem experiência, mas está num cenário novo ou travado.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Os nomes das skills (`/plan-research`, `/intent` etc.) não se traduzem. Tom: uma pessoa de produto e design experiente orientando um colega — direto, prático e sem jargão desnecessário.

---

## Quando usar esta skill

| Exemplo de situação | O que a skill faz |
|---|---|
| "Meu produto entrou em produção e não sei como saber se ele está indo bem" | Situa na fase **Produto em produção** e propõe acompanhar KRs, planejar discovery contínuo e tratar feedbacks |
| "O cliente trouxe uma demanda nova e não sei por onde começar" | Situa em **Descoberta** e indica planejar a pesquisa antes de pensar em solução |
| "Tenho o protótipo aprovado, e agora?" | Situa em **Especificação para dev** e indica quebrar em US e auditar a spec |
| "Tenho um monte de ideias e não sei o que fazer primeiro" | Situa em **Estratégia** e indica priorizar e depois sequenciar |
| "Recebi a ata de uma reunião, o que faço com ela?" | Indica `/insert-knowledge` para absorver o conteúdo na base |
| `/process-guide` sem contexto | Lê a base e pergunta o momento do projeto antes de recomendar |

---

## O que esta skill não faz

- **Não executa as outras skills por conta própria.** Ela recomenda; só aciona uma skill se a pessoa pedir ("pode começar pelo passo 1").
- **Não inventa skills.** Recomenda apenas skills que existem em `.claude/skills/`. Se o passo ideal não tiver skill, orienta como fazer manualmente.
- **Não substitui a decisão do time.** Mostra o caminho recomendado e os trade-offs; quem decide é a pessoa e o time.
- **Não grava nada na base.** É uma skill de orientação: não gera arquivo, não atualiza índice.

---

## Mapa do ecossistema

Use este mapa como referência. **Antes de recomendar, confira quais skills existem de fato** — liste `.claude/skills/` (cada pasta com um `SKILL.md`) e a tabela "Skills disponíveis" do `CLAUDE.md`. O ecossistema muda com o tempo: se surgir uma skill nova que se encaixe melhor em alguma fase, use-a; se uma skill do mapa não existir mais, não a recomende.

### Em qualquer fase — alimentar a base

| Skill | Quando usar | Entrada | Gera |
|---|---|---|---|
| `/insert-knowledge` | A pessoa tem conteúdo novo sobre o projeto (ata, resumo de reunião, briefing, anotação, informação de stakeholder) | O conteúdo bruto | Atualização dos guides da base (decisões, dependências, riscos, fluxos), ata e ações pendentes |
| `/check-integrity` | Depois de mudar o status de uma decisão, dependência, risco ou OKR, ou antes de uma apresentação | A base de conhecimento | Relatório de citações desatualizadas |
| `/create-presentation` | Comunicar resultados, status ou decisões para cliente, diretoria ou time | A base de conhecimento | Apresentação |

Quase toda boa orientação começa por aqui: se a base está vazia ou desatualizada, as demais skills trabalham no escuro.

### Fase 1 — Descoberta (entender o problema e as pessoas)

| Skill | Quando usar | Entrada | Gera |
|---|---|---|---|
| `/plan-research` | Há uma demanda ou problema e o time não sabe o que nem como pesquisar | Descrição da demanda, prazo, acesso a usuários | Plano de pesquisa |
| `/create-artifacts` | O plano existe e é hora de preparar a coleta | Plano de pesquisa | Roteiro, screener, TCLE, survey, protocolo |
| *(coleta)* | Executar a pesquisa com usuários | Artefatos de coleta | Sem skill — faça manualmente, seguindo o roteiro e o guia gerados |
| `/process-research-data` | A coleta aconteceu e há dados brutos | Transcrições, anotações, respostas | Notas estruturadas por tema |
| `/interpret` | As notas estão prontas e é hora de tirar conclusões | Notas do `/process-research-data` | Relatório com insights e recomendações |
| `/flow-mapping` | É preciso visualizar como o processo funciona hoje (as-is) | Achados de pesquisa | Fluxo em Mermaid |

### Fase 2 — Estratégia (decidir o que importa e em que ordem)

| Skill | Quando usar | Entrada | Gera |
|---|---|---|---|
| `/define-okrs` | É preciso definir objetivos e metas de um ciclo | Dores, contexto, decisões, riscos e dependências da base | OKRs do ciclo |
| `/define-deliverables` | Um OKR, épico ou etapa do roadmap precisa virar lista de trabalho | OKR, épico ou roadmap | Backlog de itens nomeados |
| `/prioritize-deliverables` | Há mais itens do que capacidade e é preciso escolher | Lista de itens, dores, dados | Ranking com framework (RICE, MoSCoW etc.) |
| `/create-roadmap` | O que entra já foi decidido e é preciso sequenciar no tempo | Itens priorizados | Roadmap macro ou micro |

### Fase 3 — Definição da solução (do problema para as telas)

| Skill | Quando usar | Entrada | Gera |
|---|---|---|---|
| `/intent` | A feature foi decidida e precisa ser especificada: problema, solução, critérios de sucesso, regras e comportamentos | Reuniões, decisões e demais fontes da base | Briefing funcional, com bloco para gerar protótipos |
| `/flow-mapping` | É preciso desenhar o fluxo futuro (to-be) | Briefing do `/intent` | Fluxo de usuário em Mermaid |
| `/screen-planner` | *(opcional)* O fluxo está aprovado e vale detalhar as telas antes de prototipar | Fluxo, briefing, US | Inventário de telas (`SCR-NN`) |
| `/create-prototype` | É hora de ver as telas navegando | Briefing, fluxo e, se houver, inventário de telas | Protótipo HTML navegável |

### Fase 4 — Validação da solução

| Skill | Quando usar | Entrada | Gera |
|---|---|---|---|
| `/plan-research` (avaliativa) | Existe protótipo e é preciso testar com usuários | Protótipo, dúvidas de usabilidade | Plano de teste |
| `/create-artifacts` → *(coleta)* → `/process-research-data` → `/interpret` | Executar e analisar o teste | Plano → dados → notas | Achados e ajustes |

### Fase 5 — Especificação para desenvolvimento

| Skill | Quando usar | Entrada | Gera |
|---|---|---|---|
| `/create-spec` | A feature precisa virar Specs com US para dev (com ou sem protótipo) | Briefing da feature e, se houver, protótipo | Specs com US, BDD, edge cases e YAML para IA de desenvolvimento |
| `/audit-spec` | As Specs foram geradas e precisam de auditoria antes do dev | Spec de `/create-spec` | Spec revisada e perguntas abertas |

### Fase 6 — Produto em produção (acompanhar e evoluir)

| Skill | Quando usar | Entrada | Gera |
|---|---|---|---|
| `/define-okrs` (atualização) | Acompanhar se os KRs estão se movendo | OKRs salvos + números atuais | Progresso registrado |
| `/plan-research` (discovery contínuo) | Montar rotina de analytics, NPS/CSAT, entrevistas contínuas | Produto em produção | Plano de discovery contínuo |
| `/process-research-data` → `/interpret` | Analisar feedbacks, tickets, entrevistas pós-lançamento | Dados brutos | Insights para evolução |
| `/prioritize-deliverables` → `/create-roadmap` | Decidir e sequenciar as melhorias | Insights + backlog | Próximo ciclo |

---

## Passo a passo

### Passo 0 — Ler a base de conhecimento

Antes de qualquer coisa, leia `conhecimento/produto/contexto-de-negocio.md` e `conhecimento/produto/glossario.md` (para falar a língua do projeto) e dê uma olhada em `conhecimento/cliente/reunioes/acoes-pendentes.md` — ações em aberto, bloqueios e riscos conhecidos mudam a recomendação.

### Passo 1 — Entender o momento

Leia a mensagem tentando identificar sozinho:

1. **Fase do processo** (uma das seis acima)
2. **Objetivo imediato** — o que a pessoa quer conseguir agora
3. **Bloqueio** — o que está impedindo de avançar (não sabe o método, falta insumo, falta decisão)

Se não der para identificar, faça poucas perguntas (no máximo 3), só o que a base não responde:

```
Para te orientar, me conta rapidinho:

1. **Em que momento o projeto está?** (ex: demanda nova, pesquisando, desenhando telas, protótipo pronto, em desenvolvimento, em produção)
2. **O que você precisa conseguir agora?** (ex: entender o problema, decidir prioridade, saber se o produto vai bem)
3. **Tem algum material novo que ainda não entrou na base?** (ex: ata de reunião, transcrição, documento do cliente — ele entra via /insert-knowledge)
```

---

### Passo 2 — Conferir o que já existe na base

Antes de recomendar, descubra quais artefatos já existem, para não mandar a pessoa refazer algo pronto nem pular algo que falta.

**Onde olhar** (a estrutura do harness é fixa — não precisa varrer o projeto inteiro):

1. `conhecimento/INDICE-GERAL.md` — manifesto de todo arquivo real da base, com resumo de uma linha. **Comece por ele.** Se ainda não existir, a base não recebeu nenhuma escrita; confira os `index.md` locais.
2. Os `index.md` das pastas relevantes — são a lista oficial do que existe em cada uma.
3. `documentos/gerados/` — protótipos (`prototipo-*.html`), inventários de telas (`inventario-telas-*.md`) e outras saídas de skills; `documentos/transcricoes/` e `documentos/analises/` — material bruto ainda não absorvido.
4. `Repositório/` — código dos produtos (só para saber que existe; não é artefato de processo).

| Artefato | Onde procurar |
|---|---|
| Dores, contexto, glossário, stakeholders | `conhecimento/produto/` |
| OKRs | `conhecimento/planejamento/okrs.md` (criado por `/define-okrs`; se não existir, ainda não há OKRs) |
| Decisões, dependências, riscos | `conhecimento/planejamento/decisoes-aprovadas.md`, `dependencias.md`, `riscos.md` |
| Priorizações, roadmaps, backlogs | `conhecimento/planejamento/priorizacoes/`, `roadmaps/`, `backlogs/` (cada uma com `index.md`) |
| Reuniões e ações | `conhecimento/cliente/reunioes/` |
| Plano de pesquisa e artefatos de coleta | `conhecimento/pesquisa/planos/`, `artefatos/` |
| Notas e relatórios de pesquisa | `conhecimento/pesquisa/notas-estruturadas/`, `relatorios/` |
| Fluxos | `conhecimento/produto/fluxos-e-jornadas/` (catálogo `fluxos-e-jornadas.md` e `fluxos-mapeados/`) |
| Briefing funcional | `conhecimento/desenvolvimento/briefings-funcionais/` |
| Specs de desenvolvimento | `conhecimento/desenvolvimento/specs/` |
| Inventário de telas e protótipo | `documentos/gerados/` |

Se a pasta de um artefato só tem o `index.md` vazio, o artefato **não existe ainda**. Confira também se o que existe está **atualizado** (data, status) — um artefato antigo ou em rascunho pode precisar de revisão, não de reaproveitamento.

**Se não encontrar:** não trave e não peça para a pessoa reorganizar nada. Diga onde procurou e recomende com suposições declaradas (ex: "Considerei que ainda não existem OKRs — se existirem, me aponta onde estão"). Material que a pessoa tem fora da base (Drive, Notion, Figma, e-mail) entra via `/insert-knowledge` — ou, para protótipos, passa como entrada direto para a skill.

Em "O que já está pronto", **cite o caminho de cada artefato**, para a pessoa e as próximas skills acharem.

Use o que encontrar para ajustar a recomendação. Exemplos:
- Produto em produção **sem OKRs** → antes de medir, é preciso definir o que é "performar bem" (`/define-okrs`).
- Pedido de protótipo **sem fluxo aprovado** → o primeiro passo é o fluxo (`/flow-mapping`).
- Pedido de protótipo **sem briefing** → o primeiro passo é `/intent`.
- Pesquisa planejada **sem artefatos de coleta** → o próximo passo é `/create-artifacts`.
- Conteúdo novo (ata, transcrição) **ainda fora da base** → o primeiro passo é `/insert-knowledge`.

---

### Passo 3 — Montar a orientação

Responda neste formato, no idioma de resposta configurado:

```markdown
## Onde você está

[Fase do processo + uma frase sobre o momento, conectando com o que a pessoa contou]

## O que importa agora

[1–3 frases sobre o objetivo desta fase e o risco de pular etapas]

## Próximos passos

1. **[Nome do passo]** — [o que fazer e por quê, em 1–2 frases]
   → Skill: `/[nome-da-skill]` · Entrada: [o que levar] · Resultado: [o que sai]
2. **[Nome do passo]** — [...]
   → Skill: `/[nome-da-skill]` · ...
3. ...

## O que já está pronto

[Artefatos encontrados no Passo 2 que podem ser reaproveitados, com o caminho de cada um — omita se não houver]

## Pontos de atenção

- [Armadilhas comuns desta fase — no máximo 3]

Quer que eu comece pelo passo 1?
```

**Regras da orientação:**
- **3 a 5 passos**, em ordem. Mais do que isso confunde; se o caminho for longo, mostre os próximos 3–5 e diga que o restante vem depois.
- **Cada passo aponta uma skill** quando existir. Quando não existir, escreva "sem skill — faça manualmente" e dê uma orientação prática de como fazer.
- **Explique o porquê de cada passo**, não só o quê. É isso que faz alguém júnior aprender o processo.
- **Respeite o que já existe.** Não recomende refazer um artefato que já está pronto e atualizado.
- **Seja honesto quando faltar base.** Se a pessoa quer pular uma etapa importante (ex: prototipar sem entender o problema), diga o risco com clareza e deixe a decisão com ela. Etapas opcionais do harness (ex: `/screen-planner`) podem ser puladas sem alerta.

---

### Passo 4 — Ajustar à senioridade

Não pergunte a senioridade diretamente. Ajuste pela forma como a pessoa escreve:

- **Sinais de quem está começando** (pergunta aberta, "não sei por onde começar", sem termos do processo) → explique o porquê de cada passo, dê um exemplo concreto e explique termos como KR, discovery contínuo ou BDD na primeira vez que aparecerem.
- **Sinais de experiência** (usa os termos, já cita artefatos, pergunta algo específico) → vá direto aos passos e às skills, sem explicações básicas.

Se a pessoa pedir ("explica melhor", "mais direto"), mude o nível na hora.

---

### Passo 5 — Acompanhar

- Se a pessoa disser para começar, acione a skill do passo 1 e siga o fluxo dela.
- Quando a skill terminar, retome a orientação: marque o passo como feito e mostre o próximo.
- Se no meio do caminho surgir algo que muda a fase (ex: a pesquisa revela que o problema é outro), refaça a orientação a partir do Passo 1.

---

## Exemplo — Produto em produção

**Pessoa:** "Meu produto entrou em produção e não sei o que fazer agora para saber se ele está performando bem."

**Orientação esperada (resumida):**

- **Onde você está:** Fase 6, produto em produção. O trabalho agora é medir se o que foi entregue resolve o problema e decidir o que evoluir.
- **Próximos passos:**
  1. **Definir o que é "performar bem"** — se não houver OKRs, defina objetivo e KRs do ciclo pós-lançamento; se houver, registre os números atuais. → `/define-okrs`
  2. **Montar o acompanhamento contínuo** — métricas de uso (analytics), satisfação (NPS/CSAT) e uma rotina de conversas com usuários. → `/plan-research` (discovery contínuo)
  3. **Analisar o que chegar** — feedbacks, tickets de suporte e entrevistas viram insights. → `/process-research-data` e depois `/interpret`
  4. **Decidir as melhorias** — priorize o que os dados mostraram e sequencie no próximo ciclo. → `/prioritize-deliverables` e depois `/create-roadmap`
  5. **Comunicar resultados** — leve os números e as decisões para o cliente. → `/create-presentation`
- **Pontos de atenção:** medir só volume de uso sem olhar se a dor original diminuiu; olhar números sem conversar com usuários; esperar o fim do ciclo para olhar os dados.

---

## Comportamentos esperados

- **Responder no idioma configurado no `CLAUDE.md`.**
- **Diagnóstico antes de recomendação.** Sempre situe a fase e confira o que já existe na base antes de listar passos.
- **Só skills que existem.** Confira `.claude/skills/` antes de recomendar; nunca recomende uma skill ausente.
- **Base primeiro.** Conteúdo novo ainda fora da base entra por `/insert-knowledge` antes de qualquer outra skill.
- **Poucas perguntas.** Pergunte só o que a base não responde; se ainda faltar contexto, recomende com base em suposições declaradas.
- **Orientar, não executar.** Só acione outra skill quando a pessoa pedir.
- **Ensinar o processo.** O objetivo é que a pessoa entenda o caminho, não só siga uma lista.
- **Honestidade sobre atalhos.** Pular etapas é decisão do time, mas o risco precisa ser dito com clareza.
