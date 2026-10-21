# dependencias.md

> **Base de Conhecimento — Planejamento**
> Mapeia as dependências dos produtos, features e User Stories do time. Os agentes consultam este arquivo para identificar bloqueios, riscos e condicionantes antes de sugerir soluções ou estimar esforço. Qualquer membro do time pode e deve mantê-lo atualizado.

---

## Metadados

| Campo | Valor |
|---|---|
| Cliente | [nome do cliente] |
| Time responsável | [nome do time/projeto] |
| Última atualização | [YYYY-MM-DD] |
| Atualizado por | [nome] |

---

## Tipos de dependência

| Tipo | Descrição |
|---|---|
| **Interna** | Depende de outro time ou squad da dti |
| **Externa — cliente** | Depende de uma área, time ou decisão do próprio cliente |
| **Externa — sistema** | Depende de um sistema, API ou serviço de terceiros |

---

## Status possíveis

| Status | Significado |
|---|---|
| **Bloqueando** | Impede o avanço do que depende dela. Requer atenção imediata. |
| **Em andamento** | Sendo resolvida. Há um responsável e prazo definidos. |
| **Aguardando** | Identificada mas ainda sem ação em curso. |
| **Resolvida** | Dependência endereçada. Mantida para rastreabilidade. |

---

## Índice

> Atualize sempre que uma nova dependência for registrada.

| ID | Título | Tipo | Produto | Feature / US | Status | Data |
|---|---|---|---|---|---|---|
| [DEP001] | [Título curto da dependência] | [Interna] | [P1] | [nome da feature ou ID da US] | [Aguardando] | [YYYY-MM-DD] |

---

## Como registrar uma dependência

```
### [ID] — [Título curto da dependência]

- **Data:** AAAA-MM-DD
- **Status:** Bloqueando | Em andamento | Aguardando | Resolvida
- **Tipo:** Interna | Externa — cliente | Externa — sistema
- **Produto:** P1, P2 | Todos
- **Feature / US relacionada:** [nome da feature ou ID da US — ex: US-042]
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

---

## Dependências ativas

> Bloqueando e em andamento, ordenadas por criticidade e depois por data.

_[Nenhuma dependência registrada ainda.]_
