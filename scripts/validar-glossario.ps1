<#
.SYNOPSIS
    Sensor híbrido (computacional + inferencial) de diff de glossário. Antes
    de `insert-knowledge` adicionar um termo novo a `glossario.md`,
    confere se esse termo (ou um sinônimo dele) já existe -- e, se existir,
    devolve a definição atual lado a lado com a proposta, para que a skill
    (ou o usuário) julgue se é a mesma coisa reescrita ou um conflito real.

.DESCRIPTION
    A parte COMPUTACIONAL (o que este script faz sozinho, com confiança):
      - Localiza o termo proposto no glossário atual por nome exato
        (normalizado: minúsculas, trim) OU como sinônimo/variação de um
        termo já existente.
      - Quando encontra, compara a Definição atual com a proposta por
        sobreposição de palavras (mesma técnica usada em check-integrity.ps1
        para título) e classifica a similaridade em uma faixa.

    A parte INFERENCIAL (o que este script NUNCA decide sozinho):
      - Se a diferença de definição é um conflito real (sentido oposto,
        contradição) ou só uma variação de redação/complemento legítimo.
      - Se deve sobrescrever, complementar ou manter os dois registros.
      Isso fica para a skill `insert-knowledge` (Passo 3 dela, "Checagem
      de divergências") ou para o usuário decidir -- o script só entrega as
      duas definições lado a lado e uma classificação de confiança, nunca uma
      resposta pronta.

    Severidades (todas exigem julgamento humano/inferencial antes de agir --
    a severidade aqui mede "quão provável é que seja conflito", não "está
    errado"):
      - Alta: termo já existe, definição proposta tem baixa sobreposição
        com a atual -- possível conflito real, precisa de decisão explícita.
      - Media: termo já existe, definição parecida (alta sobreposição) --
        provável paráfrase/complemento, mas ainda vale conferir.
      - Baixa: termo já existe com definição praticamente idêntica --
        provável duplicata exata, sinaliza só para não gerar bloco à toa.
      - Media (variante): o termo proposto bate com um SINÔNIMO de um termo
        já existente sob outro nome -- risco de registrar o mesmo conceito
        duas vezes com nomes diferentes.

    Saída: exit code 0 = nenhum termo proposto colide com o glossário atual.
           exit code 1 = pelo menos um termo proposto já existe (qualquer
           severidade) -- a skill deve apresentar o diff ao usuário antes de
           gerar o bloco final, nunca decidir sozinha qual definição vale.

.PARAMETER ArquivoNovosTermos
    Caminho de um arquivo markdown com os blocos de termo propostos, no
    mesmo formato usado em glossario.md ("### Termo" + "- **Definição:** ...").
    Pode ter um ou vários termos.

.PARAMETER Termo
    Modo de termo único: nome do termo a checar (alternativa a -ArquivoNovosTermos).

.PARAMETER Definicao
    Modo de termo único: texto da definição proposta (usado com -Termo).

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.EXAMPLE
    powershell -File scripts/validar-glossario.ps1 -ArquivoNovosTermos documentos/gerados/.novos-termos.md
    powershell -File scripts/validar-glossario.ps1 -Termo "Contrato PSC" -Definicao "Acordo comercial entre..."
#>

[CmdletBinding(DefaultParameterSetName = 'Arquivo')]
param(
    [Parameter(ParameterSetName = 'Arquivo', Mandatory = $true)]
    [string]$ArquivoNovosTermos,

    [Parameter(ParameterSetName = 'Unico', Mandatory = $true)]
    [string]$Termo,

    [Parameter(ParameterSetName = 'Unico', Mandatory = $true)]
    [string]$Definicao,

    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_lib-guides.ps1"   # Get-RotuloRegex (scripts/rotulos.txt)
$Root = (Resolve-Path -Path $Root).ProviderPath
$caminhoGlossario = Join-Path $Root 'conhecimento/produto/glossario.md'

if (-not (Test-Path $caminhoGlossario)) {
    Write-Error "Glossário não encontrado em conhecimento/produto/glossario.md"
    exit 1
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Get-CampoDoBloco {
    param([string[]]$Linhas, [int]$Inicio, [int]$Fim, [string]$NomeCampo)
    for ($k = $Inicio; $k -le $Fim; $k++) {
        if ($Linhas[$k] -match "^-\s*\*\*${NomeCampo}:?\*\*\s*(.*)$") {
            return $Matches[1].Trim()
        }
    }
    return ''
}

function Get-TermosDeArquivo {
    <# Parseia blocos "### Termo" + "- **Campo:** valor" a partir de uma
       linha inicial dada (para pular o template de exemplo no glossário
       real, que fica ANTES de "## Termos"). Devolve hashtable
       termoNormalizado -> { TermoOriginal, Definicao, Categoria, Sinonimos, Linha } #>
    param([string[]]$Linhas, [int]$LinhaInicial = 0)

    $termos = @{}
    for ($i = $LinhaInicial; $i -lt $Linhas.Count; $i++) {
        if ($Linhas[$i] -match '^###\s+(.+)$') {
            $nomeOriginal = $Matches[1].Trim()
            $fim = $Linhas.Count - 1
            for ($k = $i + 1; $k -lt $Linhas.Count; $k++) {
                if ($Linhas[$k] -match '^#{2,3}\s' -or $Linhas[$k] -match '^---\s*$') { $fim = $k - 1; break }
            }

            # rótulos dos campos em português e inglês (scripts/rotulos.txt)
            $definicao = Get-CampoDoBloco -Linhas $Linhas -Inicio ($i + 1) -Fim $fim -NomeCampo (Get-RotuloRegex 'campo.definicao')
            $categoria = Get-CampoDoBloco -Linhas $Linhas -Inicio ($i + 1) -Fim $fim -NomeCampo (Get-RotuloRegex 'campo.categoria')
            $sinonimosTexto = Get-CampoDoBloco -Linhas $Linhas -Inicio ($i + 1) -Fim $fim -NomeCampo (Get-RotuloRegex 'campo.sinonimos')

            $sinonimos = @()
            if ($sinonimosTexto -and $sinonimosTexto -notmatch '^\[') {
                $sinonimos = ($sinonimosTexto -split '[,;]') | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ -ne '' }
            }

            $chave = $nomeOriginal.Trim().ToLowerInvariant()
            if ($chave -ne '' -and $chave -ne '[termo]' -and $chave -ne '[term]') {
                $termos[$chave] = [PSCustomObject]@{
                    TermoOriginal = $nomeOriginal
                    Definicao     = $definicao
                    Categoria     = $categoria
                    Sinonimos     = $sinonimos
                    Linha         = $i + 1
                }
            }
            $i = $fim
        }
    }
    return $termos
}

function Get-Similaridade {
    <# Sobreposição de palavras (>3 letras) entre duas strings, 0.0 a 1.0 --
       mesma técnica usada em check-integrity.ps1 para comparar título #>
    param([string]$TextoA, [string]$TextoB)

    $palavrasA = @(($TextoA -split '\s+') | Where-Object { $_.Length -gt 3 } | ForEach-Object { $_.ToLowerInvariant().Trim('.,;:()') })
    $palavrasB = @(($TextoB -split '\s+') | Where-Object { $_.Length -gt 3 } | ForEach-Object { $_.ToLowerInvariant().Trim('.,;:()') })

    if ($palavrasA.Count -eq 0) { return 0.0 }

    $intersecao = @($palavrasA | Where-Object { $palavrasB -contains $_ } | Select-Object -Unique)
    $uniaoBase = @($palavrasA | Select-Object -Unique).Count
    if ($uniaoBase -eq 0) { return 0.0 }

    return [double]$intersecao.Count / [double]$uniaoBase
}

# ---------------------------------------------------------------------------
# 1. Ler o glossário atual (só a partir de "## Termos", pulando o template)
# ---------------------------------------------------------------------------

$linhasGlossario = @(Get-Content -Path $caminhoGlossario -Encoding UTF8)
$linhaTermos = 0
for ($i = 0; $i -lt $linhasGlossario.Count; $i++) {
    if ($linhasGlossario[$i] -match '^##\s+Termos\s*$') { $linhaTermos = $i; break }
}
$termosAtuais = Get-TermosDeArquivo -Linhas $linhasGlossario -LinhaInicial $linhaTermos

# índice de sinônimo -> termo canônico que o possui (para achar "termo novo
# que na verdade já existe sob outro nome")
$indiceSinonimos = @{}
foreach ($chave in $termosAtuais.Keys) {
    foreach ($syn in $termosAtuais[$chave].Sinonimos) {
        if (-not $indiceSinonimos.ContainsKey($syn)) { $indiceSinonimos[$syn] = $termosAtuais[$chave].TermoOriginal }
    }
}

# ---------------------------------------------------------------------------
# 2. Montar a lista de termos propostos (arquivo ou termo único)
# ---------------------------------------------------------------------------

$propostos = @{}
if ($PSCmdlet.ParameterSetName -eq 'Unico') {
    $chave = $Termo.Trim().ToLowerInvariant()
    $propostos[$chave] = [PSCustomObject]@{ TermoOriginal = $Termo; Definicao = $Definicao; Linha = 1 }
} else {
    $caminhoNovos = if ([System.IO.Path]::IsPathRooted($ArquivoNovosTermos)) { $ArquivoNovosTermos } else { Join-Path $Root $ArquivoNovosTermos }
    if (-not (Test-Path $caminhoNovos)) {
        Write-Error "Arquivo de novos termos não encontrado: $ArquivoNovosTermos"
        exit 1
    }
    $linhasNovos = @(Get-Content -Path $caminhoNovos -Encoding UTF8)
    $propostos = Get-TermosDeArquivo -Linhas $linhasNovos -LinhaInicial 0
}

if ($propostos.Count -eq 0) {
    Write-Output "validar-glossario: nenhum bloco '### Termo' encontrado na entrada -- nada para comparar."
    exit 0
}

# ---------------------------------------------------------------------------
# 3. Comparar cada termo proposto com o glossário atual
# ---------------------------------------------------------------------------

$achados = New-Object System.Collections.Generic.List[object]

foreach ($chave in $propostos.Keys) {
    $novo = $propostos[$chave]

    if ($termosAtuais.ContainsKey($chave)) {
        $atual = $termosAtuais[$chave]
        $sim = Get-Similaridade -TextoA $atual.Definicao -TextoB $novo.Definicao

        $severidade = if ($sim -ge 0.85) { 'Baixa' } elseif ($sim -ge 0.5) { 'Media' } else { 'Alta' }
        $rotulo = if ($sim -ge 0.85) { 'Definicao praticamente identica (provavel duplicata)' }
                  elseif ($sim -ge 0.5) { 'Definicao parecida (provavel parafrase/complemento -- revisar)' }
                  else { 'Definicao substancialmente diferente (POSSIVEL CONFLITO REAL)' }

        $achados.Add([PSCustomObject]@{
            Severidade       = $severidade
            Termo            = $novo.TermoOriginal
            Situacao         = $rotulo
            Similaridade     = [Math]::Round($sim * 100)
            LinhaAtual       = $atual.Linha
            DefinicaoAtual   = $atual.Definicao
            DefinicaoNova    = $novo.Definicao
        }) | Out-Null
    } elseif ($indiceSinonimos.ContainsKey($chave)) {
        $achados.Add([PSCustomObject]@{
            Severidade       = 'Media'
            Termo            = $novo.TermoOriginal
            Situacao         = "Ja existe como sinonimo/variacao do termo '$($indiceSinonimos[$chave])' -- risco de registrar o mesmo conceito duas vezes"
            Similaridade     = $null
            LinhaAtual       = $null
            DefinicaoAtual   = ''
            DefinicaoNova    = $novo.Definicao
        }) | Out-Null
    }
}

# ---------------------------------------------------------------------------
# 4. Saída
# ---------------------------------------------------------------------------

$achadosOrdenados = @($achados | Sort-Object @{Expression = {
        switch ($_.Severidade) { 'Alta' { 0 }; 'Media' { 1 }; 'Baixa' { 2 }; default { 3 } }
    }}, Termo)

if ($achadosOrdenados.Count -eq 0) {
    Write-Output "validar-glossario: $($propostos.Count) termo(s) proposto(s), nenhum colide com o glossario atual."
    exit 0
}

Write-Output "validar-glossario: $($achadosOrdenados.Count) de $($propostos.Count) termo(s) proposto(s) ja existem (ou colidem) no glossario:"
Write-Output ""
foreach ($a in $achadosOrdenados) {
    Write-Output "[$($a.Severidade)] '$($a.Termo)' -- $($a.Situacao)"
    if ($a.LinhaAtual) { Write-Output "  Linha no glossario: $($a.LinhaAtual)   Similaridade: $($a.Similaridade)%" }
    if ($a.DefinicaoAtual) { Write-Output "  Definicao ATUAL : $($a.DefinicaoAtual)" }
    Write-Output "  Definicao NOVA  : $($a.DefinicaoNova)"
    Write-Output ""
}

Write-Output "Nenhuma decisao foi tomada automaticamente -- julgar se e conflito real (e o que fazer: sobrescrever, complementar ou manter os dois) e sempre inferencial/humano."

exit 1
