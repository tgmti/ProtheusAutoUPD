$PRGPATH='C:\Users\thiago.mota\Documents\Projetos\SandriProtheus\faturamento\ponto entrada'
$COMPILELIST='C:\Temp\compile.lst'
$OUTRESULT='C:\Temp\'
$PROTHEUS='C:\TOTVS\Dev120127\Protheus\bin\appserver'
$APPSERVER_EXE=$PROTHEUS + '\appserver.exe'
$ENVCOMPILE='comp_custom'
$INCLUDES='C:\Users\thiago.mota\Documents\Projetos\SandriProtheus\.Includes'

$SEPARATOR="".PadRight(80,"=")
$PRG_COMPILAR=$null

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
    Write-Host $SEPARATOR
    Write-Host  $texto
    Write-Host $SEPARATOR
}

function LimparArquivosAntigos {

    MostraStatus "Limpando arquivos de Compilação existentes!"

    # Limpar os arquivos de compilação, erros e sucesso
    Remove-Item $COMPILELIST -ErrorAction SilentlyContinue
    Remove-Item ($OUTRESULT + "compile_errors.log" ) -ErrorAction SilentlyContinue
    Remove-Item ($OUTRESULT + "compile_success.log" ) -ErrorAction SilentlyContinue
}

function ListarArquivos {

    MostraStatus "Obtendo Lista dos programas a compilar..."

    Get-ChildItem  -Path $PRGPATH -File -Recurse -Force -Include *.PRW,*.PRG,*.PRX `
    | Where { $_.FullName -notlike "*\.git\*" `
    -and $_.FullName -notlike "*\.Includes\*" `
    -and $_.FullName -notlike "*\.vscode\*" `
    } `
    | Format-Table -HideTableHeaders -Property @{e={$_.FullName + ";"}; width = 255} -AutoSize -OutVariable PRG_COMPILAR

    if ($PRG_COMPILAR.Count -gt 0) {
        MostraStatus "Encontrados $($PRG_COMPILAR.Count -4) programas para compilar. Gerando arquivo $COMPILELIST ..."

        $PRG_COMPILAR | Out-File -Path $COMPILELIST -NoNewline -Encoding "Windows-1252" -Width 255

        If (Get-Item $COMPILELIST) { return $True } else { return $False}

    } else {
        MostraStatus "ERRO: Nenhum programa encontrado para compilar"
        return $False
    }

}

function compilarProgramas {

    MostraStatus "Compilando Programas listados..."

    $AppplyCommand = ('& ' + $APPSERVER_EXE + ' -compile ' `
    + ' -files="'+$COMPILELIST +'"' `
    + ' -includes="'+ $INCLUDES +'"' `
    + ' -src="'+ $PROTHEUS +'"' `
    + ' -env='+ $ENVCOMPILE `
    + ' -outreport="'+ $OUTRESULT +'"' `
    )

    Write-Host Comando:
    Write-Host $AppplyCommand
    Write-Host $SEPARATOR

    Invoke-Expression $AppplyCommand

    MostraStatus "Fim da Compilação"

}


function desfragmentarRPO {

    MostraStatus "Desfragmentando o RPO..."

    $AppplyCommand = ("& " + $APPSERVER_EXE + " -compile -defragrpo -env="+ $ENVCOMPILE )
    Invoke-Expression $AppplyCommand

    MostraStatus "Fim da Desfragmentação"
}

function limpaArquivosPreCompilacao {

    MostraStatus "Limpando arquivos de compilação"

    Get-ChildItem  -Path $PRGPATH -File -Recurse -Force `
    -Include *.ppo,*.errprw,*.errprx,*.errprg,*.erx_PRW,*.erx_PRX,*.erx_PRG,*.ppx_PRW,*.ppx_PRX,*.ppx_PRG `
    | Remove-Item -Force -ErrorAction SilentlyContinue

}

ExecutarCompilacao
