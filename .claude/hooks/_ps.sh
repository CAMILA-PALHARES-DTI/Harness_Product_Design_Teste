#!/bin/bash
# Lançador de PowerShell para os hooks e sensores em bash, em qualquer sistema:
#   - Windows: "powershell" (Windows PowerShell 5.1, o padrão do sistema) ou "pwsh" (PowerShell 7);
#   - macOS/Linux: "pwsh" (PowerShell 7; macOS: `brew install --cask powershell`).
# Uso: source "$(dirname "${BASH_SOURCE[0]}")/_ps.sh"   (a partir de .claude/hooks/)
#      source "$(dirname "${BASH_SOURCE[0]}")/../../hooks/_ps.sh"   (a partir de .claude/skills/<skill>/)
#      run_ps -File scripts/validar-indice.ps1 -Todos
# ps_disponivel devolve 0 se existe algum PowerShell; run_ps devolve 127 (com aviso em stderr) se não existe.

ps_binario() {
  if command -v powershell >/dev/null 2>&1; then echo powershell
  elif command -v pwsh >/dev/null 2>&1; then echo pwsh
  fi
}

ps_disponivel() { [[ -n "$(ps_binario)" ]]; }

run_ps() {
  local bin
  bin=$(ps_binario)
  if [[ -z "$bin" ]]; then
    echo "PowerShell não encontrado — instale o PowerShell 7 (https://aka.ms/powershell; macOS: brew install --cask powershell) para rodar os sensores .ps1." >&2
    return 127
  fi
  "$bin" -NoProfile "$@"
}
