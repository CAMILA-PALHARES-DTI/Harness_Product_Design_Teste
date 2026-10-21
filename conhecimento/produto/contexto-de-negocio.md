# contexto-de-negocio.md

> **Base de Conhecimento — Produto**
> Documenta o que o produto é e como ele funciona. Os agentes consultam este arquivo para entender o contexto do produto e garantir que sugestões, soluções e requisitos respeitem o que já está estabelecido. Qualquer membro do time pode e deve mantê-lo atualizado.

---

## Metadados

| Campo | Valor |
|---|---|
| Cliente | [nome do cliente] |
| Área de negócio | [ex: portal web, app mobile, etc.] |
| Time responsável | [nome do time/projeto] |
| Última atualização | [YYYY-MM-DD] |
| Atualizado por | [nome] |

---

## Guia de uso e escala

> Leia antes de preencher. A estrutura deste arquivo deve ser adaptada ao tamanho e complexidade do contexto do time.

**Arquivo único** — recomendado quando:
- O time gerencia apenas um produto, ou
- O time gerencia até 2 produtos simples com poucas regras

**Fragmentar em múltiplos arquivos** — recomendado quando:
- O time gerencia 3 ou mais produtos, ou
- Qualquer produto individual ultrapassar ~50 regras, ou
- Agentes estiverem demorando ou perdendo contexto ao consultar este arquivo

Ao fragmentar, adote a seguinte convenção:

```
contexto-de-negocio.md          → este arquivo: metadados, visão geral e mapa dos produtos
regras-compartilhadas.md      → regras que valem para mais de um produto
regras-[nome-do-produto].md   → regras específicas de cada produto
```

Nesse cenário, este arquivo passa a funcionar como índice: descreve os produtos, aponta para os arquivos corretos e registra as regras compartilhadas. Os agentes carregam apenas os arquivos relevantes para a tarefa em questão.

---

## Produtos geridos por este time

| ID | Nome | Tipo | Status | Arquivo de regras |
|---|---|---|---|---|
| P1 | [nome do produto] | [ex: sistema web] | [ex: ativo, em desenvolvimento] | contexto-de-negocio.md (aqui) |

> Quando fragmentar, atualize a coluna "Arquivo de regras" para apontar para o arquivo correto de cada produto.

---

## Visão geral dos produtos

### [P1] — [nome do produto]

**O que é**
[Descrição objetiva do produto: o que ele faz, para que serve.]

**Contexto de negócio**
[Por que esse produto existe, qual a proposta de valor, como se posiciona frente a outros produtos/concorrentes.]

**Público**
[Quem usa o produto — perfil de usuário/cliente.]

**Arquitetura e integrações relevantes**
[Stack técnica e sistemas com os quais o produto se integra, quando relevante para decisões de produto/design.]

---

## Como registrar uma regra

```
#### [Nome curto da regra]
- **Produtos:** P1, P2 (ou "Todos")
- **Regra:** Descrição clara e objetiva do comportamento.
- **Contexto:** Por que essa regra existe? Quem definiu? Há exceções?
- **Impacto:** O que quebra ou muda se essa regra não for respeitada?
```

> Seja objetivo. Regras longas e descritivas aumentam o custo de leitura para os agentes sem necessariamente melhorar a compreensão. Se uma regra precisar de muito contexto, considere se parte dele não pertence à visão geral do produto acima.

---

## Regras compartilhadas entre produtos

_[Nenhuma regra registrada ainda.]_

---

## Histórico de mudanças

| Data | Produto | Módulo / Funcionalidade | O que mudou | Quem atualizou |
|---|---|---|---|---|
| [YYYY-MM-DD] | [Produto] | [Módulo] | [Preenchimento inicial do guia] | [nome] |
