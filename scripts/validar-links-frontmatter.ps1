<#
.SYNOPSIS
    Sensor computacional de link/caminho de arquivo. Toda vez que uma skill
    cita `plano-origem`, `briefing-fonte`, `artefato-visual`,
    `pesquisa-relacionada`, `notas-origem`, `plano-pesquisa`, `arquivo-origem`
    (ou qualquer outro campo de frontmatter cujo valor pareça um caminho do
    repositório) no frontmatter do arquivo que acabou de gerar, este script
    confere se esse caminho existe de fato -- em vez de confiar que a skill
    escreveu o caminho certo.

.DESCRIPTION
    Comum a `create-artifacts` (plano-origem), `create-spec` (briefing-fonte,
    artefato-visual), `flow-mapping` (pesquisa-relacionada) e `interpret`
    (notas-origem, plano-pesquisa) -- mas roda sobre qualquer arquivo, não
    exige um esquema por skill como o lint-yaml-bloco.ps1: qualquer campo do
    frontmatter cujo nome bata com a lista conhecida, OU cujo valor pareça
    estruturalmente um caminho do repo (começa com "conhecimento/" ou
    "documentos/"), é checado.

    Duas categorias de achado:
      - "Placeholder nao preenchido" (Alta): o campo ainda tem a marcação de
        template não substituída (ex: "[caminho do arquivo de plano, se
        existir]") -- sinal de que a skill esqueceu de preencher o campo.
      - "Caminho referenciado nao existe" (Alta): o campo tem um valor que
        parece um caminho real, mas o arquivo/pasta não existe no repositório
        -- link quebrado, provavelmente digitado errado ou o arquivo foi
        movido/renomeado depois.

    Valores como "a confirmar", "não", "-", "indefinido" são tratados como
    "sem fonte declarada" e pulados silenciosamente -- não é erro apontar que
    uma fonte não existe ainda.

    Saída: exit code 0 = nenhum campo de caminho com problema.
           exit code 1 = pelo menos um campo aponta para algo que não existe
           ou ainda é um placeholder de template.

.PARAMETER Arquivo
    Caminho do arquivo markdown cujo frontmatter será validado.

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.EXAMPLE
    powershell -File scripts/validar-links-frontmatter.ps1 -Arquivo conhecimento/desenvolvimento/specs/spec-minha-feature-2026-08-22.md
    powershell -File scripts/validar-links-frontmatter.ps1 -Arquivo conhecimento/pesquisa/artefatos/artefato-roteiro-x-2026-09-16.md
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Arquivo,
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Campos de frontmatter conhecidos por convenção deste projeto (checados
#    mesmo que o valor não "pareça" um caminho à primeira vista) -- ver
#    create-artifacts, create-spec, flow-mapping, interpret, process-research-data
# ---------------------------------------------------------------------------

$camposConhecidos = @(
    'plano-origem', 'briefing-fonte', 'artefato-visual', 'pesquisa-relacionada',
    'notas-origem', 'plano-pesquisa', 'arquivo-origem'
)

# valores que significam "nenhuma fonte declarada" -- nunca é achado
$valoresVaziosLegitimos = @('a confirmar', 'nao', 'não', 'n/a', 'na', 'indefinido', '-', 'sim', 'nenhum', 'nenhuma',
                            'no', 'yes', 'none', 'undefined')   # equivalentes em inglês

function Test-ValorVazioLegitimo {
    param([string]$Valor)
    $v = $Valor.Trim().Trim('"').Trim("'").ToLowerInvariant()
    return ($valoresVaziosLegitimos -contains $v) -or [string]::IsNullOrWhiteSpace($v)
}

function Test-PlaceholderDeTemplate {
    param([string]$Valor)
    $v = $Valor.Trim()
    # ainda é o texto de exemplo do template, tipo "[caminho do arquivo ...]"
    return ($v -match '^\[.*\]$')
}

function Test-PareceCaminho {
    param([string]$Valor)
    $v = $Valor.Trim().Trim('"').Trim("'")
    return ($v -match '^(conhecimento|documentos)/')
}

# ---------------------------------------------------------------------------
# 2. Ler o arquivo e extrair o frontmatter (entre as duas primeiras linhas "---")
# ---------------------------------------------------------------------------

$Root = (Resolve-Path -Path $Root).ProviderPath
$caminhoArquivo = if ([System.IO.Path]::IsPathRooted($Arquivo)) { $Arquivo } else { Join-Path $Root $Arquivo }

if (-not (Test-Path $caminhoArquivo)) {
    Write-Error "Arquivo não encontrado: $Arquivo"
    exit 1
}

$linhas = @(Get-Content -Path $caminhoArquivo -Encoding UTF8)

if ($linhas.Count -eq 0 -or $linhas[0].Trim() -ne '---') {
    Write-Output "validar-links-frontmatter: arquivo nao comeca com frontmatter ('---') -- nada para validar."
    exit 0
}

$fimFrontmatter = -1
for ($i = 1; $i -lt $linhas.Count; $i++) {
    if ($linhas[$i].Trim() -eq '---') { $fimFrontmatter = $i; break }
}

if ($fimFrontmatter -lt 0) {
    Write-Output "validar-links-frontmatter: frontmatter aberto (primeiro '---') nunca fechou -- nada para validar com seguranca."
    exit 0
}

$linhasFrontmatter = $linhas[1..($fimFrontmatter - 1)]

# ---------------------------------------------------------------------------
# 3. Parsear o frontmatter em pares chave -> [lista de valores] (suporta
#    escalar simples, lista flow "[a, b]" e lista em bloco "- item")
# ---------------------------------------------------------------------------

$campos = @{}   # chave -> lista de PSCustomObject{ Valor, Linha }

for ($i = 0; $i -lt $linhasFrontmatter.Count; $i++) {
    $linha = $linhasFrontmatter[$i]
    if ($linha -notmatch '^([a-zA-Z0-9_-]+):\s*(.*)$') { continue }

    $chave = $Matches[1]
    $resto = $Matches[2].Trim()
    $linhaAbsoluta = $i + 2   # +1 pela linha "---" inicial, +1 para virar 1-indexado

    $valores = New-Object System.Collections.Generic.List[object]

    if ($resto -match '^\[(.*)\]$') {
        $conteudoInterno = $Matches[1]
        # heurística: "[caminho do arquivo de plano, se existir]" é texto de
        # template com vírgula dentro de uma frase, não uma lista YAML real de
        # caminhos -- só trata como lista flow se pelo menos um item parecer
        # de fato um caminho (tem "/" ou extensão de arquivo)
        $itensCandidatos = $conteudoInterno -split ','
        $pareceListaReal = $false
        foreach ($cand in $itensCandidatos) {
            $c = $cand.Trim()
            # critério mais estrito que "contém uma barra" -- um placeholder em
            # prosa tipo "caminho do artefato/pasta consultado" também tem barra,
            # então só conta como caminho real se começar por uma pasta conhecida
            # da base OU terminar com uma extensão de arquivo típica
            if ($c -match '^(conhecimento|documentos|Reposit[oó]rio)[/\\]' -or $c -match '\.\w{2,5}$') { $pareceListaReal = $true; break }
        }

        if ($pareceListaReal) {
            # lista flow real: [a.md, b.md]
            foreach ($item in $itensCandidatos) {
                if ($item.Trim() -ne '') { $valores.Add([PSCustomObject]@{ Valor = $item.Trim(); Linha = $linhaAbsoluta }) | Out-Null }
            }
        } else {
            # provavelmente placeholder de template ainda não preenchido --
            # mantém os colchetes originais para a checagem de placeholder pegar
            $valores.Add([PSCustomObject]@{ Valor = $resto; Linha = $linhaAbsoluta }) | Out-Null
        }
    } elseif ($resto -eq '') {
        # possível lista em bloco nas linhas seguintes
        $j = $i + 1
        while ($j -lt $linhasFrontmatter.Count -and $linhasFrontmatter[$j] -match '^\s*-\s*(.+)$') {
            $valores.Add([PSCustomObject]@{ Valor = $Matches[1].Trim(); Linha = ($j + 2) }) | Out-Null
            $j++
        }
        if ($valores.Count -eq 0) {
            # campo presente mas sem valor nenhum -- não é erro deste sensor (campo vazio é decisão de conteúdo)
            continue
        }
        $i = $j - 1
    } else {
        $valores.Add([PSCustomObject]@{ Valor = $resto; Linha = $linhaAbsoluta }) | Out-Null
    }

    $campos[$chave] = $valores
}

# ---------------------------------------------------------------------------
# 4. Validar os campos conhecidos + qualquer campo cujo valor pareça caminho
# ---------------------------------------------------------------------------

$achados = New-Object System.Collections.Generic.List[object]

foreach ($chave in $campos.Keys) {
    $ehConhecido = $camposConhecidos -contains $chave
    foreach ($entrada in $campos[$chave]) {
        $valor = $entrada.Valor

        if (Test-ValorVazioLegitimo -Valor $valor) { continue }

        if (Test-PlaceholderDeTemplate -Valor $valor) {
            if ($ehConhecido) {
                $achados.Add([PSCustomObject]@{
                    Severidade = 'Alta'
                    Campo      = $chave
                    Linha      = $entrada.Linha
                    Detalhe    = "Placeholder de template nao preenchido: '$valor'."
                }) | Out-Null
            }
            continue
        }

        # só valida existência se for campo conhecido OU se o valor parecer
        # estruturalmente um caminho do repo -- evita falso positivo em campos
        # de conteúdo livre (ex: um "objetivo" que por acaso cita a palavra "conhecimento")
        if (-not $ehConhecido -and -not (Test-PareceCaminho -Valor $valor)) { continue }

        $valorLimpo = $valor.Trim('"').Trim("'")

        # o valor às vezes traz uma anotação livre entre parênteses depois do
        # caminho de fato (ex: "Repositório/App/Feature (commit abc123, data)")
        # -- isola só a parte que parece caminho antes de testar existência
        if ($valorLimpo -match '^(.*\S)\s+\([^)]*\)$') {
            $possivelPrefixo = $Matches[1]
            if ($possivelPrefixo -match '[/\\]' -or $possivelPrefixo -match '\.\w+$') {
                $valorLimpo = $possivelPrefixo
            }
        }

        # Repositório/ é código-fonte clonado só para consulta, explicitamente
        # git-ignored (ver CLAUDE.md) -- existir ou não depende do ambiente de
        # quem está rodando, então nunca é um "link quebrado" verificável aqui
        if ($valorLimpo -match '^Reposit[oó]rio[/\\]') { continue }

        $caminhoAbsoluto = if ([System.IO.Path]::IsPathRooted($valorLimpo)) { $valorLimpo } else { Join-Path $Root $valorLimpo }

        if (-not (Test-Path $caminhoAbsoluto)) {
            $achados.Add([PSCustomObject]@{
                Severidade = 'Alta'
                Campo      = $chave
                Linha      = $entrada.Linha
                Detalhe    = "Caminho referenciado nao existe: '$valorLimpo'."
            }) | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# 5. Saída
# ---------------------------------------------------------------------------

$achadosOrdenados = @($achados | Sort-Object Linha, Campo)

if ($achadosOrdenados.Count -eq 0) {
    Write-Output "validar-links-frontmatter: todos os caminhos referenciados no frontmatter existem (ou estao legitimamente vazios)."
    exit 0
}

Write-Output "validar-links-frontmatter: $($achadosOrdenados.Count) achado(s) no frontmatter de ${Arquivo}:"
$achadosOrdenados | Format-Table -AutoSize -Wrap Severidade, Campo, Linha, Detalhe | Out-String -Width 200 | Write-Output
exit 1
