<#
.SYNOPSIS
    Sensor computacional de sequência de ID. Duas funções:

    1) Modo -ProximoId: calcula o ID correto a ser mintado a seguir para um
       prefixo (DOR/DEP/RIS/D/OKR/FLX), lendo o índice real do guide — em vez de a
       skill "prometer" ler o índice e incrementar +1 de cabeça, ela chama este
       script e usa o valor devolvido, tirando a aritmética da mão do modelo.

    2) Modo -Auditar: varre o índice de um guide (ou de todos) procurando gaps
       na sequência (ID pulado) e IDs duplicados — sinal de que alguém mintou
       um ID fora de ordem ou copiou/colou uma linha sem trocar o ID.

.PARAMETER Prefixo
    DOR | DEP | RIS | D | OKR | FLX. Obrigatório com -ProximoId; opcional com
    -Auditar (se omitido, audita todos os guides).

.PARAMETER ProximoId
    Devolve (via stdout) o próximo ID correto para o -Prefixo informado.

.PARAMETER Auditar
    Varre a sequência do(s) guide(s) procurando gaps e duplicatas.

.PARAMETER Telas
    Modo de IDs de prototipação (SCR-NN), usado pelas skills screen-planner e
    create-prototype. Audita um inventário de telas (.md) ou um protótipo (.html)
    passado em -Arquivo:
      - inventário (.md): IDs fora do padrão SCR-NN, IDs duplicados, gaps na
        sequência (todo SCR de 1 ao maior precisa estar detalhado ou na lista
        "sem protótipo") e referências a SCR que não são definidos no arquivo;
      - protótipo (.html): IDs fora do padrão, duplicados, destinos de
        navigateTo() inexistentes e, se -Inventario for informado, telas do
        protótipo que não existem no inventário e telas "com protótipo" do
        inventário que faltam no HTML.

.PARAMETER Arquivo
    Com -Telas: inventário de telas (.md) ou protótipo (.html) a auditar.

.PARAMETER Inventario
    Com -Telas e um protótipo em -Arquivo: inventário de telas (.md) correspondente.

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.EXAMPLE
    powershell -File scripts/validar-sequencia-id.ps1 -ProximoId -Prefixo DEP
    powershell -File scripts/validar-sequencia-id.ps1 -Auditar -Prefixo D
    powershell -File scripts/validar-sequencia-id.ps1 -Auditar
    powershell -File scripts/validar-sequencia-id.ps1 -Telas -Arquivo documentos/gerados/inventario-telas-x-2026-10-21.md
    powershell -File scripts/validar-sequencia-id.ps1 -Telas -Arquivo documentos/gerados/prototipo-x-2026-10-21.html -Inventario documentos/gerados/inventario-telas-x-2026-10-21.md
#>

[CmdletBinding(DefaultParameterSetName = 'Auditar')]
param(
    [Parameter(ParameterSetName = 'ProximoId', Mandatory = $true)]
    [switch]$ProximoId,

    [Parameter(ParameterSetName = 'Telas', Mandatory = $true)]
    [switch]$Telas,

    [Parameter(ParameterSetName = 'Telas', Mandatory = $true)]
    [string]$Arquivo,

    [Parameter(ParameterSetName = 'Telas')]
    [string]$Inventario,

    [Parameter(ParameterSetName = 'Auditar')]
    [switch]$Auditar,

    [Parameter(ParameterSetName = 'ProximoId', Mandatory = $true)]
    [Parameter(ParameterSetName = 'Auditar')]
    [ValidateSet('DOR', 'DEP', 'RIS', 'D', 'OKR', 'FLX')]
    [string]$Prefixo,

    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_lib-guides.ps1')

$Root = Resolve-Raiz -Root $Root
$guias = Get-Guias

# ---------------------------------------------------------------------------
# Modo -Telas (IDs de prototipação SCR-NN)
# ---------------------------------------------------------------------------

if ($Telas) {
    function Resolve-Caminho([string]$Caminho) {
        if ([System.IO.Path]::IsPathRooted($Caminho)) { return $Caminho }
        return (Join-Path $Root $Caminho)
    }

    function Get-TelasDoInventario([string]$Caminho) {
        # devolve @{ Detalhadas = ids com bloco "**ID:** SCR-NN"; SemProto = ids na lista "sem protótipo";
        #            Todas = qualquer SCR-.. citado; Invalidos = IDs fora do padrão SCR-NN }
        $texto = Get-Content -Path $Caminho -Raw -Encoding UTF8
        $det = @([regex]::Matches($texto, '(?m)^\*\*ID:\*\*\s*(SCR-\S+)') | ForEach-Object { $_.Groups[1].Value.Trim('.', ',', ';') })
        $sem = @()
        $emSemProto = $false
        foreach ($l in ($texto -split "`r?`n")) {
            if ($l -match ('^##\s+' + (Get-RotuloRegex 'secao.telas_sem_prototipo'))) { $emSemProto = $true; continue }
            if ($l -match '^##\s' -and $emSemProto) { $emSemProto = $false }
            if ($emSemProto -and $l -match '^\|\s*(SCR-\S+?)\s*\|') { $sem += $Matches[1] }
        }
        $todas = @([regex]::Matches($texto, 'SCR-[A-Za-z0-9]+') | ForEach-Object { $_.Value })
        $inval = @(($det + $sem) | Where-Object { $_ -notmatch '^SCR-\d{2,}$' })
        return @{ Detalhadas = $det; SemProto = $sem; Todas = $todas; Invalidos = $inval }
    }

    $achadosT = New-Object System.Collections.Generic.List[string]
    $caminhoArq = Resolve-Caminho $Arquivo
    if (-not (Test-Path $caminhoArq)) { Write-Error "Arquivo não encontrado: $Arquivo"; exit 1 }
    $ext = [System.IO.Path]::GetExtension($caminhoArq).ToLowerInvariant()

    if ($ext -eq '.md') {
        $inv = Get-TelasDoInventario $caminhoArq
        $definidas = @($inv.Detalhadas + $inv.SemProto)
        if ($definidas.Count -eq 0) { $achadosT.Add('Nenhum ID SCR-NN definido (esperado "**ID:** SCR-NN" por tela ou a tabela "Telas sem protótipo").') }
        foreach ($i in $inv.Invalidos) { $achadosT.Add("ID fora do padrão SCR-NN (mínimo 2 dígitos): $i") }
        foreach ($d in ($definidas | Group-Object | Where-Object { $_.Count -gt 1 })) {
            $achadosT.Add("ID duplicado: $($d.Name) definido $($d.Count) vezes (bloco detalhado e/ou lista 'sem protótipo')")
        }
        $nums = @($definidas | Where-Object { $_ -match '^SCR-(\d+)$' } | ForEach-Object { [int]($_ -replace '^SCR-', '') } | Sort-Object -Unique)
        if ($nums.Count -gt 0) {
            $max = ($nums | Measure-Object -Maximum).Maximum
            foreach ($n in (1..$max | Where-Object { $nums -notcontains $_ })) {
                $achadosT.Add(("Gap na sequência: SCR-{0:D2} não está definido (nem detalhado, nem em 'sem protótipo')" -f $n))
            }
        }
        foreach ($c in ($inv.Todas | Sort-Object -Unique | Where-Object { $definidas -notcontains $_ -and $inv.Invalidos -notcontains $_ })) {
            $achadosT.Add("$c é citado (ex: destino de navegação) mas não é definido no inventário")
        }
    }
    elseif ($ext -eq '.html') {
        $html = Get-Content -Path $caminhoArq -Raw -Encoding UTF8
        $secs = @([regex]::Matches($html, '<section\b[^>]*\bclass="[^"]*\bscreen\b[^"]*"[^>]*>') | ForEach-Object {
            if ($_.Value -match '\bid="([^"]*)"') { $Matches[1] } else { '(sem id)' }
        })
        if ($secs.Count -eq 0) { $achadosT.Add('Nenhuma <section class="screen" id="SCR-NN"> encontrada.') }
        foreach ($i in ($secs | Where-Object { $_ -notmatch '^SCR-\d{2,}$' })) { $achadosT.Add("ID de tela fora do padrão SCR-NN: $i") }
        foreach ($d in ($secs | Group-Object | Where-Object { $_.Count -gt 1 })) { $achadosT.Add("ID duplicado no HTML: $($d.Name)") }
        $destinos = @([regex]::Matches($html, "navigateTo\(\s*['""]([^'""]+)['""]") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
        foreach ($t in ($destinos | Where-Object { $secs -notcontains $_ })) { $achadosT.Add("navigateTo('$t') aponta para tela inexistente no HTML") }
        if ($Inventario) {
            $caminhoInv = Resolve-Caminho $Inventario
            if (-not (Test-Path $caminhoInv)) { Write-Error "Inventário não encontrado: $Inventario"; exit 1 }
            $inv = Get-TelasDoInventario $caminhoInv
            foreach ($s in ($secs | Where-Object { $inv.Detalhadas -notcontains $_ })) {
                $achadosT.Add("$s existe no protótipo mas não está detalhada no inventário (IDs devem ser os do inventário)")
            }
            foreach ($s in ($inv.Detalhadas | Where-Object { $secs -notcontains $_ })) {
                $achadosT.Add("$s está detalhada no inventário mas não existe no protótipo")
            }
        }
    }
    else {
        Write-Error "Extensão não suportada com -Telas: $ext (use .md para inventário ou .html para protótipo)"
        exit 1
    }

    if ($achadosT.Count -eq 0) {
        Write-Output "validar-sequencia-id -Telas: IDs SCR-NN consistentes em $Arquivo."
        exit 0
    }
    Write-Output "validar-sequencia-id -Telas: $($achadosT.Count) problema(s) em ${Arquivo}:"
    $achadosT | ForEach-Object { Write-Output "  - $_" }
    exit 1
}

# ---------------------------------------------------------------------------
# Modo -ProximoId
# ---------------------------------------------------------------------------

if ($ProximoId) {
    $g = $guias | Where-Object { $_.Prefixo -eq $Prefixo }
    $caminho = Join-Path $Root $g.Arquivo
    if (-not (Test-Path $caminho)) {
        Write-Error "Guide não encontrado: $($g.Arquivo)"
        exit 1
    }

    $linhas = @(Get-Content -Path $caminho -Encoding UTF8)
    $tabela = Get-IndiceTable -Linhas $linhas

    if ($tabela.Count -eq 0) {
        $proximoNumero = 1
    } else {
        $numeros = $tabela.Id | ForEach-Object { Get-NumeroDoId -IdCompleto $_ -Prefixo $Prefixo }
        $proximoNumero = ($numeros | Measure-Object -Maximum).Maximum + 1
    }

    $idSugerido = Format-IdComPrefixo -Prefixo $Prefixo -Numero $proximoNumero
    Write-Output $idSugerido
    exit 0
}

# ---------------------------------------------------------------------------
# Modo -Auditar (default)
# ---------------------------------------------------------------------------

$listaGuias = if ($Prefixo) { $guias | Where-Object { $_.Prefixo -eq $Prefixo } } else { $guias }
$achados = New-Object System.Collections.Generic.List[object]

foreach ($g in $listaGuias) {
    $caminho = Join-Path $Root $g.Arquivo
    if (-not (Test-Path $caminho)) {
        Write-Warning "Guide não encontrado: $($g.Arquivo)"
        continue
    }

    $linhas = @(Get-Content -Path $caminho -Encoding UTF8)
    $tabela = Get-IndiceTable -Linhas $linhas

    if ($tabela.Count -eq 0) { continue }

    # duplicatas — mesmo ID aparecendo mais de uma vez na tabela de índice
    $contagem = @{}
    foreach ($row in $tabela) {
        if ($contagem.ContainsKey($row.Id)) {
            $contagem[$row.Id]++
        } else {
            $contagem[$row.Id] = 1
        }
    }
    foreach ($idRepetido in ($contagem.Keys | Where-Object { $contagem[$_] -gt 1 })) {
        $achados.Add([PSCustomObject]@{
            Guide    = $g.Arquivo
            Problema = 'ID duplicado no indice'
            Detalhe  = "$idRepetido aparece $($contagem[$idRepetido]) vezes na tabela de indice"
        }) | Out-Null
    }

    # gaps — números faltando entre 1 e o máximo encontrado
    $numeros = $tabela.Id | ForEach-Object { Get-NumeroDoId -IdCompleto $_ -Prefixo $g.Prefixo } | Sort-Object -Unique
    if ($numeros.Count -gt 0) {
        $maximo = ($numeros | Measure-Object -Maximum).Maximum
        $faltando = 1..$maximo | Where-Object { $numeros -notcontains $_ }
        foreach ($f in $faltando) {
            $idFaltante = Format-IdComPrefixo -Prefixo $g.Prefixo -Numero $f
            $achados.Add([PSCustomObject]@{
                Guide    = $g.Arquivo
                Problema = 'Gap na sequencia'
                Detalhe  = "$idFaltante nao existe no indice -- foi pulado, removido sem renumerar os seguintes, ou digitado errado em algum lugar"
            }) | Out-Null
        }
    }
}

if ($achados.Count -eq 0) {
    Write-Output "validar-sequencia-id: nenhum gap ou ID duplicado encontrado."
    exit 0
}

Write-Output "validar-sequencia-id: encontrado(s) $($achados.Count) problema(s) de sequencia:"
$achados | Format-Table -AutoSize Guide, Problema, Detalhe | Out-String -Width 200 | Write-Output
exit 1
