$oConfig = Get-Content '.\config.json' | ConvertFrom-Json

$updatePath = $oConfig.update_path
$successPath = $oConfig.success_path
$errorPath = $oConfig.error_path
$logFile = $oConfig.log_file
$appserverExe = $oConfig.appserver_exe
$environment = $oConfig.environment

$WithSuccess= [System.Collections.ArrayList]::new()
$WithErrors= [System.Collections.ArrayList]::new()

Start-Transcript -Path $logFile # Inicia Gravação do Log

# Move os arquivos de UPD para o diretório Sucesso ou erro
function MoveUpd {

    param (
        $oUpdate,
        $lSuccess
    )
    $cDestination = If ($lSuccess) { $successPath } Else { $errorPath }
    $cPathOrigin = $oUpdate.Directory

    If ($cPathOrigin -eq $updatePath){
        Write-Host 'Mover so arquivo' $oUpdate
    } Else {
        Write-Host 'Mover Diretorio'
    }

    Write-Host 'Mover: ' $cPathOrigin
    Write-Host 'Movendo arquivos para ' $cDestination

    Move-Item -Path $cPathOrigin -Destination $cDestination -Force -ErrorAction SilentlyContinue

}


$aPatches = Get-ChildItem -Path $updatePath -Recurse -Force *tttp*.ptm

$SEPARATOR="".PadRight(80,"=")

Write-Host $SEPARATOR
Write-Host Iniciando aplicacao de $aPatches.Count Patches
Write-Host $SEPARATOR

foreach ($cPatch in $aPatches) {

    Write-Host $SEPARATOR
    Write-Host Aplicando pacote $cPatch.DirectoryName.Replace($updatePath, '')
    Write-Host $SEPARATOR

    $AppplyCommand = ("& " + $appserverExe + " -compile -applypatch -env=" + $environment + " -files=" + $cPatch)
    Write-Host $AppplyCommand
    # &($appserverExe + " -compile -applypatch -env=" + $environment + " -files="+$cPatch)
    $logApply = Invoke-Expression $AppplyCommand

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

$AppplyCommand = ("& " + $appserverExe + " -compile -defragrpo -env=" + $environment)
Invoke-Expression $AppplyCommand

Write-Host $SEPARATOR
Write-Host Aplicacao de Patches finalizada!
Write-Host Com sucesso:
$WithSuccess | Select-Object Name, Directory | Format-Table -AutoSize -Wrap
Write-Host $SEPARATOR
Write-Host Com Erros:
$WithErrors | Select-Object Name, Directory | Format-Table -AutoSize -Wrap
Write-Host $SEPARATOR

Stop-Transcript # Finaliza Gravação do Log