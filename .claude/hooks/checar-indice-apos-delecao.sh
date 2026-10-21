#!/bin/bash
# Depois de um comando Bash que pode ter apagado, movido ou renomeado um
# arquivo dentro de conhecimento/, roda validar-indice.ps1 -Todos para achar
# linha órfã no índice (índice cita algo que sumiu). Só dispara quando o
# comando parece uma remoção/movimentação real e menciona conhecimento/ --
# não roda em todo comando Bash. Ver scripts/validar-indice.ps1.
# Triggered as PostToolUse hook on Bash operations.

INPUT=$(cat)

CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Só dispara se o comando parecer remoção/movimentação de arquivo
echo "$CMD" | grep -qiE '(^|[^a-zA-Z0-9_])(rm|del|erase|remove-item|git rm|mv|move-item)([^a-zA-Z0-9_]|$)' || exit 0

# E só se mencionar a pasta conhecimento/
echo "$CMD" | grep -q 'conhecimento' || exit 0

echo "checar-indice-apos-delecao: comando de remoção/movimentação detectado mencionando conhecimento/ -- checando índice..."
powershell -NoProfile -File scripts/validar-indice.ps1 -Todos
