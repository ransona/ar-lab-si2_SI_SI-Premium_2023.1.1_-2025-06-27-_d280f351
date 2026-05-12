$DeviceName = 'Vidrio Technologies vDAQ';
$pnp = Get-WmiObject -Query "select * from Win32_PNPEntity where Name='$DeviceName'";

$pnp | ForEach-Object {
    New-Object PSObject -Property @{
        "Name" = $_.Name;
        "DeviceID" = $_.DeviceID;
        "PCIeCurrentLink" = ($_.GetDeviceProperties('DEVPKEY_PciDevice_CurrentLinkSpeed').deviceProperties[0].Data).ToString();
        "PCIeCurrentWidth" = ($_.GetDeviceProperties('DEVPKEY_PciDevice_CurrentLinkWidth').deviceProperties[0].Data).ToString();
        "PCIeMaxLink" =  ($_.GetDeviceProperties('DEVPKEY_PciDevice_MaxLinkSpeed').deviceProperties[0].Data).ToString();
        "PCIeMaxWidth" = ($_.GetDeviceProperties('DEVPKEY_PciDevice_MaxLinkWidth').deviceProperties[0].Data).ToString();
    }
} | Select-Object 'Name','DeviceID','PCIeCurrentLink','PCIeCurrentWidth','PCIeMaxLink','PCIeMaxWidth'