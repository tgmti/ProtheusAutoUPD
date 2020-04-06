$UPDPATH='C:\TOTVS\Updates\Auto\'
$LOGUPD=$UPDPATH+'logapply.log'
$PROTHEUS='C:\TOTVS\Dev\'
$APPSERVER_EXE=$PROTHEUS + 'Protheus\bin\appserver\appserver.exe'

$aPatches = Get-ChildItem -Path $UPDPATH -Recurse -Force *.ptm

$SEPARATOR="".PadRight(80,"=")

foreach ($cPatch in $aPatches) {

    Write-Host $SEPARATOR
    Write-Host Aplicando pacote $cPatch.DirectoryName.Replace($UPDPATH, '')
    Write-Host $SEPARATOR

    $AppplyCommand = ("& " + $APPSERVER_EXE + " -compile -applypatch -env=atu -files="+$cPatch)
    # Write-Host $AppplyCommand
    # &($APPSERVER_EXE + " -compile -applypatch -env=atu -files="+$cPatch)
    Invoke-Expression $AppplyCommand
}

Write-Host $SEPARATOR
Write-Host Desfragmentando o RPO
Write-Host $SEPARATOR

$AppplyCommand = ("& " + $APPSERVER_EXE + " -compile -defragrpo -env=atu")
Invoke-Expression $AppplyCommand

Write-Host $SEPARATOR
Write-Host Aplicacao de Patches finalizada!
Write-Host $SEPARATOR

