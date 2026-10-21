---
name: interpret
description: Transforma notas estruturadas (output de /process-research-data) em relatório de pesquisa consolidado com análise temática, padrões comportamentais, insights e recomendações. Acione quando o usuário invocar /interpret ou quando indicar que quer analisar, consolidar ou gerar relatório de pesquisa a partir de notas já processadas.
---

# Interpretação e Análise de Dados de Pesquisa

Esta skill transforma notas estruturadas em um relatório de pesquisa com padrões, insights e recomendações acionáveis, a partir de análise qualitativa e quantitativa dos dados.

**Comunique no idioma de resposta configurado no `CLAUDE.md` (seção "Idioma"); se ainda estiver `[não configurado]`, pergunte antes de continuar.** Tom analítico, direto e orientado a decisões.

**Rótulos que os sensores leem:** títulos de seção, rótulos em linha, nomes de coluna e valores de frontmatter listados em `scripts/rotulos.txt` são escritos com o texto da coluna do idioma configurado (português ou inglês), exatamente como no dicionário e sem inventar variações — os sensores só reconhecem essas variantes. Rótulos que o `CLAUDE.md` mantém fixos (`Dado`/`Quando`/`Então`, `Cenário`, IDs, marcadores) não mudam de idioma.

---

## Princípio fundamental

Esta skill opera em modo de **análise e síntese**. Ao contrário da skill `/process-research-data`, aqui você deve:

- **Identificar padrões** que se repetem entre participantes ou sessões
- **Correlacionar** comportamentos, atitudes e contextos
- **Interpretar** o significado de achados à luz dos objetivos da pesquisa
- **Sintetizar** dados dispersos em insights coesos e acionáveis
- **Recomendar** ações baseadas em evidências

O que você **não deve** fazer:
- Inventar dados não presentes nas notas
- Generalizar além do que o escopo amostral permite
- Ocultar divergências, limitações ou lacunas

---

## Gatilho

Acionada em duas situações:

1. **Manual:** o usuário digita `/interpret`
2. **Contextual:** o usuário menciona "analisar notas", "gerar relatório", "consolidar pesquisa", "o que encontramos" após um ciclo de processamento

---

## Entradas esperadas

| Entrada | Localização | Obrigatoriedade |
|---|---|---|
| Notas estruturadas | `conhecimento/pesquisa/notas-estruturadas/` | Obrigatória |
| Plano de pesquisa | `conhecimento/pesquisa/planos/` | Recomendada |
| Contexto do projeto | `conhecimento/produto/` e `conhecimento/planejamento/` | Opcional |

Se não houver nenhuma nota estruturada disponível, informe o usuário e oriente a usar `/process-research-data` primeiro.

---

## Verificação inicial

Antes de iniciar a análise, execute os seguintes passos:

### 1. Listar notas disponíveis

Leia todos os arquivos em `conhecimento/pesquisa/notas-estruturadas/`. Para cada arquivo, extraia:
- Nome da pesquisa (campo **Pesquisa**)
- Método (campo **Método**)
- Participantes (campo **Participantes** — quantidade e identificadores)
- Temas identificados (lista dos títulos de tema)
- Divergências registradas (se houver)
- Lacunas do material (se houver)
- Notas sobre qualidade do material (se houver)

Apresente ao usuário a lista e confirme quais devem ser incluídas na análise. Se houver pesquisas diferentes misturadas no diretório, agrupe e pergunte qual analisar.

### 2. Verificar plano de pesquisa

Busque em `conhecimento/pesquisa/planos/` o plano correspondente. Se encontrar, extraia:
- Objetivo central da pesquisa
- Perguntas de pesquisa
- Hipóteses ou suposições iniciais

Se não encontrar, pergunte ao usuário: *"Não encontrei um plano de pesquisa associado. Qual era o objetivo central desta pesquisa?"*

### 3. Confirmar escopo

Informe ao usuário:
- Quantas sessões / participantes serão analisados
- O método identificado
- O modo de análise que será aplicado (ver próxima seção)

Aguarde confirmação antes de iniciar.

---

## Identificação do tipo de dado e modo de análise

Identifique o método a partir do campo **Método** nas notas estruturadas. Aplique o modo de análise correspondente:

### Entrevista em profundidade → Análise Temática + Narrativa

**Quando usar:** notas de entrevistas individuais com dados predominantemente qualitativos.

**O que fazer:**
1. Revise os temas já identificados pelo `/process-research-data` em cada nota. Consolide os que se repetem entre arquivos — um tema é forte quando aparece em múltiplas fontes com unidades de dado independentes
2. Para cada tema consolidado: some as frequências das notas de origem. Verifique se as citações preservadas sustentam a leitura interpretativa que você está construindo; avance além delas com interpretação — não apenas as repita
3. Analise as unidades classificadas como **Opinião / percepção** para identificar sentimentos e atitudes predominantes — positivos, negativos, ambivalentes — e em quais contextos eles emergem
4. Analise narrativas a partir das unidades de **Contexto** e **Necessidade declarada**: como os participantes constroem a história do problema ou da experiência? Quais elementos recorrentes aparecem?
5. Retome as **Divergências registradas** nas notas e aprofunde: são divergências de perfil, de contexto de uso, ou genuinamente contraditórias? Explique o que cada lado revela

### Teste de usabilidade → Análise de Tarefas + Comportamental

**Quando usar:** notas com registro de interação com produto, protótipo ou interface.

**O que fazer:**
1. Mapeie cada tarefa do protocolo e registre: foi completada? Com dificuldade? Abandonada? Use as unidades de **Comportamento observado** como base
2. Identifique os pontos de fricção a partir das unidades de **Dificuldade relatada** — consolide por frequência e avalie gravidade
3. Analise padrões de navegação a partir dos **Comportamentos observados**: houve caminhos alternativos não esperados? Atalhos? Erros sistemáticos?
4. Verifique se os comportamentos observados contradizem ou confirmam as **Necessidades declaradas** — essa tensão pode revelar o insight mais valioso
5. Avalie a severidade dos problemas encontrados: crítico (impede conclusão), moderado (causa esforço extra), cosmético (não afeta tarefa)

### Survey com questões abertas → Análise de Conteúdo + Frequência

**Quando usar:** notas com respostas de survey — especialmente campos abertos.

**O que fazer:**
1. Parta dos temas já agrupados pelo `/process-research-data`. Some as frequências entre arquivos e calcule a frequência relativa de cada tema (X de N respondentes)
2. Aprofunde os **Casos isolados** das notas: mesmo sem frequência, podem revelar segmentos específicos ou pontos cegos relevantes
3. Identifique co-ocorrências: quais categorias de unidades de dado (ex: Dificuldade relatada + Contexto) aparecem juntas nos mesmos temas?
4. Analise o tom predominante nas unidades de **Opinião / percepção**: positivo, negativo, neutro, misto — e em quais temas cada tom concentra
5. Retome as **Divergências registradas** nas notas: em surveys, divergências frequentemente indicam segmentos de público distintos, não apenas opiniões individuais

### Observação / Etnografia → Análise Comportamental + Contextual

**Quando usar:** notas de campo, diários de observação, protocolos de observação preenchidos.

**O que fazer:**
1. Mapeie a sequência de **Comportamentos observados** nos temas das notas, reconstituindo a lógica temporal da atividade
2. Identifique padrões de adaptação a partir dos comportamentos agrupados: workarounds, atalhos, comportamentos não esperados
3. Use as unidades de **Contexto** para analisar o papel do ambiente físico/digital nos comportamentos — o contexto facilita ou dificulta?
4. Some frequências de comportamentos específicos entre arquivos de notas diferentes (sessões ou participantes distintos)
5. Se houver dados de entrevista para cruzar: compare **Necessidade declarada** com **Comportamento observado** — o que as pessoas dizem que fazem versus o que realmente fazem é onde os insights mais valiosos costumam estar

### Grupo focal → Análise de Discurso + Dinâmica de Grupo

**Quando usar:** notas de sessões com múltiplos participantes simultâneos.

**O que fazer:**
1. Parta dos temas já identificados pelo `/process-research-data` e analise como cada um evoluiu ao longo da sessão
2. Use as **Divergências registradas** nas notas como ponto de partida para identificar dissensos — aprofunde o que cada lado revela sobre o grupo
3. Observe dinâmicas de influência a partir dos **Casos isolados**: visões que aparecem apenas uma vez podem indicar silenciamento de minorias ou perspectivas contra-intuitivas
4. Analise o vocabulário compartilhado nas unidades de **Opinião / percepção**: quais termos o grupo usou para descrever o problema ou a solução?
5. Nas unidades de **Comportamento observado** e **Necessidade declarada**, separe o que foi dito como experiência pessoal do que foi generalizado para outros ("eu acho que todo mundo...")

### Métodos mistos → Triangulação

**Quando usar:** há notas de mais de um método (ex: entrevistas + survey, ou entrevistas + teste de usabilidade).

**O que fazer:**
1. Analise cada fonte de dados com seu modo específico (acima)
2. Na síntese, triangule: os achados se confirmam entre os métodos? Onde há contradição?
3. Dê mais peso às evidências que aparecem em múltiplas fontes
4. Seja explícito quando um achado vem de apenas uma fonte de dados

---

## Passos de execução

1. **Verificação inicial** — listar notas, plano, confirmar escopo com o usuário
2. **Leitura completa** — ler todas as notas selecionadas antes de começar a análise
3. **Identificar modo de análise** — conforme seção anterior
4. **Consolidar mapa temático** — as notas já chegam agrupadas por tema. Consolide os temas que se repetem entre arquivos diferentes, unifique nomenclaturas próximas e identifique conexões entre temas. Mostre o mapa consolidado ao usuário e pergunte se faltou algum ângulo importante
5. **Executar a análise** — aplicar o modo correspondente com profundidade
6. **Redigir o relatório** — no formato abaixo
7. **Salvar em** `conhecimento/pesquisa/relatorios/` com o nome padronizado
7.5. **Sensor de link:** rodar `powershell -File scripts/validar-links-frontmatter.ps1 -Arquivo <caminho do relatório>` — confere se `notas-origem` e `plano-pesquisa` no frontmatter apontam para arquivos que realmente existem. Corrigir antes de seguir para o próximo passo.
8. **Atualizar o índice** em `conhecimento/pesquisa/relatorios/index.md`
9. **Avaliar necessidade de mapa de fluxo** — ver seção "Acionamento automático de /flow-mapping" abaixo
10. **Confirmar ao usuário** e orientar próximos passos

---

## Acionamento automático de /flow-mapping

Depois de salvar o relatório, avalie se um mapa de fluxo ajudaria a comunicar os achados. Acione a skill `/flow-mapping` automaticamente, **sem perguntar ao usuário**, apenas quando todos os critérios abaixo forem atendidos:

- O método da pesquisa é teste de usabilidade, observação/etnografia, ou métodos mistos que incluem um destes; **e**
- A seção **Padrões Comportamentais** do relatório foi preenchida (não omitida); **e**
- Os achados descrevem uma sequência de passos, telas ou decisões — não apenas comportamentos pontuais isolados

Se os critérios forem atendidos, invoque `/flow-mapping` usando o relatório recém-salvo como fonte, sempre no modo **fluxo existente** — a skill pula a etapa de confirmação de modo nesse caso. Se não forem atendidos, não acione a skill.

---

## Formato do relatório

Nome do arquivo: `relatorio-[nome-pesquisa]-[YYYY-MM-DD].md`

```markdown
---
tipo: relatorio-de-pesquisa
pesquisa: [nome da demanda ou projeto]
metodos: [lista dos métodos utilizados]
periodo-coleta: [YYYY-MM-DD a YYYY-MM-DD]
participantes-analisados: [N participantes — lista de códigos]
gerado-em: [YYYY-MM-DD]
notas-origem: [lista dos arquivos em notas-estruturadas/]
plano-pesquisa: [caminho do arquivo de plano, se existir]
---

# Relatório de Pesquisa — [Nome da Pesquisa]

---

## Objetivo da Pesquisa

[Objetivo central recuperado do plano, ou informado pelo usuário. Se havia perguntas de pesquisa específicas, liste-as aqui para que o relatório possa ser lido como resposta a elas.]

---

## Resumo Executivo

[3 a 5 parágrafos. Descreva: o que foi pesquisado, com quem, de que forma. Quais foram os principais achados. Quais implicações eles têm para o produto ou decisão. Escreva para quem não vai ler o relatório inteiro — este resumo precisa ser suficiente para orientar uma decisão.]

---

## Achados

[Organize por tema (entrevistas, surveys, observação) ou por tarefa (testes de usabilidade). Cada achado deve ter: evidência + frequência + interpretação.]

### [Tema / Tarefa / Categoria]

**Em uma frase:** [declaração sintética do achado — o que os dados dizem sobre este tema]

**Frequência:** [X de N participantes; ou: observado em todas as sessões; ou: 40% das respostas]

**Evidências:**
> "[Citação direta mais representativa]" — P0X

> "[Segunda citação, se relevante]" — P0X

**Paráfrase:** [o que esse conjunto de dados diz, em linguagem interpretativa — não repita as citações, avance além delas]

**Convergências:** [o que a maioria concorda ou demonstra]

**Divergências / Exceções:** [quem discorda, em qual contexto, e por quê isso importa]

[Repita a estrutura para cada tema / tarefa]

---

## Padrões Comportamentais

[Preencha quando houver dados de observação ou teste de usabilidade. Descreva padrões de ação, navegação, erros recorrentes, workarounds. Se não houver dados comportamentais, omita esta seção.]

---

## Sentimentos e Atitudes

[Mapa de sentimentos identificados nos dados: quais emoções emergiram, em quais contextos, com qual frequência. Pode ser uma lista por contexto ou uma narrativa breve. Útil especialmente em entrevistas e grupos focais.]

---

## Lacunas e Limitações

[Incorpore as **Lacunas do material** e **Notas sobre qualidade do material** das notas estruturadas — elas já estão identificadas pelo /process-research-data e devem aparecer aqui com avaliação do impacto na confiabilidade dos achados. Acrescente: o que não foi possível concluir com os dados disponíveis, vieses potenciais (perfil de amostra, viés do facilitador, contexto de coleta) e perguntas que ficaram em aberto. Seja honesto — isso protege quem vai usar o relatório.]

---

## Recomendações

[Ordene da mais urgente / impactante para a menos. Cada recomendação deve ser rastreável a um achado.]

### R1: [Título da recomendação]

**Achado de base:** [referência ao tema ou achado que justifica esta recomendação]
**Ação sugerida:** [o que o time deve fazer — seja específico o suficiente para ser acionável]
**Impacto esperado:** [o que muda para o usuário ou para o produto se a recomendação for implementada]
**Prioridade:** [Alta / Média / Baixa — justifique brevemente]

[Repita para cada recomendação]

---

## Perguntas em Aberto

[Questões que surgiram durante a análise e que não eram objeto desta pesquisa, mas que merecem investigação futura. Pode ser uma lista simples.]

---

## Próximos Passos Sugeridos

[2 a 4 ações concretas que o time pode tomar a partir deste relatório — ex: validar hipótese X com um teste A/B, investigar tema Y em próxima rodada, apresentar achado Z para stakeholder específico.]
```

---

## Diretrizes de comportamento

- **Âncora nas evidências:** todo insight deve ter pelo menos uma citação ou dado de suporte explícito nas notas estruturadas. Não extrapole além do que os dados sustentam.
- **Frequência é dado:** sempre que possível, informe quantos participantes demonstraram cada padrão. "A maioria" sem número é fraco; "7 de 9 participantes" é evidência.
- **Divergência é dado:** se apenas 1 de 8 participantes mencionou algo, mas é relevante, registre como exceção — não suprima. Exceções podem ser os insights mais valiosos.
- **Separe achado de recomendação:** a seção de achados descreve o que os dados revelam; a seção de recomendações diz o que fazer. Não misture.
- **Respeite o escopo amostral:** N pequeno (< 5) impede generalização. Sinalize isso nas limitações, especialmente para surveys.
- **Preserve a voz dos participantes:** citações diretas devem aparecer no relatório exatamente como nas notas — não reescreva para soar mais formal.
- **Mostre o mapa temático antes de redigir:** antes de escrever o relatório completo, apresente os temas identificados e confirme com o usuário. Isso evita retrabalho.
- **Um relatório por pesquisa:** não consolide pesquisas de projetos diferentes em um único arquivo.

---

## Orientação ao final

Após salvar o relatório, informe o usuário:

> **Análise concluída.**
> - Relatório salvo em `conhecimento/pesquisa/relatorios/[nome-do-arquivo].md`
> - [N] participantes / sessões analisados
> - [N] achados identificados, [N] recomendações geradas
> - [Se `/flow-mapping` foi acionada:] Mapa de fluxo salvo em `conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/existentes/[nome-do-arquivo].md`
>
> **Próximos passos sugeridos:**
> - [Se `/flow-mapping` foi acionada:] A skill sugere incorporar o fluxo ao catálogo `fluxos-e-jornadas.md` para ganhar um ID (FLXxxx) — responda à pergunta dela
> - Se os achados revelarem informação nova sobre personas, dores do processo ou métricas de uso, registre-as permanentemente na base de conhecimento com `/insert-knowledge`
> - Compartilhe o relatório com os stakeholders usando a skill `/create-presentation`
> - Se houver perguntas em aberto que justifiquem nova rodada, use `/plan-research`
> - Se algum achado precisar virar especificação ou story, use `/intent`
> - Se os achados descrevem uma jornada ou fluxo de navegação e nenhum mapa foi gerado automaticamente, use `/flow-mapping` manualmente
