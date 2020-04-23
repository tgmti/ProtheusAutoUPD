$PRGPATH='C:\Users\thiago.mota\Documents\Projetos\SandriProtheus'
$COMPILELIST='C:\Temp\compile.lst'
$OUTRESULT='C:\Temp\'
$PROTHEUS='C:\TOTVS\Dev120127\Protheus\bin\appserver'
$APPSERVER_EXE=$PROTHEUS + '\appserver.exe'
$ENVCOMPILE='comp_custom'
$INCLUDES='C:\Users\thiago.mota\Documents\Projetos\SandriProtheus\.Includes'

If (Get-Item $COMPILELIST) {
    Remove-Item $COMPILELIST
}

Write-Host $SEPARATOR
Write-Host  Obtendo Lista dos programas a compilar
Write-Host $SEPARATOR

Get-ChildItem  -Path $PRGPATH -File -Recurse -Force -Include *.PRW,*.PRG,*.PRX `
| Where { $_.FullName -notlike "*\.git\*" `
-and $_.FullName -notlike "*\.Includes\*" `
-and $_.FullName -notlike "*\.vscode\*" `
} `
| Format-Table -HideTableHeaders -Property @{e={$_.FullName + ";"}; width = 255} -AutoSize `
| Out-File -Path $COMPILELIST -NoNewline -Encoding "Windows-1252" -Width 255

If (Get-Item $COMPILELIST) {
    Write-Host $SEPARATOR
    Write-Host  Compilando Programas listados
    Write-Host $SEPARATOR

    $AppplyCommand = ('& ' + $APPSERVER_EXE + ' -compile ' `
    + ' -files="'+$COMPILELIST +'"' `
    + ' -includes="'+ $INCLUDES +'"' `
    + ' -src="'+ $PROTHEUS +'"' `
    + ' -env='+ $ENVCOMPILE `
    + ' -outreport="'+ $OUTRESULT +'"' `
    )

    Write-Host $AppplyCommand
    Invoke-Expression $AppplyCommand

}

Write-Host $SEPARATOR
Write-Host Desfragmentando o RPO
Write-Host $SEPARATOR

$AppplyCommand = ("& " + $APPSERVER_EXE + " -compile -defragrpo -env="+ $ENVCOMPILE )
Invoke-Expression $AppplyCommand


Write-Host $SEPARATOR
Write-Host Limpando arquivos de compilação
Write-Host $SEPARATOR

Get-ChildItem  -Path $PRGPATH -File -Recurse -Force `
-Include *.ppo,*.errprw,*.errprx,*.errprg,*.erx_PRW,*.erx_PRX,*.erx_PRG,*.ppx_PRW,*.ppx_PRX,*.ppx_PRG `
| Remove-Item -Force

Write-Host $SEPARATOR
Write-Host Compilação de fontes finalizada!
Write-Host $SEPARATOR

