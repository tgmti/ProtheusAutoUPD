$UPDBASE='F:\TOTVSUPDATE\12.01.23_20210112\AutoUpd\Patches\'
$UPDPATH=$UPDBASE
$UPDSUCCESS=$UPDBASE + 'Success\'
$UPDERROR=$UPDBASE + 'Error\'
$LOGUPD=$UPDBASE + 'ApplyPatches_tst.log'
$APPSERVER_EXE='F:\TOTVSDEV\Microsiga\Protheus\bin\appserverThiago\appserver.exe'
$ENVIRONMENT='dev'

$WithSuccess= [System.Collections.ArrayList]::new()
$WithErrors= [System.Collections.ArrayList]::new()

Start-Transcript -Path $LOGUPD # Inicia Gravação do Log

# Move os arquivos de UPD para o diretório Sucesso ou erro
function MoveUpd {

    param (
        $oUpdate,
        $lSuccess
    )
    $cDestination = If ($lSuccess) { $UPDSUCCESS } Else { $UPDERROR }
    $cPathOrigin = $oUpdate.Directory

    If ($cPathOrigin -eq $UPDPATH){
        Write-Host 'Mover so arquivo' $oUpdate
    } Else {
        Write-Host 'Mover Diretorio'
    }

    Write-Host 'Mover: ' $cPathOrigin
    Write-Host 'Movendo arquivos para ' $cDestination

    # Move-Item -Path $cPathOrigin -Destination $cDestination -Force -ErrorAction SilentlyContinue

}


$aPatches = Get-ChildItem -Path $UPDPATH -Recurse -Force *tttp*.ptm

$SEPARATOR="".PadRight(80,"=")

Write-Host $SEPARATOR
Write-Host Iniciando aplicacao de $aPatches.Count Patches
Write-Host $SEPARATOR

foreach ($cPatch in $aPatches) {

    Write-Host $SEPARATOR
    Write-Host Aplicando pacote $cPatch.DirectoryName.Replace($UPDPATH, '')
    Write-Host $SEPARATOR

    $AppplyCommand = ("& " + $APPSERVER_EXE + " -compile -applypatch -env=" + $ENVIRONMENT + " -files=" + $cPatch)
    Write-Host $AppplyCommand
    # &($APPSERVER_EXE + " -compile -applypatch -env=" + $ENVIRONMENT + " -files="+$cPatch)
    # $logApply = Invoke-Expression $AppplyCommand

    $lSuccess = ( $logApply -contains '[CMDLINE] Patch successfully applied.' )

    if ($lSuccess) {
        $WithSuccess.Add($cPatch)

        Write-Host Patch successfully applied. - $cPatch

    } else {
        $WithErrors.Add($cPatch)

        Write-Host ERROR APPLY PATCH $cPatch :
        $logApply
    }

    #MoveUpd $cPatch $lSuccess

}

Write-Host $SEPARATOR
Write-Host Desfragmentando o RPO
Write-Host $SEPARATOR

$AppplyCommand = ("& " + $APPSERVER_EXE + " -compile -defragrpo -env=" + $ENVIRONMENT)
# Invoke-Expression $AppplyCommand

Write-Host $SEPARATOR
Write-Host Aplicacao de Patches finalizada!
Write-Host Com sucesso:
$WithSuccess | Select Name, Directory | Format-Table -AutoSize -Wrap
Write-Host $SEPARATOR
Write-Host Com Erros:
$WithErrors | Select Name, Directory | Format-Table -AutoSize -Wrap
Write-Host $SEPARATOR

Stop-Transcript # Finaliza Gravação do Log