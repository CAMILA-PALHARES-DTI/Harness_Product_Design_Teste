# documentos/

Arquivos de trabalho do projeto que não fazem parte da base de conhecimento estruturada (`conhecimento/`) — análises, apresentações, transcrições de reunião e documentos gerados por skills como `create-presentation`.

| Pasta | Conteúdo |
|---|---|
| `analises/` | Planilhas, PDFs e documentos de análise recebidos ou produzidos ao longo do projeto |
| `apresentacoes/` | `resultados/`: apresentações geradas pela skill `create-presentation` e entregues ao cliente. `templates/`: modelos (.pptx) reaproveitáveis do time — versionados, então prefira arquivos leves |
| `transcricoes/` | Transcrições brutas de reunião, antes de serem processadas para `conhecimento/cliente/reunioes/` |
| `gerados/` | Saída de skills como `create-presentation` (HTML/PDF de apresentações, roadmaps visuais etc.), `screen-planner` (`inventario-telas-[slug]-[YYYY-MM-DD].md`) e `create-prototype` (`prototipo-[slug]-[YYYY-MM-DD].html`). Rascunhos de protótipo `.rascunho-prototipo-*` ficam aqui só até a aprovação (git-ignored) |

Diferente de `conhecimento/`, os arquivos aqui não são indexados (`index.md`, `INDICE-GERAL`) — é espaço livre de trabalho. Exceção: o inventário de telas do `screen-planner` leva frontmatter e é validado por hook e por sensores (`validar-output.sh`, `validar-links-frontmatter.ps1`, `validar-sequencia-id.ps1 -Telas`), mas continua sendo insumo descartável da prototipação; a fonte duradoura do fluxo é `conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md`.
