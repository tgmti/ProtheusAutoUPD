$oConfig = Get-Content '.\config.json' | ConvertFrom-Json

$projectPath=$oConfig.project_path
$compileListFile=$oConfig.compile_list_file
$outputPath=$oConfig.output_path
$appserverPath=$oConfig.appserver_path
$appserverExe=$appserverPath + $oconfig.appserver_exe
$environment=$oConfig.environment
$includesPath=$oConfig.includes_path

$separator="".PadRight(80,"=")

function ExecutarCompilacao() {

    LimparArquivosAntigos

    If (ListarArquivos) {
        compilarProgramas
        desfragmentarRPO
        limpaArquivosPreCompilacao
    }
    MostraStatus "Compilação de fontes finalizada!"
}

function MostraStatus($texto) {
    Write-Host $separator
    Write-Host  $texto
    Write-Host $separator
}

function LimparArquivosAntigos {

    MostraStatus "Limpando arquivos de Compilação existentes!"

    # Limpar os arquivos de compilação, erros e sucesso
    Remove-Item $compileListFile -ErrorAction SilentlyContinue
    Remove-Item ($outputPath + "compile_errors.log" ) -ErrorAction SilentlyContinue
    Remove-Item ($outputPath + "compile_success.log" ) -ErrorAction SilentlyContinue
}

function ListarArquivos {

    $compileList=$null

    MostraStatus "Obtendo Lista dos programas a compilar..."

    Get-ChildItem  -Path $projectPath -File -Recurse -Force -Include *.PRW,*.PRG,*.PRX,*.TLPP,*.APP `
    | Where-Object { $_.FullName -notlike "*\.git\*" `
    -and $_.FullName -notlike "*\.Includes\*" `
    -and $_.FullName -notlike "*\.vscode\*" `
    } `
    | Format-Table -HideTableHeaders -Property @{e={$_.FullName + ";"}; width = 255} -AutoSize -OutVariable compileList

    if ($compileList.Count -gt 0) {
        MostraStatus "Encontrados $($compileList.Count -4) programas para compilar. Gerando arquivo $compileListFile ..."

        $compileList | Out-File -Path $compileListFile -NoNewline -Encoding "Windows-1252" -Width 255

        If (Get-Item $compileListFile) { return $True } else { return $False}

    } else {
        MostraStatus "ERRO: Nenhum programa encontrado para compilar"
        return $False
    }

}

function compilarProgramas {

    MostraStatus "Compilando Programas listados..."

    $AppplyCommand = ('& ' + $appserverExe + ' -compile ' `
    + ' -files="'+$compileListFile +'"' `
    + ' -includes="'+ $includesPath +'"' `
    + ' -src="'+ $appserverPath +'"' `
    + ' -env='+ $environment `
    + ' -outreport="'+ $outputPath +'"' `
    )

    Write-Host Comando:
    Write-Host $AppplyCommand
    Write-Host $separator

    Invoke-Expression $AppplyCommand

    MostraStatus "Fim da Compilação"

}


function desfragmentarRPO {

    MostraStatus "Desfragmentando o RPO..."

    $AppplyCommand = ("& " + $appserverExe + " -compile -defragrpo -env="+ $environment )
    Invoke-Expression $AppplyCommand

    MostraStatus "Fim da Desfragmentação"
}

function limpaArquivosPreCompilacao {

    MostraStatus "Limpando arquivos de compilação"

    Get-ChildItem  -Path $projectPath -File -Recurse -Force `
    -Include *.ppo,*.errprw,*.errprx,*.errprg,*.erx_PRW,*.erx_PRX,*.erx_PRG,*.ppx_PRW,*.ppx_PRX,*.ppx_PRG `
    | Remove-Item -Force -ErrorAction SilentlyContinue

}

ExecutarCompilacao
