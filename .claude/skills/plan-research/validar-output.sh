#!/bin/bash
# Valida estrutura de planos de pesquisa gerados pela skill /plan-research.
# Acionado como hook PostToolUse na ferramenta Write.

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

# Só executa para arquivos em conhecimento/pesquisa/planos/
if [[ "$FILE_PATH" != *"conhecimento/pesquisa/planos/"* ]]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")
ERRORS=()
WARNINGS=()

# 1. Convenção de nome: plano-[nome]-YYYY-MM-DD.md
if ! [[ "$BASENAME" =~ ^plano-.+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
  ERRORS+=("Nome fora da convenção. Esperado: plano-[nome-da-demanda]-YYYY-MM-DD.md  |  Recebido: $BASENAME")
fi

# 2. Lê o conteúdo do arquivo
CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")

if [[ -z "$CONTENT" ]]; then
  ERRORS+=("Arquivo vazio ou não encontrado: $FILE_PATH")
  echo "VALIDAÇÃO DO PLANO DE PESQUISA"
  echo "Arquivo: $BASENAME"
  echo ""
  echo "ERROS:"
  for e in "${ERRORS[@]}"; do echo "  • $e"; done
  exit 1
fi

# 3. Frontmatter obrigatório
for campo in "tipo:" "demanda:" "tipo-pesquisa:" "data-criacao:"; do
  if ! grep -q "^$campo" <<< "$CONTENT"; then
    ERRORS+=("Campo '$campo' ausente no frontmatter.")
  fi
done

# 3b. Lembrete de atualização do índice
WARNINGS+=("Confirme se conhecimento/pesquisa/planos/index.md foi atualizado.")

# 4. Todas as 8 seções obrigatórias presentes
SECOES=("1. Resumo" "2. Cenário" "3. Objetivo" "4. Atividades" "5. Sequência" "6. Recursos" "7. Premissas" "8. Critérios")
for i in "${!SECOES[@]}"; do
  NUM=$((i + 1))
  if ! grep -q "^## $NUM\." <<< "$CONTENT"; then
    ERRORS+=("Seção ausente: ## $NUM. ${SECOES[$i]#*. }")
  fi
done

# 5. Tipo de pesquisa identificado
TIPOS_RE="($(rotulo_re valor.tipo_pesquisa_generativa)|$(rotulo_re valor.tipo_pesquisa_avaliativa)|$(rotulo_re valor.tipo_pesquisa_discovery))"
if ! grep -qiE "^tipo-pesquisa: *${TIPOS_RE}" <<< "$CONTENT"; then
  ERRORS+=("Tipo de pesquisa não identificado. O frontmatter deve conter 'tipo-pesquisa:' com um destes valores: $(rotulo_msg valor.tipo_pesquisa_generativa), $(rotulo_msg valor.tipo_pesquisa_avaliativa) ou $(rotulo_msg valor.tipo_pesquisa_discovery).")
fi

# 6. Ferramentas desatualizadas
for tool in "Mural" "Notion"; do
  if grep -q "$tool" <<< "$CONTENT"; then
    WARNINGS+=("Ferramenta desatualizada: '$tool'. Substituir por FigJam ou Sharepoint.")
  fi
done

# 7. Placeholders do template não substituídos
if grep -qE "\[mesma estrutura acima\]|\[Nome da Demanda\]|\[explicação breve" <<< "$CONTENT"; then
  WARNINGS+=("Placeholder do template não substituído. Revise o documento gerado.")
fi

# 8. Seções com conteúdo mínimo (menos de 20 caracteres úteis)
while IFS= read -r line; do
  if [[ "$line" =~ ^##\  ]]; then
    CURRENT_SECTION="$line"
    SECTION_CONTENT=""
  else
    SECTION_CONTENT+="$line"
    if [[ ${#SECTION_CONTENT} -gt 20 ]]; then
      CURRENT_SECTION=""
    fi
  fi
  if [[ -n "$CURRENT_SECTION" ]] && [[ "$line" == "## "* ]] && [[ "$line" != "$CURRENT_SECTION" ]]; then
    if [[ ${#SECTION_CONTENT} -lt 20 ]]; then
      WARNINGS+=("Seção possivelmente vazia: $CURRENT_SECTION")
    fi
  fi
done <<< "$CONTENT"

# 9. Campos de transição entre atividades
if ! tem_texto campo.quando_avancar "$CONTENT"; then
  ERRORS+=("Campo '$(rotulo_msg campo.quando_avancar)' não encontrado. Cada atividade deve conter este campo indicando sinais de conclusão.")
fi

if ! tem_texto campo.leva_proxima_etapa "$CONTENT"; then
  ERRORS+=("Campo '$(rotulo_msg campo.leva_proxima_etapa)' não encontrado. Cada atividade deve conter este campo conectando ao próximo passo.")
fi

# --- Relatório ---
echo "VALIDAÇÃO DO PLANO DE PESQUISA"
echo "Arquivo: $BASENAME"
echo ""

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
