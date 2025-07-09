# Example: Using a custom QEMU package with microvm.nix
#
# This example demonstrates how to use the new microvm.qemu.package option
# to provide a custom QEMU derivation for a specific MicroVM.

{ pkgs, lib, ... }:

let
  # Example: Create a patched QEMU with custom features
  # In real usage, this might be a QEMU with GPU passthrough patches,
  # custom devices, or other modifications
  customQemu = pkgs.qemu_kvm.overrideAttrs (oldAttrs: {
    pname = "qemu-custom";
    # Add custom patches or build flags here
    postPatch = (oldAttrs.postPatch or "") + ''
      echo "This is a custom QEMU build" > CUSTOM_BUILD
    '';
  });
in
{
  # Example MicroVM configuration using custom QEMU
  microvm.vms.custom = {
    enable = true;
    
    # Specify the hypervisor
    hypervisor = "qemu";
    
    # Use our custom QEMU package
    qemu.package = customQemu;
    
    # Rest of the VM configuration
    mem = 1024;
    vcpu = 2;
    
    config = {
      networking.hostName = "custom-qemu-vm";
      system.stateVersion = "24.05";
      
      # Your VM configuration here
      services.getty.autologinUser = "root";
    };
  };
  
  # Alternative: Use a QEMU from another flake input
  # microvm.vms.jetson = {
  #   enable = true;
  #   hypervisor = "qemu";
  #   qemu.package = inputs.jetson-qemu.packages.${pkgs.system}.qemu-tegra;
  #   # ... rest of config
  # };
}