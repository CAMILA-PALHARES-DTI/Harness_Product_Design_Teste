---
name: create-presentation
description: Cria uma apresentação sobre qualquer assunto do projeto — coleta o briefing (assunto, público, tom, profundidade, formato), consolida as informações dos guides relevantes da base de conhecimento, monta e valida um plano de slides com o usuário e só então gera o arquivo final no formato escolhido. Acione quando o usuário invocar /create-presentation ou pedir para criar, montar ou gerar uma apresentação (kickoff, status, riscos, roadmap etc.).
---

# create-presentation

> **Skill da Camada de Agentes**
> Esta skill é chamada quando o usuário quer criar uma apresentação sobre qualquer assunto do projeto. Ela coleta o briefing, consolida as informações dos guides relevantes, monta e valida um plano de slides com o usuário, e só então gera o arquivo final no formato escolhido.

---

## Quando usar esta skill

Use esta skill quando o usuário pedir para criar, montar ou gerar uma apresentação — independentemente do assunto, do público ou do formato final desejado.

| Exemplo de comando | O que a skill faz |
|---|---|
| `/create-presentation` | Inicia o briefing com perguntas |
| `/create-presentation kickoff` | Pula para perguntas sobre tom e profundidade, assunto já definido |
| `/create-presentation riscos para diretoria` | Pula assunto e público; pergunta tom, profundidade e formato |

---

## O que esta skill não faz

- Não inventa informações — usa apenas o que está nos guides de conhecimento ou o que o usuário fornecer explicitamente
- Não gera o arquivo final sem aprovação do plano de slides pelo usuário
- Não escolhe template visual sem perguntar ao usuário

---

## Passo a passo

### Passo 1 — Briefing

Faça todas as perguntas abaixo em **uma única mensagem**, de forma compacta:

```
Para montar sua apresentação, preciso de algumas informações:

1. **Assunto:** Sobre o que é a apresentação? (pode ser um tema livre ou um recorte do projeto)
2. **Tópicos principais:** Quais assuntos ou seções não podem faltar?
3. **Tom da comunicação:** Como você quer soar?
   → Exemplos: executivo e direto / técnico e detalhado / narrativo e persuasivo / neutro e informativo
4. **Profundidade:** Apresentação simples (poucos slides, direto ao ponto) ou completa (mais contexto, mais seções)?
5. **Formato de saída:** Como prefere receber a apresentação?
   → PPT (PowerPoint, usando template visual) / HTML (navegável, sem template) / outro formato
6. **Público-alvo:** Para quem é a apresentação? (diretoria, time técnico, cliente externo, etc.)
7. **Idioma da apresentação:** o mesmo idioma de resposta configurado no `CLAUDE.md`, ou outro (ex: cliente internacional)? Pergunte só se o público-alvo sugerir que pode ser diferente — o padrão é o idioma configurado.
```

Aguarde todas as respostas antes de avançar. Se o usuário já tiver fornecido alguma dessas informações no comando inicial, não repita a pergunta — use o que já foi dito.

---

### Passo 2 — Consolidação de informações

Com base no assunto e nos tópicos informados, leia os guides de conhecimento relevantes:

| Se o assunto envolver... | Leia estes guides |
|---|---|
| Contexto do produto, visão ou estratégia | `conhecimento/produto/contexto-de-negocio.md` |
| Pessoas, times ou stakeholders | `conhecimento/produto/mapa-stakeholders.md` |
| Problemas, dores ou riscos | `conhecimento/produto/dores-de-processo.md` |
| Fluxos, processos ou jornadas | `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md` |
| Reuniões, encaminhamentos ou histórico | `conhecimento/cliente/reunioes/index.md` |
| Decisões tomadas | `conhecimento/planejamento/decisoes-aprovadas.md` |
| Termos ou conceitos específicos | `conhecimento/produto/glossario.md` |

Se algum tópico solicitado não tiver cobertura nos guides, sinalize antes de montar o plano:

```
⚠️ Não encontrei informações sobre "[tópico]" nos arquivos do projeto.
Você pode:
- Fornecer as informações agora para eu incluir
- Deixar o bloco marcado como [a preencher] no plano
- Remover este tópico da apresentação
```

**Sensor de integridade antes de montar o plano:** liste os IDs (`DORxxx`, `DEPxxx`, `RISxxx`, `Dxxx`, `OKR-N`) que provavelmente serão citados nos slides, e acione a skill `check-integrity` restrita a esses IDs, sem perguntar antes de rodar — o objetivo é nunca deixar um slide (principalmente para cliente ou diretoria) repetir um status que já mudou desde que o item foi citado da última vez em algum outro arquivo. Se houver achado de severidade Alta ou Média, resolva-o (ou pelo menos sinalize ao usuário) antes de montar o plano de slides; se não houver nada, siga sem mencionar.

---

### Passo 3 — Plano de slides

Monte um plano estruturado com todos os slides da apresentação. Para cada slide, mostre:

- **Número e tipo** do slide (capa, seção, conteúdo, encerramento)
- **Título** do slide
- **Conteúdo proposto** — rascunho do que estará no slide (bullets, parágrafos curtos ou estrutura visual sugerida)
- **Fonte dos dados** — de qual guide veio a informação, ou "a preencher" se não há fonte

Formato de apresentação do plano:

```
## Plano de slides — [título da apresentação]

---

**Slide 1 — Capa**
Título: [título principal]
Subtítulo: [contexto — data, evento, público]

---

**Slide 2 — [Tipo: Conteúdo]**
Título: [título do slide]
Conteúdo:
- [bullet 1]
- [bullet 2]
- [bullet 3]
Fonte: conhecimento/produto/contexto-de-negocio.md

---

[...demais slides...]
```

**Regras de geração do plano:**
- Apresentações **simples:** máximo de 12 slides, no máximo 5 bullets por slide
- Apresentações **completas:** máximo de 20 slides, no máximo 6 bullets por slide
- Slides de seção não têm bullets — apenas título e subtítulo opcional
- Não repita a mesma informação em slides diferentes
- Priorize clareza sobre completude — menos e melhor

Ao final do plano, pergunte:

```
Este é o plano proposto. Você pode:
- Aprovar o plano e avançar para a criação
- Pedir ajuste em qualquer slide (título, conteúdo, ordem, remoção ou inclusão)
- Reorganizar seções inteiras

O que deseja alterar antes de gerar a apresentação?
```

Repita o ciclo de ajuste quantas vezes o usuário precisar. Só avance para o Passo 4 com aprovação explícita.

**Sensor de referência cruzada no plano aprovado:** salve o plano de slides aprovado em um arquivo temporário (ex: `documentos/gerados/.plano-temp-[slug]-[YYYY-MM-DD].md`) e rode `powershell -File scripts/validar-referencias.ps1 -Arquivo <caminho do arquivo temporário>` sobre ele — antes de gerar o PPT/HTML final, não depois. Isso vale para os dois formatos de saída (o PPT não é texto simples depois de gerado, então validar o plano markdown é o único jeito de checar isso também nesse caso). Se apontar algum ID citado (`DORxxx`/`DEPxxx`/`RISxxx`/`Dxxx`/`OKR-N`) que não existe em nenhum guide, corrija o plano antes de prosseguir — nunca gere o arquivo final com uma referência quebrada. Depois de validar, apague o arquivo temporário (ele não é um artefato do projeto, só um insumo do sensor).

---

### Passo 4 — Template visual (apenas para PPT)

Se o formato escolhido for **PPT**, pergunte:

```
Para o PowerPoint, você tem um template (.pptx) que quer usar como base?
- Se sim: informe o caminho ou nome do arquivo (modelos do time ficam em `documentos/apresentacoes/templates/`). Vou inspecionar os layouts disponíveis antes de gerar.
- Se não: vou usar os slides em branco do PowerPoint com formatação básica.
```

Se o formato for **HTML**, pule este passo — o HTML será gerado com estilo próprio.

Se o template for informado, inspecione os layouts disponíveis antes de gerar (slides de capa, seção e conteúdo) e confirme com o usuário quais layouts serão usados para cada tipo de slide.

---

### Passo 5 — Geração da apresentação

Com plano aprovado e template definido (se aplicável), gere a apresentação conforme o formato escolhido:

#### PPT

- Use PowerPoint COM via PowerShell
- Abra o template informado (ou crie uma nova apresentação em branco)
- Para cada slide do plano aprovado, duplique o layout correspondente e preencha os textos
- Delete os slides originais do template ao final
- Salve em: `documentos/apresentacoes/resultados/[nome-da-apresentacao].pptx`
- **Atenção:** caminhos com acentos devem ser tratados — copie o template para `C:\Temp\` antes de abrir via COM

#### HTML

- Gere um arquivo HTML único, autocontido (sem dependências externas)
- Use CSS inline ou `<style>` interno — sem CDN, sem fontes externas
- Inclua navegação entre seções (âncoras ou botões anterior/próximo)
- Salve em: `documentos/gerados/[nome-da-apresentacao].html`
- Abra o arquivo no navegador ao final para validação visual

#### Outros formatos

Se o usuário pedir um formato não coberto acima (ex: PDF, Markdown, Notion), pergunte se há uma ferramenta ou processo preferido antes de tentar gerar.

---

### Passo 6 — Entrega

Após gerar o arquivo, informe:

```
Apresentação gerada em: [caminho do arquivo]
[N] slides / seções criados

Pontos que ficaram marcados como [a preencher] e precisam de revisão manual:
- Slide [N]: [o que falta]

Deseja abrir o arquivo agora?
```

Se não houver campos pendentes, omita essa parte.

---

## Comportamentos esperados

- **Nunca avance para geração sem plano aprovado.** O plano é obrigatório — mesmo que o usuário peça para "ir direto".
- **Nunca invente conteúdo.** Se uma informação não está nos guides nem foi fornecida pelo usuário, marque como `[a preencher]`.
- **Adapte o volume ao tom.** Tom executivo = menos texto por slide. Tom técnico = pode ter mais detalhe.
- **Mantenha consistência visual.** Dentro de um mesmo formato, todos os slides de mesmo tipo devem seguir o mesmo padrão de estrutura e tamanho de texto.
- **Não repita o ciclo de perguntas.** Se o usuário já informou algo em conversa anterior, use o que foi dito — não pergunte de novo.
- **Sinalize ambiguidades antes de gerar.** Se o plano tiver um slide sobre algo que os guides cobrem de forma contraditória, sinaliza antes de montar o conteúdo.