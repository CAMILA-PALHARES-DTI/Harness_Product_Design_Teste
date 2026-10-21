# Harness de Produto e Design

Ambiente de trabalho estruturado para times de produto, design e pesquisa da dti digital. Organiza o conhecimento do projeto e fornece skills que guiam o processo de descoberta, planejamento, pesquisa e entrega diretamente no Claude Code.

---

## O que é um harness

Um harness é um projeto Claude Code configurado com skills, base de conhecimento e convenções específicas para um domínio de trabalho. Ao abrir este repositório no Claude Code, o assistente passa a operar dentro desse contexto — usando os arquivos de conhecimento como fonte de verdade e as skills como fluxos de trabalho guiados.

---

## Pré-requisitos

- [Claude Code](https://claude.ai/code) instalado
- Acesso ao repositório com permissão de leitura e escrita
- Abrir a pasta raiz deste repositório como projeto no Claude Code
- [Node.js](https://nodejs.org/) instalado, se for usar o sensor de validação de diagramas Mermaid (`scripts/validar-mermaid.ps1`) ou os sensores do protótipo (`/create-prototype`)
- **Python 3** e **bash** — os hooks (`.claude/hooks/` e `validar-output.sh` das skills) usam os dois. No macOS o bash e o `git` vêm com o sistema, e o `python3` vem com as Command Line Tools (`xcode-select --install`).
- **PowerShell** — os sensores em `scripts/*.ps1` rodam em PowerShell. No **Windows** o Windows PowerShell 5.1 (`powershell`) já vem instalado. No **macOS/Linux** instale o PowerShell 7 (`brew install --cask powershell`, que fornece o comando `pwsh`) e, onde este repositório e as skills dizem `powershell -File scripts/...`, use `pwsh -File scripts/...`. Os hooks já escolhem sozinhos entre `powershell` e `pwsh`.

> **macOS/Linux:** o harness foi escrito no Windows. Os sensores `.ps1` e os hooks foram ajustados para caminhos e comandos portáveis, mas só foram executados no Windows — se algum sensor se comportar diferente no seu sistema, avise o time.

---

## Primeiros passos (novo time/cliente)

Este repositório é uma estrutura base — a base de conhecimento (`conhecimento/`) já vem vazia (só esqueleto/template), pronta para o seu time preencher com o contexto do cliente/projeto que vocês atendem. Ao copiar este repositório para começar um novo projeto:

1. **Preencha o `CLAUDE.md`** — troque `[NOME DO PROJETO/CLIENTE]` pelo nome real do projeto, e a seção "Aplicações do ecossistema [NOME DO ECOSSISTEMA/CLIENTE]" pela descrição real das aplicações que o time atende (ou remova a seção se não fizer sentido para o seu contexto).
2. **Idioma de resposta** — não precisa editar nada: na primeira conversa o agente pergunta em qual idioma responder e grava a escolha na seção "Idioma" do `CLAUDE.md`. Para trocar depois, peça ao agente ou edite essa linha.
3. **Preencha os metadados de `conhecimento/produto/contexto-de-negocio.md` e `glossario.md`** — cliente, produtos geridos, time responsável. Esses dois arquivos são lidos em toda tarefa.
4. **(Opcional) Conecte o board do time** — o harness funciona sem isso: `define-deliverables` e `create-spec` só leem ou criam itens no board se houver um MCP conectado na sessão, e nunca escrevem sem a sua confirmação; sem MCP, geram só o markdown (ou pedem que você cole a lista do backlog). Para conectar, copie `.mcp.json.example` para `.mcp.json` (arquivo que o Claude Code lê; cada projeto faz commit do seu), troque `[nome-da-organizacao-azure-devops]` pelo nome real da organização e defina o token na variável de ambiente `AZURE_DEVOPS_PAT_B64` — **nunca grave o token no arquivo**. Se o time usa Jira, Linear ou outra ferramenta, não use o exemplo: conecte o MCP ou o conector oficial dela, seguindo a documentação atual do fornecedor. Sem board conectado, não crie o `.mcp.json`: um servidor com placeholder só gera erro de conexão a cada sessão.
5. **Instale as dependências dos sensores computacionais:**

   ```sh
   cd scripts
   npm install
   ```

   Necessário para o sensor de Mermaid (`validar-mermaid.ps1`) e para os sensores de runtime do protótipo (`.claude/skills/create-prototype/sensores-prototipo.mjs`, reflow, contraste, alvo e foco), ambos via Puppeteer; os demais sensores (`.ps1`) não têm dependência externa. Confirme com `node .claude/skills/create-prototype/sensores-prototipo.mjs --check`.
6. **Rode a validação inicial do índice** para confirmar que a estrutura vazia está íntegra:

   ```sh
   powershell -File scripts/validar-indice.ps1 -Todos
   powershell -File scripts/gerar-indice-geral.ps1
   ```

7. **Em dúvida sobre por onde começar, invoque `/process-guide`** — ela lê a base, situa a fase do processo em que você está e recomenda os próximos passos, indicando qual skill usar em cada um. Depois, use as skills normalmente — a primeira execução de `insert-knowledge`, `define-okrs` etc. começa a popular a base.

---

## Fluxo de pesquisa

As skills de pesquisa seguem uma sequência. Cada etapa produz o insumo da próxima:

```
/plan-research   → define objetivo, método e perguntas de pesquisa
/create-artifacts     → gera roteiro, screener, TCLE e guia de facilitação
(coleta com os participantes, feita fora do harness)
/process-research-data           → salva o dado bruto (transcrições, notas, respostas) e gera notas estruturadas por tema
/interpret         → transforma notas estruturadas em relatório com insights e recomendações
```

---

## Skills disponíveis

Para invocar uma skill, digite o comando correspondente no chat do Claude Code.

<!-- SKILLS_TABLE_START -->
| Comando | Descrição |
|---|---|
| `/audit-spec` | Audita a qualidade e a completude de uma especificação de desenvolvimento (Specs com suas US) já gerada pela skill `create-spec`, verificando cobertura em categorias que a geração original não teve como objetivo cobrir a fundo — atributos não-funcionais (performance, segurança, observabilidade, compliance), referências de design/Figma por tela e estado, terminologia consistente com o glossário, testabilidade do critério de aceite, adjetivos vagos sem quantificação e tradeoffs não registrados. |
| `/check-integrity` | Audita a integridade de citações de IDs (DORxxx, DEPxxx, RISxxx, Dxxx, OKR-N) em toda a base de conhecimento — não confere se o ID existe apenas, confere se o que outros arquivos dizem sobre ele (status, título) ainda bate com a fonte de verdade no guide de origem. |
| `/create-artifacts` | Gera artefatos operacionais de pesquisa (roteiro de entrevista, screener, TCLE, guia de facilitação, survey, protocolo de observação) com base no plano de pesquisa mais recente e no contexto do projeto. |
| `/create-presentation` | Cria uma apresentação sobre qualquer assunto do projeto — coleta o briefing (assunto, público, tom, profundidade, formato), consolida as informações dos guides relevantes da base de conhecimento, monta e valida um plano de slides com o usuário e só então gera o arquivo final no formato escolhido. |
| `/create-prototype` | Gera um protótipo navegável em um único arquivo HTML a partir dos artefatos da feature, de preferência o briefing do /intent, o fluxo do /flow-mapping e o inventário de telas do /screen-planner, mas aceita qualquer outro material de base (PRD, user stories, rascunhos, prints, anotações). |
| `/create-roadmap` | Monta o sequenciamento no tempo de um projeto — no nível macro (próximos passos, sem backlog fechado) ou micro (algo já priorizado, com datas e estimativas), com visão visual (Mermaid ou HTML interativo) sob demanda. |
| `/create-spec` | Gera a especificação de desenvolvimento de uma feature (Specs com User Stories), agrupando várias User Stories em Specs do tamanho de uma entrega de desenvolvimento (feature-sized), a partir do briefing funcional da feature — com ou sem protótipo/artefato visual. |
| `/define-deliverables` | Quebra um direcionador maior já definido (roadmap macro, OKR, épico) nos itens de trabalho necessários para cumpri-lo — por nome e uma descrição de uma frase, sem refinar. |
| `/define-okrs` | Gera OKRs (objetivos e key results) para um ciclo específico do projeto, a partir das dores de processo, contexto de negócio, decisões aprovadas, riscos e dependências da base de conhecimento. |
| `/flow-mapping` | Transforma documentação, achados de pesquisa, requisitos ou regras de negócio em diagramas de fluxo de usuário no formato Mermaid. |
| `/insert-knowledge` | Absorve conteúdo bruto sobre o projeto (atas e resumos de reuniões, ações pendentes, briefings, anotações, descrições de produto, informações sobre stakeholders, decisões, dependências e riscos), identifica o que é relevante para cada guide da base de conhecimento e gera os blocos formatados para o usuário confirmar antes de salvar. |
| `/intent` | Gera a especificação funcional (briefing) de uma feature a partir do que já foi decidido/discutido em reuniões, decisões aprovadas e demais fontes da base — detalhando regras, comportamentos e necessidades com nível de profundidade suficiente para servir de base à construção de protótipos visuais. |
| `/interpret` | Transforma notas estruturadas (output de /process-research-data) em relatório de pesquisa consolidado com análise temática, padrões comportamentais, insights e recomendações. |
| `/plan-research` | Assistente de planejamento de pesquisa de UX para times de produto da dti digital — guia a conversa, classifica a pesquisa (generativa, avaliativa ou discovery contínuo), recomenda métodos do catálogo e gera o plano em conhecimento/pesquisa/planos/. |
| `/prioritize-deliverables` | Ajuda a priorizar entregáveis, features ou um recorte de MVP usando frameworks de priorização (RICE, MoSCoW, Valor x Esforço, Kano, WSJF/Custo do Atraso), apoiado em dados de uso, severidade de dores mapeadas e risco. |
| `/process-guide` | Orienta pessoas de produto e design que não sabem o que fazer em determinado momento do desenvolvimento de uma solução digital dentro do harness. |
| `/process-research-data` | Transforma dados brutos de pesquisa (transcrições, anotações de notetaker, respostas de survey, notas de campo) em notas estruturadas por tema, com unidades de dado classificadas, citações preservadas e divergências registradas. |
| `/screen-planner` | Etapa OPCIONAL que transforma um user flow aprovado (mais briefing do /intent e US, se houver) em um inventário de telas que alimenta a prototipação, do fluxo inteiro ou só das telas que vão ter protótipo, podendo ser pulada indo direto para /create-prototype. |
<!-- SKILLS_TABLE_END -->

---

## Base de conhecimento

Os arquivos em `conhecimento/` são a memória do projeto. O Claude Code os consulta antes de responder sobre o contexto do projeto.

```
conhecimento/
  produto/         — contexto de negócio, personas, fluxos, regras, métricas
  cliente/         — registros de reuniões com o cliente
  planejamento/    — OKRs, backlog, roadmap, especificação do projeto
  desenvolvimento/ — user flows e specs técnicas
  pesquisa/
    planos/              — documentos gerados por /plan-research
    artefatos/           — roteiros, screeners, TCLEs e guias gerados por /create-artifacts
    coleta/              — dados brutos de pesquisa salvos por /process-research-data
    notas-estruturadas/  — notas processadas por /process-research-data
    relatorios/          — relatórios gerados por /interpret
```

Toda pasta acima (e cada subpasta) tem um `index.md`. Nas pastas de arquivos fixos ele é estático; nas pastas que acumulam arquivos gerados por skill, ele é dinâmico — a skill correspondente adiciona uma linha a cada arquivo novo.

---

## Como criar uma nova skill

Toda skill deve ser **portável** — autocontida em sua própria pasta para poder ser copiada para outro harness sem dependências externas.

**Estrutura mínima:**
```
.claude/skills/[nome-da-skill]/
  SKILL.md            ← define o comportamento (obrigatório)
  validar-output.sh   ← validação estrutural do output (quando aplicável)
```

**Regras:**
1. Todos os arquivos da skill ficam dentro de `.claude/skills/[nome-da-skill]/`
2. Nenhuma skill depende de arquivos de outra skill
3. Scripts de validação ficam dentro da pasta da skill, não em pastas globais
4. O `settings.json` apenas aponta para os scripts das skills
5. Se a skill grava arquivos em uma pasta de `conhecimento/` com `index.md` dinâmico, ela deve manter esse índice atualizado

**Hooks automáticos:**

O harness tem dois tipos de hook configurados em `.claude/settings.json`:

- **Ao salvar qualquer arquivo:** se a skill tiver um `validar-output.sh`, ele roda automaticamente e verifica convenção de nome, seções obrigatórias e metadados. Erros de validação aparecem no chat logo após o arquivo ser salvo.
- **Ao salvar um `SKILL.md`:** a tabela de skills no `README.md` é atualizada automaticamente com a descrição da skill.

---

## Convenções

- Sempre consulte os arquivos de conhecimento antes de responder sobre o projeto
- Ao atualizar conhecimento, prefira editar os arquivos existentes a criar novos
- Datas no formato `YYYY-MM-DD`
- Metadados de arquivos em `conhecimento/` usam frontmatter YAML, não tabelas ou listas em markdown
- Idioma de resposta: configurável por time — configurado na primeira utilização (o agente pergunta e grava em `CLAUDE.md`, seção "Idioma")
