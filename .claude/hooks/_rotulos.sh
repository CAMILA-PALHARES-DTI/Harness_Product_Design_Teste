#!/bin/bash
# Biblioteca compartilhada dos sensores em bash: lê scripts/rotulos.txt (dicionário de rótulos por idioma)
# para que os validar-output.sh reconheçam títulos, campos e valores em qualquer idioma suportado.
# Uso, no início de um validar-output.sh:
#   source "$(dirname "${BASH_SOURCE[0]}")/../../hooks/_rotulos.sh"
# Funções:
#   rotulo_variantes <chave>        uma variante por linha (todas as colunas/idiomas)
#   rotulo_re <chave>               alternância ERE das variantes, com metacaracteres escapados: (A|B)
#   rotulo_msg <chave>              "A / B" — para mensagens de erro
#   tem_secao <chave> <conteudo>    0 se existe "## <variante>" (sem diferenciar maiúsculas)
#   bloco_secao <chave> <conteudo>  imprime o corpo da seção "## <variante>" até o próximo "## "
#   tem_texto <chave> <conteudo>    0 se alguma variante aparece em qualquer lugar do conteúdo
# Chave desconhecida: avisa em stderr e a regex nunca casa (o sensor reporta ausência, nunca passa em silêncio).

_ROT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROTULOS_FILE="${ROTULOS_FILE:-$_ROT_DIR/../../scripts/rotulos.txt}"

rotulo_variantes() {
  local chave="$1" linha k rest v
  local -a partes
  while IFS= read -r linha || [[ -n "$linha" ]]; do
    linha="${linha%$'\r'}"
    [[ -z "$linha" || "${linha:0:1}" == "#" ]] && continue
    k="${linha%%|*}"; k="${k//[[:space:]]/}"
    [[ "$k" == "$chave" ]] || continue
    rest="${linha#*|}"; rest="${rest//|/;}"
    IFS=';' read -ra partes <<< "$rest"
    for v in "${partes[@]}"; do
      v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
      [[ -n "$v" ]] && printf '%s\n' "$v"
    done
  done < "$ROTULOS_FILE"
}

rotulo_re() {
  local alt="" v esc
  while IFS= read -r v; do
    esc=$(printf '%s' "$v" | sed 's/[][\\.*^$+?(){}|]/\\&/g')
    alt+="${alt:+|}$esc"
  done < <(rotulo_variantes "$1")
  if [[ -z "$alt" ]]; then
    echo "rotulos: chave desconhecida '$1' em $ROTULOS_FILE" >&2
    echo 'x^x'
    return
  fi
  echo "($alt)"
}

rotulo_msg() {
  local out="" v
  while IFS= read -r v; do out+="${out:+ / }$v"; done < <(rotulo_variantes "$1")
  echo "$out"
}

tem_secao() {
  local re; re=$(rotulo_re "$1")
  grep -qiE "^##[[:space:]]+${re}" <<< "$2"
}

tem_texto() {
  local re; re=$(rotulo_re "$1")
  grep -qiE "${re}" <<< "$2"
}

bloco_secao() {
  # Não usa [[ =~ ]] com o rótulo: no Git Bash do Windows, regex com acentos (ç, õ...) derruba o bash.
  # A localização do título é feita pelo grep; o corte no próximo "## " usa só glob ASCII.
  local re ini linha
  re=$(rotulo_re "$1")
  ini=$(grep -niE "^##[[:space:]]+${re}" <<< "$2" | head -1 | cut -d: -f1)
  [[ -z "$ini" ]] && return 0
  tail -n +"$((ini + 1))" <<< "$2" | while IFS= read -r linha; do
    [[ "$linha" == "## "* ]] && break
    printf '%s\n' "$linha"
  done
}
