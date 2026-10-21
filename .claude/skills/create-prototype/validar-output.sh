#!/bin/bash
# Valida protótipos gerados pela skill /create-prototype:
# - localização e convenção de nome do arquivo final (documentos/gerados/prototipo-[slug]-YYYY-MM-DD.html)
# - estrutura mínima: DOCTYPE, lang, viewport, <title>
# - ao menos uma tela <section class="screen" id="SCR-NN"> e as funções navigateTo/setState
# - sem script/CSS externo e sem lorem ipsum
# Os sensores completos (WCAG, contraste, reflow, foco) rodam dentro da skill, sobre o rascunho
# (sensores-prototipo.mjs) — este hook só confere o arquivo final salvo.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

# No Windows o caminho pode vir com barra invertida
FILE_PATH="${FILE_PATH//\\//}"

# Só valida protótipos finais em documentos/gerados/ (rascunhos .rascunho-* não entram)
BASENAME=$(basename "$FILE_PATH")
if [[ "$FILE_PATH" != *"documentos/gerados/"* || "$BASENAME" != prototipo-*.html ]]; then
  exit 0
fi

ERRORS=()
WARNINGS=()

echo "VALIDAÇÃO DO PROTÓTIPO"
echo "Arquivo: $BASENAME"
echo ""

# 1. Convenção de nome: prototipo-[slug]-YYYY-MM-DD.html
if ! [[ "$BASENAME" =~ ^prototipo-.+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.html$ ]]; then
  ERRORS+=("Nome fora da convenção. Esperado: prototipo-[slug-da-feature]-YYYY-MM-DD.html  |  Recebido: $BASENAME")
fi

CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")
if [[ -z "$CONTENT" ]]; then
  ERRORS+=("Arquivo vazio ou não encontrado: $FILE_PATH")
  echo "ERROS (${#ERRORS[@]}):"
  for e in "${ERRORS[@]}"; do echo "  • $e"; done
  exit 1
fi

# 2. Estrutura mínima
grep -qi '<!DOCTYPE html>' <<< "$CONTENT" || ERRORS+=("Falta <!DOCTYPE html>")
grep -qiE '<html[^>]*\blang="[^"]+"' <<< "$CONTENT" || ERRORS+=("Falta o atributo lang em <html> (idioma do protótipo)")
grep -qi 'name="viewport"' <<< "$CONTENT" || ERRORS+=("Falta <meta name=\"viewport\">")
grep -qiE '<title>[^<]+</title>' <<< "$CONTENT" || ERRORS+=("Falta <title> preenchido")

# 3. Telas e funções de navegação
if ! grep -qE '<section[^>]*class="[^"]*screen[^"]*"[^>]*id="SCR-[0-9]+"|<section[^>]*id="SCR-[0-9]+"[^>]*class="[^"]*screen' <<< "$CONTENT"; then
  ERRORS+=("Nenhuma <section class=\"screen\" id=\"SCR-NN\"> encontrada")
fi
grep -q 'function navigateTo' <<< "$CONTENT" || ERRORS+=("Função navigateTo() não encontrada")
grep -q 'function setState' <<< "$CONTENT" || WARNINGS+=("Função setState() não encontrada — os estados das telas não são alternáveis")

# 4. Arquivo único e copy real
if grep -qiE '<script[^>]+src="(https?:)?//|<link[^>]+rel="stylesheet"[^>]+href="(https?:)?//' <<< "$CONTENT"; then
  ERRORS+=("Script ou CSS externo — o protótipo deve ser um arquivo único que abre offline")
fi
grep -qiE 'lorem ipsum|dolor sit amet' <<< "$CONTENT" && ERRORS+=("Contém lorem ipsum — use copy real")

# 5. Avisos de pendência
N_CONF=$(grep -o '\[a confirmar\]' <<< "$CONTENT" | wc -l | tr -d ' ')
N_SUG=$(grep -o '\[sugest' <<< "$CONTENT" | wc -l | tr -d ' ')
N_A11Y=$(grep -o '\[a11y' <<< "$CONTENT" | wc -l | tr -d ' ')
WARNINGS+=("$N_CONF [a confirmar], $N_SUG [sugestão], $N_A11Y [a11y] no protótipo — confirme que o relatório do Passo 5 listou todos.")
WARNINGS+=("Rode também: powershell -File scripts/validar-sequencia-id.ps1 -Telas -Arquivo $FILE_PATH [-Inventario <inventário>]")

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
