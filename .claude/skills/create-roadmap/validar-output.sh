#!/bin/bash
# Valida roadmaps gerados pela skill /create-roadmap:
# - localização correta em conhecimento/planejamento/roadmaps/
# - convenção de nome
# - seções obrigatórias presentes e não vazias
# - ao menos um passo na sequência

source "$(dirname "${BASH_SOURCE[0]}")/../../hooks/_rotulos.sh"  # rótulos por idioma (scripts/rotulos.txt)

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Só valida arquivos na pasta de roadmaps
if [[ "$FILE_PATH" != *"conhecimento/planejamento/roadmaps/"* ]]; then
  exit 0
fi

# O index.md da pasta não segue o formato de roadmap — ignora
if [[ "$(basename "$FILE_PATH")" == "index.md" ]]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")
ERRORS=()
WARNINGS=()

echo "VALIDAÇÃO DO ROADMAP"
echo "Arquivo: $BASENAME"
echo ""

# 1. Convenção de nome: roadmap-[recorte]-YYYY-MM-DD.md
if ! [[ "$BASENAME" =~ ^roadmap-.+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
  ERRORS+=("Nome fora da convenção. Esperado: roadmap-[recorte]-YYYY-MM-DD.md  |  Recebido: $BASENAME")
fi

# 2. Lê o conteúdo
CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")

if [[ -z "$CONTENT" ]]; then
  ERRORS+=("Arquivo vazio ou não encontrado: $FILE_PATH")
  echo "ERROS (${#ERRORS[@]}):"
  for e in "${ERRORS[@]}"; do echo "  • $e"; done
  exit 1
fi

# 3. Seções obrigatórias
SECOES=(secao.cenario secao.premissas_e_restricoes secao.sequencia_de_passos secao.riscos_ao_cronograma)
for secao in "${SECOES[@]}"; do
  if ! tem_secao "$secao" "$CONTENT"; then
    ERRORS+=("Seção ausente: ## $(rotulo_msg "$secao")")
  fi
done

# 4. Campos de frontmatter obrigatórios não podem estar em branco, placeholder ou ausentes
METADATA_FIELDS=("cenario" "recorte" "gerado-em")
for field in "${METADATA_FIELDS[@]}"; do
  LINE=$(grep "^${field}:" <<< "$CONTENT" || true)
  VALUE=$(echo "$LINE" | sed "s/^${field}: *//" | tr -d '\n')
  if [[ -z "$LINE" ]]; then
    ERRORS+=("Campo de frontmatter ausente: $field")
  elif [[ -z "$VALUE" ]] || [[ "$VALUE" == \[* ]]; then
    ERRORS+=("Metadado não preenchido: $field")
  fi
done

# 5. Cenário deve ser um dos valores esperados
CENARIO_LINE=$(grep "^cenario:" <<< "$CONTENT" || true)
CENARIO_VALUE=$(echo "$CENARIO_LINE" | sed "s/^cenario: *//" | tr -d '\n' | tr -d '[:space:]')
CENARIO_MISTO_RE=$(rotulo_re valor.cenario_misto)
if [[ -n "$CENARIO_VALUE" ]] && [[ "$CENARIO_VALUE" != "macro" && "$CENARIO_VALUE" != "micro" ]] && ! grep -qiE "^${CENARIO_MISTO_RE}$" <<< "$CENARIO_VALUE"; then
  WARNINGS+=("Campo 'cenario' com valor inesperado: '$CENARIO_VALUE' (esperado: macro | micro | $(rotulo_msg valor.cenario_misto))")
fi

# 6. Seção Sequência de Passos deve ter ao menos uma linha de tabela com dados
if tem_secao secao.sequencia_de_passos "$CONTENT"; then
  SEQ_BLOCK=$(bloco_secao secao.sequencia_de_passos "$CONTENT")
  DATA_ROWS=$(echo "$SEQ_BLOCK" | grep -E "^\| *[0-9]+ *\|" || true)
  if [[ -z "$DATA_ROWS" ]]; then
    ERRORS+=("Seção 'Sequência de Passos' não contém nenhum passo (esperado ao menos uma linha de tabela numerada).")
  fi
fi

# 7. Diagrama Mermaid, se presente, deve ser timeline ou gantt
if grep -q '```mermaid' <<< "$CONTENT"; then
  MERMAID_BLOCK=$(awk '/```mermaid/{found=1; next} /```/{if(found) found=0} found{print}' <<< "$CONTENT")
  FIRST_LINE=$(echo "$MERMAID_BLOCK" | grep -v '^\s*$' | head -1 | tr -d '[:space:]')
  if [[ "$FIRST_LINE" != timeline* && "$FIRST_LINE" != gantt* ]]; then
    WARNINGS+=("Diagrama Mermaid presente não é 'timeline' nem 'gantt' — fora da convenção da skill.")
  fi
fi

# 8. Lembrete de atualização do índice
WARNINGS+=("Confirme se conhecimento/planejamento/roadmaps/index.md foi atualizado.")

# ── RELATÓRIO ─────────────────────────────────────────────────────────────────
if [[ ${#ERRORS[@]} -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
  echo "OK — todas as verificações passaram."
  exit 0
fi

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
