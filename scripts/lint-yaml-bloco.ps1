<#
.SYNOPSIS
    Sensor computacional de sintaxe e estrutura para os blocos YAML gerados por
    intent (seção "Direcionador para o Protótipo") e create-spec
    (bloco "Bloco para IA de desenvolvimento" por US, dentro de cada Spec) — pega bloco malformado ou
    incompleto antes de ele virar prompt para uma IA de desenvolvimento.

.DESCRIPTION
    Não é um parser YAML genérico (não lida com âncoras, flow-style `{...}`/`[...]`,
    multiline `|`/`>`, etc.) — é um linter deliberadamente escopado às DUAS
    estruturas reais geradas nesta base, com checagens de dois níveis:

      1) SINTAXE (linha a linha, dentro de cada bloco ```yaml ... ```):
         - Bloco não fechado (fence de abertura sem fence de fechamento correspondente)
         - Tabs usados para indentação (YAML exige espaços)
         - "chave:valor" sem espaço depois dos dois-pontos (erro comum de geração)
         - Aspas desbalanceadas na linha
         - Placeholder de template esquecido sem preencher (ex: "[ex: ...]" que
           deveria ter sido substituído por um valor real)

      2) ESTRUTURA (campos obrigatórios e enums, por esquema):
         - Todo campo de topo obrigatório do esquema está presente
         - Todo item de lista-de-mapas (campos, endpoints, edge_cases,
           regras_visuais_derivadas_de_limite_tecnico) tem as sub-chaves obrigatórias
         - Campos com enum conhecido (tipo, obrigatorio, status, metodo,
           status_prontidao) têm valor dentro do conjunto permitido — "a confirmar"
           é sempre aceito como escape-hatch legítimo do projeto, nunca um erro

    Saída: exit code 0 = nenhum achado de severidade Alta (pode seguir).
           exit code 1 = há achado de severidade Alta — a skill chamadora deve
           corrigir o bloco antes de considerá-lo pronto para virar prompt de dev.

.PARAMETER Arquivo
    Caminho do arquivo markdown que contém o(s) bloco(s) ```yaml.

.PARAMETER Esquema
    intent | create-spec — define quais campos são obrigatórios.

.PARAMETER Root
    Raiz do repositório. Default: diretório atual.

.EXAMPLE
    powershell -File scripts/lint-yaml-bloco.ps1 -Arquivo conhecimento/desenvolvimento/briefings-funcionais/briefing-minha-feature-2026-08-20.md -Esquema intent
    powershell -File scripts/lint-yaml-bloco.ps1 -Arquivo conhecimento/desenvolvimento/specs/spec-minha-feature-2026-08-22.md -Esquema create-spec
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Arquivo,
    [Parameter(Mandatory = $true)]
    [ValidateSet('intent', 'create-spec')]
    [string]$Esquema,
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Esquemas conhecidos (campos de topo obrigatórios + listas-de-mapas com
#    suas sub-chaves obrigatórias e enums, quando houver)
# ---------------------------------------------------------------------------

$esquemas = @{
    'intent' = [PSCustomObject]@{
        CamposTopoObrigatorios = @(
            'tela', 'objetivo', 'campos', 'estados_de_tela', 'comportamentos',
            'regras_visuais_derivadas_de_limite_tecnico', 'perguntas_abertas_relacionadas'
        )
        ListasDeMapas = @(
            [PSCustomObject]@{
                Chave           = 'campos'
                SubChaves       = @('nome', 'tipo', 'obrigatorio', 'origem', 'validacao')
                Enums           = @{
                    tipo        = @('texto', 'numero', 'data', 'selecao', 'booleano', 'lista', 'arquivo')
                    obrigatorio = @('true', 'false')
                }
            }
            [PSCustomObject]@{
                Chave     = 'regras_visuais_derivadas_de_limite_tecnico'
                SubChaves = @('origem', 'comportamento_exigido', 'status')
                Enums     = @{ status = @('confirmado', 'hipotese') }
            }
        )
        EnumsTopo = @{}
    }
    'create-spec' = [PSCustomObject]@{
        CamposTopoObrigatorios = @(
            'user_story', 'objetivo', 'tela_referencia', 'endpoints', 'campos',
            'estados_de_tela', 'regras_de_negocio', 'edge_cases', 'fora_de_escopo',
            'perguntas_abertas', 'status_prontidao'
        )
        ListasDeMapas = @(
            [PSCustomObject]@{
                Chave     = 'endpoints'
                SubChaves = @('acao', 'destino', 'metodo')
                Enums     = @{ metodo = @('GET', 'POST', 'PUT', 'DELETE', 'a confirmar') }
            }
            [PSCustomObject]@{
                Chave     = 'campos'
                SubChaves = @('nome', 'tipo', 'obrigatorio', 'validacao')
                Enums     = @{ obrigatorio = @('true', 'false') }
            }
            [PSCustomObject]@{
                Chave     = 'edge_cases'
                SubChaves = @('categoria', 'cenario', 'tratamento', 'status')
                Enums     = @{ status = @('confirmado', 'hipotese', 'pergunta_aberta') }
            }
        )
        EnumsTopo = @{ status_prontidao = @('pronta_para_dev', 'bloqueada_por_perguntas_abertas') }
    }
}

$esquemaAtual = $esquemas[$Esquema]

# ---------------------------------------------------------------------------
# 2. Ler o arquivo e localizar os blocos ```yaml ... ```
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
    if (-not $dentroDoBloco -and $linha -match '^```ya?ml\s*$') {
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
    # chegou ao fim do arquivo com um bloco ainda aberto
    $blocos.Add([PSCustomObject]@{
        Inicio   = $inicioBloco + 1
        Conteudo = @($conteudoBloco)
        Fechado  = $false
    }) | Out-Null
}

if ($blocos.Count -eq 0) {
    Write-Output "lint-yaml-bloco: nenhum bloco \`\`\`yaml encontrado em $Arquivo -- nada para validar."
    exit 0
}

# ---------------------------------------------------------------------------
# 3. Helpers
# ---------------------------------------------------------------------------

function Add-Achado {
    param($Lista, $Severidade, $Bloco, $LinhaRelativa, $Detalhe)
    $Lista.Add([PSCustomObject]@{
        Severidade = $Severidade
        Bloco      = $Bloco
        Linha      = $LinhaRelativa
        Detalhe    = $Detalhe
    }) | Out-Null
}

function Test-ValorEmEnum {
    param([string]$Valor, [string[]]$Enum)
    $v = $Valor.Trim().Trim('"').Trim("'")
    if ($v -eq 'a confirmar' -or $v -eq '[a confirmar]') { return $true }   # escape-hatch sempre valido
    foreach ($opcao in $Enum) {
        if ($v -ieq $opcao) { return $true }
    }
    return $false
}

# ---------------------------------------------------------------------------
# 4. Validar cada bloco encontrado
# ---------------------------------------------------------------------------

$achados = New-Object System.Collections.Generic.List[object]
$numeroBloco = 0

foreach ($bloco in $blocos) {
    $numeroBloco++
    $conteudo = $bloco.Conteudo

    if (-not $bloco.Fechado) {
        Add-Achado $achados 'Alta' $numeroBloco $bloco.Inicio "Bloco \`\`\`yaml aberto na linha $($bloco.Inicio) nunca foi fechado com \`\`\` -- resto do arquivo pode ter sido engolido como YAML."
        continue   # sem fechamento, não faz sentido validar estrutura
    }

    # --- 4.1 Sintaxe, linha a linha ---
    for ($j = 0; $j -lt $conteudo.Count; $j++) {
        $linhaTexto = $conteudo[$j]
        $linhaAbsoluta = $bloco.Inicio + 1 + $j

        if ($linhaTexto -match "`t") {
            Add-Achado $achados 'Alta' $numeroBloco $linhaAbsoluta "Tab usado para indentacao -- YAML exige espacos."
        }
        if ($linhaTexto -match '^\s*(?:-\s*)?[a-zA-Z_][\w-]*:\S') {
            Add-Achado $achados 'Media' $numeroBloco $linhaAbsoluta "Possivel falta de espaco depois dos dois-pontos: '$($linhaTexto.Trim())'."
        }
        $qtdAspas = ([regex]::Matches($linhaTexto, '"')).Count
        if ($qtdAspas % 2 -ne 0) {
            Add-Achado $achados 'Media' $numeroBloco $linhaAbsoluta "Aspas desbalanceadas na linha: '$($linhaTexto.Trim())'."
        }
        if ($linhaTexto -match '\[ex:') {
            Add-Achado $achados 'Alta' $numeroBloco $linhaAbsoluta "Placeholder de template ainda presente, nao substituido por valor real: '$($linhaTexto.Trim())'."
        }
    }

    # --- 4.2 Campos de topo obrigatórios ---
    foreach ($chaveObrigatoria in $esquemaAtual.CamposTopoObrigatorios) {
        $padraoChave = "^$chaveObrigatoria\s*:\s*(.*)$"
        $linhaEncontrada = $null
        $indiceEncontrado = -1
        for ($j = 0; $j -lt $conteudo.Count; $j++) {
            if ($conteudo[$j] -match $padraoChave) {
                $linhaEncontrada = $Matches[1]
                $indiceEncontrado = $j
                break
            }
        }
        if ($indiceEncontrado -eq -1) {
            Add-Achado $achados 'Alta' $numeroBloco $bloco.Inicio "Campo obrigatorio ausente no bloco: '$chaveObrigatoria'."
            continue
        }

        # se o esquema define enum para este campo de topo (ex: status_prontidao), valide o valor
        if ($esquemaAtual.EnumsTopo.ContainsKey($chaveObrigatoria)) {
            $valor = $linhaEncontrada.Trim()
            if ([string]::IsNullOrWhiteSpace($valor)) {
                Add-Achado $achados 'Alta' $numeroBloco ($bloco.Inicio + 1 + $indiceEncontrado) "Campo '$chaveObrigatoria' presente mas sem valor."
            } elseif (-not (Test-ValorEmEnum -Valor $valor -Enum $esquemaAtual.EnumsTopo[$chaveObrigatoria])) {
                Add-Achado $achados 'Media' $numeroBloco ($bloco.Inicio + 1 + $indiceEncontrado) "Campo '$chaveObrigatoria' = '$valor' fora do conjunto esperado ($($esquemaAtual.EnumsTopo[$chaveObrigatoria] -join ' | '))."
            }
        }
    }

    # --- 4.3 Listas-de-mapas: sub-chaves obrigatórias + enums ---
    foreach ($listaDef in $esquemaAtual.ListasDeMapas) {
        # localizar a linha "chave:" de topo (indentação zero) que abre a lista
        $inicioLista = -1
        for ($j = 0; $j -lt $conteudo.Count; $j++) {
            if ($conteudo[$j] -match "^$($listaDef.Chave)\s*:\s*$") {
                $inicioLista = $j
                break
            }
        }
        if ($inicioLista -eq -1) { continue }   # já reportado como campo de topo ausente, acima

        # delimitar o alcance da lista: até a próxima chave de indentação zero, ou fim do bloco
        $fimLista = $conteudo.Count
        for ($j = $inicioLista + 1; $j -lt $conteudo.Count; $j++) {
            if ($conteudo[$j] -match '^\S') { $fimLista = $j; break }
        }

        # dentro do alcance, separar em itens por linha "- " (início de item de lista)
        $itensIndices = New-Object System.Collections.Generic.List[int]
        for ($j = $inicioLista + 1; $j -lt $fimLista; $j++) {
            if ($conteudo[$j] -match '^\s*-\s') { $itensIndices.Add($j) | Out-Null }
        }

        if ($itensIndices.Count -eq 0) {
            Add-Achado $achados 'Alta' $numeroBloco ($bloco.Inicio + 1 + $inicioLista) "Lista '$($listaDef.Chave)' declarada mas sem nenhum item."
            continue
        }

        for ($idx = 0; $idx -lt $itensIndices.Count; $idx++) {
            $inicioItem = $itensIndices[$idx]
            $fimItem = if ($idx + 1 -lt $itensIndices.Count) { $itensIndices[$idx + 1] } else { $fimLista }

            # colher todas as sub-chaves "chave: valor" dentro do item (a primeira linha
            # tem o "- " na frente; as seguintes são continuação, mesma indentação)
            $subChavesEncontradas = @{}
            for ($k = $inicioItem; $k -lt $fimItem; $k++) {
                if ($conteudo[$k] -match '^\s*-?\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(.*)$') {
                    $subChavesEncontradas[$Matches[1]] = @{ Valor = $Matches[2]; Linha = $bloco.Inicio + 1 + $k }
                }
            }

            foreach ($subChaveObrigatoria in $listaDef.SubChaves) {
                if (-not $subChavesEncontradas.ContainsKey($subChaveObrigatoria)) {
                    Add-Achado $achados 'Alta' $numeroBloco ($bloco.Inicio + 1 + $inicioItem) "Item de '$($listaDef.Chave)' sem a sub-chave obrigatoria '$subChaveObrigatoria'."
                }
            }

            foreach ($campoComEnum in $listaDef.Enums.Keys) {
                if ($subChavesEncontradas.ContainsKey($campoComEnum)) {
                    $entrada = $subChavesEncontradas[$campoComEnum]
                    $valor = $entrada.Valor.Trim()
                    if ([string]::IsNullOrWhiteSpace($valor)) {
                        Add-Achado $achados 'Alta' $numeroBloco $entrada.Linha "Sub-chave '$campoComEnum' presente mas sem valor."
                    } elseif (-not (Test-ValorEmEnum -Valor $valor -Enum $listaDef.Enums[$campoComEnum])) {
                        Add-Achado $achados 'Media' $numeroBloco $entrada.Linha "Sub-chave '$campoComEnum' = '$valor' fora do conjunto esperado ($($listaDef.Enums[$campoComEnum] -join ' | '))."
                    }
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 5. Saída
# ---------------------------------------------------------------------------

$achadosOrdenados = @($achados | Sort-Object @{Expression = {
        switch ($_.Severidade) { 'Alta' { 0 }; 'Media' { 1 }; 'Baixa' { 2 }; default { 3 } }
    }}, Bloco, Linha)

if ($achadosOrdenados.Count -eq 0) {
    Write-Output "lint-yaml-bloco: $($blocos.Count) bloco(s) yaml validados contra o esquema '$Esquema' -- nenhum problema encontrado."
    exit 0
}

Write-Output "lint-yaml-bloco: $($achadosOrdenados.Count) achado(s) em $($blocos.Count) bloco(s) (esquema '$Esquema'):"
$achadosOrdenados | Format-Table -AutoSize -Wrap Severidade, Bloco, Linha, Detalhe | Out-String -Width 200 | Write-Output

$temAlta = @($achadosOrdenados | Where-Object { $_.Severidade -eq 'Alta' }).Count -gt 0
if ($temAlta) { exit 1 } else { exit 0 }
