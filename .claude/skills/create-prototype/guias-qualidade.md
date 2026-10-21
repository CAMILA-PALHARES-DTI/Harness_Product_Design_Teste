# Guias de qualidade — create-prototype

Arquivo de apoio da skill `create-prototype`. A skill manda **ler este arquivo inteiro antes de escrever o HTML** (Passo 4) — os dois guias valem para **toda tela e todo estado**. Use as tabelas como checklist enquanto constrói; os Sensores (`sensores.md`) verificam o resultado.

---

## Guia A — 10 Heurísticas de Usabilidade de Nielsen

Fonte: Jakob Nielsen, Nielsen Norman Group — https://www.nngroup.com/articles/ten-usability-heuristics/

| # | Heurística | O que significa | Como aplicar no protótipo |
|---|---|---|---|
| 1 | **Visibilidade do status do sistema** | O sistema mantém o usuário informado sobre o que está acontecendo, com feedback adequado e em tempo razoável. | Todo envio tem estado loading (spinner/skeleton + texto "Salvando...") e success/error. Indique onde o usuário está: passo X de Y em fluxos multietapa, item ativo no menu, título claro em cada tela. Botões em ação ficam desabilitados com feedback. |
| 2 | **Correspondência entre o sistema e o mundo real** | Fala a língua do usuário, com palavras e conceitos familiares, em ordem natural e lógica. | Copy no vocabulário da persona da feature e do `glossario.md` — sem jargão técnico, códigos internos ou mensagens de sistema. Datas, moeda e números no formato do idioma/mercado do protótipo. Ícones com significado convencional. Ordem dos campos segue a ordem mental do usuário. |
| 3 | **Controle e liberdade do usuário** | Usuários erram; precisam de uma "saída de emergência" clara para sair da ação sem passar por um processo longo. | Todo modal/drawer tem "Cancelar"/fechar e fecha com `Esc`. Fluxos multietapa têm "Voltar" sem perder dados. Ações destrutivas oferecem desfazer ou confirmação. Nunca prender o usuário numa tela sem saída. |
| 4 | **Consistência e padrões** | O usuário não deveria ter que se perguntar se palavras, situações ou ações diferentes significam a mesma coisa. Siga convenções da plataforma e do produto. | Mesmo componente do DS para a mesma função em todas as telas. Mesmo termo para a mesma coisa (não alternar "Salvar"/"Gravar"). CTA principal sempre na mesma posição e estilo. Padrões web comuns (logo leva à home, link sublinhado ou distinguível). |
| 5 | **Prevenção de erros** | Melhor que boas mensagens de erro é um design que evita que o problema aconteça. | Restrinja entradas com o componente certo (select, datepicker, máscara). Mostre formato esperado antes do erro ("DD/MM/AAAA"). Valores padrão sensatos. Confirmação antes de ações irreversíveis. Desabilite opções inválidas em vez de deixar errar. |
| 6 | **Reconhecer em vez de lembrar** | Minimize a carga de memória: elementos, ações e opções visíveis; o usuário não deve precisar lembrar informação de uma tela para outra. | Labels sempre visíveis (placeholder não substitui label). Em etapas finais, mostre resumo do que foi preenchido. Opções visíveis em vez de comandos a decorar. Histórico/recentes quando o fluxo previr. |
| 7 | **Flexibilidade e eficiência de uso** | Atalhos (ocultos para novatos) aceleram o uso de experientes; o design serve aos dois. | Ações frequentes acessíveis em poucos cliques. `Enter` envia formulários. Filtros/busca em listas longas. Atalhos só se o fluxo previr — não invente funcionalidade (use `[sugestão: Heurística 7]`). |
| 8 | **Estética e design minimalista** | Interfaces não devem conter informação irrelevante ou raramente necessária; cada elemento extra compete com o relevante. | Uma ação principal por tela, com hierarquia visual clara. Corte texto e elementos que não servem ao objetivo da feature. Use espaçamento do DS para agrupar (proximidade) em vez de bordas e caixas extras. |
| 9 | **Ajudar a reconhecer, diagnosticar e se recuperar de erros** | Mensagens de erro em linguagem simples (sem códigos), indicando com precisão o problema e sugerindo solução. | Toda mensagem de erro: o que aconteceu + como resolver ("CPF incompleto. Digite os 11 números."). Erro junto ao campo, com ícone + texto + cor. Preserve o que o usuário digitou. Estado error de tela inclui ação de recuperação ("Tentar novamente"). |
| 10 | **Ajuda e documentação** | Idealmente o sistema não precisa de explicação, mas pode ser necessário oferecer ajuda contextual, focada na tarefa e concisa. | Texto de apoio e tooltips no ponto de dúvida, não em páginas separadas. Empty states explicam o que é a tela e qual o primeiro passo. Links de ajuda no mesmo lugar em todas as telas. |

---

## Guia B — Acessibilidade WCAG 2.2, nível AA

Fonte: W3C — Web Content Accessibility Guidelines 2.2 (https://www.w3.org/TR/WCAG22/). O protótipo deve atender **nível AA**. Os critérios abaixo são os aplicáveis a um protótipo HTML, organizados pelos 4 princípios (POUR). O número entre parênteses é o critério de sucesso oficial.

### 1. Perceptível — a informação precisa ser percebida por todos os sentidos disponíveis

| Critério | Regra no protótipo |
|---|---|
| Conteúdo não textual (1.1.1) | Toda imagem informativa tem `alt` descritivo; decorativas têm `alt=""`. Ícones sozinhos em botões têm `aria-label`. SVGs decorativos com `aria-hidden="true"`. |
| Informação e relações (1.3.1) | Estrutura semântica: um `<h1>` por tela, hierarquia `h2`/`h3` sem pular níveis, `<main>`, `<nav>`, `<header>`, `<footer>`. Listas com `<ul>/<ol>`, tabelas com `<th scope>`. Campos com `<label for>`; grupos de radio/checkbox com `<fieldset>` + `<legend>`. |
| Sequência significativa (1.3.2) | Ordem do DOM = ordem visual de leitura. Não reordene com CSS de forma que mude o sentido. |
| Características sensoriais (1.3.3) | Instruções não dependem só de forma, posição ou cor ("clique no botão verde à direita" ✗). |
| Orientação (1.3.4) | Funciona em retrato e paisagem. |
| Identificar propósito de entrada (1.3.5) | Campos de dados pessoais com `autocomplete` adequado (`name`, `email`, `tel`, `postal-code`...). |
| Uso de cor (1.4.1) | Cor nunca é o único meio de transmitir informação: erro tem ícone + texto, links distinguíveis por sublinhado ou outro indicador, status com rótulo. |
| Contraste mínimo (1.4.3) | Texto normal ≥ **4.5:1**; texto grande (≥ 24px, ou ≥ 18,66px bold) ≥ **3:1**. Inclui placeholder, texto desabilitado informativo e texto sobre imagem. |
| Redimensionar texto (1.4.4) | Funciona com zoom de 200% sem perda de conteúdo. Use `rem` para fontes. |
| Reflow (1.4.10) | A 320px de largura (equivalente a 400% de zoom), sem rolagem horizontal — exceto tabelas/dados que exigem 2D. |
| Contraste não textual (1.4.11) | Bordas de campos, ícones informativos, indicadores de foco e estados de componentes ≥ **3:1** contra o fundo adjacente. |
| Espaçamento de texto (1.4.12) | Layout não quebra se o usuário aumentar entrelinha (1.5×), espaçamento entre parágrafos, letras e palavras. Evite alturas fixas em contêineres de texto. |
| Conteúdo em hover ou foco (1.4.13) | Tooltips/popovers: dispensáveis com `Esc`, permanecem enquanto o ponteiro está sobre eles, não somem sozinhos. Abrem também no foco do teclado. |

### 2. Operável — a interface precisa ser operável por qualquer meio de entrada

| Critério | Regra no protótipo |
|---|---|
| Teclado (2.1.1) | Tudo funciona só com teclado: `Tab`, `Shift+Tab`, `Enter`, `Espaço`, setas em componentes compostos. Use `<button>` e `<a>` nativos — nunca `<div onclick>`. |
| Sem armadilha de teclado (2.1.2) | O foco nunca fica preso. Modais prendem o foco **dentro** enquanto abertos, mas fecham com `Esc` e devolvem o foco ao elemento que os abriu. |
| Tempo ajustável (2.2.1) | Sem timeouts que encerram a tarefa; se o fluxo prevê, ofereça estender. Toasts importantes não somem antes de serem lidos. |
| Pausar, parar, ocultar (2.2.2) | Carrosséis e animações > 5s têm controle de pausa. |
| Três flashes (2.3.1) | Nada pisca mais de 3 vezes por segundo. Respeite `prefers-reduced-motion`. |
| Pular blocos (2.4.1) | Link "Pular para o conteúdo" como primeiro elemento focável. |
| Página com título (2.4.2) | `<title>` atualizado a cada troca de tela. |
| Ordem do foco (2.4.3) | Ordem de `Tab` lógica e igual à visual. Ao trocar de tela, foco vai para o `<h1>`; ao abrir modal, para o modal; ao fechar, volta ao gatilho. Evite `tabindex` positivo. |
| Propósito do link (2.4.4) | Texto do link diz para onde leva ("Ver detalhes do pedido 123", não "Clique aqui"). |
| Cabeçalhos e rótulos (2.4.6) | Títulos e labels descrevem o conteúdo/propósito. |
| Foco visível (2.4.7) | Todo elemento focável tem indicador de foco visível (`:focus-visible`). Nunca `outline: none` sem substituto. |
| Foco não obscurecido (2.4.11) | Elemento focado não fica escondido por header fixo, barra de debug, cookie banner ou similar. |
| Gestos de ponteiro (2.5.1) | Gesto multiponto ou de trajetória tem alternativa com toque simples. |
| Cancelamento de ponteiro (2.5.2) | Ações disparam no *up* (comportamento nativo de `click`), não no *down*. |
| Rótulo no nome (2.5.3) | O nome acessível contém o texto visível do botão/link (se o botão diz "Enviar", o `aria-label` começa com "Enviar"). |
| Movimentos de arrastar (2.5.7) | Todo arrastar (reordenar, slider) tem alternativa por clique/botões. |
| Tamanho do alvo (2.5.8) | Alvos clicáveis ≥ **24×24 px** (ou com espaçamento equivalente). Em mobile, prefira 44×44 px. |

### 3. Compreensível — informação e operação precisam ser compreensíveis

| Critério | Regra no protótipo |
|---|---|
| Idioma da página (3.1.1) | `<html lang="...">` com o idioma do protótipo (ex: `pt-BR`, `en`, `es`); trechos em outro idioma com `lang` próprio (3.1.2). |
| Em foco / em entrada (3.2.1, 3.2.2) | Receber foco ou mudar um campo não dispara navegação ou envio inesperado. Mudança de contexto só por ação explícita (botão). |
| Navegação e identificação consistentes (3.2.3, 3.2.4) | Menus na mesma ordem em todas as telas; mesmos ícones/nomes para as mesmas funções. |
| Ajuda consistente (3.2.6) | Se houver ajuda/contato, fica no mesmo lugar relativo em todas as telas. |
| Identificação de erro (3.3.1) | Erro descrito em texto, associado ao campo (`aria-describedby`) e com `aria-invalid="true"`. Ao enviar com erros, mova o foco para o primeiro campo inválido ou para um resumo de erros. |
| Rótulos ou instruções (3.3.2) | Todo campo tem label visível; formato e obrigatoriedade indicados antes do preenchimento (não só com `*` — explique o asterisco ou escreva "(obrigatório)"). |
| Sugestão de erro (3.3.3) | Mensagem sugere como corrigir. |
| Prevenção de erros — legal/financeiro/dados (3.3.4) | Envios com consequência (pagamento, contrato, exclusão) são reversíveis, verificados ou têm tela de revisão/confirmação. |
| Entrada redundante (3.3.7) | Não peça de novo informação já fornecida no mesmo fluxo — preencha automaticamente ou permita selecionar. |
| Autenticação acessível (3.3.8) | Login não exige teste cognitivo (decorar, transcrever, resolver quebra-cabeça). Permita colar senha e usar gerenciador de senhas (`autocomplete="current-password"`). |

### 4. Robusto — compatível com tecnologias assistivas

| Critério | Regra no protótipo |
|---|---|
| Nome, função, valor (4.1.2) | Componentes customizados expõem `role`, nome acessível e estado: `aria-expanded` em acordeões/menus, `aria-selected` em abas, `aria-checked` em toggles, `aria-current="page"` no item ativo, `role="dialog"` + `aria-modal="true"` + `aria-labelledby` em modais. Prefira elementos nativos a ARIA. |
| Mensagens de status (4.1.3) | Loading, sucesso, erro de envio e resultados de busca são anunciados via `aria-live="polite"` (ou `role="alert"` para erros críticos) sem mover o foco. |

---

## Como os estados aplicam os guias

| Estado | Nielsen | WCAG |
|---|---|---|
| **default** | H4, H6, H8 — ação principal clara, labels visíveis | 1.3.1, 1.4.3, 2.4.6 |
| **loading** | H1 — feedback imediato, texto do que está acontecendo | 4.1.3 (anunciar "Carregando..."), `aria-busy="true"`, 2.3.1 (sem animação agressiva) |
| **empty** | H10 — explica a tela e indica o primeiro passo com CTA | 1.3.1, 2.4.6 |
| **error** | H9 — o que houve + como resolver + ação de recuperação; H3 — saída | 3.3.1, 3.3.3, 1.4.1, 4.1.3 (`role="alert"`) |
| **success** | H1 — confirmação clara e próximo passo | 4.1.3 (anunciar sem roubar foco) |
