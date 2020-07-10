$UPDBASE='E:\Totvs12\Update23\Patch\'
$UPDPATH=$UPDBASE + 'Auto\'
$UPDSUCCESS=$UPDBASE + 'Success\'
$UPDERROR=$UPDBASE + 'Error\'
$LOGUPD='E:\Totvs12\Update23\ApplyPatches.log'
$APPSERVER_EXE='E:\Totvs12\Microsiga\Protheus\bin\AppServerUpd\appserver.exe'
$ENVIRONMENT='UPD'


# Move os arquivos de UPD para o diretório Sucesso ou erro
function MoveUpd {

    param (
        $oUpdate,
        $lSuccess
    )
    $cDestination = If ($lSuccess) { $UPDSUCCESS } Else { $UPDERROR }
    $cPathOrigin = $oUpdate.Directory

    Write-Host 'Mover: ' $oUpdate.Directory
    Write-Host 'Mover: ' $cPathOrigin
    Write-Host 'Movendo arquivos para ' $cDestination

    Move-Item -Path $cPathOrigin -Destination $cDestination -Force -ErrorAction SilentlyContinue

}


$aPatches = Get-ChildItem -Path $UPDPATH -Recurse -Force *tttp*.ptm

$SEPARATOR="".PadRight(80,"=")

foreach ($cPatch in $aPatches) {

    Write-Host $SEPARATOR
    Write-Host Aplicando pacote $cPatch.DirectoryName.Replace($UPDPATH, '')
    Write-Host $SEPARATOR

    $AppplyCommand = ("& " + $APPSERVER_EXE + " -compile -applypatch -env=" + $ENVIRONMENT + " -files=" + $cPatch)
    Write-Host $AppplyCommand
    # &($APPSERVER_EXE + " -compile -applypatch -env=" + $ENVIRONMENT + " -files="+$cPatch)
    $logApply = Invoke-Expression $AppplyCommand

    $lSuccess = ( $logApply -contains '[CMDLINE] Patch successfully applied.' )

    if ($lSuccess) {
        Write-Host Patch successfully applied. - $cPatch
    } else {
        Write-Host ERROR APPLY PATCH $cPatch :
        $logApply
    }
    
    MoveUpd $cPatch $lSuccess

}

Write-Host $SEPARATOR
Write-Host Desfragmentando o RPO
Write-Host $SEPARATOR

$AppplyCommand = ("& " + $APPSERVER_EXE + " -compile -defragrpo -env=" + $ENVIRONMENT)
Invoke-Expression $AppplyCommand

Write-Host $SEPARATOR
Write-Host Aplicacao de Patches finalizada!
Write-Host $SEPARATOR
