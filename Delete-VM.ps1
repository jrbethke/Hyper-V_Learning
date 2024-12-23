<#
.SYNOPSIS
    Script to shutdown a running Virtual Machine, delete it from Hyper-V, and remove associated files from the disk.
.DESCRIPTION
    This script first checks if the specified Virtual Machine is running and shuts it down if necessary.
    It then deletes the VM from Hyper-V and removes all associated files from the disk.
.NOTES
    Author: Jesse Bethke
    Date: 2024-12-22
.PARAMETER VMName
    The name of the Virtual Machine to be deleted.
.PARAMETER VMPath
    The path where the Virtual Machine files are stored.
.EXAMPLE
    .\Delete-VM.ps1 -VMName 'MyVM' -VMPath 'D:\VMs\MyVM'
#>

param (
    [string]$VMName,   # Name of the Virtual Machine to be deleted
    [string]$VMPath    # Path where the Virtual Machine files are stored
)

Set-ExecutionPolicy RemoteSigned -Scope Process -Force

try {
    # Check if the VM exists
    $vm = Get-VM -Name $VMName -ErrorAction Stop

    # Check if the VM is running and shut it down if necessary
    if ($vm.State -eq 'Running') {
        Write-Output "Shutting down the running VM: $VMName"
        Stop-VM -Name $VMName -Force -ErrorAction Stop
    }

    # Remove the VM from Hyper-V
    Write-Output "Removing the VM: $VMName from Hyper-V"
    Remove-VM -Name $VMName -Force -ErrorAction Stop

    # Delete the VM files from the disk
    if (Test-Path -Path $VMPath) {
        Write-Output "Deleting VM files from: $VMPath"
        Remove-Item -Path $VMPath -Recurse -Force -ErrorAction Stop
    } else {
        Write-Warning "VM path does not exist: $VMPath"
    }

    Write-Output "The virtual machine $VMName has been successfully deleted."
} catch {
    Write-Error "An error occurred: $_"
}