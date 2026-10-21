# Sensores — create-prototype

Arquivo de apoio da skill `create-prototype`. A skill manda **ler este arquivo antes de rodar o Passo 4.1**.

No modelo de *harness*, os **Guias** (`guias-qualidade.md`) são controles *feedforward*: orientam a geração **antes** de o protótipo existir. Os **Sensores** são controles *feedback*: observam o protótipo **depois** de gerado e devolvem sinais para a própria skill se corrigir antes de entregar. Guia sem sensor é intenção sem verificação — por isso todo guia tem pelo menos um sensor associado.

Há dois tipos:

- **Sensores computacionais (SC)** — determinísticos, rodam por script sobre o arquivo HTML. Cobrem o que é mensurável: estrutura, navegação, estados, semântica, contraste, reflow, foco, tamanho de alvo e consistência dos IDs `SCR-NN`.
- **Sensores inferenciais (SI)** — avaliação por IA com rubrica fixa, de preferência por um agente revisor separado (não o mesmo que gerou). Cobrem o que exige julgamento: heurísticas de Nielsen, fidelidade aos materiais, qualidade da copy, cobertura do fluxo.

## Severidade

| Nível | Significado | Efeito |
|---|---|---|
| **BLOQUEANTE** | Viola regra obrigatória da skill ou critério WCAG AA de forma verificável | Corrija antes de entregar. Não entregue com bloqueante aberto (ver exceções) |
| **ALERTA** | Provável problema ou boa prática não seguida; pode ter justificativa | Corrija se for simples; senão, liste no relatório do Passo 5 |
| **INFO** | Contagem ou contexto | Vai para o relatório |

## Mapa sensores × guias

| Sensor | Tipo | O que verifica | Guia / regra coberta |
|---|---|---|---|
| SC-01 Estrutura e arquivo único | Computacional | DOCTYPE, `lang` presente (e igual ao idioma do protótipo, se informado), viewport, `<title>`, nenhum script/CSS externo, sem `localStorage`/`fetch`, sem erro de JavaScript | Regras técnicas 1 e 8; WCAG 2.4.2, 3.1.1 |
| SC-02 Telas e navegação | Computacional | Toda tela confirmada no Passo 3 existe; IDs únicos e no padrão `SCR-NN`; todo `navigateTo()` aponta para tela existente; telas alcançáveis a partir da primeira | Passo 3; regra técnica 2; IDs estáveis |
| SC-03 Estados | Computacional | Valores de `data-state` válidos; toda tela com estados tem `default`; telas com envio têm `loading` e `error` | Passo 4 item 3; Nielsen H1 e H9 |
| SC-04 Acessibilidade estática | Computacional | Um `<h1>` por tela, sem salto de heading; `alt` em imagens; nome acessível em botões/links; label em campos; sem `<div onclick>`; sem `tabindex` positivo; `role="dialog"` completo; região `aria-live`; skip link; `outline` não removido sem `:focus-visible`; `prefers-reduced-motion`; `autocomplete` em email/telefone | WCAG 1.1.1, 1.3.1, 1.3.5, 2.1.1, 2.3.3, 2.4.1, 2.4.3, 2.4.7, 3.3.2, 4.1.2, 4.1.3 |
| SC-05 Conteúdo | Computacional | Sem lorem ipsum; marcador `[a confirmar]` (e não `[to be confirmed]`); contagem de `[a confirmar]`, `[sugestão]`, `[a11y]` | Regra técnica 6; marcadores do harness |
| SC-06 Reflow | Computacional (runtime) | Sem rolagem horizontal a 320px em cada tela e estado (não se aplica a web não responsivo) | WCAG 1.4.10; Plataforma |
| SC-07 Contraste | Computacional (runtime) | Razão de contraste de todo texto visível em cada tela e estado (4.5:1 normal, 3:1 grande) | WCAG 1.4.3 |
| SC-08 Tamanho de alvo | Computacional (runtime) | Botões, links e controles ≥ 24×24 px na web; ≥ 44×44 px em app | WCAG 2.5.8; Plataforma |
| SC-09 Foco por teclado | Computacional (runtime) | Navegando com `Tab`, todo elemento focado tem indicador visível e não fica coberto por elemento fixo (ex: barra de debug) | WCAG 2.1.1, 2.4.7, 2.4.11 |
| SC-10 IDs de prototipação | Computacional | `scripts/validar-sequencia-id.ps1 -Telas`: IDs `SCR-NN` no padrão, sem duplicata, sem gap (inventário), destinos de navegação existentes e telas do protótipo coerentes com o inventário | Passo 3; IDs estáveis |
| SI-01 Heurísticas de Nielsen | Inferencial | As 10 heurísticas, tela a tela, com evidência | Guia A |
| SI-02 Fidelidade aos materiais | Inferencial | Toda tela, regra e texto vem dos materiais de base ou está marcado `[a confirmar]` / `[sugestão: Heurística N]` | Passo 2; "Materiais são a única fonte" |
| SI-03 Copy e idioma | Inferencial | Vocabulário da persona e do glossário; mensagens de erro com "o que houve + como resolver"; mesmo termo para a mesma coisa; links com propósito claro; toda a copy no idioma do protótipo | Nielsen H2, H4, H9; WCAG 2.4.4, 2.4.6, 3.3.3 |
| SI-04 Cobertura do fluxo | Inferencial | Cada decisão e cada caminho de erro do fluxo tem representação navegável; início e fim corretos | Passo 2; Passo 4 item 2 |
| SI-05 Plataforma | Inferencial | Navegação, componentes e padrões de interação coerentes com a plataforma escolhida | Plataforma; Passo 2.1 |

## Como rodar os sensores computacionais

**Dependência:** Puppeteer, o mesmo que o harness já instala para o `validar-mermaid.ps1` (`cd scripts && npm install`). Não há dependência de Python nem de Playwright. Sem Puppeteer, **nenhum** SC-01 a SC-09 roda — o script avisa e sai com exit 2.

1. **Verifique o ambiente:**

```bash
node .claude/skills/create-prototype/sensores-prototipo.mjs --check
```

   - `AMBIENTE OK` (exit 0) → siga.
   - `AMBIENTE INCOMPLETO` (exit 2) → tente `cd scripts && npm install` e rode `--check` de novo. Se falhar, **avise o usuário na conversa antes de continuar** e registre no relatório que os sensores computacionais não rodaram (checagem manual de tudo).

2. **Rode sobre o rascunho** (`documentos/gerados/.rascunho-prototipo-[slug].html`), passando a lista de telas confirmada no Passo 3, o idioma e a plataforma:

```bash
node .claude/skills/create-prototype/sensores-prototipo.mjs documentos/gerados/.rascunho-prototipo-[slug].html --screens SCR-01,SCR-02 --lang pt-BR --platform web-responsive
# --platform: web-responsive | web-desktop | app (a escolha do Passo 2.1). Muda a largura testada e o alvo mínimo.
# --no-runtime pula SC-06 a SC-09 de propósito (o resultado sai como APROVADO PARCIAL)
```

3. **SC-10 — IDs de prototipação.** Com inventário de telas:

```bash
powershell -File scripts/validar-sequencia-id.ps1 -Telas -Arquivo documentos/gerados/.rascunho-prototipo-[slug].html -Inventario documentos/gerados/inventario-telas-[slug]-[data].md
```

   Sem inventário, omita `-Inventario` (o script valida só o protótipo).

4. **Leia o relatório:**

| Resultado | Exit | Significado |
|---|---|---|
| `APROVADO` | 0 | Todos os sensores rodaram, sem bloqueante |
| `APROVADO PARCIAL` | 2 | Sem bloqueante, mas SC-06 a SC-09 **não rodaram** (`--no-runtime`) — esses 4 pontos não foram verificados. Nunca trate como `APROVADO` |
| `REPROVADO` | 1 | Há bloqueante — entre no laço de correção |

## Como rodar os sensores inferenciais

Se a ferramenta de subagentes estiver disponível, delegue a avaliação a **um agente revisor separado**, passando: o HTML do protótipo, os materiais de base, a lista de telas confirmada, o idioma do protótipo e a rubrica abaixo. Peça o resultado **somente** no formato indicado. Se não houver subagente, faça você mesmo, seguindo a rubrica à risca, e registre no relatório que foi autoavaliação.

```
Você é revisor de UX e acessibilidade. Avalie o protótipo HTML anexado contra os materiais de base.
Não sugira redesign; aponte apenas problemas verificáveis, com evidência (ID da tela + elemento ou texto).

SI-01 Heurísticas de Nielsen — para cada tela, avalie as 10 heurísticas. Para cada violação, dê
      severidade na escala de Nielsen: 1 cosmético · 2 menor · 3 maior · 4 catástrofe.
SI-02 Fidelidade — liste tela, regra de negócio, campo ou texto que NÃO vem dos materiais e NÃO está
      marcado [a confirmar] ou [sugestão: Heurística N].
SI-03 Copy e idioma — vocabulário fora da persona/glossário, jargão técnico, mensagem de erro sem "como resolver",
      termos inconsistentes para a mesma coisa, link genérico ("clique aqui"), texto fora do idioma do protótipo.
SI-04 Cobertura do fluxo — decisão ou caminho de erro do fluxo sem representação navegável; início/fim errados.
SI-05 Plataforma — padrão de navegação ou componente incompatível com a plataforma escolhida
      (ex: menu web num app, tab bar num site desktop, hover como única forma de acesso num app).

Formato de saída (uma linha por achado, nada mais):
SI-0X | SEVERIDADE | SCR-XX | evidência | correção sugerida
SEVERIDADE = BLOQUEANTE (Nielsen 3–4, regra inventada, caminho do fluxo ausente, copy em idioma errado)
           | ALERTA (Nielsen 1–2, demais pontos de copy)
Se não houver achados num sensor: SI-0X | OK
```

## Laço de correção (obrigatório)

1. Rode SC e SI.
2. Corrija todos os **BLOQUEANTES** editando o **rascunho** (preserve IDs).
3. Rode de novo **apenas os sensores que falharam** e confirme que passaram — e rode SC completo uma última vez (correções podem quebrar outra coisa).
4. Repita até zerar bloqueantes, no máximo **3 rodadas**. Se depois disso ainda houver bloqueante, pare e leve ao PD no Passo 5 explicando o que não foi possível resolver e por quê.

**Exceções aceitas a um BLOQUEANTE** — só estas, e sempre registradas no relatório:

- Conflito com o Design System (ex: contraste de um token do DS sem alternativa) → marque `[a11y: a revisar]` no protótipo.
- Decisão de produto que só o PD pode tomar (ex: o fluxo não tem caminho de erro e não há material para inventar um) → marque `[a confirmar]`.
- Web não responsivo → SC-06 sai como `NÃO SE APLICA`; registre no relatório que WCAG 1.4.10 (Reflow) não é atendido por decisão de plataforma.
- Falso positivo do sensor → explique em uma linha por que não é problema (ex: "alvo de 20px, mas com 8px de espaçamento — atende a exceção de 2.5.8").

**Nunca altere o script (`sensores-prototipo.mjs`) nem a rubrica para fazer um sensor passar.**

## O que os sensores não cobrem

Continua como checagem do PD no Passo 5: experiência real com leitor de tela, qualidade do texto alternativo, se a cor sozinha transmite informação, e julgamento visual geral.
