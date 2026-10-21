<#
.SYNOPSIS
    Sensor computacional de referência cruzada, escopado a um ou mais arquivos
    específicos — pensado para rodar no "antes de salvar" de qualquer skill que
    cite DORxxx / DEPxxx / RISxxx / Dxxx / OKR-N / FLXxxx (intent,
    create-spec, prioritize-deliverables, create-roadmap, define-okrs, define-deliverables,
    insert-knowledge, create-presentation).

.DESCRIPTION
    Diferente de check-integrity.ps1 (que varre a base inteira procurando
    citações desatualizadas), este script é rápido e local: recebe o(s)
    arquivo(s) que uma skill está prestes a salvar (ou já salvou) e confere
    se todo ID citado ali existe de fato no índice canônico do guide
    correspondente. Não confere status nem título — só existência.

    Saída: exit code 0 = nenhum ID inexistente encontrado (pode salvar/seguir).
           exit code 1 = há pelo menos um ID citado que não existe — a skill
           chamadora deve mostrar os achados ao usuário antes de prosseguir,
           nunca ignorar silenciosamente.

.PARAMETER Arquivo
    Um ou mais caminhos de arquivo a validar (relativos ao -Root, ou absolutos).

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.EXAMPLE
    powershell -File scripts/validar-referencias.ps1 -Arquivo conhecimento/planejamento/roadmaps/roadmap-mvp.md
    powershell -File scripts/validar-referencias.ps1 -Arquivo doc1.md,doc2.md -Root "C:\...\Harness Produto e Design"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arquivo,
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_lib-guides.ps1')

$Root = Resolve-Raiz -Root $Root
$canonico = Get-CanonicoIds -Root $Root

if ($canonico.Count -eq 0) {
    Write-Error "Nenhum ID canônico encontrado — confira o parâmetro -Root e os caminhos dos guides."
    exit 1
}

$padraoId = '\b(DOR\d{3}|DEP\d{3}|RIS\d{3}|FLX\d{3}|OKR-\d+|D\d{3})\b'
$achados = New-Object System.Collections.Generic.List[object]

foreach ($a in $Arquivo) {
    $caminho = if ([System.IO.Path]::IsPathRooted($a)) { $a } else { Join-Path $Root $a }
    if (-not (Test-Path $caminho)) {
        Write-Warning "Arquivo não encontrado, pulando: $a"
        continue
    }

    $linhas = @(Get-Content -Path $caminho -Encoding UTF8)
    for ($n = 0; $n -lt $linhas.Count; $n++) {
        $correspondencias = [regex]::Matches($linhas[$n], $padraoId)
        foreach ($m in $correspondencias) {
            $idCitado = $m.Value
            if (-not $canonico.ContainsKey($idCitado)) {
                $achados.Add([PSCustomObject]@{
                    Arquivo  = $a
                    Linha    = $n + 1
                    Id       = $idCitado
                    Situacao = 'ID nao encontrado em nenhum indice canonico'
                }) | Out-Null
            }
        }
    }
}

# dedup: mesmo ID citado 2x na mesma linha (prosa + coluna de tabela, por exemplo)
# @() força array mesmo quando sobra um único resultado (senão .Count fica vazio)
$achadosUnicos = @($achados | Group-Object Arquivo, Linha, Id | ForEach-Object { $_.Group[0] })

if ($achadosUnicos.Count -eq 0) {
    Write-Output "validar-referencias: todos os IDs citados existem no indice correspondente."
    exit 0
}

Write-Output "validar-referencias: encontrado(s) $($achadosUnicos.Count) ID(s) citado(s) que nao existem em nenhum guide:"
$achadosUnicos | Sort-Object Arquivo, Linha | Format-Table -AutoSize Arquivo, Linha, Id, Situacao | Out-String -Width 200 | Write-Output
exit 1
