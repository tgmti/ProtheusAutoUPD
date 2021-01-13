
# Configurações
$UPDBASE='F:\TOTVSUPDATE\12.01.23_20210112\AutoUpd\Patches\'
$UPDPATH= $UPDBASE
$UPDSUCCESS= $UPDBASE + 'Success\'
$UPDERROR= $UPDBASE + 'Error\'

$PROTHEUS='F:\TOTVSDEV\Microsiga\'
$APPSERVER_EXE=$PROTHEUS + 'Protheus\bin\appserverAutoUpdDistr\appserver.exe'
$ENVIRONMENT='dev'
$SYSTEM=$PROTHEUS + 'Protheus_Data\system\'
$SYSTEMLOAD=$PROTHEUS + 'Protheus_Data\systemload\'

$RESULT_FILE=($SYSTEMLOAD + 'result.json')
$PARAMS_FILE_ORIGIN=('.\upddistr_param.json')
$PARAMS_FILE=($SYSTEMLOAD + 'upddistr_param.json')

$SEPARATOR="".PadRight(80,"=")

$Simulado=$False
$Invoke=$True

$LOGUPD=$UPDBASE + '..\UpdDistr.log'
$WithSuccess= [System.Collections.ArrayList]::new()
$WithErrors= [System.Collections.ArrayList]::new()

# Organiza execução dos updates
function UpdateProtheus {

    Write-Host $SEPARATOR
    Write-Host 'Iniciando execução dos compatibilizadores UPDDISTR'
    Write-Host $SEPARATOR

    $TotalTime = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Host 'Listando atualizações existentes em ' $UPDPATH

    $aUpdates = ListUpdates($UPDPATH)

    # Se só tem um, encapsula no array
    If ( $aUpdates.GetType().Name -ne 'Object[]' ) {
        $aUpdates = @( $aUpdates )
    }

    foreach ($aFiles in $aUpdates) {

        Write-Host $SEPARATOR
        Write-Host Iniciando atualização ($aUpdates.IndexOf($aFiles)+1) de $aUpdates.Length

        PrepareUpd
        CopyFiles($aFiles)

        if ($Invoke) {
            $Time = [System.Diagnostics.Stopwatch]::StartNew()

            ExecuteUpdInvoke

            if ( Test-Path ($RESULT_FILE) ) {
                Write-Host UPDDISTR Executado em ("{0:HH:mm:ss}" -f ([datetime]$Time.Elapsed.Ticks))
            }

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

        CleanUpd

        Write-Host Finalizada atualização ($aUpdates.IndexOf($aFiles)+1) de $aUpdates.Length
        Write-Host $SEPARATOR
    }

    Write-Host $SEPARATOR
    Write-Host 'Execução dos compatibilizadores UPDDISTR finalizada'

    Write-Host $SEPARATOR
    Write-Host Com sucesso:
    $WithSuccess | Select Name | Format-Table -AutoSize -Wrap

    Write-Host $SEPARATOR
    Write-Host Com Erros:
    $WithErrors | Select Name | Format-Table -AutoSize -Wrap

    Write-Host $SEPARATOR
    Write-Host $aUpdates.Length atualizações executadas em ("{0:HH:mm:ss}" -f ([datetime]$TotalTime.Elapsed.Ticks))
    Write-Host $SEPARATOR


}



# Listar arquivos de update diferencial
function ListUpdates($cDistPath) {

    $aUpdates = Get-ChildItem -Path $cDistPath -Recurse -Force *df*.txt |
        Where-Object -FilterScript {
            ($_.Name -eq 'sdfbra.txt') -or ($_.Name -eq 'hlpdfpor.txt') -or ($_.Name -eq 'hlpdfspa.txt') -or ($_.Name -eq 'hlpdfeng.txt')
        } | Group-Object -Property DirectoryName

    return $aUpdates
}

# Prepara o Protheus para a atualização
function PrepareUpd() {

    Write-Host 'Preparando base para atualização'

    Remove-Item -Path ($SYSTEMLOAD + '*.dtc') -ErrorAction SilentlyContinue
    Remove-Item -Path ($SYSTEMLOAD + '*.idx') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path ($SYSTEMLOAD + 'ctreeint') -Recurse -Force -ErrorAction SilentlyContinue

    CleanUpd

    Copy-Item $PARAMS_FILE_ORIGIN $PARAMS_FILE

}

# Limpa os arquivos de atualização
function CleanUpd() {

    Remove-Item -Path ($SYSTEM + 'TOTVSP*.*') -ErrorAction SilentlyContinue

    Remove-Item -Path ($SYSTEMLOAD + '*df*.txt') -ErrorAction SilentlyContinue
    Remove-Item -Path ($RESULT_FILE) -ErrorAction SilentlyContinue
    Remove-Item -Path ($PARAMS_FILE) -ErrorAction SilentlyContinue
}


# Copiar os arquivos para o diretório SystemLoad
function CopyFiles($aCopyFiles) {

    foreach ($oFile in $aCopyFiles.Group) {
        Write-Host Copiando arquivo $oFile.BaseName de $oFile.DirectoryName.Replace($UPDPATH,'')
        Copy-Item $oFile -Destination $SYSTEMLOAD
    }

}


# Executa o Appserver
function ExecuteUpd() {
    Write-Host 'Executando UPDDISTR No Protheus'

    If ($Simulado) {
        Sleep 2
        '{ "result": "success" }' > $RESULT_FILE
    } Else {
        return (Start-Process -FilePath ($APPSERVER_EXE) -ArgumentList '-console' -PassThru)
    }
}
# Executa o Appserver via Invoke
function ExecuteUpdInvoke() {
    Write-Host 'Executando UPDDISTR No Protheus'
    Write-Host $SEPARATOR

    If ($Simulado) {
        Sleep 2
        '{ "result": "success" }' > $RESULT_FILE
    } Else {
        $UpdCommand = ("& " + $APPSERVER_EXE + " -run=UPDDISTR -env=" + $ENVIRONMENT)
        Invoke-Expression $UpdCommand
    }

    Write-Host $SEPARATOR

}

# Monitora o resultado
function WaitResult() {

    $Time = [System.Diagnostics.Stopwatch]::StartNew()

    # Aguarda Criação do Arquivo result.json
    while ( !( Test-Path ($RESULT_FILE) ) ) {
        Start-Sleep 1

        Write-Progress -Activity "Aguardando execução do UPDDISTR" -Status ("{0:HH:mm:ss}" -f ([datetime]$Time.Elapsed.Ticks))
    }

    if ( Test-Path ($RESULT_FILE) ) {
        Write-Host UPDDISTR Executado em ("{0:HH:mm:ss}" -f ([datetime]$Time.Elapsed.Ticks))
    }


}

# Derruba o serviço Protheus
function StopProtheus($oProc) {
    Write-Host 'Finalizando serviço Protheus'
    Stop-Process $oProc -ErrorAction SilentlyContinue
}


function GetResult {
    if ( Test-Path ($RESULT_FILE) ) {
        $oResult = Get-Content $RESULT_FILE | ConvertFrom-Json
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
    $cDestination = If ($lSuccess) { $UPDSUCCESS } Else { $UPDERROR }
    $cPathOrigin = $oUpdate.Name.ToUpper().Replace($UPDPATH.ToUpper(),'').Split('\')[0]
    $cPathToMove = $UPDPATH + $cPathOrigin
    $cPathResult = $cDestination + $cPathOrigin + "\result.json"

    Write-Host 'Movendo arquivos para ' $cDestination

    Write-Host Origem: $cPathToMove
    Write-Host ResultFile: $cPathResult

    Move-Item -Path $cPathToMove -Destination $cDestination -Force
    # -ErrorAction SilentlyContinue

    Copy-Item -Path $RESULT_FILE -Destination $cPathResult -Force
    # -ErrorAction SilentlyContinue

}



Start-Transcript -Path $LOGUPD # Inicia Gravação do Log

UpdateProtheus
#PrepareUpd

Stop-Transcript # Finaliza Gravação do Log