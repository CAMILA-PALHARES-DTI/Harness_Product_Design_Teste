#!/bin/bash
# Regenera conhecimento/INDICE-GERAL.md sempre que o conteúdo de conhecimento/ mudou,
# não importa como a mudança aconteceu (Write, Edit, mv, cp, rm, git pull, edição manual
# no editor...). Ver scripts/gerar-indice-geral.ps1.
#
# Em vez de adivinhar pelo nome da ferramenta ou pelo texto do comando se algo mudou,
# compara uma "impressão digital" da pasta (caminho + tamanho + data de modificação de
# todo arquivo, exceto o próprio INDICE-GERAL.md) com a da última regeneração, guardada em
# .claude/.indice-geral.fingerprint (git-ignored). Só regenera se for diferente — então é
# barato rodar em todo evento e nunca faz trabalho à toa.
#
# Disparado por hooks em: PostToolUse (Write, Edit, Bash), SessionStart e UserPromptSubmit
# (estes dois pegam o que mudou fora do Claude Code). Ver .claude/settings.json.
# Silencioso quando tudo certo — hooks de UserPromptSubmit/SessionStart injetam a saída no contexto.

cat > /dev/null  # consome o JSON do hook; o conteúdo não importa

[ -d conhecimento ] || exit 0

FP_FILE=".claude/.indice-geral.fingerprint"

NOVO=$(find conhecimento -type f ! -name 'INDICE-GERAL.md' -printf '%p|%s|%T@\n' 2>/dev/null | LC_ALL=C sort | md5sum | cut -d' ' -f1)
ANTIGO=$(cat "$FP_FILE" 2>/dev/null)

# Nada mudou desde a última regeneração e o índice existe: não faz nada
if [ "$NOVO" = "$ANTIGO" ] && [ -f conhecimento/INDICE-GERAL.md ]; then
  exit 0
fi

if SAIDA=$(powershell -NoProfile -File scripts/gerar-indice-geral.ps1 2>&1); then
  echo "$NOVO" > "$FP_FILE"
else
  # Não grava a impressão digital: a próxima execução tenta de novo
  echo "atualizar-indice-geral: falha ao regenerar conhecimento/INDICE-GERAL.md:"
  echo "$SAIDA"
fi
exit 0
