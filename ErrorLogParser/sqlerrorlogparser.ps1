$errorlogpath = "d:\temp\logs\errorlog\"
$server       = "."
$database     = "sample"

# create table for storing data
$sql_table = "DROP TABLE IF EXISTS [dbo].[ErrorLog]
GO
CREATE TABLE [dbo].[ErrorLog]
(
    [log_date] datetime2,
    [source] nvarchar(12),
    [message] nvarchar(max),
    INDEX DCI CLUSTERED ([log_date] DESC)
)
"

Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $sql_table

Get-ChildItem -Path $errorlogpath  -Filter *ERRORLOG* | Foreach-Object {
      Write-Host "Processing file:" $_.FullName -ForegroundColor Cyan
     

$table        = New-Object System.Data.DataTable "errorlog"
$col_logdate  = New-Object System.Data.DataColumn logdate,([DateTime])
$col_source   = New-Object System.Data.DataColumn source, ([string])
$col_message  = New-Object System.Data.DataColumn message,([string])
$rowctr       = 1

$table.columns.add($col_logdate)
$table.columns.add($col_source)
$table.columns.add($col_message)


Get-Content -Path $_.FullName  | ForEach-Object {

    if ($_.Length -gt 22)
        {
            if ($_.Substring(0,22) -as [DateTime])
            {                
                if ($rowctr -gt 1) {$table.Rows.Add($row)}
                
                $row         = $table.NewRow()
                $row.logdate = $_.Substring(0,22) #logdate
                $row.source  = $_.Substring(23,12) #source
                $row.message = $_.Substring(35,$_.Length-35) #message
            }
            else
            {
                $row.message += $_ #message
            }
        }
    else
    {
        $row.message += $_ #message
    }

    $rowctr += 1
}
    Write-SqlTableData -ServerInstance $server -DatabaseName $database -SchemaName "dbo" -TableName "ErrorLog" -InputData $table
}