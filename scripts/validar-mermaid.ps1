<#
.SYNOPSIS
    Sensor computacional de sintaxe Mermaid. Roda o parser real do Mermaid
    (via @mermaid-js/mermaid-cli, headless) sobre cada bloco ```mermaid ... ```
    de um arquivo markdown, em vez de confiar na promessa em prosa de
    flow-mapping/create-roadmap ("garanta que o diagrama seja sintaticamente válido").

.DESCRIPTION
    Para cada bloco encontrado, extrai o conteúdo, escreve num .mmd temporário
    e chama o mermaid-cli (mmdc) de verdade para tentar renderizar. Se o
    parser do Mermaid rejeitar a sintaxe, mmdc devolve exit code != 0 e uma
    mensagem de erro com o número da linha -- este script recupera essa linha,
    mapeia de volta para a linha real no arquivo markdown, e reporta.

    Não valida convenção de projeto (ex: "todo losango tem 2 saídas", "não
    embuta código de decisão no nó") -- isso é uma checagem semântica, não de
    sintaxe, e fica fora do escopo deste sensor.

    LIMITAÇÃO CONHECIDA: mmdc não é um validador de sintaxe puro -- ele
    renderiza de verdade (SVG via Chromium headless), e a pipeline de
    renderização pode falhar por motivos que não são erro de sintaxe. Caso
    confirmado nesta base: gantt com status `active` (ex: `Item :a1, active,
    2026-09-01, 5d`) derruba a renderização com um TypeError interno em
    algumas versões do mermaid-cli, mesmo sendo sintaxe 100% válida e
    documentada -- `crit` e `done` não têm esse problema. Por isso o script
    distingue: "Parse error"/"Lexical error"/"UnknownDiagramError" = rejeição
    real do parser (severidade Alta); qualquer outro crash (ex: TypeError do
    Puppeteer) = severidade Media, com o texto deixando claro que pode ser
    falso positivo e pedindo conferência visual antes de assumir que o
    Mermaid está inválido.

    PRÉ-REQUISITO (uma vez só): rode `npm install` dentro da pasta scripts/
    -- instala @mermaid-js/mermaid-cli e baixa um Chromium headless via
    Puppeteer (~700MB na primeira vez; instalações seguintes são rápidas).
    Sem isso, o script sai com exit code 2 e instruções de como instalar --
    nunca finge que validou quando na verdade não rodou.

    Saída: exit code 0 = todos os blocos são sintaticamente válidos.
           exit code 1 = pelo menos um bloco tem erro de sintaxe CONFIRMADO
           (ou bloco não fechado) -- corrigir antes de considerar pronto.
           exit code 2 = sensor indisponível (mmdc não instalado) -- a skill
           chamadora deve avisar o usuário e seguir sem o sensor, nunca tratar
           isso como "diagrama válido".
           exit code 3 = mmdc rejeitou algum bloco mas sem confirmar que é
           erro de sintaxe (possível crash de renderização) -- pedir
           conferência visual antes de tratar como inválido.

.PARAMETER Arquivo
    Caminho do arquivo markdown que contém o(s) bloco(s) ```mermaid.

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.EXAMPLE
    powershell -File scripts/validar-mermaid.ps1 -Arquivo conhecimento/produto/fluxos-e-jornadas/fluxos-mapeados/existentes/fluxo-x.md
    powershell -File scripts/validar-mermaid.ps1 -Arquivo conhecimento/planejamento/roadmaps/roadmap-mvp.md
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Arquivo,
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Localizar o mmdc (instalação local em scripts/node_modules, com fallback
#    para uma instalação global) -- nunca segue em frente fingindo que validou
#    se o sensor não estiver disponível
# ---------------------------------------------------------------------------

$cliLocal = Join-Path $PSScriptRoot 'node_modules/@mermaid-js/mermaid-cli/src/cli.js'
$cliGlobal = $null
try {
    $raizGlobal = (npm root -g 2>$null)
    if ($raizGlobal) {
        $candidato = Join-Path $raizGlobal '@mermaid-js/mermaid-cli/src/cli.js'
        if (Test-Path $candidato) { $cliGlobal = $candidato }
    }
} catch { }

$cli = $null
if (Test-Path $cliLocal) { $cli = $cliLocal }
elseif ($cliGlobal) { $cli = $cliGlobal }

if (-not $cli) {
    Write-Output "validar-mermaid: sensor indisponivel -- @mermaid-js/mermaid-cli nao esta instalado."
    Write-Output ""
    Write-Output "Para instalar (uma vez so):"
    Write-Output "  cd scripts"
    Write-Output "  npm install"
    Write-Output ""
    Write-Output "A primeira instalacao baixa um Chromium headless via Puppeteer (~700MB) -- instalacoes seguintes sao rapidas."
    Write-Output "Ate instalar, este sensor nao roda -- NAO trate a ausencia dele como 'diagrama valido', apenas como 'nao verificado'."
    exit 2
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Output "validar-mermaid: sensor indisponivel -- Node.js nao encontrado no PATH."
    exit 2
}

# ---------------------------------------------------------------------------
# 2. Ler o arquivo e localizar os blocos ```mermaid ... ```
# ---------------------------------------------------------------------------

$Root = (Resolve-Path -Path $Root).ProviderPath
$caminho = if ([System.IO.Path]::IsPathRooted($Arquivo)) { $Arquivo } else { Join-Path $Root $Arquivo }

if (-not (Test-Path $caminho)) {
    Write-Error "Arquivo não encontrado: $Arquivo"
    exit 1
}

$linhas = @(Get-Content -Path $caminho -Encoding UTF8)

$blocos = New-Object System.Collections.Generic.List[object]
$dentroDoBloco = $false
$inicioBloco = -1
$conteudoBloco = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $linhas.Count; $i++) {
    $linha = $linhas[$i]
    if (-not $dentroDoBloco -and $linha -match '^```mermaid\s*$') {
        $dentroDoBloco = $true
        $inicioBloco = $i
        $conteudoBloco = New-Object System.Collections.Generic.List[string]
        continue
    }
    if ($dentroDoBloco -and $linha -match '^```\s*$') {
        $blocos.Add([PSCustomObject]@{
            Inicio   = $inicioBloco + 1   # 1-indexado, para reportar ao usuário
            Conteudo = @($conteudoBloco)
            Fechado  = $true
        }) | Out-Null
        $dentroDoBloco = $false
        continue
    }
    if ($dentroDoBloco) {
        $conteudoBloco.Add($linha) | Out-Null
    }
}

if ($dentroDoBloco) {
    $blocos.Add([PSCustomObject]@{
        Inicio   = $inicioBloco + 1
        Conteudo = @($conteudoBloco)
        Fechado  = $false
    }) | Out-Null
}

if ($blocos.Count -eq 0) {
    Write-Output "validar-mermaid: nenhum bloco \`\`\`mermaid encontrado em $Arquivo -- nada para validar."
    exit 0
}

# ---------------------------------------------------------------------------
# 3. Validar cada bloco chamando o mmdc de verdade
# ---------------------------------------------------------------------------

$pastaTemp = Join-Path ([System.IO.Path]::GetTempPath()) ("validar-mermaid-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $pastaTemp -Force | Out-Null

$achados = New-Object System.Collections.Generic.List[object]
$numeroBloco = 0

try {
    foreach ($bloco in $blocos) {
        $numeroBloco++

        if (-not $bloco.Fechado) {
            $achados.Add([PSCustomObject]@{
                Severidade = 'Alta'
                Bloco      = $numeroBloco
                Linha      = $bloco.Inicio
                Detalhe    = "Bloco \`\`\`mermaid aberto na linha $($bloco.Inicio) nunca foi fechado com \`\`\`."
            }) | Out-Null
            continue
        }

        $arquivoMmd = Join-Path $pastaTemp "bloco-$numeroBloco.mmd"
        $arquivoSvg = Join-Path $pastaTemp "bloco-$numeroBloco.svg"
        $arquivoErr = Join-Path $pastaTemp "bloco-$numeroBloco.err.txt"
        $arquivoOut = Join-Path $pastaTemp "bloco-$numeroBloco.out.txt"

        ($bloco.Conteudo -join "`n") | Out-File -FilePath $arquivoMmd -Encoding utf8

        # $ErrorActionPreference = 'Stop' faria o stderr do mmdc (processo nativo)
        # virar exceção terminante, mesmo redirecionado a arquivo -- suspendemos
        # isso só para esta chamada e restauramos logo em seguida
        $eapAnterior = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & node $cli -i $arquivoMmd -o $arquivoSvg -q 1>$arquivoOut 2>$arquivoErr
        $exitMmdc = $LASTEXITCODE
        $ErrorActionPreference = $eapAnterior

        if ($exitMmdc -ne 0) {
            $textoErro = if (Test-Path $arquivoErr) { Get-Content -Path $arquivoErr -Raw } else { '' }
            $linhasErro = @($textoErro -split "`r?`n")

            # linhas de "ruído" que não são a mensagem real do mmdc/mermaid: o
            # wrapper NativeCommandError que o PowerShell injeta no stream de
            # erro ao redirecionar stderr de um processo nativo com exit != 0
            $padraoRuido = '^node\.exe\s*:|^No\s|^No linha|^\s*\+|^\s*CategoryInfo|^\s*FullyQualifiedErrorId'

            $linhaRelativa = $null
            if ($textoErro -match 'Parse error on line (\d+)') {
                $linhaRelativa = [int]$Matches[1]
            }

            # monta um trecho compacto e legível a partir da mensagem real do mmdc:
            # começa na linha "Parse error on line N:" (ou na primeira linha de
            # conteúdo real, pulando todo o ruído do wrapper) e para assim que
            # bater num frame de stack trace
            $indiceInicio = -1
            for ($e = 0; $e -lt $linhasErro.Count; $e++) {
                if ($linhasErro[$e] -match 'Parse error on line') { $indiceInicio = $e; break }
            }
            if ($indiceInicio -lt 0) {
                for ($e = 0; $e -lt $linhasErro.Count; $e++) {
                    if ($linhasErro[$e].Trim() -ne '' -and $linhasErro[$e] -notmatch $padraoRuido) { $indiceInicio = $e; break }
                }
            }

            $trechoUtil = New-Object System.Collections.Generic.List[string]
            if ($indiceInicio -ge 0) {
                for ($e = $indiceInicio; $e -lt $linhasErro.Count -and $trechoUtil.Count -lt 4; $e++) {
                    $l = $linhasErro[$e]
                    if ($l -match '^\s*at \S' -or $l -match '^\s*Parser\.parseError' -or $l -match $padraoRuido) { break }
                    if ($l.Trim() -ne '') { $trechoUtil.Add($l.Trim()) | Out-Null }
                }
            }
            $mensagem = if ($trechoUtil.Count -gt 0) { $trechoUtil -join ' | ' } else { "mmdc saiu com exit code $exitMmdc sem mensagem de erro capturada." }

            # nem todo exit != 0 do mmdc é rejeição de sintaxe -- "Parse error"/
            # "Lexical error"/"UnknownDiagramError" são o parser do Mermaid
            # recusando o texto (alta confiança). Um "TypeError"/"Cannot read
            # properties of undefined" é um crash da própria pipeline de
            # renderização (puppeteer/DOM), que pode acontecer mesmo com
            # sintaxe válida -- caso conhecido: gantt com status "active" quebra
            # o render em algumas versões do mermaid-cli sem ser erro de sintaxe.
            $ehErroDeSintaxeConfirmado = $textoErro -match 'Parse error on line|Lexical error|UnknownDiagramError'
            $severidade = if ($ehErroDeSintaxeConfirmado) { 'Alta' } else { 'Media' }
            $prefixoMensagem = if ($ehErroDeSintaxeConfirmado) { 'Erro de sintaxe Mermaid' } else { 'mmdc rejeitou o bloco, mas nao e claramente erro de sintaxe (pode ser crash de renderizacao -- confira visualmente antes de assumir que o Mermaid esta invalido)' }

            if ($linhaRelativa) {
                $linhaAbsoluta = $bloco.Inicio + $linhaRelativa
                $achados.Add([PSCustomObject]@{
                    Severidade = $severidade
                    Bloco      = $numeroBloco
                    Linha      = $linhaAbsoluta
                    Detalhe    = "$($prefixoMensagem): $mensagem"
                }) | Out-Null
            } else {
                $achados.Add([PSCustomObject]@{
                    Severidade = $severidade
                    Bloco      = $numeroBloco
                    Linha      = $bloco.Inicio
                    Detalhe    = "$($prefixoMensagem): $mensagem"
                }) | Out-Null
            }
        }
    }
} finally {
    Remove-Item -Path $pastaTemp -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# 4. Saída
# ---------------------------------------------------------------------------

$achadosOrdenados = @($achados | Sort-Object Bloco, Linha)

if ($achadosOrdenados.Count -eq 0) {
    Write-Output "validar-mermaid: $($blocos.Count) bloco(s) mermaid validados com o parser real -- todos sintaticamente validos."
    exit 0
}

Write-Output "validar-mermaid: $($achadosOrdenados.Count) achado(s) (de $($blocos.Count) bloco(s) no arquivo):"
$achadosOrdenados | Format-Table -AutoSize -Wrap Severidade, Bloco, Linha, Detalhe | Out-String -Width 200 | Write-Output

$temAlta = @($achadosOrdenados | Where-Object { $_.Severidade -eq 'Alta' }).Count -gt 0
if ($temAlta) {
    exit 1   # erro de sintaxe confirmado (ou bloco nao fechado) -- corrigir antes de considerar pronto
} else {
    exit 3   # só achado de confiança media (possível crash de renderização, não confirmadamente sintaxe) -- checar visualmente
}
