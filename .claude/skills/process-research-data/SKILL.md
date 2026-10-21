---
name: process-research-data
description: Transforma dados brutos de pesquisa (transcrições, anotações de notetaker, respostas de survey, notas de campo) em notas estruturadas por tema, com unidades de dado classificadas, citações preservadas e divergências registradas. Acione sempre que o usuário invocar /process-research-data OU quando detectar que o usuário enviou dados brutos de pesquisa — transcrições com turnos de fala (E:/P:, Moderador:/Participante:, blocos de texto com perguntas e respostas), anotações de campo coladas no chat, planilhas com respostas abertas, ou frases como "aqui está a transcrição", "processa isso", "vou colar a entrevista". Esta skill extrai e organiza o que foi dito com fidelidade máxima ao material original, SEM interpretar, concluir ou gerar insights.
---

# Processamento de Dados Brutos de Pesquisa

Esta skill transforma dados brutos de pesquisa em notas estruturadas, organizadas por temas emergentes — com unidades de dado classificadas, citações preservadas e divergências registradas — sem análise, sem interpretação, sem insights.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom direto e técnico.

**Rótulos que os sensores leem:** títulos de seção, rótulos em linha, nomes de coluna e valores de frontmatter listados em `scripts/rotulos.txt` são escritos com o texto da coluna do idioma configurado (português ou inglês), exatamente como no dicionário e sem inventar variações — os sensores só reconhecem essas variantes. Rótulos que o `CLAUDE.md` mantém fixos (`Dado`/`Quando`/`Então`, `Cenário`, IDs, marcadores) não mudam de idioma.

---

## Princípio fundamental

Esta skill opera em modo de **extração e organização fiel**. Isso significa:

- **Extraia** unidades de dado individuais — comportamentos, dificuldades, necessidades, opiniões, contextos
- **Classifique** cada unidade em uma das cinco categorias (ver abaixo)
- **Preserve** citações diretas com atribuição ao participante
- **Agrupe** por temas que emergem do material — nunca force categorias pré-definidas
- **Registre** divergências entre participantes sem resolvê-las
- **Sinalize** lacunas quando tópicos esperados não aparecem no material
- **Não interprete** o que o participante quis dizer além do que disse
- **Não julgue** se uma resposta é boa, ruim, esperada ou surpreendente
- **Não gere** insights, hipóteses ou recomendações

Se algo for ambíguo nos dados, registre a ambiguidade — não resolva com interpretação.

A etapa de análise e geração de insights pertence à skill `/interpret`, que opera sobre as notas estruturadas geradas aqui.

---

## Gatilho

Esta skill é acionada em duas situações:

1. **Manual:** o usuário digita `/process-research-data`
2. **Automático:** detecte dados brutos de pesquisa sendo enviados. Sinais de identificação:
   - Texto com turnos de fala (E:/P:, Moderador:/Participante:, nomes seguidos de dois-pontos)
   - Blocos longos com perguntas e respostas em sequência
   - Frase introdutória como "aqui está a transcrição", "vou colar a entrevista", "processa isso", "aqui estão as notas"
   - Conteúdo com aparência de anotações de campo ou respostas abertas de survey
   - Arquivo compartilhado com extensão sugestiva (.docx, .txt, .csv) e contexto de pesquisa

Quando detectar acionamento automático, confirme antes de processar: *"Percebi que você compartilhou dados brutos de pesquisa. Posso processar agora e gerar as notas estruturadas?"*

---

## Entradas esperadas

A skill aceita qualquer um dos seguintes formatos:

| Tipo | Observação |
|---|---|
| Transcrição com falantes identificados | `[Entrevistador]` / `[P1]` etc. — formato ideal |
| Transcrição sem identificação de falantes | Processar com cautela — sinalizar ambiguidades de atribuição |
| Anotações de notetaker | Distinguir o que foi observado do que foi interpretado pelo notetaker |
| Respostas de survey | Indicar a pergunta que originou cada resposta |
| Notas de campo e observação | Separar o que foi visto do que foi ouvido |
| Síntese humana | Sinalizar que é uma camada de interpretação, não dado bruto |
| Gravação processada por IA | Transcrição gerada por ferramenta (ex: Otter, Fireflies) |

O usuário pode enviar os dados colados diretamente no chat ou indicar o caminho do arquivo em `conhecimento/pesquisa/coleta/`.

---

## Verificação de metadados

Antes de processar, verifique se as informações abaixo estão disponíveis. Se estiverem faltando, pergunte — no máximo 3 por vez:

- **Nome da pesquisa ou demanda** — para nomear e salvar o arquivo corretamente
- **Método utilizado** — entrevista, teste de usabilidade, observação, survey, grupo focal, etc.
- **Participantes** — quantidade e identificadores usados (nunca nomes reais)
- **Contexto da pesquisa** — objetivo e perfil dos participantes, se disponível (afeta o que é relevante extrair)
- **Arquivo de origem** — nome do arquivo bruto em `conhecimento/pesquisa/coleta/`, se existir

Se o usuário não souber algum item, use um placeholder entre colchetes (ex: `[objetivo não informado]`) e siga o processamento.

### Anonimização

Se os dados brutos contiverem nomes reais de participantes, avise o usuário:

> "Os dados contêm nomes reais (ex: 'João disse que...'). Recomendo substituí-los por códigos (P1, P2) nas notas estruturadas para proteger a identidade dos participantes. Posso fazer isso automaticamente — confirma?"

---

## Passos de execução

1. **Identificar o tipo e qualidade do material** — bruto ou já editado? falantes identificados? contexto de pesquisa disponível?
2. **Verificar metadados** — perguntar o que estiver faltando (máx. 3 por vez)
3. **Verificar anonimização** — alertar se houver nomes reais e confirmar como proceder
4. **Salvar o dado bruto** em `conhecimento/pesquisa/coleta/` antes de qualquer processamento (ver convenção abaixo)
5. **Extrair unidades de dado** — uma observação atômica por unidade, classificada em uma das cinco categorias
6. **Preservar citações** — para cada unidade significativa, extrair citação direta atribuída ao participante
7. **Agrupar por temas emergentes** — um tema é válido quando ao menos duas unidades independentes apontam para ele
8. **Registrar casos isolados** — unidades sem correspondência entre participantes, listadas separadamente
9. **Registrar divergências** — quando participantes expressam visões opostas sobre o mesmo ponto
10. **Sinalizar lacunas** — tópicos que deveriam ter aparecido mas não aparecem no material
11. **Gerar o arquivo de notas estruturadas** no formato abaixo, referenciando o arquivo de coleta
12. **Salvar em** `conhecimento/pesquisa/notas-estruturadas/` com o nome padronizado
13. **Atualizar os índices** — adicione uma linha em `conhecimento/pesquisa/coleta/index.md` (para o dado bruto) e em `conhecimento/pesquisa/notas-estruturadas/index.md` (para as notas geradas)
14. **Confirmar ao usuário** o que foi salvo, com os caminhos de ambos os arquivos
15. **Orientar o próximo passo** no fluxo de pesquisa

Se o usuário enviou múltiplos participantes ou sessões em um único bloco de dados, informe quantos arquivos serão gerados antes de começar e aguarde confirmação.

### Convenção de nome para arquivos

- **Coleta (dado bruto):** `bruto-[nome-pesquisa]-[YYYY-MM-DD].[extensão]`
- **Notas estruturadas:** `notas-[nome-pesquisa]-[YYYY-MM-DD].md`
- Dados colados no chat → salvar como `.md` preservando o conteúdo exato, sem modificação
- Se o dado ainda não estiver anonimizado, salvar somente após aprovação do usuário (passo 3)

---

## Categorias de classificação das unidades de dado

Classifique cada unidade em uma das cinco categorias:

| Categoria | O que registrar |
|---|---|
| **Comportamento observado** | O que o participante faz ou fez — relatado ou observado diretamente |
| **Dificuldade relatada** | O que o participante identifica como problema ou obstáculo |
| **Necessidade declarada** | O que o participante diz que precisa ou quer |
| **Opinião / percepção** | Avaliação subjetiva do participante sobre algo |
| **Contexto** | Informação sobre o ambiente, rotina ou situação do participante |

---

## Regras de extração por tipo de dado

### Transcrições de entrevista ou teste de usabilidade

- Preserve turnos de fala com o identificador original (E/P, Moderador/Participante, ou código)
- Extraia unidades de dado das falas do participante — não do entrevistador
- Registre comportamentos não-verbais (hesitação, riso, silêncio prolongado) como **Comportamento observado**, sem atribuir significado
- Registre perguntas que ficaram sem resposta, respostas truncadas ou trechos inaudíveis como lacunas

### Anotações de notetaker

- Preserve a voz e o vocabulário do notetaker
- Não corrija ou suavize anotações incompletas — registre como estão
- Separe claramente o que o notetaker observou do que interpretou (sinalize: `[nota do notetaker — possível interpretação]`)
- Se houver timestamps, preserve-os

### Respostas de survey

- Transcreva cada resposta na íntegra, associada ao identificador do respondente
- Indique a pergunta que originou cada resposta
- Não reformule respostas gramaticalmente incorretas — preserve o texto original
- Registre respostas em branco ou "não sei" como dados válidos

### Notas de campo e observação

- Preserve a sequência temporal das observações
- Separe o que foi visto do que foi ouvido
- Registre o ambiente e o contexto físico/digital conforme descrito
- Não interprete reações — registre-as (ex: "participante parou de falar por 5 segundos", não "participante ficou confuso")

### Síntese humana (material já interpretado)

- Sinalize no output que o dado passou por uma camada de interpretação humana antes de chegar à skill
- Isso afeta o grau de certeza da interpretação subsequente — registre nas notas de qualidade do material

---

## Formato das notas estruturadas

Nome do arquivo: `notas-[nome-pesquisa]-[YYYY-MM-DD].md`

```markdown
---
tipo: notas-estruturadas
pesquisa: [nome da demanda ou projeto]
metodo: [entrevista / teste de usabilidade / observação / survey / etc.]
participantes: [quantidade e identificadores — ex: P1 a P5]
contexto-da-pesquisa: [objetivo e perfil dos participantes, se fornecido]
arquivo-origem: [caminho em conhecimento/pesquisa/coleta/, se existir]
processado-em: [YYYY-MM-DD]
---

# Notas Estruturadas — [Método] | [Nome da Pesquisa]

---

## Temas identificados

### [Nome do tema]
- **Frequência:** [quantos participantes trouxeram este tema]
- **Unidades de dado:**
  - [Categoria] — [descrição da observação] *(P1: "citação direta relevante")*
  - [Categoria] — [descrição da observação] *(P3: "citação direta relevante")*

### [Próximo tema]
...

---

## Casos isolados

- [Categoria] — [descrição] *(P2: "citação")* — apareceu apenas em P2, sem correspondência nos demais

---

## Divergências registradas

- **[Ponto de divergência]:** P1 relata [X] *("citação")*; P4 relata o oposto [Y] *("citação")*

---

## Lacunas do material

- [Tópico ausente] — não apareceu no material; pode indicar que não foi abordado na pesquisa, que o material está incompleto, ou que o tema genuinamente não emergiu

---

## Notas sobre qualidade do material

- [Observações sobre limitações, vieses aparentes, ambiguidades de atribuição, ou características do material que afetam a confiabilidade das notas]
```

---

## Orientação ao final

Após salvar os arquivos, informe o usuário:

> **Processamento concluído.**
> - Dado(s) bruto(s) salvo(s) em `conhecimento/pesquisa/coleta/` (índice atualizado)
> - Notas estruturadas salvas em `conhecimento/pesquisa/notas-estruturadas/` (índice atualizado)
>
> **Próximo passo:** Utilize a skill `/interpret` para transformar as notas estruturadas em um relatório de pesquisa com padrões, insights e recomendações.

---

## Diretrizes de comportamento

- **Preserve a voz dos participantes:** citações devem ser transcritas com fidelidade, incluindo erros gramaticais, expressões coloquiais e repetições.
- **Temas emergem do material:** agrupe somente o que aparecer em ao menos duas unidades de dado independentes. Casos com menos evidência vão para "Casos isolados".
- **Não resolva divergências:** quando participantes expressarem visões opostas, preserve os dois lados — não tente conciliar.
- **Sinalize ativamente o que não está claro:** ambiguidades de atribuição, trechos inaudíveis ou contraditórios devem aparecer nas notas de qualidade do material.
- **Não antecipe a análise:** mesmo que padrões sejam evidentes, não os interprete durante o processamento. O lugar dos insights é na skill `/interpret`.
- **Alerte sobre PII:** qualquer dado que identifique um participante (nome, empresa, cargo específico) deve ser anonimizado antes ou durante o processamento, com aprovação do usuário.
- **Material já interpretado:** se o input for uma síntese escrita por um pesquisador, sinalize isso nas notas de qualidade — o dado passou por uma camada de interpretação antes de chegar à skill.
