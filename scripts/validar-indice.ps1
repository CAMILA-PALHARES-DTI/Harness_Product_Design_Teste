<#
.SYNOPSIS
    Sensor computacional de índice órfão/desatualizado. Compara os arquivos e
    subpastas que existem de verdade dentro de uma pasta com o que o
    `index.md` dessa pasta afirma existir -- em vez de confiar que a skill que
    salvou o arquivo lembrou de atualizar o índice.

.DESCRIPTION
    Toda skill deste projeto que salva um arquivo em `conhecimento/` termina
    com uma instrução do tipo "salve em X e atualize X/index.md" -- isso hoje
    depende inteiramente da disciplina do modelo em cada execução. Este script
    confere de fato:

      - **Arquivo/pasta órfã (Alta):** existe em disco, mas nenhuma linha de
        nenhuma tabela do `index.md` da pasta cita esse nome -- sinal de que
        o índice não foi atualizado quando o arquivo foi criado.
      - **Linha órfã no índice (Alta):** o índice cita um nome que não existe
        mais em disco -- sinal de arquivo renomeado/movido/apagado sem
        atualizar o índice.
      - **index.md ausente (Alta):** a pasta não tem `index.md` nenhum, mas
        tem conteúdo -- quebra a convenção do projeto.

    Modo -Remover (opt-in, nunca automático): remove fisicamente do index.md
    toda linha de tabela cujo nome não existe mais em disco ("Linha órfã no
    índice"). É seguro automatizar só essa direção -- remover uma referência
    a algo comprovadamente inexistente não exige inventar conteúdo. Já
    "Arquivo/pasta órfã" (existe em disco, falta linha) nunca é corrigido
    sozinho por este script -- exigiria inventar uma descrição para a coluna,
    o que é decisão de skill/humano, não deste sensor.

    Não interpreta o CONTEÚDO das linhas (isso é trabalho de skill/humano) --
    só confere se o nome do arquivo/pasta aparece em alguma tabela do índice
    e se cada nome citado no índice ainda existe. Considera toda tabela
    markdown do arquivo (não só a que vem depois de "## Arquivos"), porque
    índices de domínio (ex: conhecimento/pesquisa/index.md) usam cabeçalhos
    como "## Subpastas" ou "## Domínios" para a mesma finalidade.

.PARAMETER Pasta
    Uma pasta específica a validar (deve conter um index.md, ou deveria).

.PARAMETER Todos
    Varre todo `conhecimento/` -- roda a checagem em toda pasta que tenha
    (ou devesse ter) um index.md.

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.PARAMETER Remover
    Remove fisicamente as linhas "Linha órfã no índice" encontradas (índice
    cita algo que não existe mais). Nunca remove nem adiciona nada relativo a
    "Arquivo/pasta órfã" -- só a direção "índice cita algo que sumiu".

.EXAMPLE
    powershell -File scripts/validar-indice.ps1 -Pasta conhecimento/planejamento/backlogs
    powershell -File scripts/validar-indice.ps1 -Todos
    powershell -File scripts/validar-indice.ps1 -Todos -Remover
#>

[CmdletBinding(DefaultParameterSetName = 'Pasta')]
param(
    [Parameter(ParameterSetName = 'Pasta', Mandatory = $true)]
    [string]$Pasta,

    [Parameter(ParameterSetName = 'Todos', Mandatory = $true)]
    [switch]$Todos,

    [switch]$Remover,

    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path -Path $Root).ProviderPath

function Split-TableRowLocal {
    param([string]$Linha)
    $c = $Linha.Trim().Trim('|')
    return ($c -split '\|') | ForEach-Object { $_.Trim() }
}

function Get-NomesReferenciados {
    <# Lê um index.md e devolve o conjunto de nomes citados na primeira coluna
       de toda tabela markdown do arquivo, sem barra final e sem crases #>
    param([string]$CaminhoIndice)

    $nomes = New-Object System.Collections.Generic.HashSet[string]
    # IMPORTANTE: "return $nomes" sozinho faria o PowerShell enumerar a coleção
    # no pipeline (desenrolando-a) -- se vazia, o chamador recebe $null em vez
    # de um HashSet vazio. O operador vírgula (",$nomes") impede isso em
    # todo "return" desta função.
    if (-not (Test-Path $CaminhoIndice)) { return , $nomes }

    $linhas = @(Get-Content -Path $CaminhoIndice -Encoding UTF8)
    for ($i = 0; $i -lt $linhas.Count; $i++) {
        # linha separadora de tabela markdown com N colunas: |---|---|---|
        # (regex anterior só reconhecia tabela de 1 coluna -- corrigido para
        # aceitar qualquer número de colunas, com alinhamento opcional :---:)
        if ($linhas[$i] -match '^\|.*\|\s*$' -and $i + 1 -lt $linhas.Count -and $linhas[$i + 1] -match '^\|(\s*:?-+:?\s*\|)+\s*$') {
            $j = $i + 2
            while ($j -lt $linhas.Count -and $linhas[$j] -match '^\|.*\|\s*$') {
                $celulas = Split-TableRowLocal -Linha $linhas[$j]
                if ($celulas.Count -gt 0) {
                    $primeira = $celulas[0].Trim('`').Trim().TrimEnd('/')
                    if ($primeira -ne '' -and $primeira -ne '—' -and $primeira -ne '-') {
                        [void]$nomes.Add($primeira)
                    }
                }
                $j++
            }
            $i = $j
        }
    }
    return , $nomes
}

function Test-IndiceDaPasta {
    param([string]$CaminhoPasta, [string]$RootRepo)

    $achados = New-Object System.Collections.Generic.List[object]
    $caminhoIndice = Join-Path $CaminhoPasta 'index.md'
    $pastaRel = Get-CaminhoRelativoLocal -CaminhoCompleto $CaminhoPasta -Base $RootRepo

    $itensDisco = @(Get-ChildItem -Path $CaminhoPasta -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'index.md' -and $_.Name -ne 'INDICE-GERAL.md' -and $_.Name -notmatch '^\.' })   # INDICE-GERAL.md é gerado por gerar-indice-geral.ps1, não é item de índice

    if (-not (Test-Path $caminhoIndice)) {
        if ($itensDisco.Count -gt 0) {
            $achados.Add([PSCustomObject]@{
                Severidade = 'Alta'
                Pasta      = $pastaRel
                Item       = '(index.md)'
                Problema   = 'index.md ausente'
                Detalhe    = "A pasta tem $($itensDisco.Count) item(ns) mas nenhum index.md."
            }) | Out-Null
        }
        return $achados
    }

    $referenciados = Get-NomesReferenciados -CaminhoIndice $caminhoIndice

    # 1) todo item em disco precisa aparecer em alguma linha do índice
    foreach ($item in $itensDisco) {
        $nome = $item.Name
        if (-not $referenciados.Contains($nome)) {
            $achados.Add([PSCustomObject]@{
                Severidade = 'Alta'
                Pasta      = $pastaRel
                Item       = $nome
                Problema   = 'Arquivo/pasta orfa'
                Detalhe    = "Existe em disco mas nao aparece em nenhuma tabela de $pastaRel/index.md."
            }) | Out-Null
        }
    }

    # 2) todo nome referenciado no índice precisa existir em disco
    $nomesDisco = @($itensDisco | ForEach-Object { $_.Name })
    foreach ($nomeRef in $referenciados) {
        if ($nomesDisco -notcontains $nomeRef) {
            $achados.Add([PSCustomObject]@{
                Severidade = 'Alta'
                Pasta      = $pastaRel
                Item       = $nomeRef
                Problema   = 'Linha orfa no indice'
                Detalhe    = "index.md cita '$nomeRef' mas esse arquivo/pasta nao existe em $pastaRel."
            }) | Out-Null
        }
    }

    return $achados
}

function Remove-LinhasOrfasDoIndice {
    <# Reescreve o index.md removendo toda linha de tabela cujo primeiro
       campo bate com um dos nomes em $NomesParaRemover. Nunca toca em linha
       de cabeçalho/separador (o primeiro campo delas nunca é um nome de
       arquivo/pasta real, então nunca dá match). Devolve quantas linhas
       foram removidas de fato. #>
    param([string]$CaminhoIndice, [string[]]$NomesParaRemover)

    $linhas = @(Get-Content -Path $CaminhoIndice -Encoding UTF8)
    $novasLinhas = New-Object System.Collections.Generic.List[string]
    $removidos = 0

    foreach ($linha in $linhas) {
        $manter = $true
        if ($linha -match '^\|.*\|\s*$') {
            $celulas = Split-TableRowLocal -Linha $linha
            if ($celulas.Count -gt 0) {
                $primeira = $celulas[0].Trim('`').Trim().TrimEnd('/')
                if ($NomesParaRemover -contains $primeira) {
                    $manter = $false
                    $removidos++
                }
            }
        }
        if ($manter) { $novasLinhas.Add($linha) | Out-Null }
    }

    if ($removidos -gt 0) {
        # sem BOM, igual à convenção já usada nos index.md deste projeto
        $encUtf8SemBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($CaminhoIndice, ($novasLinhas -join "`n") + "`n", $encUtf8SemBom)
    }

    return $removidos
}

function Get-CaminhoRelativoLocal {
    param([string]$CaminhoCompleto, [string]$Base)
    $baseComBarra = $Base
    if (-not $baseComBarra.EndsWith('\') -and -not $baseComBarra.EndsWith('/')) { $baseComBarra += [System.IO.Path]::DirectorySeparatorChar }
    if ($CaminhoCompleto.StartsWith($baseComBarra, [System.StringComparison]::OrdinalIgnoreCase)) {
        return ($CaminhoCompleto.Substring($baseComBarra.Length) -replace '\\', '/')
    }
    return ($CaminhoCompleto -replace '\\', '/')
}

# ---------------------------------------------------------------------------
# Execução
# ---------------------------------------------------------------------------

$achados = New-Object System.Collections.Generic.List[object]

if ($Todos) {
    $indices = Get-ChildItem -Path (Join-Path $Root 'conhecimento') -Recurse -Filter 'index.md' -ErrorAction SilentlyContinue
    foreach ($idx in $indices) {
        $pastaAtual = $idx.Directory.FullName
        foreach ($a in (Test-IndiceDaPasta -CaminhoPasta $pastaAtual -RootRepo $Root)) { $achados.Add($a) | Out-Null }
    }
} else {
    $caminhoPasta = if ([System.IO.Path]::IsPathRooted($Pasta)) { $Pasta } else { Join-Path $Root $Pasta }
    if (-not (Test-Path $caminhoPasta -PathType Container)) {
        Write-Error "Pasta não encontrada: $Pasta"
        exit 1
    }
    foreach ($a in (Test-IndiceDaPasta -CaminhoPasta $caminhoPasta -RootRepo $Root)) { $achados.Add($a) | Out-Null }
}

$achadosOrdenados = @($achados | Sort-Object Pasta, Item)

if ($achadosOrdenados.Count -eq 0) {
    Write-Output "validar-indice: nenhum arquivo orfao ou linha desatualizada encontrada no escopo avaliado."
    exit 0
}

Write-Output "validar-indice: $($achadosOrdenados.Count) achado(s):"
$achadosOrdenados | Format-Table -AutoSize -Wrap Severidade, Pasta, Item, Problema, Detalhe | Out-String -Width 220 | Write-Output

if ($Remover) {
    $linhasOrfas = @($achadosOrdenados | Where-Object { $_.Problema -eq 'Linha orfa no indice' })
    if ($linhasOrfas.Count -eq 0) {
        Write-Output "validar-indice -Remover: nenhuma linha orfa para remover (os achados acima sao de outro tipo -- Arquivo/pasta orfa ou index.md ausente -- e precisam de decisao humana, nao sao removidos automaticamente)."
    } else {
        $totalRemovido = 0
        foreach ($grupo in ($linhasOrfas | Group-Object Pasta)) {
            $pastaRel = $grupo.Name
            $caminhoIndiceAlvo = Join-Path $Root (Join-Path $pastaRel 'index.md')
            $nomesParaRemover = @($grupo.Group | ForEach-Object { $_.Item })
            $removidos = Remove-LinhasOrfasDoIndice -CaminhoIndice $caminhoIndiceAlvo -NomesParaRemover $nomesParaRemover
            $totalRemovido += $removidos
            Write-Output "  -> $pastaRel/index.md: $removidos linha(s) removida(s) ($($nomesParaRemover -join ', '))"
        }
        Write-Output "validar-indice -Remover: $totalRemovido linha(s) orfa(s) removida(s) no total."
    }

    # recalcula o que sobrou (Arquivo/pasta orfa e index.md ausente nunca somem sozinhos)
    $restantes = @($achadosOrdenados | Where-Object { $_.Problema -ne 'Linha orfa no indice' })
    if ($restantes.Count -eq 0) {
        Write-Output "validar-indice: apos a remocao, nenhum achado restante."
        exit 0
    }
    Write-Output "validar-indice: $($restantes.Count) achado(s) ainda pendente(s) de decisao humana:"
    $restantes | Format-Table -AutoSize -Wrap Severidade, Pasta, Item, Problema, Detalhe | Out-String -Width 220 | Write-Output
    exit 1
}

exit 1
