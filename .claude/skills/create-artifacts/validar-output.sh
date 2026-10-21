#!/bin/bash
# Valida artefatos gerados pela skill /create-artifacts

source "$(dirname "${BASH_SOURCE[0]}")/../../hooks/_rotulos.sh"  # rótulos por idioma (scripts/rotulos.txt)

ARTEFATOS_DIR="conhecimento/pesquisa/artefatos"
ERRORS=0
WARNINGS=0

# exigir_secoes <arquivo> <nome> <h2|texto> <chave>...: erro para cada título ausente (qualquer idioma do dicionário)
exigir_secoes() {
  local arq="$1" nome="$2" modo="$3" chave re prefixo
  shift 3
  for chave in "$@"; do
    re=$(rotulo_re "$chave")
    prefixo=""; [[ "$modo" == "h2" ]] && prefixo="##[[:space:]]+"
    if ! grep -qiE "${prefixo}${re}" "$arq"; then
      echo "ERRO: Seção '$([[ "$modo" == "h2" ]] && echo '## ')$(rotulo_msg "$chave")' ausente em $nome"
      ERRORS=$((ERRORS + 1))
    fi
  done
}

# Verifica apenas arquivos criados/editados recentemente (últimos 5 minutos)
ARQUIVOS=$(find "$ARTEFATOS_DIR" -name "artefato-*.md" -newer "$ARTEFATOS_DIR/.gitkeep" 2>/dev/null)

if [ -z "$ARQUIVOS" ]; then
  exit 0
fi

for FILE in $ARQUIVOS; do
  FILENAME=$(basename "$FILE")

  # 1. Convenção de nomenclatura: artefato-[tipo]-[slug]-YYYY-MM-DD.md
  if ! echo "$FILENAME" | grep -qE '^artefato-[a-z-]+-[a-z0-9-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$'; then
    echo "ERRO: Nome de arquivo fora do padrão: $FILENAME"
    echo "      Esperado: artefato-[tipo]-[slug]-YYYY-MM-DD.md"
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Frontmatter obrigatório
  if ! grep -q "^tipo:" "$FILE"; then
    echo "ERRO: Campo 'tipo' ausente no frontmatter: $FILENAME"
    ERRORS=$((ERRORS + 1))
  fi

  if ! grep -q "^plano-origem:" "$FILE"; then
    echo "ERRO: Campo 'plano-origem' ausente no frontmatter: $FILENAME"
    ERRORS=$((ERRORS + 1))
  fi

  if ! grep -q "^data-criacao:" "$FILE"; then
    echo "ERRO: Campo 'data-criacao' ausente no frontmatter: $FILENAME"
    ERRORS=$((ERRORS + 1))
  fi

  # 3. Placeholders não preenchidos
  if grep -qE '\[nome da demanda\]|\[nome-do-arquivo\]|\[a preencher\]' "$FILE"; then
    echo "AVISO: Placeholders não preenchidos em: $FILENAME"
    WARNINGS=$((WARNINGS + 1))
  fi

  # 4. Seções obrigatórias por tipo de artefato
  TIPO=$(grep "^tipo:" "$FILE" | sed 's/tipo: *//')

  # Os títulos (português e inglês) vêm de scripts/rotulos.txt (chaves art.*).
  # "h2" exige o título como "## <título>"; "texto" aceita o título em qualquer lugar do arquivo.
  case "$TIPO" in
    roteiro-de-entrevista)
      exigir_secoes "$FILE" "$FILENAME" h2 art.objetivo_sessao art.perfil_participante art.aquecimento art.bloco_principal art.encerramento
      ;;
    screener)
      exigir_secoes "$FILE" "$FILENAME" h2 art.objetivo_recrutamento art.perfil_alvo art.criterios_inclusao art.criterios_exclusao art.perguntas_triagem
      ;;
    tcle)
      exigir_secoes "$FILE" "$FILENAME" texto art.identificacao_pesquisa art.objetivo_pesquisa art.o_que_sera_pedido art.uso_informacoes art.direito_recusa art.declaracao_consentimento
      ;;
    guia-de-facilitacao)
      exigir_secoes "$FILE" "$FILENAME" h2 art.objetivo_teste art.perfil_participante art.setup_tecnico art.cenarios_tarefas art.formulario_observacao
      ;;
    questionario)
      exigir_secoes "$FILE" "$FILENAME" texto art.objetivo art.instrucoes_respondente art.bloco_1 art.espaco_aberto
      ;;
    protocolo-de-observacao)
      exigir_secoes "$FILE" "$FILENAME" h2 art.objetivo_observacao art.o_que_observar art.formulario_registro art.guia_anotacoes
      ;;
  esac
done

echo "Lembrete: confirme se conhecimento/pesquisa/artefatos/index.md foi atualizado com os artefatos criados."

# Resumo
if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "Validação: $ERRORS erro(s) encontrado(s) nos artefatos gerados."
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo "Validação: $WARNINGS aviso(s) — verifique os placeholders antes de usar em campo."
  exit 0
fi

exit 0
