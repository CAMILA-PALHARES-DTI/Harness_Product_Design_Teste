---
name: prioritize-deliverables
description: Ajuda a priorizar entregáveis, features ou um recorte de MVP usando frameworks de priorização (RICE, MoSCoW, Valor x Esforço, Kano, WSJF/Custo do Atraso), apoiado em dados de uso, severidade de dores mapeadas e risco. Não sequencia no tempo — isso é feito pela skill `create-roadmap`. Acione quando o usuário invocar /prioritize-deliverables ou pedir para priorizar um backlog, decidir o que entra no MVP, rankear itens, comparar valor x esforço, aplicar RICE/MoSCoW/Kano, ou decidir o que vem primeiro sem ainda pensar em datas.
---

# prioritize-deliverables

Esta skill ajuda a decidir **o quê** priorizar e **em que ordem de importância** — usando um framework explícito e dados reais, não datas. Sequenciamento no tempo (quando cada coisa acontece) é escopo da skill `create-roadmap`.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e objetivo.

**Rótulos que os sensores leem:** títulos de seção, rótulos em linha, nomes de coluna e valores de frontmatter listados em `scripts/rotulos.txt` são escritos com o texto da coluna do idioma configurado (português ou inglês), exatamente como no dicionário e sem inventar variações — os sensores só reconhecem essas variantes. Rótulos que o `CLAUDE.md` mantém fixos (`Dado`/`Quando`/`Então`, `Cenário`, IDs, marcadores) não mudam de idioma.

---

## Princípio fundamental

Esta skill não decide sozinha o que é importante — ela estrutura o julgamento do usuário com um framework e os dados que ele fornecer ou que já estejam registrados no projeto.

Nunca invente:
- Métricas de uso que não foram fornecidas — nem "estime por cima" para preencher uma lacuna
- Pesos ou notas de critério sem que o usuário informe, aponte a fonte, ou eles já estejam registrados em `conhecimento/`

Quando faltar um dado necessário para pontuar um critério, marque `[dado necessário]` na matriz e pergunte — nunca preencha com achismo.

**Diferença para a skill `create-roadmap`:** esta skill decide o quê e em que ordem de importância; a skill `create-roadmap` decide quando, dado o que já foi priorizado aqui (ou por qualquer outro processo) mais as dependências e riscos registrados. Ao final desta skill, oriente o usuário a rodar `/create-roadmap` para sequenciar no tempo.

---

## Gatilho

Acionada quando o usuário invoca `/prioritize-deliverables` ou pede para: priorizar um backlog, decidir o escopo de um MVP, ranquear features, aplicar um framework de priorização (RICE, MoSCoW, Kano, Valor x Esforço, WSJF), ou responder "o que vem primeiro" sem falar de datas ou prazos.

Se o pedido já vier com data, prazo ou sequência ("quero um roadmap", "quando isso fica pronto", "monta um cronograma"), isso é sequenciamento no tempo, não priorização — pergunte:

> Isso é sobre sequenciar no tempo — quer que eu chame a skill `create-roadmap`? Se a lista de prioridade ainda não estiver fechada, eu faço essa parte aqui primeiro.

---

## Passo 1 — Reunir os itens a priorizar

Pergunte, se não vier no pedido (no máximo 3 perguntas):
- Quais são os itens candidatos? (features, módulos, User Stories, épicos) — peça a lista, mesmo que informal ou incompleta
- Existe um corte já em mente (ex: "isso é pra decidir o que entra no MVP") ou é uma priorização aberta de backlog, sem corte definido?
- Há alguma restrição já conhecida que deve ser respeitada (orçamento, prazo duro, escopo já travado por decisão)?

---

## Passo 2 — Escolher o framework

Pergunte qual framework usar, ou recomende um com base no que o usuário já tem disponível:

| Framework | Quando se aplica | O que exige do usuário |
|---|---|---|
| **RICE** (Reach, Impact, Confidence, Effort) | Muitos itens, precisa de um score comparável | Estimativa de alcance, impacto, confiança e esforço por item |
| **Valor x Esforço** (matriz 2x2) | Decisão rápida, poucos itens, sem dados numéricos precisos | Julgamento qualitativo de valor e esforço por item |
| **MoSCoW** (Must / Should / Could / Won't) | Definir corte de escopo (ex: o que é MVP) | Classificação categórica por item, não um score contínuo |
| **Kano** | Priorizar por tipo de satisfação do usuário (básico, de desempenho, encantador) | Perfil de reação do usuário a cada item — normalmente vindo de pesquisa/survey |
| **WSJF / Custo do Atraso** | Fluxo contínuo, quando atraso tem custo mensurável | Estimativa de custo do atraso e duração do job por item |

Critério de recomendação quando o usuário não souber qual usar:
- Tem dado numérico de uso/impacto → RICE
- Precisa de um corte binário rápido de escopo (dentro/fora do MVP) → MoSCoW
- Poucos itens, decisão qualitativa e rápida → Valor x Esforço
- Tem pesquisa de satisfação do usuário → Kano
- Ambiente de fluxo contínuo com custo de atraso mensurável → WSJF

Confirme o framework escolhido antes de seguir — a estrutura da matriz muda de acordo.

---

## Passo 3 — Buscar critérios e dados

Para cada critério do framework escolhido, busque dado real antes de pedir ao usuário para estimar às cegas:

| Fonte | O que buscar |
|---|---|
| Dado de uso/analytics fornecido pelo usuário, ou de uma ferramenta conectada (MCP) | Alcance, frequência de uso, volume — quando existir |
| `conhecimento/produto/dores-de-processo.md` | Severidade das dores ligadas a cada item — dor de severidade Alta aumenta o caso de priorizar |
| `conhecimento/planejamento/riscos.md` | Itens que mitigam um risco Crítico/Alto merecem destaque no critério de impacto |
| `conhecimento/planejamento/decisoes-aprovadas.md` | Escopo já travado por decisão não é repriorizado aqui — apenas confirmado. Se o usuário tentar reabrir algo já decidido, aponte o conflito |
| `conhecimento/planejamento/dependencias.md` | Uma dependência "Bloqueando" não tira um item do ranking, mas deve ser sinalizada como condicionante para quando o `create-roadmap` for montado depois |

Se não houver dado de uso disponível nem em `conhecimento/` nem via ferramenta conectada, pergunte diretamente: "Você tem dado de uso pra isso, ou prefere que eu trate esse critério de forma qualitativa?" Nunca preencha um critério numérico sem dado — marque `[dado necessário]` na matriz quando faltar.

---

## Passo 4 — Montar e apresentar o ranking

Apresente uma tabela com os itens ordenados pelo framework escolhido, o valor de cada critério por item, e o racional por trás da posição — não apenas o número final.

- **RICE/WSJF:** score numérico + fórmula aplicada, ordenado do maior para o menor.
- **Valor x Esforço:** quadrante (Alto valor/Baixo esforço primeiro) com justificativa qualitativa.
- **MoSCoW:** categoria por item (Must/Should/Could/Won't), com o corte de escopo explícito.
- **Kano:** perfil por item (básico/de desempenho/encantador), com a leitura de prioridade que isso sugere.

Se o pedido era definir um corte de MVP, destaque explicitamente onde a linha corta e por quê — não deixe implícito.

Apresente ao usuário e pergunte se quer ajustar pesos, critérios ou itens antes de salvar.

---

## Formato do arquivo salvo

Nome do arquivo: `priorizacao-[recorte]-[YYYY-MM-DD].md`

```markdown
---
tipo: priorizacao
framework: RICE | MoSCoW | Valor x Esforço | Kano | WSJF
recorte: [ex: escopo do MVP, backlog do módulo X]
gerado-em: [YYYY-MM-DD]
fontes-consultadas: [lista de guides/dados usados]
---

# Priorização — [Nome do recorte]

## Contexto
[O que está sendo priorizado e por quê — 2-3 frases]

## Framework e Critérios
[Framework escolhido, critérios usados, e por que esse framework se encaixa neste contexto]

## Ranking

| # | Item | [Critério 1] | [Critério 2] | ... | Score/Categoria | Racional |
|---|---|---|---|---|---|---|
| 1 | ... | ... | ... | ... | ... | ... |

## Corte de MVP
[Se aplicável — onde a linha corta e por quê. Omitir se não houver corte pedido.]

## Itens sem dado suficiente
[Lista de itens/critérios marcados como `[dado necessário]` — o que falta e onde buscar]

## Premissas Adotadas
[Suposições feitas por falta de informação]
```

Antes de salvar, rode `powershell -File scripts/validar-referencias.ps1 -Arquivo <caminho do arquivo>` sobre o conteúdo já escrito. Se apontar algum ID citado (`DORxxx`/`DEPxxx`/`RISxxx`/`Dxxx`) que não existe em nenhum guide, corrija antes de prosseguir — provavelmente é erro de digitação.

Salve em `conhecimento/planejamento/priorizacoes/` e atualize `conhecimento/planejamento/priorizacoes/index.md` com uma nova linha.

---

## Diretrizes de comportamento

- **Nunca invente métrica de uso.** Pergunte ou marque `[dado necessário]`.
- **Nunca repriorize o que já é uma decisão travada.** Aponte o conflito antes de prosseguir em vez de silenciosamente reordenar algo já decidido.
- **Seja transparente sobre lacunas de dado.** Um ranking parcialmente baseado em achismo deve dizer isso explicitamente, não se apresentar como definitivo.
- **Recorte pequeno, resposta pequena.** Priorizar 3 itens não precisa da estrutura inteira de um framework formal — uma comparação direta com racional já resolve.
- **Um framework por vez.** Não misture RICE com MoSCoW no mesmo ranking — se o usuário quiser comparar dois frameworks, rode em passagens separadas e compare os resultados no final.

---

## Orientação ao final

Após salvar a priorização, informe o usuário:

> **Priorização concluída.**
> - Arquivo salvo em `conhecimento/planejamento/priorizacoes/[nome-do-arquivo].md`
> - Framework: [nome] · [N] itens priorizados
> - [Se houver corte de MVP:] Corte definido em: [onde]
> - [N] itens marcados com dado insuficiente
>
> **Próximo passo:** rode `/create-roadmap` para sequenciar isso no tempo, considerando dependências e riscos já registrados.
