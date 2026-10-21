# decisoes-aprovadas.md

> **Base de Conhecimento — Planejamento**
> Registra as decisões formais tomadas ao longo do projeto. Os agentes consultam este arquivo para não contradizer o que já foi decidido, entender o racional por trás das escolhas e identificar decisões que precisam ser revisadas. Qualquer membro do time pode registrar decisões, mas toda decisão precisa de um aprovador identificado.

---

## Metadados

| Campo | Valor |
|---|---|
| Cliente | [nome do cliente] |
| Time responsável | [nome do time/projeto] |
| Última atualização | [YYYY-MM-DD] |
| Atualizado por | [nome] |

---

## Índice por produto e área

> Atualize este índice sempre que uma nova decisão for registrada. Ele permite que os agentes localizem decisões relevantes sem varrer o arquivo inteiro.

| ID | Título | Produto | Área | Status | Data |
|---|---|---|---|---|---|
| [D001] | [Título curto da decisão] | [P1] | [ex: Arquitetura / Integração] | [Ativa] | [YYYY-MM-DD] |

---

## Status possíveis

| Status | Significado |
|---|---|
| **Ativa** | Decisão válida e em vigor. Os agentes devem respeitá-la. |
| **Revisada** | Decisão substituída por uma versão mais recente. Mantida no histórico para rastreabilidade. |
| **Revogada** | Decisão cancelada sem substituta. Não deve mais orientar o produto. |
| **Reclassificada** | Não era de fato uma decisão (confirmação de fato existente ou equivalência de termo) — conteúdo movido para `contexto-de-negocio.md` ou `glossario.md`. Mantida aqui só para preservar o ID e as referências cruzadas. |

---

## Como registrar uma decisão

```
### [ID] — [Título curto da decisão]

- **Data:** AAAA-MM-DD
- **Status:** Ativa | Revisada | Revogada
- **Produto:** P1, P2 | Todos
- **Área:** [ex: Autenticação, Cadastro, Experiência geral]
- **Aprovado por:** [nome e cargo]
- **Origem:** [ex: Reunião AAAA-MM-DD | Alinhamento interno | Solicitação do cliente]

**Contexto**
[Por que essa decisão precisou ser tomada? Qual era o problema ou dúvida em aberto?]

**Decisão**
[O que foi decidido, de forma clara e objetiva.]

**Alternativas consideradas**
[O que mais estava na mesa antes dessa decisão? Por que foram descartadas?]

**Impacto**
[O que muda ou passa a valer a partir dessa decisão? Quais áreas, fluxos ou regras são afetados?]

**Decisões relacionadas:** [IDs de decisões que se conectam a esta — ex: D002, D005]
**Substituída por:** [ID da decisão substituta, se status for Revisada]
```

---

## Decisões ativas

> Decisões em vigor, ordenadas da mais recente para a mais antiga.

_[Nenhuma decisão registrada ainda.]_

---

## Decisões revisadas e revogadas

> Mantidas para rastreabilidade. Os agentes não devem usá-las como referência ativa — consulte a decisão substituta indicada ou o contexto de revogação.

_[Nenhuma decisão registrada ainda.]_
