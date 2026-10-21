<#
.SYNOPSIS
    Biblioteca compartilhada de parsing dos guides canônicos (dores, dependências,
    riscos, decisões, OKRs). Usada por check-integrity.ps1, validar-referencias.ps1
    e validar-sequencia-id.ps1 — mantém a lógica de leitura de índice num único
    lugar, para os três sensores nunca divergirem entre si sobre o que é "canônico".

    Dot-source este arquivo no início de cada script:
        . "$PSScriptRoot\_lib-guides.ps1"
#>

function Get-Guias {
    <# Lista fixa dos 6 guides que usam o esquema de ID Prefixo+número #>
    return @(
        [PSCustomObject]@{ Prefixo = 'DOR'; Arquivo = 'conhecimento/produto/dores-de-processo.md' }
        [PSCustomObject]@{ Prefixo = 'DEP'; Arquivo = 'conhecimento/planejamento/dependencias.md' }
        [PSCustomObject]@{ Prefixo = 'RIS'; Arquivo = 'conhecimento/planejamento/riscos.md' }
        [PSCustomObject]@{ Prefixo = 'D';   Arquivo = 'conhecimento/planejamento/decisoes-aprovadas.md' }
        [PSCustomObject]@{ Prefixo = 'OKR'; Arquivo = 'conhecimento/planejamento/okrs.md' }
        [PSCustomObject]@{ Prefixo = 'FLX'; Arquivo = 'conhecimento/produto/fluxos-e-jornadas/fluxos-e-jornadas.md' }
    )
}

function Resolve-Raiz {
    param([string]$Root)
    return (Resolve-Path -Path $Root).ProviderPath
}

function Get-CaminhoRelativo {
    param([string]$CaminhoCompleto, [string]$Base)
    $baseComBarra = $Base
    if (-not $baseComBarra.EndsWith('\') -and -not $baseComBarra.EndsWith('/')) {
        $baseComBarra += '\'
    }
    if ($CaminhoCompleto.StartsWith($baseComBarra, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $CaminhoCompleto.Substring($baseComBarra.Length)
    }
    return $CaminhoCompleto
}

function Split-TableRow {
    param([string]$Linha)
    $celulas = $Linha.Trim()
    $celulas = $celulas.Trim('|')
    return ($celulas -split '\|') | ForEach-Object { $_.Trim() }
}

# ---------------------------------------------------------------------------
# Rótulos por idioma — scripts/rotulos.txt
# O conteúdo dos arquivos segue o idioma configurado no CLAUDE.md (português ou inglês); os sensores
# precisam reconhecer títulos, colunas e valores em qualquer um deles. O dicionário é o único lugar
# onde esses textos moram (formato e regras no cabeçalho do próprio rotulos.txt).
# ---------------------------------------------------------------------------

function Get-RotuloVariantes {
    <# Todas as variantes (todas as colunas/idiomas) da chave, sem repetir. Chave desconhecida = erro. #>
    param([Parameter(Mandatory = $true)][string]$Chave)

    $arquivo = Join-Path $PSScriptRoot 'rotulos.txt'
    if (-not (Test-Path $arquivo)) { throw "Dicionário de rótulos não encontrado: $arquivo" }

    $variantes = New-Object System.Collections.Generic.List[string]
    foreach ($linha in (Get-Content -Path $arquivo -Encoding UTF8)) {
        if ([string]::IsNullOrWhiteSpace($linha) -or $linha.TrimStart().StartsWith('#')) { continue }
        $partes = $linha -split '\|'
        if ($partes[0].Trim() -ne $Chave) { continue }
        foreach ($v in (($partes | Select-Object -Skip 1) -join ';') -split ';') {
            $v = $v.Trim()
            if ($v -ne '' -and -not $variantes.Contains($v)) { $variantes.Add($v) | Out-Null }
        }
    }
    if ($variantes.Count -eq 0) { throw "Chave de rótulo desconhecida em rotulos.txt: $Chave" }
    return $variantes.ToArray()
}

function Get-RotuloRegex {
    <# Alternância de regex (escapada), SEM grupo de captura, com todas as variantes: (?:A|B|C). Não desloca
       os índices de $Matches dos padrões que a usam. O -match do PowerShell ignora maiúsculas. #>
    param([Parameter(Mandatory = $true)][string]$Chave)
    return '(?:' + ((Get-RotuloVariantes -Chave $Chave | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')'
}

function Test-RotuloIgual {
    <# $true se o valor (sem espaços nas pontas, sem diferenciar maiúsculas) é uma variante da chave. #>
    param([string]$Valor, [Parameter(Mandatory = $true)][string]$Chave)
    return (@(Get-RotuloVariantes -Chave $Chave) -contains $Valor.Trim())
}

function Find-ColunaIndice {
    <# Posição da coluna do cabeçalho que é variante da chave (-1 se nenhuma). #>
    param([string[]]$Cabecalho, [string]$Chave)
    $variantes = @(Get-RotuloVariantes -Chave $Chave)
    for ($c = 0; $c -lt $Cabecalho.Count; $c++) {
        if ($variantes -contains $Cabecalho[$c].Trim()) { return $c }
    }
    return -1
}

function Get-IndiceTable {
    <# Localiza a primeira tabela markdown com coluna "Status" e devolve os
       registros (Id, Titulo, Status, Linha). Os nomes das colunas (Título/Title,
       Objetivo/Goal, Status) vêm de scripts/rotulos.txt. #>
    param([string[]]$Linhas)

    $resultados = New-Object System.Collections.Generic.List[object]

    for ($i = 0; $i -lt $Linhas.Count; $i++) {
        if ($Linhas[$i] -match '^\|\s*ID\s*\|') {
            $cabecalho = Split-TableRow -Linha $Linhas[$i]
            $idxStatus = Find-ColunaIndice -Cabecalho $cabecalho -Chave 'coluna.status'
            $idxTitulo = Find-ColunaIndice -Cabecalho $cabecalho -Chave 'coluna.titulo'
            if ($idxTitulo -lt 0) { $idxTitulo = Find-ColunaIndice -Cabecalho $cabecalho -Chave 'coluna.objetivo' }

            if ($idxStatus -ge 0 -and $idxTitulo -ge 0) {
                $j = $i + 2   # pula cabeçalho + linha separadora ---
                while ($j -lt $Linhas.Count -and $Linhas[$j] -match '^\|.*\|\s*$') {
                    $celulas = Split-TableRow -Linha $Linhas[$j]
                    $maxIdx = [Math]::Max($idxStatus, $idxTitulo)
                    if ($celulas.Count -gt $maxIdx) {
                        $idVal = $celulas[0]
                        if ($idVal -match '^[A-Z]+-?\d+$') {
                            $resultados.Add([PSCustomObject]@{
                                Id     = $idVal
                                Titulo = $celulas[$idxTitulo]
                                Status = $celulas[$idxStatus]
                                Linha  = $j + 1
                            })
                        }
                    }
                    $j++
                }
            }
            break   # só a primeira tabela de índice interessa
        }
    }
    return $resultados
}

function Get-BlocoStatus {
    <# Procura "### <Id> — ..." e devolve o valor de "**Status:**" dentro
       do bloco detalhado correspondente, se existir #>
    param([string[]]$Linhas, [string]$AlvoId)

    for ($i = 0; $i -lt $Linhas.Count; $i++) {
        if ($Linhas[$i] -match "^###\s+\[?$AlvoId\]?\s*[—\-]") {
            for ($j = $i + 1; $j -lt $Linhas.Count -and $j -lt ($i + 15); $j++) {
                if ($Linhas[$j] -match '^###\s') { break }
                if ($Linhas[$j] -match '^\-\s*\*\*Status:?\*\*\s*(.+)$') {
                    return @{ Status = $Matches[1].Trim(); Linha = $j + 1 }
                }
            }
            return $null
        }
    }
    return $null
}

function Get-CanonicoIds {
    <# Monta o dicionário canônico Id -> {Titulo, Status, Arquivo, Prefixo, Linhas}
       lendo o índice de todos os guides. $Root já deve estar resolvido
       (Resolve-Raiz). Emite Write-Warning para guide não encontrado, não falha. #>
    param([string]$Root)

    $canonico = @{}
    foreach ($g in (Get-Guias)) {
        $caminho = Join-Path $Root $g.Arquivo
        if (-not (Test-Path $caminho)) {
            Write-Warning "Guide não encontrado: $($g.Arquivo)"
            continue
        }
        $linhas = @(Get-Content -Path $caminho -Encoding UTF8)
        $tabela = Get-IndiceTable -Linhas $linhas
        foreach ($row in $tabela) {
            $canonico[$row.Id] = [PSCustomObject]@{
                Id      = $row.Id
                Titulo  = $row.Titulo
                Status  = $row.Status
                Arquivo = $g.Arquivo
                Prefixo = $g.Prefixo
                Linhas  = $linhas
            }
        }
    }
    return $canonico
}

function Get-NumeroDoId {
    <# Extrai a parte numérica de um ID, dado o prefixo (DOR/DEP/RIS/D/OKR/FLX) #>
    param([string]$IdCompleto, [string]$Prefixo)
    if ($Prefixo -eq 'OKR') {
        return [int]($IdCompleto -replace '^OKR-', '')
    }
    return [int]($IdCompleto -replace "^$Prefixo", '')
}

function Format-IdComPrefixo {
    <# Monta o ID formatado (DEP007, OKR-3, D026, ...) a partir do prefixo e número #>
    param([string]$Prefixo, [int]$Numero)
    if ($Prefixo -eq 'OKR') {
        return "OKR-$Numero"
    }
    return "$Prefixo" + $Numero.ToString('D3')
}
