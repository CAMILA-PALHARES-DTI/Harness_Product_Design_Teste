# Estrutura do HTML — create-prototype

Arquivo de apoio da skill `create-prototype`. A skill manda **ler este arquivo antes de escrever o HTML** (Passo 4). O esqueleto abaixo é o mínimo que os sensores (`sensores.md`) esperam encontrar: `navigateTo`, `setState`, `section.screen#SCR-XX`, `data-screen`/`data-state`, `live-region` e `debug-nav`.

## Esqueleto mínimo

```html
<!DOCTYPE html>
<html lang="pt-BR"> <!-- idioma do protótipo: pt-BR, en, es... -->
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>[Nome da tela ativa] — [Nome da feature] — Protótipo</title>
  <style>
    /* Tokens do Design System do projeto (ver "Design System" na skill) */
    :root { /* cores, tipografia, espaçamentos, raios */ }
    .screen { display: none; }
    .screen.active { display: block; }
    .sr-only { position:absolute; width:1px; height:1px; overflow:hidden; clip:rect(0 0 0 0); white-space:nowrap; }
    :focus-visible { outline: 2px solid var(--color-focus, currentColor); outline-offset: 2px; }
    body { padding-bottom: 4rem; } /* reserva espaço para a barra de debug fixa */
    @media (prefers-reduced-motion: reduce) { *, *::before, *::after { animation: none !important; transition: none !important; } }
  </style>
</head>
<body>
  <a href="#main" class="skip-link">Pular para o conteúdo</a>
  <main id="main">
    <!-- SCR-01: [Nome] — [passo do fluxo / origem] -->
    <section id="SCR-01" class="screen active" aria-labelledby="SCR-01-title">
      <h1 id="SCR-01-title" tabindex="-1">[Título da tela]</h1>
      <!-- <div data-screen="SCR-01" data-state="default"> ... </div> -->
      <!-- <div data-screen="SCR-01" data-state="loading" hidden aria-busy="true"> ... </div> -->
      <!-- <div data-screen="SCR-01" data-state="empty" hidden> ... </div> -->
      <!-- <div data-screen="SCR-01" data-state="error" hidden> ... </div> -->
    </section>
  </main>

  <!-- Região de anúncios para leitores de tela -->
  <div id="live-region" class="sr-only" aria-live="polite"></div>

  <!-- Barra de navegação (debug), fixa no rodapé, lista todas as telas -->
  <nav id="debug-nav" aria-label="Navegação do protótipo (debug)"></nav>

  <script>
    function announce(msg) { const r = document.getElementById('live-region'); r.textContent = ''; setTimeout(() => r.textContent = msg, 50); }
    function navigateTo(id) {
      document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
      const screen = document.getElementById(id);
      screen?.classList.add('active');
      const title = screen?.querySelector('h1');
      if (title) { document.title = title.textContent + ' — Protótipo'; title.focus(); }
      renderDebugNav();
      window.scrollTo(0, 0);
    }
    function setState(screenId, state) {
      document.querySelectorAll(`[data-screen="${screenId}"]`)
        .forEach(el => el.hidden = el.dataset.state !== state);
      // Anuncie mudanças relevantes (ex: "Carregando...", "Erro: ...", "Salvo com sucesso")
    }
    function renderDebugNav() { /* um botão por tela, com aria-current="page" na ativa */ }
    renderDebugNav();
  </script>
</body>
</html>
```

## Textos fixos por idioma do protótipo

| | Português (pt-BR) | Inglês (en) |
|---|---|---|
| Skip link | "Pular para o conteúdo" | "Skip to content" |
| Barra de debug (`aria-label`) | "Navegação do protótipo (debug)" | "Prototype navigation (debug)" |
| Datas | DD/MM/AAAA | conforme o mercado do produto (ex: MM/DD/YYYY nos EUA) |
| Números e moeda | `1.234,56` · `R$` | `1,234.56` · moeda do produto |

Para outros idiomas (ex: `es`), traduza os textos fixos e siga o formato de data/número do mercado. O marcador de pendência é sempre `[a confirmar]`, independentemente do idioma do protótipo (regra do harness; ver `CLAUDE.md`).

## Regras técnicas

1. **Arquivo único.** CSS e JS dentro do `.html`.
2. **Navegação via JS simples.** `navigateTo('SCR-XX')` mostra e esconde as seções e move o foco para o título da nova tela.
3. **Estados via data attributes.** `data-state` com `setState('SCR-XX', 'estado')`; mudanças de estado relevantes são anunciadas na `live-region`. Valores válidos: `default`, `loading`, `empty`, `error`, `success`.
4. **Barra de debug fixa** com atalho para todas as telas e para os estados da tela atual. Ela não pode cobrir o conteúdo nem o elemento focado (reserve espaço com `padding-bottom` no `body`). Em **app**, ela fica fora da moldura do dispositivo.
5. **Dados mock dentro do arquivo** para popular listas e tabelas.
6. **Copy real**, vinda dos materiais de base (briefing, fluxo, inventário, glossário). Nunca lorem ipsum.
7. **Acessibilidade:** cumprir o Guia B inteiro (`guias-qualidade.md`) — não só o mínimo.
8. **Sem lógica de negócio real**, autenticação, backend ou armazenamento no navegador.
9. **Plataforma respeitada.** Em **app**, a área de conteúdo tem o tamanho de uma tela de celular (ex: `max-width: 390px; min-height: 844px`, centralizada, com moldura), com barra superior e navegação de app. Em **web não responsivo**, use uma largura mínima de desktop (ex: `min-width: 1024px`) em vez de breakpoints.
10. **IDs de tela estáveis.** Cada tela é uma `<section class="screen" id="SCR-XX">` — o mesmo `SCR-XX` do inventário de telas (se existir). Nunca reutilize um ID para outra tela.
