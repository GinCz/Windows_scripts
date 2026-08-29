function Invoke-WPFTab {

    <#

    .SYNOPSIS
        Sets the selected tab to the tab that was clicked

    .PARAMETER ClickedTab
        The name of the tab that was clicked

    #>

    Param (
        [Parameter(Mandatory,position=0)]
        [string]$ClickedTab
    )

    $tabNav = Get-WinUtilVariables | Where-Object {$psitem -like "WPFTabNav"}
    $tabNumber = [int]($ClickedTab -replace "WPFTab","" -replace "BT","") - 1

    $filter = Get-WinUtilVariables -Type ToggleButton | Where-Object {$psitem -like "WPFTab?BT"}
    $sync.$tabNav.Items[$tabNumber].IsSelected = $true
    ($sync.GetEnumerator()).where{$psitem.Key -in $filter} | ForEach-Object {
        if ($ClickedTab -ne $PSItem.name) {
            $sync[$PSItem.Name].IsChecked = $false
        } else {
            $sync["$ClickedTab"].IsChecked = $true
        }
    }
    $sync.currentTab = $sync.$tabNav.Items[$tabNumber].Header
    Initialize-WinUtilTabContent -TabName $sync.currentTab

    # Always reset the filter for the current tab
    if ($sync.currentTab -eq "Install") {
        # Reset the search text, but keep the categories the chips are still showing as selected
        $selectedCategories = if ($sync.SelectedAppCategories) { $sync.SelectedAppCategories.ToArray() } else { @() }
        Find-AppsByNameOrDescription -SearchString "" -Categories $selectedCategories
    } elseif ($sync.currentTab -eq "Tweaks") {
        # Reset Tweaks tab filter
        Find-TweaksByNameOrDescription -SearchString ""
    } elseif ($sync.currentTab -eq "AppX") {
        # Reset AppX tab filter
        Find-TweaksByNameOrDescription -SearchString ""
    } elseif ($sync.currentTab -eq "Defender") {
        try {
            $disabled = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue).DisableAntiSpyware -eq 1
            if ($disabled) {
                if ($sync.WPFDefenderStatusText) {
                    $sync.WPFDefenderStatusText.Text = "Status: Defender is DISABLED [OFF]"
                    $sync.WPFDefenderStatusText.Foreground = [System.Windows.Media.Brushes]::OrangeRed
                }
                if ($sync.WPFDisableDefender) {
                    $sync.WPFDisableDefender.BorderBrush = [System.Windows.Media.Brushes]::Black
                    $sync.WPFDisableDefender.BorderThickness = New-Object Windows.Thickness(3)
                }
                if ($sync.WPFEnableDefender) {
                    $sync.WPFEnableDefender.BorderThickness = New-Object Windows.Thickness(1)
                }
            } else {
                if ($sync.WPFDefenderStatusText) {
                    $sync.WPFDefenderStatusText.Text = "Status: Defender is ENABLED [ON]"
                    $sync.WPFDefenderStatusText.Foreground = [System.Windows.Media.Brushes]::LightGreen
                }
                if ($sync.WPFEnableDefender) {
                    $sync.WPFEnableDefender.BorderBrush = [System.Windows.Media.Brushes]::Black
                    $sync.WPFEnableDefender.BorderThickness = New-Object Windows.Thickness(3)
                }
                if ($sync.WPFDisableDefender) {
                    $sync.WPFDisableDefender.BorderThickness = New-Object Windows.Thickness(1)
                }
            }
        } catch {}
    }

    # Show search bar in Install, Tweaks, and AppX tabs
    if ($tabNumber -eq 0 -or $tabNumber -eq 1 -or $tabNumber -eq 5) {
        $sync.SearchBar.Visibility = "Visible"
        $searchIcon = ($sync.Form.FindName("SearchBar").Parent.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] -and $_.Text -eq [char]0xE721 })[0]
        if ($searchIcon) {
            $searchIcon.Visibility = "Visible"
        }
    } else {
        $sync.SearchBar.Visibility = "Collapsed"
        $searchIcon = ($sync.Form.FindName("SearchBar").Parent.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] -and $_.Text -eq [char]0xE721 })[0]
        if ($searchIcon) {
            $searchIcon.Visibility = "Collapsed"
        }
        # Hide the clear button if it's visible
        $sync.SearchBarClearButton.Visibility = "Collapsed"
    }
}
