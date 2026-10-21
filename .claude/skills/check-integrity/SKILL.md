---
name: check-integrity
description: Audita a integridade de citações de IDs (DORxxx, DEPxxx, RISxxx, Dxxx, OKR-N) em toda a base de conhecimento — não confere se o ID existe apenas, confere se o que outros arquivos dizem sobre ele (status, título) ainda bate com a fonte de verdade no guide de origem. Detecta especificamente marcadores `[BLOQUEADO até DEPxxx]` esquecidos depois que a dependência já foi resolvida, e divergência entre o índice e o bloco detalhado do mesmo guide. Acione quando o usuário invocar /check-integrity, pedir para auditar/checar referências cruzadas, ou quando outra skill mudar o status de um item citável (`insert-knowledge`, `define-okrs`) ou for consolidar citações num relatório/apresentação (`create-presentation`).
---

# check-integrity

Esta skill é um **sensor**, não um gerador. Ela não produz conhecimento novo — ela audita se o conhecimento já registrado em vários arquivos ainda está consistente entre si. Existe porque toda skill deste projeto que cita um ID (`DEP007 — título curto`) cria, na prática, uma cópia (snapshot) do estado daquele item no momento em que o arquivo foi escrito. Quando a fonte de verdade muda depois (ex: uma dependência que estava `Bloqueando` passa a `Resolvida`), nada hoje avisa que as cópias espalhadas ficaram desatualizadas.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e objetivo.

---

## Princípio fundamental

Esta skill não decide **se** um item deveria ter seu status mudado — isso é sempre resultado de uma decisão real registrada em outra skill (`insert-knowledge`, `define-okrs`, etc.). O que ela decide é: **dado que algo mudou, quem mais na base ainda fala como se não tivesse mudado — e isso importa o suficiente para interromper o usuário?**

Ela roda em dois modos:

- **Focado** — logo depois que outra skill muda o status de um ID específico. Varre só esse ID.
- **Amplo** — sob demanda do usuário, ou antes de consolidar uma apresentação/relatório que vai citar vários IDs. Varre a base inteira ou um recorte.

Ela nunca edita a fonte de verdade (o guide onde o ID vive) — só o texto que **cita** o ID em outros arquivos, e só depois de confirmação do usuário.

---

## Gatilho

**Manual:** o usuário invoca `/check-integrity`, ou pede para auditar/checar referências cruzadas, achar citação desatualizada, ou conferir se um guide está consistente com o resto da base.

**Automático — focado em um ID (sem perguntar, mas sempre reportando o resultado):**

- `insert-knowledge`, ao **atualizar o status** de uma decisão, dependência ou risco já existente (não ao criar um novo) — rodar logo após a confirmação do Passo 5, focado no ID que mudou.
- `define-okrs`, na seção "Iterando sobre OKRs já salvos", sempre que o campo `Status` de um `OKR-N` for alterado.

**Automático — amplo, antes de consolidar citações (sem perguntar, sempre reportando o resultado):**

- `create-presentation`, no Passo 2 (Consolidação de informações) — depois de identificar quais dores/riscos/decisões/dependências vão ser citadas nos slides, rodar esta skill restrita a esses IDs específicos, antes de montar o plano de slides. O objetivo é nunca deixar um slide para o cliente ou para a diretoria repetir um status que já mudou.

Em todo acionamento automático, se a varredura não encontrar nada, a skill que chamou segue seu fluxo normalmente e nem precisa mencionar que rodou o check. Só interrompe o fluxo da skill chamadora quando há achado de severidade **Alta**.

---

## Passo 1 — Definir o escopo

Se acionada manualmente e o usuário não especificar, pergunte (no máximo 1 rodada):

1. **Escopo:** um ID específico, um tipo (`DOR`/`DEP`/`RIS`/`D`/`OKR`), ou a base inteira?
2. Só pergunte isso se o pedido do usuário não deixar claro — ex: "checa se o DEP019 tá tudo certo" já define o escopo sozinho.

Se acionada automaticamente por outra skill, o escopo já vem definido pelo gatilho (o ID que mudou, ou a lista de IDs que vão ser citados).

---

## Passo 2 — Rodar o sensor computacional

Execute o script `scripts/check-integrity.ps1` via PowerShell, com os parâmetros correspondentes ao escopo do Passo 1:

```
powershell -NoProfile -File "scripts/check-integrity.ps1" -Root "<raiz do repositório>" [-Id <ID>] [-Tipo <DOR|DEP|RIS|D|OKR>]
```

O script faz 4 checagens, da mais confiável para a mais heurística — **nunca edita nada, só relata**:

| Checagem | Severidade | O que detecta |
|---|---|---|
| **A — Marcador de bloqueio desatualizado** | Alta | `[BLOQUEADO até DEPxxx]` ainda presente em algum arquivo, mas a dependência já está `Resolvida` no guide de origem |
| **B — Índice x bloco detalhado** | Alta | Dentro do próprio guide, o `Status` da linha do índice diverge do `**Status:**` do bloco detalhado da mesma entrada |
| **C — ID inexistente** | Média | Um ID no formato certo (ex: `DEP041`) citado em algum arquivo, mas que não existe em nenhum índice canônico |
| **D — Título possivelmente divergente** | Baixa | O título citado ao lado do ID em outro arquivo tem baixa sobreposição com o título atual no guide — pode ser paráfrase legítima ou pode ser um item renomeado sem atualizar as citações |

Isso é o controle computacional puro — não depende de julgamento do modelo para existir, só para interpretar o resultado no passo seguinte.

---

## Passo 3 — Interpretar os achados (inferencial)

Para cada linha do relatório do script, principalmente as de severidade **Alta** e **Média**, leia o trecho real do arquivo citado (não confie só na coluna "Detalhe" — abra o arquivo na linha indicada) e classifique:

- **Divergência real** — o texto citante realmente afirma ou implica algo que não é mais verdade (ex: uma etapa de roadmap marcada `[BLOQUEADO até DEP019]` quando `DEP019` já foi resolvida).
- **Falso positivo** — o texto é histórico por natureza (ex: um "Histórico" de decisão descrevendo um status passado, um log de reunião relatando o que era verdade naquela data) — não precisa de correção.
- **Ambíguo** — não dá para decidir sozinho; leve para o usuário perguntar.

Achados de severidade **Baixa** (Checagem D) não precisam desse nível de escrutínio individual — apresente-os em bloco, como lista de possíveis parafraseamentos a revisar, sem gastar uma pergunta por item.

---

## Passo 4 — Apresentar o relatório e confirmar correções

Apresente ao usuário, separado por severidade:

```
check-integrity — [escopo avaliado]

🔴 Alta confiança — precisa de ação:
- DEP019 — marcador [BLOQUEADO até DEP019] em `roadmap-mvp.md:42` mas DEP019 já está "Resolvida" desde [data, se souber]. Atualizar esse trecho?

🟡 Média confiança — revisar:
- DEP041 citado em `briefing-X.md:12` mas não existe em `dependencias.md` — erro de digitação ou item ainda não registrado?

⚪ Baixa confiança — paráfrase possível, sem ação sugerida a menos que você aponte um problema real:
- [lista curta]

O que você quer que eu corrija?
```

Não edite nenhum arquivo citante sem essa confirmação — mesma regra de toda skill desta base que grava conteúdo.

---

## Passo 5 — Aplicar as correções aprovadas

Para cada correção aprovada, edite **apenas o arquivo citante** (nunca o guide de origem — esse já está correto, é a fonte de verdade). Formas comuns de correção:

- Remover ou atualizar um marcador `[BLOQUEADO até DEPxxx]` que não se aplica mais.
- Atualizar o título citado para bater com o atual.
- Corrigir um ID de citação que apontava para o item errado.

Se a correção exigir uma decisão de conteúdo que você não pode tomar sozinho (ex: "essa etapa do roadmap dependia de DEP019 só nesse ponto, ou o desbloqueio muda a data toda?"), não edite — sinalize e pergunte, ou oriente o usuário a rodar a skill dona daquele arquivo (`create-roadmap`, `create-spec`, etc.) para revisar o impacto completo, não só o texto da citação.

---

## Passo 6 — Salvar o relatório (opcional)

Se a varredura foi ampla (não focada em um ID só) e encontrou algo relevante, ofereça salvar o relatório:

```
Quer que eu salve este relatório em documentos/gerados/check-integrity-[YYYY-MM-DD].md para referência futura?
```

Use o parâmetro `-OutFile` do script para gerar o markdown diretamente, em vez de reescrever à mão.

---

## Diretrizes de comportamento

- **Nunca edite a fonte de verdade.** Este sensor só corrige o texto que cita um ID — o guide de origem (`dependencias.md`, `riscos.md`, `decisoes-aprovadas.md`, `okrs.md`, `dores-de-processo.md`) já está certo por definição; se ele estiver errado, isso é um problema para `insert-knowledge`/`define-okrs`, não para esta skill.
- **Severidade Alta e Média sempre são reportadas ao usuário, mesmo em acionamento automático silencioso.** Só o "nada encontrado" pode passar batido sem interromper a skill chamadora.
- **Baixa confiança nunca vira correção automática.** Achado de título possivelmente divergente é sinal para revisão humana, não uma ordem de reescrita.
- **Nunca edite um arquivo citante sem aprovação explícita**, mesmo quando o achado parecer óbvio.
- **Não confunda esta skill com o validador de existência de ID sozinho.** A Checagem C (existência) é um efeito colateral útil do mesmo script, mas o valor central desta skill é a Checagem A/B — status que ficou obsoleto depois de uma mudança real.
- **Escopo pequeno, resposta pequena.** Uma checagem focada em um ID que não encontrou nada não precisa de um relatório extenso — uma linha de confirmação basta.

---

## Orientação ao final

Quando acionada manualmente ou com achados relevantes, informe o usuário:

> **check-integrity concluído.**
> - Escopo: [ID específico / tipo / base inteira]
> - [N] achados de alta confiança, [N] de média, [N] de baixa
> - [N] correções aplicadas nos arquivos citantes
> - [Se salvo:] Relatório em `documentos/gerados/check-integrity-[YYYY-MM-DD].md`
>
> **Se algo ficou ambíguo:** revise manualmente ou rode a skill dona do arquivo citante antes de aceitar a correção sugerida aqui.
