#!/bin/bash
# Valida fluxos gerados pela skill /flow-mapping:
# - localização correta em conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/existentes/ ou /futuros/, conforme o campo 'tipo'
# - consistência entre a subpasta (existentes/futuros) e o campo 'tipo' no frontmatter
# - convenção de nome
# - frontmatter obrigatório preenchido
# - presença de um diagrama Mermaid válido (bloco ```mermaid)
# - seção de notas de design presente

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

# Só valida arquivos nas pastas de rascunho de fluxo
if [[ "$FILE_PATH" != *"conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/existentes/"* && "$FILE_PATH" != *"conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/futuros/"* ]]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")
ERRORS=()
WARNINGS=()

echo "VALIDAÇÃO DO FLUXO DE USUÁRIO"
echo "Arquivo: $BASENAME"
echo ""

# 1. Convenção de nome: fluxo-[nome-fluxo]-YYYY-MM-DD.md
if ! [[ "$BASENAME" =~ ^fluxo-.+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
  ERRORS+=("Nome fora da convenção. Esperado: fluxo-[nome-fluxo]-YYYY-MM-DD.md  |  Recebido: $BASENAME")
fi

# 2. Lê o conteúdo
CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")

if [[ -z "$CONTENT" ]]; then
  ERRORS+=("Arquivo vazio ou não encontrado: $FILE_PATH")
  echo "ERROS (${#ERRORS[@]}):"
  for e in "${ERRORS[@]}"; do echo "  • $e"; done
  exit 1
fi

# 3. Campos de frontmatter obrigatórios não podem estar em branco, placeholder ou ausentes
METADATA_FIELDS=("tipo" "titulo" "ator" "origem" "gerado-em")
for field in "${METADATA_FIELDS[@]}"; do
  LINE=$(grep "^${field}:" <<< "$CONTENT" || true)
  VALUE=$(echo "$LINE" | sed "s/^${field}: *//" | tr -d '\n')
  if [[ -z "$LINE" ]]; then
    ERRORS+=("Campo de frontmatter ausente: $field")
  elif [[ -z "$VALUE" ]] || [[ "$VALUE" == \[* ]]; then
    ERRORS+=("Metadado não preenchido: $field")
  fi
done

# 4. Campo 'tipo' deve ser fluxo-existente ou fluxo-futuro
TIPO_LINE=$(grep "^tipo:" <<< "$CONTENT" || true)
TIPO_VALUE=$(echo "$TIPO_LINE" | sed "s/^tipo: *//" | tr -d '\n' | tr -d '\r')
if [[ -n "$TIPO_VALUE" ]] && [[ "$TIPO_VALUE" != "fluxo-existente" ]] && [[ "$TIPO_VALUE" != "fluxo-futuro" ]]; then
  ERRORS+=("Campo 'tipo' deve ser 'fluxo-existente' ou 'fluxo-futuro'. Recebido: $TIPO_VALUE")
fi

# 4b. Caminho deve ser compatível com o campo 'tipo'
if [[ "$FILE_PATH" == *"/fluxos-mapeados/existentes/"* ]] && [[ "$TIPO_VALUE" != "fluxo-existente" ]]; then
  ERRORS+=("Arquivo salvo em 'fluxos-mapeados/existentes/' mas campo 'tipo' é '$TIPO_VALUE' — esperado 'fluxo-existente'.")
fi
if [[ "$FILE_PATH" == *"/fluxos-mapeados/futuros/"* ]] && [[ "$TIPO_VALUE" != "fluxo-futuro" ]]; then
  ERRORS+=("Arquivo salvo em 'fluxos-mapeados/futuros/' mas campo 'tipo' é '$TIPO_VALUE' — esperado 'fluxo-futuro'.")
fi

# 5. Campo 'origem' deve ser pesquisa ou manual
ORIGEM_LINE=$(grep "^origem:" <<< "$CONTENT" || true)
ORIGEM_VALUE=$(echo "$ORIGEM_LINE" | sed "s/^origem: *//" | tr -d '\n' | tr -d '\r')
ORIGEM_PESQUISA_RE=$(rotulo_re valor.origem_pesquisa)
ORIGEM_MANUAL_RE=$(rotulo_re valor.origem_manual)
if [[ -n "$ORIGEM_VALUE" ]] && ! grep -qiE "^(${ORIGEM_PESQUISA_RE}|${ORIGEM_MANUAL_RE})$" <<< "$ORIGEM_VALUE"; then
  ERRORS+=("Campo 'origem' deve ser '$(rotulo_msg valor.origem_pesquisa)' ou '$(rotulo_msg valor.origem_manual)'. Recebido: $ORIGEM_VALUE")
fi

# 6. Se origem = pesquisa, pesquisa-relacionada deveria estar preenchida
if grep -qiE "^${ORIGEM_PESQUISA_RE}$" <<< "$ORIGEM_VALUE"; then
  PR_LINE=$(grep "^pesquisa-relacionada:" <<< "$CONTENT" || true)
  PR_VALUE=$(echo "$PR_LINE" | sed "s/^pesquisa-relacionada: *//" | tr -d '\n')
  if [[ -z "$PR_LINE" ]] || [[ -z "$PR_VALUE" ]] || [[ "$PR_VALUE" == \[* ]]; then
    WARNINGS+=("Origem é 'pesquisa' mas 'pesquisa-relacionada' não está preenchida — rastreabilidade fluxo → relatório comprometida.")
  fi
fi

# 7. Diagrama Mermaid presente
if ! grep -q '^```mermaid' <<< "$CONTENT"; then
  ERRORS+=("Nenhum bloco \`\`\`mermaid encontrado — o fluxo deve conter um diagrama Mermaid.")
fi

# 8. Seção de Notas de Design presente
if ! tem_secao secao.notas_de_design "$CONTENT"; then
  ERRORS+=("Seção ausente: ## $(rotulo_msg secao.notas_de_design)")
fi

# 9. Aviso: fonte não preenchida
if ! grep -qiE "^\*\*$(rotulo_re campo.fonte):?\*\*" <<< "$CONTENT"; then
  WARNINGS+=("Campo '$(rotulo_msg campo.fonte)' não encontrado no corpo do arquivo — verifique se os documentos consultados estão referenciados.")
fi

# 10. Lembrete de atualização do índice
if [[ "$FILE_PATH" == *"/fluxos-mapeados/existentes/"* ]]; then
  WARNINGS+=("Confirme se conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/existentes/index.md foi atualizado.")
else
  WARNINGS+=("Confirme se conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/futuros/index.md foi atualizado.")
fi

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
