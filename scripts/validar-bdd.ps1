<#
.SYNOPSIS
    Sensor computacional de critério de aceite BDD. Confirma que todo cenário
    "- [ ] **Cenário:** ..." gerado por create-spec tem as três linhas
    Dado/Quando/Então presentes, preenchidas e na ordem certa -- em vez de
    confiar que o modelo lembrou de escrever as três toda vez.

.DESCRIPTION
    Formato esperado (Passo 8 de create-spec):

        - [ ] **Cenário:** [nome curto]
              **Dado** [pré-condição]
              **Quando** [ação/evento]
              **Então** [resultado verificável]

    Para cada bloco "- [ ] **Cenário:** ..." encontrado (delimitado até o
    próximo cenário, o próximo "## SPEC-"/"### US-", ou o fim do arquivo), confere:

      - **Linha ausente (Alta):** falta "**Dado**", "**Quando**" ou "**Então**".
      - **Campo vazio (Alta):** a linha existe mas não tem texto depois do
        marcador em negrito (ex: "**Dado**" sozinho, sem pré-condição).
      - **Linha duplicada (Media):** o mesmo marcador aparece mais de uma vez
        dentro do mesmo cenário -- provavelmente colou/repetiu por engano.
      - **Fora de ordem (Media):** Dado/Quando/Então aparecem, mas não nessa
        ordem dentro do bloco -- indício de bloco malformado ou cenário
        misturado com o de cima/baixo.

    Não julga a QUALIDADE do conteúdo (se "Então" tem adjetivo vago sem
    quantificação, se "Dado" descreve estado de verdade e não ação) -- isso é
    checagem semântica, feita pela sabatina da própria skill ou por
    `audit-spec`, não por este sensor de estrutura.

    Também sinaliza (Media) toda seção "Critério de aceite (BDD)" que não tem
    NENHUM cenário dentro -- sinal de que a US ficou sem critério de aceite
    apesar da seção existir.

    Saída: exit code 0 = nenhum achado de severidade Alta.
           exit code 1 = pelo menos um achado de severidade Alta (linha
           ausente ou campo vazio) -- corrigir antes de considerar a US
           pronta para desenvolvimento.

.PARAMETER Arquivo
    Caminho do arquivo markdown gerado por create-spec (um ou mais US).

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.EXAMPLE
    powershell -File scripts/validar-bdd.ps1 -Arquivo conhecimento/desenvolvimento/specs/spec-[nome-da-feature]-2026-09-01.md
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Arquivo,
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path -Path $Root).ProviderPath
$caminho = if ([System.IO.Path]::IsPathRooted($Arquivo)) { $Arquivo } else { Join-Path $Root $Arquivo }

if (-not (Test-Path $caminho)) {
    Write-Error "Arquivo não encontrado: $Arquivo"
    exit 1
}

$linhas = @(Get-Content -Path $caminho -Encoding UTF8)

# ---------------------------------------------------------------------------
# 1. Localizar cenários: linhas "- [ ] **Cenário:** ..." (ou "[x]"/"[X]")
#    Cada bloco vai até o próximo cenário, o próximo "## SPEC-"/"### US-" / "## " de
#    nível 2, ou o fim do arquivo.
# ---------------------------------------------------------------------------

. "$PSScriptRoot\_lib-guides.ps1"   # Get-RotuloRegex: rótulos do BDD em português e inglês (scripts/rotulos.txt)

$reCenario  = Get-RotuloRegex 'bdd.cenario'
$reCriterio = Get-RotuloRegex 'bdd.criterio_aceite'
$reDado     = Get-RotuloRegex 'bdd.dado'
$reQuando   = Get-RotuloRegex 'bdd.quando'
$reEntao    = Get-RotuloRegex 'bdd.entao'

$padraoCenario = "^\s*-\s*\[.?\]\s*\*\*${reCenario}:?\*\*\s*(.*)$"
$padraoUS = '^#{2,3}\s+(US|SPEC)-'

$indicesCenario = New-Object System.Collections.Generic.List[int]
for ($i = 0; $i -lt $linhas.Count; $i++) {
    if ($linhas[$i] -match $padraoCenario) { $indicesCenario.Add($i) | Out-Null }
}

$achados = New-Object System.Collections.Generic.List[object]

function Get-USAtual {
    param([string[]]$Linhas, [int]$Indice)
    for ($k = $Indice; $k -ge 0; $k--) {
        if ($Linhas[$k] -match '^#{2,3}\s+((US|SPEC)-\S+.*)$') { return $Matches[1].Trim() }
    }
    return '(US não identificada)'
}

# ---------------------------------------------------------------------------
# 1.5 Checagem por US: toda seção "Critério de aceite (BDD)" precisa ter pelo
#     menos um cenário DENTRO do trecho daquela US -- não basta ter cenário
#     em algum lugar do arquivo (isso escondia uma US inteira sem nenhum
#     critério de aceite, desde que outra US no mesmo arquivo tivesse).
# ---------------------------------------------------------------------------

$indicesUS = New-Object System.Collections.Generic.List[int]
for ($i = 0; $i -lt $linhas.Count; $i++) {
    if ($linhas[$i] -match '^#{2,3}\s+(US|SPEC)-') { $indicesUS.Add($i) | Out-Null }
}

if ($indicesUS.Count -eq 0) {
    # arquivo sem nenhuma seção "## SPEC-"/"### US-" -- trata o arquivo inteiro como um único bloco
    $indicesUS.Add(0) | Out-Null
}

for ($u = 0; $u -lt $indicesUS.Count; $u++) {
    $inicioUS = $indicesUS[$u]
    $fimUS = if ($u + 1 -lt $indicesUS.Count) { $indicesUS[$u + 1] - 1 } else { $linhas.Count - 1 }

    $nomeUS = if ($linhas[$inicioUS] -match '^#{2,3}\s+((US|SPEC)-\S+.*)$') { $Matches[1].Trim() } else { '(arquivo inteiro)' }

    $temSecaoCriterio = $false
    for ($k = $inicioUS; $k -le $fimUS; $k++) {
        if ($linhas[$k] -match "\*\*${reCriterio}") { $temSecaoCriterio = $true; break }
    }
    if (-not $temSecaoCriterio) { continue }

    $cenariosNestaUS = @($indicesCenario | Where-Object { $_ -ge $inicioUS -and $_ -le $fimUS })
    if ($cenariosNestaUS.Count -eq 0) {
        $achados.Add([PSCustomObject]@{
            Severidade = 'Alta'
            US         = $nomeUS
            Cenario    = '(nenhum)'
            Problema   = 'Nenhum cenario BDD encontrado'
            Detalhe    = "'$nomeUS' tem secao 'Criterio de aceite (BDD)' mas nenhum bloco '- [ ] **Cenario:**' foi encontrado dentro dela."
        }) | Out-Null
    }
}

if ($indicesCenario.Count -gt 0) {
    for ($idx = 0; $idx -lt $indicesCenario.Count; $idx++) {
        $inicio = $indicesCenario[$idx]
        $fim = $linhas.Count - 1
        # limite do bloco: próximo cenário, próximo "## SPEC-"/"### US-", ou fim do arquivo
        if ($idx + 1 -lt $indicesCenario.Count) { $fim = [Math]::Min($fim, $indicesCenario[$idx + 1] - 1) }
        for ($k = $inicio + 1; $k -le $fim; $k++) {
            if ($linhas[$k] -match $padraoUS) { $fim = $k - 1; break }
        }

        $usAtual = Get-USAtual -Linhas $linhas -Indice $inicio
        $nomeCenario = if ($linhas[$inicio] -match $padraoCenario) { $Matches[1].Trim() } else { "(linha $($inicio + 1))" }

        # coleta as ocorrências de Dado/Quando/Então dentro do bloco, na ordem em que aparecem
        $ocorrencias = New-Object System.Collections.Generic.List[object]
        for ($k = $inicio; $k -le $fim; $k++) {
            if ($linhas[$k] -match "^\s*\*\*${reDado}\*\*\s*(.*)$") {
                $ocorrencias.Add([PSCustomObject]@{ Campo = 'Dado'; Linha = $k + 1; Valor = $Matches[1].Trim() }) | Out-Null
            } elseif ($linhas[$k] -match "^\s*\*\*${reQuando}\*\*\s*(.*)$") {
                $ocorrencias.Add([PSCustomObject]@{ Campo = 'Quando'; Linha = $k + 1; Valor = $Matches[1].Trim() }) | Out-Null
            } elseif ($linhas[$k] -match "^\s*\*\*${reEntao}\*\*\s*(.*)$") {
                $ocorrencias.Add([PSCustomObject]@{ Campo = 'Então'; Linha = $k + 1; Valor = $Matches[1].Trim() }) | Out-Null
            }
        }

        foreach ($campo in @('Dado', 'Quando', 'Então')) {
            $doCampo = @($ocorrencias | Where-Object { $_.Campo -eq $campo })

            if ($doCampo.Count -eq 0) {
                $achados.Add([PSCustomObject]@{
                    Severidade = 'Alta'
                    US         = $usAtual
                    Cenario    = $nomeCenario
                    Problema   = "Linha '$campo' ausente"
                    Detalhe    = "Cenario '$nomeCenario' (linha $($inicio + 1)) nao tem nenhuma linha '**$campo**'."
                }) | Out-Null
                continue
            }

            if ($doCampo.Count -gt 1) {
                $achados.Add([PSCustomObject]@{
                    Severidade = 'Media'
                    US         = $usAtual
                    Cenario    = $nomeCenario
                    Problema   = "Linha '$campo' duplicada"
                    Detalhe    = "Cenario '$nomeCenario' tem $($doCampo.Count) linhas '**$campo**' (linhas $((@($doCampo | ForEach-Object { $_.Linha })) -join ', '))."
                }) | Out-Null
            }

            foreach ($ocorrencia in $doCampo) {
                if ([string]::IsNullOrWhiteSpace($ocorrencia.Valor)) {
                    $achados.Add([PSCustomObject]@{
                        Severidade = 'Alta'
                        US         = $usAtual
                        Cenario    = $nomeCenario
                        Problema   = "Campo '$campo' vazio"
                        Detalhe    = "Linha $($ocorrencia.Linha): '**$campo**' presente mas sem texto depois do marcador."
                    }) | Out-Null
                }
            }
        }

        # ordem: se os três existem, a ordem das linhas deve ser Dado < Quando < Então
        $linhaDado = (@($ocorrencias | Where-Object { $_.Campo -eq 'Dado' }) | Select-Object -First 1).Linha
        $linhaQuando = (@($ocorrencias | Where-Object { $_.Campo -eq 'Quando' }) | Select-Object -First 1).Linha
        $linhaEntao = (@($ocorrencias | Where-Object { $_.Campo -eq 'Então' }) | Select-Object -First 1).Linha

        if ($linhaDado -and $linhaQuando -and $linhaEntao) {
            if (-not ($linhaDado -lt $linhaQuando -and $linhaQuando -lt $linhaEntao)) {
                $achados.Add([PSCustomObject]@{
                    Severidade = 'Media'
                    US         = $usAtual
                    Cenario    = $nomeCenario
                    Problema   = 'Fora de ordem'
                    Detalhe    = "Cenario '$nomeCenario': as linhas Dado/Quando/Entao nao aparecem nessa ordem (linhas $linhaDado/$linhaQuando/$linhaEntao)."
                }) | Out-Null
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Saída
# ---------------------------------------------------------------------------

$achadosOrdenados = @($achados | Sort-Object US, Cenario)

if ($achadosOrdenados.Count -eq 0) {
    Write-Output "validar-bdd: $($indicesCenario.Count) cenario(s) BDD validados -- todos com Dado/Quando/Entao presentes, preenchidos e em ordem."
    exit 0
}

Write-Output "validar-bdd: $($achadosOrdenados.Count) achado(s) (de $($indicesCenario.Count) cenario(s) no arquivo):"
$achadosOrdenados | Format-Table -AutoSize -Wrap Severidade, US, Cenario, Problema, Detalhe | Out-String -Width 220 | Write-Output

$temAlta = @($achadosOrdenados | Where-Object { $_.Severidade -eq 'Alta' }).Count -gt 0
if ($temAlta) { exit 1 } else { exit 0 }
