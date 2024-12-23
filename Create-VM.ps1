<#
.SYNOPSIS
    Script to create and configure a new Virtual Machine with a unique name.
.DESCRIPTION
    This script creates a new Virtual Machine, ensuring the VM name is unique.
    It sets up the VM with specified memory, generation, VHD path, and switch.
    Additionally, it configures the VM to boot from a specified installation media.
.NOTES
    Author: Jesse Bethke
    Date: 2024-12-22
.PARAMETER VMName
    The name of the Virtual Machine. Default is 'NewVM'.
.PARAMETER Switch
    The name of the Virtual Switch. Default is 'Default Switch'.
.PARAMETER BasePath
    The base path for ISOs. Default is 'D:\ISOs'.
.PARAMETER InstallMedia
    The path to the installation media ISO. Default is 'D:\ISOs\Win_server_2022_2108.16_64Bit.iso'.
.PARAMETER VHDSizeBytes
    The size of the Virtual Hard Disk in bytes. Default is 107374182400 (100 GB).
.PARAMETER MemoryStartupBytes
    The amount of startup memory for the Virtual Machine in bytes. Default is 4294967296 (4 GB).
.EXAMPLE
    .\Create-VM.ps1 -VMName 'MyVM' -Switch 'MySwitch' -BasePath 'E:\ISOs' -InstallMedia 'E:\ISOs\Windows.iso' -VHDSizeBytes 214748364800 -MemoryStartupBytes 8589934592
#>

param (
    [string]$VMName = 'NewVM',                # Default Name of the Virtual Machine
    [string]$Switch = 'Default Switch',       # Default Switch Name
    [string]$BasePath = 'D:\ISOs',            # Base path for ISOs
    [string]$InstallMedia = "$BasePath\Win_server_2022_2108.16_64Bit.iso", # Default ISO to use
    [long]$VHDSizeBytes = 107374182400,       # Default VHD size set to 100 GB
    [long]$MemoryStartupBytes = 4294967296    # Default Memory set to 4 GB
)

Set-ExecutionPolicy RemoteSigned -Scope Process -Force

# Create a new Virtual Machine with a unique name if the name already exists
$originalVMName = $VMName
$counter = 1
do {
    $VMName = if ($counter -eq 1) { $originalVMName } else { "$originalVMName$counter" }
    $counter++
} while (Get-VM -Name $VMName -ErrorAction SilentlyContinue)

try {
    # Create the new Virtual Machine
    New-VM -Name $VMName `
           -MemoryStartupBytes $MemoryStartupBytes `
           -Generation 2 `
           -NewVHDPath "D:\VMs\$VMName\$VMName.vhdx" `
           -NewVHDSizeBytes $VHDSizeBytes `
           -SwitchName $Switch

    # Add SCSI Controller
    Add-VMScsiController -VMName $VMName

    # Add DVD Drive to the Virtual Machine
    Add-VMDvdDrive -VMName $VMName `
                   -ControllerNumber 1 `
                   -ControllerLocation 0 `
                   -Path $InstallMedia

    # Configure the Virtual Machine to boot from DVD
    $DVDDrive = Get-VMDvdDrive -VMName $VMName

    # Set the firmware to boot from DVD
    Set-VMFirmware -VMName $VMName `
                   -FirstBootDevice $DVDDrive

    Set-VMProcessor -VMName $VMName -Count 2 # Set the number of processors to 2

    Write-Output "The virtual machine $VMName has been successfully created."
} catch {
    Write-Error "An error occurred: $_"
    # Attempt to remove the VM if it was partially created
    if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
        Remove-VM -Name $VMName -Force -ErrorAction SilentlyContinue
        Write-Output "The virtual machine $VMName has been removed due to an error."
    }
}