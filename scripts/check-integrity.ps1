<#
.SYNOPSIS
    Sensor computacional da skill check-integrity.
    Varre a base de conhecimento procurando citações desatualizadas de
    DORxxx / DEPxxx / RISxxx / Dxxx / OKR-N / FLXxxx em relação ao estado canônico
    registrado no índice do guide de origem.

.DESCRIPTION
    Executa 4 checagens, da mais confiável (puramente computacional) para a
    mais heurística:

      A) Marcador de bloqueio desatualizado — encontra "[BLOQUEADO ... DEPxxx ...]"
         em qualquer arquivo e confere se a dependência citada já está "Resolvida".
      B) Índice x bloco detalhado — dentro do próprio guide, confere se o Status
         da linha do índice bate com o "**Status:**" do bloco detalhado do mesmo ID.
      C) ID citado mas inexistente — ID no formato certo que não existe em
         nenhum índice canônico.
      D) Título citado desatualizado — comparação heurística (baixa confiança)
         entre o título citado ao lado do ID em outro arquivo e o título atual.

    Este script NUNCA edita nada — só relata. A decisão de corrigir é sempre
    humana ou de uma passada inferencial da skill check-integrity.

    Ver também: validar-referencias.ps1 (mesma Checagem C, só que escopada a
    um único arquivo — útil para uma skill rodar "antes de salvar" um arquivo
    novo, sem varrer a base inteira) e validar-sequencia-id.ps1 (garante que o
    próximo ID mintado é de fato o correto, sem gap nem duplicata).

.PARAMETER Id
    Limita a varredura a um ID específico (ex: DEP007). Opcional.

.PARAMETER Tipo
    Limita a varredura a um tipo de guide: DOR | DEP | RIS | D | OKR | FLX. Opcional.

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.PARAMETER OutFile
    Caminho de um .md para salvar o relatório. Opcional — se omitido, só imprime.

.EXAMPLE
    powershell -File scripts/check-integrity.ps1
    powershell -File scripts/check-integrity.ps1 -Id DEP007
    powershell -File scripts/check-integrity.ps1 -Tipo DEP -OutFile documentos/gerados/check-integrity-2026-09-15.md
#>

[CmdletBinding()]
param(
    [string]$Id,
    [ValidateSet('DOR', 'DEP', 'RIS', 'D', 'OKR', 'FLX')]
    [string]$Tipo,
    [string]$Root = (Get-Location).Path,
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_lib-guides.ps1"

$Root = Resolve-Raiz -Root $Root
$guias = Get-Guias

# ---------------------------------------------------------------------------
# 1. Montar o dicionário canônico (sempre com TODOS os tipos — -Tipo só filtra
#    os achados finais reportados, no fim do script; ver nota na função)
# ---------------------------------------------------------------------------

$canonico = Get-CanonicoIds -Root $Root

if ($canonico.Count -eq 0) {
    Write-Error "Nenhum ID canônico encontrado — confira o parâmetro -Root e os caminhos dos guides."
    exit 1
}

$achados = New-Object System.Collections.Generic.List[object]

function Add-Achado {
    param($Severidade, $Checagem, $IdRef, $Arquivo, $Linha, $Detalhe)
    $achados.Add([PSCustomObject]@{
        Severidade = $Severidade
        Checagem   = $Checagem
        Id         = $IdRef
        Arquivo    = $Arquivo
        Linha      = $Linha
        Detalhe    = $Detalhe
    }) | Out-Null
}

# ---------------------------------------------------------------------------
# CHECAGEM B — índice x bloco detalhado (dentro do próprio guide)
# ---------------------------------------------------------------------------

foreach ($chave in $canonico.Keys) {
    if ($Id -and $chave -ne $Id) { continue }
    $c = $canonico[$chave]
    $bloco = Get-BlocoStatus -Linhas $c.Linhas -AlvoId $c.Id
    if ($bloco -and $bloco.Status -ne $c.Status) {
        Add-Achado -Severidade 'Alta' -Checagem 'Indice x bloco detalhado' -IdRef $c.Id `
            -Arquivo $c.Arquivo -Linha $bloco.Linha `
            -Detalhe "Indice diz Status = '$($c.Status)', bloco detalhado (linha $($bloco.Linha)) diz '$($bloco.Status)'."
    }
}

# ---------------------------------------------------------------------------
# Coleta de todos os arquivos .md relevantes para as checagens A, C, D
# ---------------------------------------------------------------------------

$arquivosBase = Get-ChildItem -Path (Join-Path $Root 'conhecimento') -Recurse -Filter '*.md' -ErrorAction SilentlyContinue
$arquivosGerados = @()
$pastaGerados = Join-Path $Root 'documentos/gerados'
if (Test-Path $pastaGerados) {
    $arquivosGerados = Get-ChildItem -Path $pastaGerados -Recurse -Filter '*.md' -ErrorAction SilentlyContinue
}
$todosArquivos = @($arquivosBase) + @($arquivosGerados)

# ---------------------------------------------------------------------------
# CHECAGEM A — marcador [BLOQUEADO ... DEPxxx ...] desatualizado
# ---------------------------------------------------------------------------

foreach ($arq in $todosArquivos) {
    $linhas = @(Get-Content -Path $arq.FullName -Encoding UTF8)
    for ($n = 0; $n -lt $linhas.Count; $n++) {
        $linha = $linhas[$n]
        $correspondencias = [regex]::Matches($linha, '\[BLOQUEAD[OA][^\]]*?(DEP\d{3}|D\d{3})[^\]]*\]')
        foreach ($m in $correspondencias) {
            $idCitado = $m.Groups[1].Value
            if ($Id -and $idCitado -ne $Id) { continue }
            if ($canonico.ContainsKey($idCitado)) {
                $statusAtual = $canonico[$idCitado].Status
                if (Test-RotuloIgual -Valor $statusAtual -Chave 'valor.status_resolvida') {
                    $arqRel = Get-CaminhoRelativo -CaminhoCompleto $arq.FullName -Base $Root
                    Add-Achado -Severidade 'Alta' -Checagem 'Marcador de bloqueio desatualizado' -IdRef $idCitado `
                        -Arquivo $arqRel -Linha ($n + 1) `
                        -Detalhe "Marcador '$($m.Value)' ainda presente, mas $idCitado já está '$statusAtual' no guide de origem."
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# CHECAGEM C — ID citado mas inexistente em nenhum índice canônico
# CHECAGEM D — título citado divergente do título atual (heurística, baixa confiança)
# ---------------------------------------------------------------------------

$padraoIdGenerico = '\b(DOR\d{3}|DEP\d{3}|RIS\d{3}|FLX\d{3}|OKR-\d+|D\d{3})\b'

foreach ($arq in $todosArquivos) {
    $arqRel = Get-CaminhoRelativo -CaminhoCompleto $arq.FullName -Base $Root
    $ehGuideCanonico = $guias.Arquivo -contains ($arqRel -replace '\\', '/')

    $linhas = @(Get-Content -Path $arq.FullName -Encoding UTF8)
    for ($n = 0; $n -lt $linhas.Count; $n++) {
        $linha = $linhas[$n]

        # pula a própria linha do índice do guide de origem (já coberta na checagem B)
        if ($ehGuideCanonico -and $linha -match '^\|') { continue }

        $correspondencias = [regex]::Matches($linha, $padraoIdGenerico)
        foreach ($m in $correspondencias) {
            $idCitado = $m.Value
            if ($Id -and $idCitado -ne $Id) { continue }

            # CHECAGEM C — existência
            if (-not $canonico.ContainsKey($idCitado)) {
                Add-Achado -Severidade 'Media' -Checagem 'ID citado nao encontrado no indice' -IdRef $idCitado `
                    -Arquivo $arqRel -Linha ($n + 1) `
                    -Detalhe "Formato de ID reconhecido, mas '$idCitado' nao existe no indice de nenhum guide (ou o tipo nao foi incluido nesta varredura)."
                continue
            }

            # se essa e a própria linha canônica dentro do guide de origem, pula
            if ($ehGuideCanonico) { continue }

            # CHECAGEM D — título citado ao lado do ID, comparado ao título atual
            $tituloCanonico = $canonico[$idCitado].Titulo
            if ($linha -match [regex]::Escape($idCitado) + '\s*[—\-]\s*([^;,\n\|\.]+)') {
                $tituloCitado = $Matches[1].Trim()
                $palavrasCanonicas = ($tituloCanonico -split '\s+' | Where-Object { $_.Length -gt 3 } | ForEach-Object { $_.ToLowerInvariant() })
                $palavrasCitadas = ($tituloCitado -split '\s+' | Where-Object { $_.Length -gt 3 } | ForEach-Object { $_.ToLowerInvariant() })
                if ($palavrasCanonicas.Count -gt 0) {
                    $intersecao = $palavrasCanonicas | Where-Object { $palavrasCitadas -contains $_ }
                    $proporcao = $intersecao.Count / $palavrasCanonicas.Count
                    if ($proporcao -lt 0.4) {
                        Add-Achado -Severidade 'Baixa' -Checagem 'Titulo citado possivelmente divergente' -IdRef $idCitado `
                            -Arquivo $arqRel -Linha ($n + 1) `
                            -Detalhe "Citado como '$idCitado — $tituloCitado' mas o titulo atual no guide e '$tituloCanonico'. Pode ser parafrase legitima -- revisar com julgamento, nao e um erro automatico."
                    }
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 4. Saída
# ---------------------------------------------------------------------------

if ($Tipo) {
    $prefixoFiltro = $Tipo
    if ($Tipo -eq 'OKR') {
        $achados = $achados | Where-Object { $_.Id -match '^OKR-' }
    } else {
        $achados = $achados | Where-Object { $_.Id -match "^$prefixoFiltro\d" }
    }
}

# dedup: a mesma linha pode citar o mesmo ID mais de uma vez (ex: em prosa e
# de novo numa coluna de tabela) — isso gera o mesmo achado repetido.
# @() força array mesmo quando sobra um único resultado (senão .Count fica vazio)
$achadosUnicos = @($achados | Group-Object Checagem, Id, Arquivo, Linha | ForEach-Object { $_.Group[0] })

$achadosOrdenados = $achadosUnicos | Sort-Object @{Expression = {
        switch ($_.Severidade) { 'Alta' { 0 }; 'Media' { 1 }; 'Baixa' { 2 }; default { 3 } }
    }}, Id

if ($achadosOrdenados.Count -eq 0) {
    Write-Output "check-integrity: nenhuma divergencia encontrada no escopo avaliado."
} else {
    $achadosOrdenados | Format-Table -AutoSize -Wrap Severidade, Checagem, Id, Arquivo, Linha, Detalhe | Out-String -Width 200 | Write-Output
}

if ($OutFile) {
    $linhasRelatorio = New-Object System.Collections.Generic.List[string]
    $linhasRelatorio.Add('# Relatório check-integrity')
    $linhasRelatorio.Add('')
    $linhasRelatorio.Add("Gerado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
    $linhasRelatorio.Add('')
    if ($achadosOrdenados.Count -eq 0) {
        $linhasRelatorio.Add('Nenhuma divergência encontrada no escopo avaliado.')
    } else {
        $linhasRelatorio.Add('| Severidade | Checagem | ID | Arquivo | Linha | Detalhe |')
        $linhasRelatorio.Add('|---|---|---|---|---|---|')
        foreach ($a in $achadosOrdenados) {
            $linhasRelatorio.Add("| $($a.Severidade) | $($a.Checagem) | $($a.Id) | $($a.Arquivo) | $($a.Linha) | $($a.Detalhe) |")
        }
    }
    $caminhoSaida = Join-Path $Root $OutFile
    $linhasRelatorio -join "`n" | Out-File -FilePath $caminhoSaida -Encoding utf8
    Write-Output "Relatório salvo em: $OutFile"
}

# devolve os achados como objetos, para quem chamar o script programaticamente
$achadosOrdenados
