<#
.SYNOPSIS
    Gera/atualiza `conhecimento/INDICE-GERAL.md` -- um manifesto único,
    agregado a partir de todo `index.md` da base, para uma IA descobrir
    rapidamente "quais arquivos existem e o que cada um contém" sem precisar
    abrir pasta por pasta.

.DESCRIPTION
    Reaproveita a mesma lógica de leitura de tabela do sensor
    validar-indice.ps1: para cada pasta com um `index.md` dentro de
    `conhecimento/`, lê as tabelas do índice local e monta, por arquivo real
    em disco, um resumo de uma linha a partir das colunas da própria tabela
    (Data, Tipo, Tema, Status, etc. -- o que a pasta tiver).

    Arquivos em disco que não têm nenhuma linha correspondente no índice
    local da própria pasta (órfãos -- ver validar-indice.ps1) aparecem
    marcados explicitamente como tal, em vez de desaparecerem silenciosamente
    do índice geral.

    Este script NUNCA edita os índices locais (`index.md` de cada pasta) --
    só lê e agrega. A disciplina de manter o índice local correto continua
    sendo da skill que salva o arquivo + do sensor validar-indice.ps1.

    Rode depois de qualquer skill salvar um arquivo novo em `conhecimento/`
    (ou de tempos em tempos) para manter `INDICE-GERAL.md` sincronizado.

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.PARAMETER Saida
    Caminho do arquivo de saída. Default: conhecimento/INDICE-GERAL.md

.EXAMPLE
    powershell -File scripts/gerar-indice-geral.ps1
#>

[CmdletBinding()]
param(
    [string]$Root = (Get-Location).Path,
    [string]$Saida = 'conhecimento/INDICE-GERAL.md'
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path -Path $Root).ProviderPath

function Split-TableRowGeral {
    param([string]$Linha)
    $c = $Linha.Trim().Trim('|')
    return ($c -split '\|') | ForEach-Object { $_.Trim() }
}

function Get-ResumosDoIndice {
    <# Lê um index.md e devolve um hashtable nome-do-arquivo -> resumo (string
       montada a partir das demais colunas da linha correspondente) #>
    param([string]$CaminhoIndice)

    $resumos = @{}
    if (-not (Test-Path $CaminhoIndice)) { return $resumos }

    $linhas = @(Get-Content -Path $CaminhoIndice -Encoding UTF8)
    for ($i = 0; $i -lt $linhas.Count; $i++) {
        if ($linhas[$i] -match '^\|.*\|\s*$' -and $i + 1 -lt $linhas.Count -and $linhas[$i + 1] -match '^\|(\s*:?-+:?\s*\|)+\s*$') {
            $cabecalho = Split-TableRowGeral -Linha $linhas[$i]
            $j = $i + 2
            while ($j -lt $linhas.Count -and $linhas[$j] -match '^\|.*\|\s*$') {
                $celulas = Split-TableRowGeral -Linha $linhas[$j]
                if ($celulas.Count -gt 0) {
                    $nome = $celulas[0].Trim('`').Trim().TrimEnd('/')
                    if ($nome -ne '' -and $nome -ne '—' -and $nome -ne '-') {
                        $partes = New-Object System.Collections.Generic.List[string]
                        for ($k = 1; $k -lt $celulas.Count -and $k -lt $cabecalho.Count; $k++) {
                            $valor = $celulas[$k].Trim()
                            if ($valor -ne '' -and $valor -ne '—' -and $valor -ne '-') {
                                $partes.Add("$($cabecalho[$k]): $valor") | Out-Null
                            }
                        }
                        $resumos[$nome] = ($partes -join ' · ')
                    }
                }
                $j++
            }
            $i = $j
        }
    }
    return , $resumos
}

# ---------------------------------------------------------------------------
# Percorrer toda pasta de conhecimento/ que tenha um index.md
# ---------------------------------------------------------------------------

$raizConhecimento = Join-Path $Root 'conhecimento'
$indices = Get-ChildItem -Path $raizConhecimento -Recurse -Filter 'index.md' -ErrorAction SilentlyContinue |
    Sort-Object { $_.Directory.FullName }

$secoes = New-Object System.Collections.Generic.List[string]
$orfaos = New-Object System.Collections.Generic.List[string]
$totalArquivos = 0

foreach ($idx in $indices) {
    $pastaAtual = $idx.Directory.FullName
    $pastaRel = ($pastaAtual.Substring($Root.Length) -replace '\\', '/').TrimStart('/')

    $resumos = Get-ResumosDoIndice -CaminhoIndice $idx.FullName

    $itensDisco = @(Get-ChildItem -Path $pastaAtual -Force -ErrorAction SilentlyContinue |
        Where-Object { -not $_.PSIsContainer -and $_.Name -ne 'index.md' } |
        Sort-Object Name)

    if ($itensDisco.Count -eq 0) { continue }

    $linhasSecao = New-Object System.Collections.Generic.List[string]
    $linhasSecao.Add("### $pastaRel/") | Out-Null
    $linhasSecao.Add('') | Out-Null
    $linhasSecao.Add('| Arquivo | Resumo |') | Out-Null
    $linhasSecao.Add('|---|---|') | Out-Null

    foreach ($item in ($itensDisco | Sort-Object Name)) {
        $nome = $item.Name
        $totalArquivos++
        if ($resumos.ContainsKey($nome) -and $resumos[$nome] -ne '') {
            $linhasSecao.Add('| `' + $nome + '` | ' + $resumos[$nome] + ' |') | Out-Null
        } else {
            $linhasSecao.Add('| `' + $nome + '` | ⚠️ sem entrada no índice local desta pasta |') | Out-Null
            $orfaos.Add("$pastaRel/$nome") | Out-Null
        }
    }

    $secoes.Add(($linhasSecao -join "`n")) | Out-Null
}

# ---------------------------------------------------------------------------
# Montar o arquivo final
# ---------------------------------------------------------------------------

$linhasFinal = New-Object System.Collections.Generic.List[string]
$linhasFinal.Add('# Índice Geral da Base de Conhecimento') | Out-Null
$linhasFinal.Add('') | Out-Null
$linhasFinal.Add('> Gerado automaticamente por `scripts/gerar-indice-geral.ps1` -- **não edite à mão**, ele é sobrescrito a cada regeneração.') | Out-Null
$linhasFinal.Add('>') | Out-Null
$linhasFinal.Add('> **Para agentes de IA:** antes de abrir pasta por pasta procurando algo na base, confira este arquivo primeiro -- ele lista todo arquivo real de `conhecimento/` com um resumo de uma linha. Se um item aparecer marcado `⚠️ sem entrada no índice local`, o índice da pasta dele está desatualizado (rode `scripts/validar-indice.ps1 -Todos` para o diagnóstico completo) -- o arquivo ainda existe e pode ser lido normalmente, só o resumo aqui não é confiável.') | Out-Null
$linhasFinal.Add('') | Out-Null
$linhasFinal.Add("Atualizado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm')") | Out-Null
$linhasFinal.Add("Total de arquivos indexados: $totalArquivos") | Out-Null
$linhasFinal.Add('') | Out-Null
$linhasFinal.Add('---') | Out-Null
$linhasFinal.Add('') | Out-Null

foreach ($secao in $secoes) {
    $linhasFinal.Add($secao) | Out-Null
    $linhasFinal.Add('') | Out-Null
}

if ($orfaos.Count -gt 0) {
    $linhasFinal.Add('---') | Out-Null
    $linhasFinal.Add('') | Out-Null
    $linhasFinal.Add('## ⚠️ Itens sem entrada no índice local da própria pasta') | Out-Null
    $linhasFinal.Add('') | Out-Null
    $linhasFinal.Add('Existem em disco, mas o `index.md` da pasta onde vivem não os cita -- provavelmente a skill que os gerou esqueceu de atualizar o índice local. Rode `scripts/validar-indice.ps1 -Todos` para o diagnóstico completo (inclui também linhas órfãs, que apontam para arquivos que não existem mais).') | Out-Null
    $linhasFinal.Add('') | Out-Null
    foreach ($o in $orfaos) {
        $linhasFinal.Add('- `' + $o + '`') | Out-Null
    }
    $linhasFinal.Add('') | Out-Null
}

$caminhoSaida = if ([System.IO.Path]::IsPathRooted($Saida)) { $Saida } else { Join-Path $Root $Saida }
($linhasFinal -join "`n") | Out-File -FilePath $caminhoSaida -Encoding utf8

Write-Output "gerar-indice-geral: $totalArquivos arquivo(s) indexado(s) em $($indices.Count) pasta(s)."
if ($orfaos.Count -gt 0) {
    Write-Output "$($orfaos.Count) item(ns) sem entrada no indice local (marcados no arquivo gerado)."
}
Write-Output "Salvo em: $Saida"
