Add-Type -assemblyName PresentationFramework, PresentationCore, WindowsBase, Microsoft.VisualBasic, System.Windows.Forms
$global:current_dir = [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath

#region sync hashtables
$global:uiHash = [hashtable]::Synchronized(@{ })
$global:runspaceHash = [hashtable]::Synchronized(@{ })
$global:jobs = [system.collections.arraylist]::Synchronized((New-Object System.Collections.ArrayList))
$global:jobCleanup = [hashtable]::Synchronized(@{ })
$global:UpdatesHash = [hashtable]::Synchronized(@{ })
$Global:updateAudit = [system.collections.arraylist]::Synchronized((New-Object System.Collections.ArrayList))
$Global:installAudit = [system.collections.arraylist]::Synchronized((New-Object System.Collections.ArrayList))
$Global:servicesAudit = [system.collections.arraylist]::Synchronized((New-Object System.Collections.ArrayList))
$Global:installedUpdates = [system.collections.arraylist]::Synchronized((New-Object System.Collections.ArrayList))
#endregion sync hashtables

#region xaml
[xml]$xaml = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        WindowStartupLocation="CenterScreen"
        Title="WinTool v2.0 | www.aamer.in" Height="700" Width="750" MinHeight="700" MinWidth="1024"
        Name='Muhammad' FontFamily='Calibri' FontSize='12' Background='white'>
        <Grid></Grid>
</Window>
"@
#endregion xaml

#region load xaml
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$uiHash.Window = [Windows.Markup.XamlReader]::Load($reader)
#endregion load xaml

#region Background runspace to clean up jobs
$jobCleanup.Flag = $True
$newRunspace = [runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA"
$newRunspace.ThreadOptions = "ReuseThread"
$newRunspace.Open()
$newRunspace.SessionStateProxy.SetVariable("uiHash", $uiHash)
$newRunspace.SessionStateProxy.SetVariable("jobCleanup", $jobCleanup)
$newRunspace.SessionStateProxy.SetVariable("jobs", $jobs)
$jobCleanup.PowerShell = [PowerShell]::Create().AddScript( {
        #Routine to handle completed runspaces
        Do {
            Foreach ($runspace in $jobs) {
                If ($runspace.Runspace.isCompleted) {
                    $runspace.powershell.EndInvoke($runspace.Runspace) | Out-Null
                    $runspace.powershell.dispose()
                    $runspace.Runspace = $null
                    $runspace.powershell = $null
                }
            }
            #Clean out unused runspace jobs
            $temphash = $jobs.clone()
            $temphash | Where-Object {
                $_.runspace -eq $Null
            } | ForEach-Object {
                Write-Verbose ("Removing {0}" -f $_.computer)
                $jobs.remove($_)
            }
            Start-Sleep -Seconds 1
        }
        while ($jobCleanup.Flag)
    })
$jobCleanup.PowerShell.Runspace = $newRunspace
$jobCleanup.Thread = $jobCleanup.PowerShell.BeginInvoke()
#endregion

$uiHash.Window.ShowDialog() | Out-Null