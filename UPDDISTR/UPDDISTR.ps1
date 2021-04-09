# Configurações
$oConfig = Get-Content '.\config.json' | ConvertFrom-Json

$updatePath = $oConfig.update_path
$successPath = $oConfig.success_path
$errorPath = $oConfig.error_path
$logPath = $oConfig.log_path
$logFile = $oConfig.log_file
$systemPath = $oConfig.system_path
$systemloadPath = $oConfig.systemload_path
$appserverPath = $oConfig.appserver_path
$appserverExe = $appserverPath + $oConfig.appserver_exe
$environment = $oConfig.environment


# Variáveis Globais
$resultFile=($systemloadPath + 'result.json')
$paramsFileOrigin=('.\upddistr_param.json')
$paramsFile=($systemloadPath + 'upddistr_param.json')

$separator="".PadRight(80,"=")

$Simulado=$False
$Invoke=$True

$WithSuccess= [System.Collections.ArrayList]::new()
$WithErrors= [System.Collections.ArrayList]::new()

# Organiza execução dos updates
function UpdateProtheus {

    Write-Host $separator
    Write-Host 'Iniciando execução dos compatibilizadores UPDDISTR'
    Write-Host $separator

    $TotalTime = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Host 'Listando atualizações existentes em ' $updatePath

    $aUpdates = ListUpdates($updatePath)

    # Se só tem um, encapsula no array
    If ( $aUpdates.GetType().Name -ne 'Object[]' ) {
        $aUpdates = @( $aUpdates )
    }

    foreach ($aFiles in $aUpdates) {

        Write-Host $separator
        Write-Host Iniciando atualização ($aUpdates.IndexOf($aFiles)+1) de $aUpdates.Length

        PrepareUpd

        if ( CopyFiles($aFiles) ) {
            if ($Invoke) {

                ExecuteUpdInvoke($aFiles)

            } Else {
                $oProcProtheus = ExecuteUpd

                WaitResult

                StopProtheus $oProcProtheus
            }

            #MoveUpd $aFiles (GetResult)
            if (GetResult) {
                $WithSuccess.Add($aFiles)
            } Else {
                $WithErrors.Add($aFiles)
            }
        }

        CleanUpd

        Write-Host Finalizada atualização ($aUpdates.IndexOf($aFiles)+1) de $aUpdates.Length
        Write-Host $separator
    }

    Write-Host $separator
    Write-Host 'Execução dos compatibilizadores UPDDISTR finalizada'

    if ($WithSuccess.Length -gt 0) {
        Write-Host $separator
        Write-Host Com sucesso:
        $WithSuccess | Select Name | Format-Table -AutoSize -Wrap
    }

    if ($WithErrors.Length -gt 0) {
        Write-Host $separator
        Write-Host Com Erros:
        $WithErrors | Select Name | Format-Table -AutoSize -Wrap
    }

    Write-Host $separator
    Write-Host $aUpdates.Length atualizações executadas em ("{0:HH:mm:ss}" -f ([datetime]$TotalTime.Elapsed.Ticks))
    Write-Host $separator


}



# Listar arquivos de update diferencial
function ListUpdates($cDistPath) {

    $aUpdates = Get-ChildItem -Path $cDistPath -Recurse -Force *df*.txt |
        Where-Object -FilterScript {
            (($_.Name -eq 'sdfbra.txt') -or ($_.Name -eq 'hlpdfpor.txt') -or ($_.Name -eq 'hlpdfeng.txt') -or ($_.Name -eq 'hlpdfspa.txt')) -and
            ( $_.DirectoryName -notlike '*\sdf\chi*' ) -and
            ( $_.DirectoryName -notlike '*\sdf\arg*' ) -and
            ( $_.DirectoryName -notlike '*\sdf\col*' ) -and
            ( $_.DirectoryName -notlike '*\sdf\mex*' ) -and
            ( $_.DirectoryName -notlike '*\sdf\per*' )
        } | Group-Object -Property DirectoryName

    return $aUpdates
}

# Prepara o Protheus para a atualização
function PrepareUpd() {

    Write-Host 'Preparando base para atualização'

    Remove-Item -Path ($systemloadPath + '*.dtc') -ErrorAction SilentlyContinue
    Remove-Item -Path ($systemloadPath + '*.idx') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path ($systemloadPath + 'ctreeint') -Recurse -Force -ErrorAction SilentlyContinue

    CleanUpd

    Copy-Item $paramsFileOrigin $paramsFile

}

# Limpa os arquivos de atualização
function CleanUpd() {

    Remove-Item -Path ($appserverPath + 'mpupd*.*') -Force -ErrorAction SilentlyContinue

    Remove-Item -Path ($systemPath + 'TOTVSP*.*') -Force -ErrorAction SilentlyContinue

    Remove-Item -Path ($systemloadPath + '*df*.txt') -Force -ErrorAction SilentlyContinue
    Remove-Item -Path ($resultFile) -Force -ErrorAction SilentlyContinue
    Remove-Item -Path ($paramsFile) -Force -ErrorAction SilentlyContinue
}


# Copiar os arquivos para o diretório SystemLoad
function CopyFiles($aCopyFiles) {

    $Success = $False

    foreach ($oFile in $aCopyFiles.Group) {
        Write-Host Copiando arquivo $oFile.BaseName de $oFile.DirectoryName.Replace($updatePath,'')
        Copy-Item $oFile -Destination $systemloadPath

        If ( Test-Path(($systemloadPath + $oFile.Name)) ) {
            $Success = $True
        } Else {
            Write-Host Erro ao Copiar o arquivo $oFile.BaseName
            Return $False
        }

    }

    return $Success

}


# Executa o Appserver
function ExecuteUpd() {
    Write-Host 'Executando UPDDISTR No Protheus'

    If ($Simulado) {
        #Sleep 2
        '{ "result": "SIMULADO" }' > $resultFile
    } Else {
        return (Start-Process -FilePath ($appserverExe) -ArgumentList '-console' -PassThru)
    }
}
# Executa o Appserver via Invoke
function ExecuteUpdInvoke() {

    param (
        $oUpdate
    )

    Write-Host 'Executando UPDDISTR No Protheus'

    $Time = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Progress -Activity "Aguardando execução do UPDDISTR" -Status ("{0:HH:mm:ss}" -f ([datetime]$Time.Elapsed.Ticks))

    $LogName = $oUpdate.Name.ToUpper().Replace($updatePath.ToUpper(),'').Split('\')[0]

    $LogInvoke = $logPath + $LogName + ".log"
    $LogResult = $logPath + $LogName + "_Result.json"

    Stop-Transcript # Finaliza Gravação do Log Principal

    # Grava o log do Appserver separado
    Start-Transcript -Path $LogInvoke -UseMinimalHeader

    If ($Simulado) {
        #Sleep 2
        '{ "result": "SIMULADO" }' > $resultFile
    } Else {
        $UpdCommand = ("& " + $appserverExe + " -run=UPDDISTR -env=" + $environment)
        Invoke-Expression $UpdCommand
    }

    Stop-Transcript # Finaliza Gravação do Log do Appserver

    Start-Transcript -Path $logFile -Append -UseMinimalHeader # Volta a gravar no log principal

    if ( Test-Path ($resultFile) ) {
        Write-Host UPDDISTR Executado em ("{0:HH:mm:ss}" -f ([datetime]$Time.Elapsed.Ticks))
        Copy-Item -Path $resultFile -Destination $LogResult -Force -ErrorAction SilentlyContinue
    }

}

# Monitora o resultado
function WaitResult() {

    $Time = [System.Diagnostics.Stopwatch]::StartNew()

    # Aguarda Criação do Arquivo result.json
    while ( !( Test-Path ($resultFile) ) ) {
        Start-Sleep 1

        Write-Progress -Activity "Aguardando execução do UPDDISTR" -Status ("{0:HH:mm:ss}" -f ([datetime]$Time.Elapsed.Ticks))
    }

    if ( Test-Path ($resultFile) ) {
        Write-Host UPDDISTR Executado em ("{0:HH:mm:ss}" -f ([datetime]$Time.Elapsed.Ticks))
    }


}

# Derruba o serviço Protheus
function StopProtheus($oProc) {
    Write-Host 'Finalizando serviço Protheus'
    Stop-Process $oProc -ErrorAction SilentlyContinue
}


function GetResult {
    if ( Test-Path ($resultFile) ) {
        $oResult = Get-Content $resultFile | ConvertFrom-Json
        if ($oResult.result -eq "success") {
            Write-Host "Sucesso!!!"
            return $True
        } else {
            Write-Host $oResult.result
            return $False
        }
    } else {
        Write-Host 'Arquivo result não encontrado.'
        return $False
    }
}

# Move os arquivos de UPD para o diretório Sucesso ou erro
function MoveUpd {

    param (
        $oUpdate,
        $lSuccess
    )
    $cDestination = If ($lSuccess) { $successPath } Else { $errorPath }
    $cPathOrigin = $oUpdate.Name.ToUpper().Replace($updatePath.ToUpper(),'').Split('\')[0]
    $cPathToMove = $updatePath + $cPathOrigin
    $cPathResult = $cDestination + $cPathOrigin + "\result.json"

    Write-Host 'Movendo arquivos para ' $cDestination

    Write-Host Origem: $cPathToMove
    Write-Host ResultFile: $cPathResult

    Move-Item -Path $cPathToMove -Destination $cDestination -Force
    # -ErrorAction SilentlyContinue

    Copy-Item -Path $resultFile -Destination $cPathResult -Force
    # -ErrorAction SilentlyContinue

}



Start-Transcript -Path $logFile -UseMinimalHeader # Inicia Gravação do Log

UpdateProtheus
#PrepareUpd

Stop-Transcript # Finaliza Gravação do Log
