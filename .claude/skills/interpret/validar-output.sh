#!/bin/bash
# Valida relatórios gerados pela skill /interpret:
# - localização correta em conhecimento/pesquisa/relatorios/
# - convenção de nome
# - seções obrigatórias presentes e não vazias
# - ao menos um achado e uma recomendação

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

# Só valida arquivos na pasta de relatórios
if [[ "$FILE_PATH" != *"conhecimento/pesquisa/relatorios/"* ]]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")
ERRORS=()
WARNINGS=()

echo "VALIDAÇÃO DO RELATÓRIO DE PESQUISA"
echo "Arquivo: $BASENAME"
echo ""

# 1. Convenção de nome: relatorio-[nome-pesquisa]-YYYY-MM-DD.md
if ! [[ "$BASENAME" =~ ^relatorio-.+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
  ERRORS+=("Nome fora da convenção. Esperado: relatorio-[nome-pesquisa]-YYYY-MM-DD.md  |  Recebido: $BASENAME")
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
SECOES=(secao.resumo_executivo secao.achados secao.recomendacoes secao.lacunas_e_limitacoes)
for secao in "${SECOES[@]}"; do
  if ! tem_secao "$secao" "$CONTENT"; then
    ERRORS+=("Seção ausente: ## $(rotulo_msg "$secao")")
  fi
done

# 4. Campos de frontmatter obrigatórios não podem estar em branco, placeholder ou ausentes
METADATA_FIELDS=("pesquisa" "metodos" "participantes-analisados" "gerado-em")
for field in "${METADATA_FIELDS[@]}"; do
  LINE=$(grep "^${field}:" <<< "$CONTENT" || true)
  VALUE=$(echo "$LINE" | sed "s/^${field}: *//" | tr -d '\n')
  if [[ -z "$LINE" ]]; then
    ERRORS+=("Campo de frontmatter ausente: $field")
  elif [[ -z "$VALUE" ]] || [[ "$VALUE" == \[* ]]; then
    ERRORS+=("Metadado não preenchido: $field")
  fi
done

# 5. Seção Achados deve ter ao menos um H3 (achado real)
if tem_secao secao.achados "$CONTENT"; then
  ACHADOS_BLOCK=$(bloco_secao secao.achados "$CONTENT")
  if ! grep -q "^### " <<< "$ACHADOS_BLOCK"; then
    ERRORS+=("Seção 'Achados' não contém nenhum achado (esperado pelo menos um '### Tema/Tarefa').")
  fi
fi

# 6. Seção Recomendações deve ter ao menos um H3 (recomendação real)
if tem_secao secao.recomendacoes "$CONTENT"; then
  REC_BLOCK=$(bloco_secao secao.recomendacoes "$CONTENT")
  if ! grep -q "^### " <<< "$REC_BLOCK"; then
    ERRORS+=("Seção 'Recomendações' não contém nenhuma recomendação (esperado pelo menos um '### R1: ...').")
  fi
fi

# 7. Resumo Executivo não pode ser placeholder
if tem_secao secao.resumo_executivo "$CONTENT"; then
  EXEC_BLOCK=$(bloco_secao secao.resumo_executivo "$CONTENT")
  EXEC_TEXT=$(echo "$EXEC_BLOCK" | grep -v "^##" | tr -d '[:space:]')
  if [[ -z "$EXEC_TEXT" ]] || [[ "$EXEC_TEXT" == \[* ]]; then
    ERRORS+=("Seção 'Resumo Executivo' está vazia ou contém apenas placeholder.")
  fi
fi

# 8. Aviso: notas de origem não preenchidas
ORIGEM=$(grep "^notas-origem:" <<< "$CONTENT" || true)
ORIGEM_VALUE=$(echo "$ORIGEM" | sed "s/^notas-origem: *//" | tr -d '\n')
if [[ -z "$ORIGEM_VALUE" ]] || [[ "$ORIGEM_VALUE" == \[* ]]; then
  WARNINGS+=("Campo 'notas-origem' não preenchido — rastreabilidade notas → relatório comprometida.")
fi

# 9. Aviso: ausência de citações diretas (heurística — relatório provavelmente não tem evidências)
if ! grep -q "^>" <<< "$CONTENT"; then
  WARNINGS+=("Nenhuma citação direta encontrada (linhas começando com '>'). Verifique se os achados têm evidências diretas dos participantes.")
fi

# 10. Aviso: plano de pesquisa não referenciado
if ! grep -q "^plano-pesquisa:" <<< "$CONTENT" || grep -qE "^plano-pesquisa: \[" <<< "$CONTENT"; then
  WARNINGS+=("Plano de pesquisa não referenciado. Se houver um plano em conhecimento/pesquisa/planos/, referencie-o no frontmatter.")
fi

# 11. Lembrete de atualização do índice
WARNINGS+=("Confirme se conhecimento/pesquisa/relatorios/index.md foi atualizado.")

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
