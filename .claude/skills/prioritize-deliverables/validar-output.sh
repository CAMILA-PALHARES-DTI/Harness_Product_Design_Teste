#!/bin/bash
# Valida priorizações geradas pela skill /prioritize-deliverables:
# - localização correta em conhecimento/planejamento/priorizacoes/
# - convenção de nome
# - seções obrigatórias presentes e não vazias
# - ao menos um item no ranking

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

# Só valida arquivos na pasta de priorizações
if [[ "$FILE_PATH" != *"conhecimento/planejamento/priorizacoes/"* ]]; then
  exit 0
fi

# O index.md da pasta não segue o formato de priorização — ignora
if [[ "$(basename "$FILE_PATH")" == "index.md" ]]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")
ERRORS=()
WARNINGS=()

echo "VALIDAÇÃO DA PRIORIZAÇÃO"
echo "Arquivo: $BASENAME"
echo ""

# 1. Convenção de nome: priorizacao-[recorte]-YYYY-MM-DD.md
if ! [[ "$BASENAME" =~ ^priorizacao-.+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
  ERRORS+=("Nome fora da convenção. Esperado: priorizacao-[recorte]-YYYY-MM-DD.md  |  Recebido: $BASENAME")
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
SECOES=(secao.contexto secao.framework_e_criterios secao.ranking)
for secao in "${SECOES[@]}"; do
  if ! tem_secao "$secao" "$CONTENT"; then
    ERRORS+=("Seção ausente: ## $(rotulo_msg "$secao")")
  fi
done

# 4. Campos de frontmatter obrigatórios não podem estar em branco, placeholder ou ausentes
METADATA_FIELDS=("framework" "recorte" "gerado-em")
for field in "${METADATA_FIELDS[@]}"; do
  LINE=$(grep "^${field}:" <<< "$CONTENT" || true)
  VALUE=$(echo "$LINE" | sed "s/^${field}: *//" | tr -d '\n')
  if [[ -z "$LINE" ]]; then
    ERRORS+=("Campo de frontmatter ausente: $field")
  elif [[ -z "$VALUE" ]] || [[ "$VALUE" == \[* ]]; then
    ERRORS+=("Metadado não preenchido: $field")
  fi
done

# 5. Framework deve ser um dos valores esperados
FRAMEWORK_LINE=$(grep "^framework:" <<< "$CONTENT" || true)
FRAMEWORK_VALUE=$(echo "$FRAMEWORK_LINE" | sed "s/^framework: *//" | tr -d '\n')
case "$FRAMEWORK_VALUE" in
  *RICE*|*MoSCoW*|*Kano*|*WSJF*|"") ;;
  *)
    if ! tem_texto valor.framework_valor_esforco "$FRAMEWORK_VALUE"; then
      WARNINGS+=("Campo 'framework' com valor inesperado: '$FRAMEWORK_VALUE' (esperado: RICE | MoSCoW | $(rotulo_msg valor.framework_valor_esforco) | Kano | WSJF)")
    fi ;;
esac

# 6. Seção Ranking deve ter ao menos uma linha de tabela com dados
if tem_secao secao.ranking "$CONTENT"; then
  RANKING_BLOCK=$(bloco_secao secao.ranking "$CONTENT")
  DATA_ROWS=$(echo "$RANKING_BLOCK" | grep -E "^\| *[0-9]+ *\|" || true)
  if [[ -z "$DATA_ROWS" ]]; then
    ERRORS+=("Seção 'Ranking' não contém nenhum item (esperado ao menos uma linha de tabela numerada).")
  fi
fi

# 7. Aviso: itens marcados como dado necessário
if tem_texto marcador.dado_necessario "$CONTENT"; then
  WARNINGS+=("Há itens marcados como '$(rotulo_msg marcador.dado_necessario)' — confirme se a seção 'Itens sem dado suficiente' está preenchida.")
fi

# 8. Lembrete de atualização do índice
WARNINGS+=("Confirme se conhecimento/planejamento/priorizacoes/index.md foi atualizado.")

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
