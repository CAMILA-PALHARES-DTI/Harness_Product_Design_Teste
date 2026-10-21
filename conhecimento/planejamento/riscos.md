# riscos.md

> **Base de Conhecimento — Planejamento**
> Centraliza os riscos identificados no projeto — eventos incertos que, se ocorrerem, podem comprometer prazo, qualidade, operação ou negócio do produto. Os agentes consultam este arquivo para alertar sobre riscos relevantes antes de sugerir soluções, priorizar entregas ou planejar releases. Qualquer membro do time pode e deve mantê-lo atualizado.

---

## Risco x Dependência x Dor — quando usar cada guide

| Guide | O que registra | Quando usar |
|---|---|---|
| `riscos.md` (este arquivo) | Um evento **incerto** que ainda não aconteceu, mas que pode acontecer e gerar impacto | "Se X acontecer, isso vai comprometer Y" |
| `dependencias.md` | Um bloqueio ou condicionante **conhecido e concreto** que precisa ser resolvido para algo avançar | "Y só pode avançar depois que Z acontecer" |
| `dores-de-processo.md` | Um problema que **já está acontecendo** hoje, na operação real | "Hoje, X já causa Y" |

Um risco que se materializa vira uma dor (deve ser registrado em `dores-de-processo.md`, com referência de volta ao risco de origem). Um risco também pode nascer de uma dependência não resolvida a tempo — nesse caso, relacione o risco à dependência de origem.

---

## Metadados

| Campo | Valor |
|---|---|
| Cliente | [nome do cliente] |
| Time responsável | [nome do time/projeto] |
| Última atualização | [YYYY-MM-DD] |
| Atualizado por | [nome] |


---

## Tipos de risco

| Tipo | Descrição |
|---|---|
| **Técnico** | Risco de arquitetura, integração, performance, disponibilidade ou dívida técnica |
| **Operacional** | Risco de execução no dia a dia — capacidade do time, processo, dado ou pessoa envolvida |
| **Negócio** | Risco de receita, relacionamento comercial, posicionamento ou modelo de negócio |
| **Prazo / Cronograma** | Risco de atraso em entrega, dependência externa com prazo incerto, ou capacidade insuficiente para a data prevista |
| **Adoção / Mudança** | Risco de resistência, baixa adesão ou dificuldade de mudança de hábito por parte de usuários ou stakeholders |
| **Segurança / Compliance** | Risco legal, regulatório, de dados ou de segurança da informação |

---

## Probabilidade, Impacto e Nível de Risco

**Probabilidade** — chance de o risco se materializar:

| Nível | Critério |
|---|---|
| **Alta** | Já há sinais concretos de que está acontecendo ou é muito provável no prazo do projeto |
| **Média** | Pode acontecer, mas depende de outros fatores ainda incertos |
| **Baixa** | Possível, mas sem sinais concretos hoje |

**Impacto** — tamanho do dano caso o risco se materialize:

| Nível | Critério |
|---|---|
| **Alto** | Compromete prazo crítico, operação essencial, segurança de dados ou relação com o cliente |
| **Médio** | Gera retrabalho, atraso parcial ou insatisfação, sem comprometer o projeto como um todo |
| **Baixo** | Impacto pontual, absorvível sem grandes ajustes |

**Nível de risco** — combinação de Probabilidade x Impacto, usada para priorizar atenção:

| | Impacto Baixo | Impacto Médio | Impacto Alto |
|---|---|---|---|
| **Probabilidade Alta** | Médio | Alto | Crítico |
| **Probabilidade Média** | Baixo | Médio | Alto |
| **Probabilidade Baixa** | Baixo | Baixo | Médio |

---

## Status possíveis

| Status | Significado |
|---|---|
| **Identificado** | Risco registrado, ainda sem plano de mitigação definido |
| **Monitorando** | Risco com plano definido, sendo observado, sem ação ativa necessária ainda |
| **Mitigando** | Ação ativa em curso para reduzir probabilidade ou impacto |
| **Materializado** | O risco aconteceu — deve ter uma dor correspondente registrada em `dores-de-processo.md` |
| **Encerrado** | Risco não se aplica mais (ex: contexto mudou, dependência foi resolvida) — mantido para rastreabilidade |

---

## Índice

| ID | Título | Tipo | Probabilidade | Impacto | Nível | Produto | Status | Data |
|---|---|---|---|---|---|---|---|---|
| [RIS001] | [Título curto do risco] | [Técnico] | [Média] | [Alto] | [Alto] | [P1] | [Identificado] | [YYYY-MM-DD] |

---

## Como registrar um risco

```
### [ID] — [Título curto do risco]

- **Data:** AAAA-MM-DD
- **Status:** Identificado | Monitorando | Mitigando | Materializado | Encerrado
- **Tipo:** Técnico | Operacional | Negócio | Prazo / Cronograma | Adoção / Mudança | Segurança / Compliance
- **Probabilidade:** Alta | Média | Baixa
- **Impacto:** Alto | Médio | Baixo
- **Nível de risco:** Crítico | Alto | Médio | Baixo
- **Produto:** P1, P2 | Todos
- **Dono / Responsável pelo acompanhamento:** [nome ou "a confirmar"]
- **Fonte:** [onde este risco foi identificado — reunião, documento, observação]

**Descrição**
[O que pode acontecer, por que é uma possibilidade real, e o que dispara esse risco.]

**Sinais de alerta**
[O que observar para saber que o risco está começando a se materializar.]

**Plano de mitigação**
[O que está sendo feito ou pode ser feito para reduzir a probabilidade ou o impacto. Se não houver, marcar "a confirmar".]

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

Relacione apenas quando fizer sentido — nem todo risco tem dor, fluxo, feature, dependência e decisão associados. Não force uma relação sem base clara no conteúdo.

---

## Riscos ativos

> Identificado, Monitorando e Mitigando — ordenados por nível de risco e depois por data.

_[Nenhum risco registrado ainda.]_

---

## Riscos materializados ou encerrados

> Mantidos para rastreabilidade. Os agentes não precisam considerá-los como risco ativo.

_[Nenhum risco registrado ainda.]_

---

## Histórico de mudanças

| Data | Risco | O que mudou | Quem atualizou |
|---|---|---|---|
| [YYYY-MM-DD] | — | [Guia criado] | [nome] |
