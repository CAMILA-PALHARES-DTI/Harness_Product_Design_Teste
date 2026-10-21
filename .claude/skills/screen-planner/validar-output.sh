#!/bin/bash
# Valida inventários de telas gerados pela skill /screen-planner:
# - localização e convenção de nome (documentos/gerados/inventario-telas-[slug]-YYYY-MM-DD.md)
# - frontmatter obrigatório preenchido e valores válidos (tipo, escopo, status)
# - ao menos uma tela detalhada ou a lista "Telas sem protótipo"
# - IDs SCR-NN consistentes (delegado a scripts/validar-sequencia-id.ps1 -Telas)

source "$(dirname "${BASH_SOURCE[0]}")/../../hooks/_rotulos.sh"  # rótulos por idioma (scripts/rotulos.txt)
source "$(dirname "${BASH_SOURCE[0]}")/../../hooks/_ps.sh"       # run_ps: powershell (Windows) ou pwsh (macOS/Linux)

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

FILE_PATH="${FILE_PATH//\\//}"

BASENAME=$(basename "$FILE_PATH")
if [[ "$FILE_PATH" != *"documentos/gerados/"* || "$BASENAME" != inventario-telas-*.md ]]; then
  exit 0
fi

ERRORS=()
WARNINGS=()

echo "VALIDAÇÃO DO INVENTÁRIO DE TELAS"
echo "Arquivo: $BASENAME"
echo ""

# 1. Convenção de nome
if ! [[ "$BASENAME" =~ ^inventario-telas-.+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
  ERRORS+=("Nome fora da convenção. Esperado: inventario-telas-[slug-da-feature]-YYYY-MM-DD.md  |  Recebido: $BASENAME")
fi

CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")
if [[ -z "$CONTENT" ]]; then
  ERRORS+=("Arquivo vazio ou não encontrado: $FILE_PATH")
  echo "ERROS (${#ERRORS[@]}):"
  for e in "${ERRORS[@]}"; do echo "  • $e"; done
  exit 1
fi

# 2. Frontmatter obrigatório
for field in tipo feature fluxo-fonte briefing-fonte design-system plataforma escopo quantidade-telas telas-com-prototipo gerado-em status; do
  LINE=$(grep "^${field}:" <<< "$CONTENT" | head -1 || true)
  VALUE=$(echo "$LINE" | sed "s/^${field}: *//" | tr -d '\r')
  if [[ -z "$LINE" ]]; then
    ERRORS+=("Campo de frontmatter ausente: $field")
  elif [[ -z "$VALUE" ]] || [[ "$VALUE" == \[* ]]; then
    ERRORS+=("Metadado não preenchido: $field")
  fi
done

TIPO=$(grep "^tipo:" <<< "$CONTENT" | head -1 | sed 's/^tipo: *//' | tr -d '\r')
[[ -n "$TIPO" && "$TIPO" != "inventario-de-telas" ]] && ERRORS+=("Campo 'tipo' deve ser 'inventario-de-telas'. Recebido: $TIPO")

ESCOPO=$(grep "^escopo:" <<< "$CONTENT" | head -1 | sed 's/^escopo: *//' | tr -d '\r')
ESCOPO_RE="($(rotulo_re valor.escopo_completo)|$(rotulo_re valor.escopo_parcial))"
if [[ -n "$ESCOPO" ]] && ! grep -qiE "^${ESCOPO_RE}$" <<< "$ESCOPO"; then
  ERRORS+=("Campo 'escopo' deve ser '$(rotulo_msg valor.escopo_completo)' ou '$(rotulo_msg valor.escopo_parcial)'. Recebido: $ESCOPO")
fi

# 3. Conteúdo mínimo
if ! grep -qE '^\*\*ID:\*\* SCR-[0-9]+' <<< "$CONTENT" && ! tem_secao secao.telas_sem_prototipo "$CONTENT"; then
  ERRORS+=("Nenhuma tela encontrada (esperado '**ID:** SCR-NN' por tela ou a seção '## $(rotulo_msg secao.telas_sem_prototipo)')")
fi
tem_secao secao.mapa_de_navegacao "$CONTENT" || ERRORS+=("Seção ausente: ## $(rotulo_msg secao.mapa_de_navegacao)")

# 4. IDs SCR-NN (sensor computacional)
if ps_disponivel; then
  IDS_OUT=$(run_ps -File scripts/validar-sequencia-id.ps1 -Telas -Arquivo "$FILE_PATH" 2>&1)
  if [[ $? -ne 0 ]]; then
    while IFS= read -r l; do [[ "$l" == "  - "* ]] && ERRORS+=("IDs de tela: ${l#  - }"); done <<< "$IDS_OUT"
  fi
fi

N_CONF=$(grep -o '\[a confirmar\]' <<< "$CONTENT" | wc -l | tr -d ' ')
WARNINGS+=("$N_CONF pontos [a confirmar] no inventário — confirme que foram listados ao PD.")
WARNINGS+=("Rode também (pwsh no macOS/Linux, powershell no Windows): <pwsh|powershell> -File scripts/validar-links-frontmatter.ps1 -Arquivo $FILE_PATH")

# ── RELATÓRIO ─────────────────────────────────────────────────────────────────
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "ERROS (${#ERRORS[@]}):"
  for e in "${ERRORS[@]}"; do echo "  • $e"; done
  echo ""
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo "AVISOS (${#WARNINGS[@]}):"
  for w in "${WARNINGS[@]}"; do echo "  • $w"; done
fi

[[ ${#ERRORS[@]} -gt 0 ]] && exit 1 || exit 0
