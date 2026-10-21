#!/bin/bash
# Valida outputs gerados pela skill /process-research-data:
# - dados brutos em conhecimento/pesquisa/coleta/
# - notas estruturadas em conhecimento/pesquisa/notas-estruturadas/

INPUT=$(cat)

source "$(dirname "${BASH_SOURCE[0]}")/../../hooks/_rotulos.sh"  # rótulos por idioma (scripts/rotulos.txt)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

BASENAME=$(basename "$FILE_PATH")
ERRORS=()
WARNINGS=()

# ── ARQUIVO DE COLETA ─────────────────────────────────────────────────────────
if [[ "$FILE_PATH" == *"conhecimento/pesquisa/coleta/"* ]]; then

  echo "VALIDAÇÃO DO DADO BRUTO (coleta)"
  echo "Arquivo: $BASENAME"
  echo ""

  # 1. Convenção de nome: bruto-[código]-[nome-pesquisa]-YYYY-MM-DD.md
  if ! [[ "$BASENAME" =~ ^bruto-.+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
    ERRORS+=("Nome fora da convenção. Esperado: bruto-[código]-[nome-pesquisa]-YYYY-MM-DD.md  |  Recebido: $BASENAME")
  fi

  # 2. Arquivo não pode estar vazio
  CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")
  if [[ -z "$CONTENT" ]]; then
    ERRORS+=("Arquivo vazio — o dado bruto não foi salvo corretamente.")
  fi

  if [[ ${#ERRORS[@]} -eq 0 ]]; then
    echo "OK — dado bruto salvo corretamente."
    exit 0
  else
    echo "ERROS (${#ERRORS[@]}):"
    for e in "${ERRORS[@]}"; do echo "  • $e"; done
    exit 1
  fi
fi

# ── NOTAS ESTRUTURADAS ────────────────────────────────────────────────────────
if [[ "$FILE_PATH" != *"conhecimento/pesquisa/notas-estruturadas/"* ]]; then
  exit 0
fi

echo "VALIDAÇÃO DAS NOTAS ESTRUTURADAS"
echo "Arquivo: $BASENAME"
echo ""

# 1. Convenção de nome: notas-[código]-[nome-pesquisa]-YYYY-MM-DD.md
if ! [[ "$BASENAME" =~ ^notas-.+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
  ERRORS+=("Nome fora da convenção. Esperado: notas-[código]-[nome-pesquisa]-YYYY-MM-DD.md  |  Recebido: $BASENAME")
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
SECOES=(secao.temas_identificados secao.casos_isolados secao.divergencias_registradas secao.lacunas_do_material secao.notas_qualidade_material)
for secao in "${SECOES[@]}"; do
  if ! tem_secao "$secao" "$CONTENT"; then
    ERRORS+=("Seção ausente: ## $(rotulo_msg "$secao")")
  fi
done

# 4. Frontmatter obrigatório não pode ser placeholder ou vazio
METADATA_FIELDS=("pesquisa" "metodo" "participantes" "processado-em")
for field in "${METADATA_FIELDS[@]}"; do
  LINE=$(grep "^${field}:" <<< "$CONTENT" || true)
  VALUE=$(echo "$LINE" | sed "s/^${field}: *//" | tr -d '\n')
  if [[ -z "$LINE" ]]; then
    ERRORS+=("Campo de frontmatter ausente: $field")
  elif [[ -z "$VALUE" ]] || [[ "$VALUE" == \[* ]]; then
    ERRORS+=("Metadado não preenchido: $field")
  fi
done

# 5. Arquivo de origem deve estar preenchido (não placeholder)
ORIGEM=$(grep "^arquivo-origem:" <<< "$CONTENT" || true)
ORIGEM_VALUE=$(echo "$ORIGEM" | sed "s/^arquivo-origem: *//" | tr -d '\n')
if [[ -z "$ORIGEM_VALUE" ]] || [[ "$ORIGEM_VALUE" == \[* ]]; then
  WARNINGS+=("Campo 'arquivo-origem' não preenchido — rastreabilidade coleta → notas comprometida.")
fi

# 6. Heurística de nome real no campo participantes (nome próprio com sobrenome)
if grep -qE "^participantes: .*[A-ZÁÉÍÓÚÃÕÂÊÎÔÛÇ][a-záéíóúãõâêîôûç]+ [A-ZÁÉÍÓÚÃÕÂÊÎÔÛÇ]" <<< "$CONTENT"; then
  WARNINGS+=("Possível nome real no campo 'participantes'. Substitua por código (P01, P02).")
fi

# 7. Lembrete de atualização dos índices
WARNINGS+=("Confirme se conhecimento/pesquisa/coleta/index.md e conhecimento/pesquisa/notas-estruturadas/index.md foram atualizados.")

# 8. Linguagem de interpretação — aviso (pode ser falso positivo em citações diretas)
#    Os termos (português e inglês) vêm de scripts/rotulos.txt, chave 'interpretacao'.
while IFS= read -r term; do
  if grep -qiF -- "$term" <<< "$CONTENT"; then
    WARNINGS+=("Possível linguagem de interpretação: \"$term\". Verifique se não é citação direta — interpretações pertencem à skill /interpret.")
    break
  fi
done < <(rotulo_variantes interpretacao)

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
