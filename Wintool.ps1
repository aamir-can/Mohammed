[cmdletbinding()]
param()
BEGIN {
    Add-Type -assemblyName PresentationFramework, PresentationCore, WindowsBase, Microsoft.VisualBasic, System.Windows.Forms
    Import-Module AWSPowerShell -DisableNameChecking | Out-Null
}
PROCESS {

    #region  create hashtables
    $uiHash = [hashtable]::Synchronized(@{ })
    $runspaceHash = [hashtable]::Synchronized(@{ })
    $jobs = [system.collections.arraylist]::Synchronized((New-Object System.Collections.ArrayList))
    $jobCleanup = [hashtable]::Synchronized(@{ })
    $UpdatesHash = [hashtable]::Synchronized(@{ })
    #endregion  create hashtables

    #region build GUI
    [xml]$xaml = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        WindowStartupLocation="CenterScreen"
        Title="WinTool v2.0 | www.aamer.in" Height="700" Width="750" MinHeight="700" MinWidth="1024"
		Name='Muhammad' FontFamily='Calibri' FontSize='12' Background='white'>

    <Window.Resources>
        <Style x:Key="MyButton" TargetType="Button">
            <Setter Property="OverridesDefaultStyle" Value="False" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="border" BorderThickness="0" BorderBrush="Black" Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Opacity" Value="0.8" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ListViewItem">
            <Setter Property="HorizontalContentAlignment" Value="Stretch" />
        </Style>

    </Window.Resources>
    <Grid>
        <Grid.Resources>
            <Style x:Key="AlternatingRowStyle" TargetType="{x:Type Control}" >
                <Setter Property="Background" Value="LightGray"/>
                <Setter Property="Foreground" Value="Black"/>
                <Style.Triggers>
                    <Trigger Property="ItemsControl.AlternationIndex" Value="1">
                        <Setter Property="Background" Value="White"/>
                        <Setter Property="Foreground" Value="Black"/>
                    </Trigger>
                </Style.Triggers>
            </Style>
        </Grid.Resources>

        <RichTextBox Name='RichTextboxStatus' Margin="10,0,10,46.519" BorderThickness="0,0,0,1" Background="Transparent" Height="182.14" VerticalAlignment="Bottom" AcceptsReturn="False" IsReadOnly="True" VerticalScrollBarVisibility="Auto" FontFamily="Calibri" FontSize='13' Cursor="Arrow" ToolTip="Select and click Ctrl + Alt + C to clear the logs.."/>

		<ProgressBar Name='ProgressBar' Height="32" BorderThickness="0" VerticalAlignment="Bottom" Margin="10,0,10,10" Minimum="0" Maximum="100" Value="0">
            <ProgressBar.Foreground>
                <LinearGradientBrush EndPoint="0, 0.5" StartPoint="1, 0.5">
                    <GradientStop Color="{Binding ProgressColor, Mode=OneWay}" Offset="0"/>
                    <GradientStop Color="Crimson" Offset="0"/>
                    <GradientStop Color="Orange" Offset="1"/>
                </LinearGradientBrush>
            </ProgressBar.Foreground>
        </ProgressBar>

        <TextBlock Name='Percentage' HorizontalAlignment="Stretch" TextAlignment="Center" VerticalAlignment="Bottom" Margin="10,0,10,10" Height="32" Foreground='white' FontStyle="Normal" Padding="0,9,0,0" FontFamily="Lucida Sans" FontSize="10">
            <TextBlock.Text>
                <MultiBinding StringFormat="{}{0} / {1} ">
                    <Binding ElementName="ProgressBar" Path="Value"/>
                    <Binding ElementName="ProgressBar" Path="Maximum"/>
                </MultiBinding>
            </TextBlock.Text>
        </TextBlock>

        <Grid Margin="0,130,0,0" >
            <Grid.Resources>
                <Style x:Key="AlternatingRowStyle" TargetType="{x:Type ListViewItem}">
                    <Style.Triggers>
                        <Trigger Property="ItemsControl.AlternationIndex" Value="0">
                            <Setter Property="Foreground" Value="Black"></Setter>
                            <Setter Property="Background" Value="#FCF3CF"></Setter>
                            <Setter Property="BorderThickness" Value="0" />
                            <Setter Property="Padding" Value="0" />
                            <Setter Property="VerticalContentAlignment" Value="Center" />
                            <Setter Property="HorizontalContentAlignment" Value="Stretch" />
                            <Setter Property="VerticalContentAlignment" Value="Center" />
                            <Setter Property="Height" Value="22px" />
                        </Trigger>

                        <Trigger Property="ItemsControl.AlternationIndex" Value="1">
                            <Setter Property="Foreground" Value="black"></Setter>
                            <Setter Property="Background" Value="white"></Setter>
                            <Setter Property="BorderThickness" Value="0" />
                            <Setter Property="Padding" Value="0" />
                            <Setter Property="VerticalContentAlignment" Value="Center" />
                            <Setter Property="HorizontalContentAlignment" Value="Stretch" />
                            <Setter Property="VerticalContentAlignment" Value="Center" />
                            <Setter Property="Height" Value="22px" />
                        </Trigger>

                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="BorderBrush" Value="#F7F79B" />
                            <Setter Property="Background" Value="#F7F79B" />
                            <Setter Property="Foreground" Value="Black" />
                        </Trigger>

                        <Trigger Property="IsSelected" Value="True">
                            <Setter Property="Background" Value="#BFC9CA"/>
                            <Setter Property="Foreground" Value="Black"/>
                        </Trigger>

                    </Style.Triggers>
                </Style>

                <Style x:Key="GridViewColumnHeaderStyle1" TargetType="{x:Type GridViewColumnHeader}">
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="{x:Type GridViewColumnHeader}">
                                <Border BorderThickness="0" BorderBrush="Red" Background="Black" >
                                    <TextBlock x:Name="ContentHeader" Text="{TemplateBinding Content}" Padding="10,10,10,10" Width="{TemplateBinding Width}" TextAlignment="Left" Foreground='white' />
                                </Border>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                    <Setter Property="OverridesDefaultStyle" Value="False" />
                    <Setter Property="Foreground" Value="White" />
                    <Setter Property="FontFamily" Value="Calibri" />
                    <Setter Property="FontSize" Value="14" />
                </Style>

            </Grid.Resources>

            <ListView Name='ListView' BorderBrush="#FFA8CC7B" BorderThickness="0,0,0,1" Margin="10,0,9.6,232.111" AllowDrop = 'True' ItemContainerStyle="{StaticResource AlternatingRowStyle}" ScrollViewer.HorizontalScrollBarVisibility="Disabled" ToolTip="Double Click to add Servers list" AlternationCount="2" >

                <ListView.View>
                    <GridView x:Name = 'GridView' AllowsColumnReorder = 'True' ColumnHeaderContainerStyle="{StaticResource GridViewColumnHeaderStyle1}" >
                        <GridViewColumn x:Name = 'ComputerColumn' Width="250" DisplayMemberBinding = '{Binding Path = Computer}' Header='Servername' />
                        <GridViewColumn x:Name = 'OSColumn' Width="295" DisplayMemberBinding = '{Binding Path = OS}' Header='Operating System' />
                        <GridViewColumn x:Name = 'UpdateColumn' Width="369" DisplayMemberBinding = '{Binding Path = Updates}' Header='Updates' />
                        <GridViewColumn x:Name = 'NotesColumn' Width="250" DisplayMemberBinding = '{Binding Path = Notes}' Header='Notes' />
                    </GridView>
                </ListView.View>

                <ListView.ContextMenu>
                    <ContextMenu x:Name = 'ListViewContextMenu'>
                        <MenuItem x:Name = 'AddServerMenu' Header = 'Add Server' InputGestureText ='Ctrl+S'>
                            <MenuItem.Icon>
                                <Image Name='ContextMenuAddServer' />
                            </MenuItem.Icon>
                        </MenuItem>
                        <MenuItem x:Name = 'RemoveServerMenu' Header = 'Remove Server' InputGestureText ='Ctrl+D'>
                            <MenuItem.Icon>
                                <Image Name='ContextMenuRemoveServer' />
                            </MenuItem.Icon>
                        </MenuItem>

                        <Separator />

                        <MenuItem x:Name = 'ContextMenuPingServer' Header = 'Check Server Access' InputGestureText ='Ctrl+P'>
                            <MenuItem.Icon>
                                <Image Name='ContextMenuPingServerImage' />
                            </MenuItem.Icon>
                        </MenuItem>

                        <MenuItem x:Name = 'RemoveOFFLINEServerMenu' Header = 'Remove OFFLINE' InputGestureText ='Ctrl+M'>
                            <MenuItem.Icon>
                                <Image Name='ContextMenuRemoveOFFLINEServer' />
                            </MenuItem.Icon>
                        </MenuItem>

                        <Separator />
                        <MenuItem x:Name = 'PowerShellMenu' Header = 'PowerShell' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuPowerShell' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'TestPSRemotingMenu' Header = 'Test-PSRemoting' />
                            <MenuItem x:Name = 'EnablePSRemotingMenu' Header = 'Enable-PSRemoting' />
                            <MenuItem x:Name = 'DisablePSRemotingMenu' Header = 'Disable-PSRemoting' />
                            <MenuItem x:Name = 'SetExecPolRestrictedMenu' Header = 'Set-ExecutionPolicy Restricted' />
                            <MenuItem x:Name = 'SetExecPolUnRestrictedMenu' Header = 'Set-ExecutionPolicy Unrestricted' />
                            <MenuItem x:Name = 'SetExecPolAllSignedMenu' Header = 'Set-ExecutionPolicy AllSigned' />
                            <MenuItem x:Name = 'SetExecPolRemoteSignedMenu' Header = 'Set-ExecutionPolicy RemoteSigned' />
                            <MenuItem x:Name = 'SetExecPolByPassMenu' Header = 'Set-ExecutionPolicy ByPass' />
							<MenuItem x:Name = 'GetPSSession' Header = 'Get-PSSession' />
							<MenuItem x:Name = 'RemoveClosedSessions' Header = 'Remove Disconnected Sessions' />
                        </MenuItem>
                        <MenuItem x:Name = 'AutoServicesMenu' Header = 'Auto Services' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuAutoSvc' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'CheckAutoServicesMenu' Header = 'Check Auto Services' />
                            <MenuItem x:Name = 'StartAutoServicesMenu' Header = 'Start Auto Services' />
                        </MenuItem>
                        <MenuItem x:Name = 'ADDSServiceMenu' Header = 'Active Directory Services' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuADService' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'ADDSInventory' Header = 'AD Inventory' />
                            <MenuItem x:Name = 'ADDSHealthChecks' Header = 'AD Health Check' />
                            <MenuItem x:Name = 'ADDSServiceRestart' Header = 'Restart AD Service' />
                        </MenuItem>
                        <MenuItem x:Name = 'DNSDHCPServerMenu' Header = 'DNS DHCP Services' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuDNSService' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'DHCPReport' Header = 'Get-DHCPScope' />
                        </MenuItem>
                        <Separator />
                        <MenuItem x:Name = 'WindowsUpdateServiceMenu' Header = 'Windows Update Service' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuWUSVC' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'WUStopServiceMenu' Header = 'Stop WindowsUpdate Service' />
                            <MenuItem x:Name = 'WUStartServiceMenu' Header = 'Start WindowsUpdate Service' />
                            <MenuItem x:Name = 'WURestartServiceMenu' Header = 'Restart WindowsUpdate Service' />
                        </MenuItem>
                        <MenuItem x:Name = 'BITSServiceMenu' Header = 'BITS Service' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuBITSSVC' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'BITSStopServiceMenu' Header = 'Stop Service' />
                            <MenuItem x:Name = 'BITSStartServiceMenu' Header = 'Start Service' />
                            <MenuItem x:Name = 'BITSRestartServiceMenu' Header = 'Restart Service' />
                        </MenuItem>
                        <MenuItem x:Name = 'ContextMenuWSUSActions' Header = 'WSUS Actions' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuWSUSActionsLogo' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'wsusauditpatches' Header = 'Audit Patches' ToolTip="Scans for available patches and generate report"/>
                            <MenuItem x:Name = 'wsusdownloadpatches' Header = 'Download Patches' ToolTip="Downloads available patches in the server"/>
                            <MenuItem x:Name = 'wsusinstallpatches' Header = 'Install Patches' ToolTip="Scan, Download and Installs available patches in the server. Reboot is suppressed. "/>
                            <MenuItem x:Name = 'DetectNowMenu' Header = 'Run Detect Now' ToolTip="Executes detectnow command against the server to fix the issue if server unable to find published patches."/>
                            <MenuItem x:Name = 'ResetAuthorizationMenu' Header = 'Run Reset Authorization' ToolTip="Resets the authorization with WSUS server"/>
                            <MenuItem x:Name = 'FixAUMenu' Header = 'Run Clean Scan' ToolTip="Performs Microsoft recommanded steps to fix the issues like server could not detect the patches etc.."/>
                            <MenuItem x:Name = 'WindowsUpdateLogMenu' Header = 'Update Log' >
                                <MenuItem x:Name = 'EntireLogMenu' Header = 'View Entire Log'/>
                                <MenuItem x:Name = 'Last25LogMenu' Header = 'View Last 25' />
                                <MenuItem x:Name = 'Last50LogMenu' Header = 'View Last 50'/>
                                <MenuItem x:Name = 'Last100LogMenu' Header = 'View Last 100'/>
                            </MenuItem>
                            <MenuItem x:Name = 'InstalledUpdatesMenu' Header = 'Installed Updates' >
                                <MenuItem x:Name = 'GUIInstalledUpdatesMenu' Header = 'Get Installed Updates'/>
                            </MenuItem>
                        </MenuItem>
                        <Separator />
                        <MenuItem x:Name = 'ContextMenuACF' Header = 'ACF' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuACFLogo' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'ContextMenuACFMenuInfo' Header = 'Collect ACF Info' />
                        </MenuItem>
                        <MenuItem x:Name = 'OVOMenu' Header = 'HP OVO Agent' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuOVO' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'OpcagtStatus' Header = 'Opcagt -Status' />
							<MenuItem x:Name = 'OpcagtStop' Header = 'Opcagt -Stop' />
							<MenuItem x:Name = 'OpcagtStart' Header = 'Opcagt -Start' />
							<MenuItem x:Name = 'OpcagtRestart' Header = 'Opcagt -restart' />
                            <MenuItem x:Name = 'OpcagtCleanStart' Header = 'Opcagt -Cleanstart' />
                            <MenuItem x:Name = 'OpcagtKill' Header = 'Opcagt -Kill' />
							<MenuItem x:Name = 'OpcagtVersions' Header = 'Opcagt -list_all_versions' />
                        </MenuItem>
                        <MenuItem x:Name = 'OpswareMenu' Header = 'Opsware Agent' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuOpsware' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'CheckOpswareServiceStatus' Header = 'Check Opsware Status' />
                            <MenuItem x:Name = 'StartOpswareServiceMenu' Header = 'Start Opsware Service' />
                            <MenuItem x:Name = 'StopOpswareServiceMenu' Header = 'Stop Opsware Service' />
                            <MenuItem x:Name = 'ReStartOpswareServiceMenu' Header = 'Restart Opsware Service' />
                            <MenuItem x:Name = 'CheckMIDOpswareServiceMenu' Header = 'List MID' />
                            <MenuItem x:Name = 'ReadOpswareGWMenu' Header = 'List Opsware Gateways' />
                            <MenuItem x:Name = 'UpdateOpswareGWMenu' Header = 'Update Opsware Gateways' />
                            <MenuItem x:Name = 'RunBSHardwareOpswareServiceMenu' Header = 'Run BS_Hardware' />
                            <MenuItem x:Name = 'RunBSSoftwareOpswareServiceMenu' Header = "Run BS_Software" />
                            <MenuItem x:Name = 'UninstallOpswareServiceMenu' Header = 'Uninstall Opsware Agent' />
                        </MenuItem>
                        <MenuItem x:Name = 'ContextMenuTSM' Header = 'TSM Backup Agent' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuTSMLogo' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'ContextMenuTSMMenuInfo' Header = 'Collect TSM Info' />
                        </MenuItem>
                        <MenuItem x:Name = 'ClusterServerMenu' Header = 'Microsoft Cluster Services' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuCluster' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'ClusterInfoMenu1' Header = 'Stop Service' />
                            <MenuItem x:Name = 'ClusterInfoMenu2' Header = 'Start Service' />
                            <MenuItem x:Name = 'ClusterInfoMenu3' Header = 'Restart Service' />
                        </MenuItem>
                        <Separator />
                        <MenuItem x:Name = 'VMwareServerMenu' Header = 'VMWare' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuVMware' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'VMwareServerMenu1' Header = 'Stop Service' />
                            <MenuItem x:Name = 'VMwareServerMenu2' Header = 'Start Service' />
                            <MenuItem x:Name = 'VMwareServerMenu3' Header = 'Restart Service' />
                        </MenuItem>
                        <MenuItem x:Name = 'MicrosoftToolsMenu' Header = 'Tools and Utilities' >
                            <MenuItem.Icon>
                                <Image Name='ContextMenuTools' />
                            </MenuItem.Icon>
                            <MenuItem x:Name = 'RoboCopy' Header = 'Copy Files' />
                            <MenuItem x:Name = 'ConnectRDP' Header = 'Connect-RDP' />
                            <MenuItem x:Name = 'ScheduledTasks' Header = 'ScheduledTasks' />
                            <MenuItem x:Name = 'HealthChecks' Header = 'Health Checks' />
                            <MenuItem x:Name = 'CheckFirewall' Header = 'Check Firewall' />
                            <MenuItem x:Name = 'TestCreds' Header = 'Validate Credentials' />
							<MenuItem x:Name = 'TestPorts' Header = 'Test Ports' />
                            <MenuItem x:Name = 'vssadminlistwriters' Header = 'VSS List Writers' />
							<MenuItem x:Name = 'TimeZoneInfo' Header = 'Check DST Info' />
							<MenuItem x:Name = 'InstallDSTPatch' Header = 'Install Hotfix/Patch' />
							<MenuItem x:Name = 'VerifyPatch' Header = 'Find Patch/Hotfix Status' />
							<MenuItem x:Name = 'UninstallSoftware' Header = 'Uninstall Software' />
							<MenuItem x:Name = 'localaccounts' Header = 'Get-Local-Users' />
							<MenuItem x:Name = 'localGroups' Header = 'Get-Local-Groups' />
                        </MenuItem>
						<Separator />
						<MenuItem x:Name = 'Chocolatey' Header = 'Install Choco' />
						<MenuItem x:Name = 'InstallMyPatches' Header = 'Install MyPatches' />
                        <MenuItem x:Name = 'Export' Header = 'Export' InputGestureText ='Ctrl+E' />
                    </ContextMenu>
                </ListView.ContextMenu>
            </ListView>
        </Grid>
        <GroupBox x:Name="Tasks" Height="124" Margin="10,1,9.6,0" VerticalAlignment="Top" FontFamily="Calibri Light" >
            <GroupBox.Header >
                <TextBlock Text="mohammed.ameer@hp.com" Foreground="Gray" FontWeight="Bold" />
            </GroupBox.Header>
            <Grid HorizontalAlignment="Stretch" Margin="0" >
                <Image Name="AppLogo" Width="151" HorizontalAlignment="Left" Margin="10,0,0,0" Source="$Path\Logo.png" />
                <RadioButton Name='RadioPingCheck' Content="_Ping Check" HorizontalAlignment="Left" Margin="186,16,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioTestPSRemoting' Content="_Test PS-Remoting" HorizontalAlignment="Left" Margin="186,36,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioEnablePSRemoting' Content="_Enable PS-Remoting" HorizontalAlignment="Left" Margin="186,56,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioDisablePSRemoting' Content="_Disable PS-Remoting" HorizontalAlignment="Left" Margin="186,76,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioCopyPatches' Content="_Bulk Copy" HorizontalAlignment="Left" Margin="324,16,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioInstallPatches' Content="_Install Patches" HorizontalAlignment="Left" Margin="324,36,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioCheckPendingReboot' Content="C_heck Pending Reboot" HorizontalAlignment="Left" Margin="324,56,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioHBAwin' Content="Get-HBA Report" HorizontalAlignment="Left" Margin="615,56,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioInstallWSUSPatches' Content="Install _WSUS Patches" HorizontalAlignment="Left" Margin="463,56,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioInstalledUpdatesReport' Content="Insta_lled Updates Report" HorizontalAlignment="Left" Margin="463,76,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioServicesReport' Content="Services Rep_ort" HorizontalAlignment="Left" Margin="615,76,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioRestartServers' Content="Restart Ser_vers" HorizontalAlignment="Left" Margin="324,76,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioDownloadPatches' Content="Download WSUS Patches" HorizontalAlignment="Left" Margin="463,36,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioAuditPatches' Content="Audit WSU_S Patches" HorizontalAlignment="Left" Margin="463,16,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioVMwareToolsVersion' Content="VMwa_re Tools Version" HorizontalAlignment="Left" Margin="736,16,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioDiskSpaceInfo' Content="DiskS_pace HTML" HorizontalAlignment="Left" Margin="615,16,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioUpTimeReport' Content="Up_time HTML" HorizontalAlignment="Left" Margin="615,36,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioAvailabilityReport' Content="Ava_ilability Report" HorizontalAlignment="Left" Margin="736,36,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioInstalledSoftwares' Content="Instal_led S/W Report" HorizontalAlignment="Left" Margin="736,56,0,0" VerticalAlignment="Top" Height="15"/>
                <RadioButton Name='RadioServerInventory' Content="Server Invent_ory" HorizontalAlignment="Left" Margin="736,76,0,0" VerticalAlignment="Top" Height="15"/>
                <Button Name="RunButton" Style="{StaticResource MyButton}" HorizontalAlignment="Right" Visibility="Visible" Width="90" Height="90" IsEnabled="True" Padding="0,0,0,0" BorderThickness="0" Margin="0,0,5,0">
                    <Button.Background>
                        <ImageBrush />
                    </Button.Background>
                </Button>
                <Button Name="CancelButton" Style="{StaticResource MyButton}" HorizontalAlignment="Right" Visibility="Hidden" Width="90" Height="90" IsEnabled="True" Padding="0,0,0,0" BorderThickness="0" Margin="0,0,5,0">
                    <Button.Background>
                        <ImageBrush />
                    </Button.Background>
                </Button>
            </Grid>
        </GroupBox>
    </Grid>
</Window>

"@

    #endregion build gui

    #region load XAML
    try {
        $reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $uiHash.Window = [Windows.Markup.XamlReader]::Load($reader)
    }
    catch [exception] { $_.exception.message }
    #endregion load XAML

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

    #region event handler
    $uiHash.window.add_sourceinitialized( {
        })

    $uiHash.window.add_closed( {
            $jobCleanup.Flag = $false
            $jobCleanup.PowerShell.Dispose()
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
        })
    #endregion event handler

    #region invoke the script
    $uiHash.Window.ShowDialog() | Out-Null
    #endregion invoke the script

}
END {}