$PRGPATH='C:\Users\thiago.mota\Documents\Projetos\SandriProtheus'
$LOGUPD='.\logapply.log'
$COMPILELIST='.\compile.lst'
$OUTRESULT='.\'
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

Set-Location $PROTHEUS

Get-ChildItem  -Path $PRGPATH -File -Recurse -Force -Include *.PRW,*.PRG,*.PRX `
| Where { $_.FullName -notlike "*\.git\*" `
-and $_.FullName -notlike "*\.Includes\*" `
-and $_.FullName -notlike "*\.vscode\*" `
} `
| Select-Object @{Expression={$_.FullName + ";"}} `
| Format-Table -HideTableHeaders `
| Out-File -Path $COMPILELIST -NoNewline

If (Get-Item $COMPILELIST) {
    Write-Host $SEPARATOR
    Write-Host  Compilando Programas listados
    Write-Host $SEPARATOR

    $AppplyCommand = ("& " + $APPSERVER_EXE + " -compile " `
    + " -files="+$COMPILELIST `
    + "-includes="+ $INCLUDES `
    + "-src="+ $PRGPATH `
    + "-env="+ $ENVCOMPILE `
    + "-outreport="+ $OUTRESULT `
    )

    Invoke-Expression $AppplyCommand

}

Write-Host $SEPARATOR
Write-Host Desfragmentando o RPO
Write-Host $SEPARATOR

$AppplyCommand = ("& " + $APPSERVER_EXE + " -compile -defragrpo -env="+ $ENVCOMPILE )
Invoke-Expression $AppplyCommand

Write-Host $SEPARATOR
Write-Host Compilação de fontes finalizada!
Write-Host $SEPARATOR

