# QEMU Package Override

The `microvm.qemu.package` option allows you to override the QEMU derivation used for a specific MicroVM. This is useful when you need:

- A patched QEMU with custom devices (e.g., Jetson GPU passthrough)
- QEMU with specific build flags or features enabled
- A different QEMU version than what's in nixpkgs
- QEMU from an external flake input

## Usage

```nix
{
  microvm.qemu.package = pkgs.qemu_kvm_custom;
}
```

## Requirements

The provided package must contain a binary named `qemu-system-${arch}` where `${arch}` matches your target architecture (e.g., `qemu-system-x86_64`, `qemu-system-aarch64`).

## Example: Jetson GPU Passthrough

```nix
{
  microvm.vms.gpu = {
    enable = true;
    hypervisor = "qemu";
    qemu.package = inputs.jetson-qemu.packages.${pkgs.system}.qemu-tegra;
    
    config = {
      # VM configuration for GPU passthrough
    };
  };
}
```

## Example: Custom Build Flags

```nix
let
  customQemu = pkgs.qemu_kvm.override {
    smbdSupport = true;
    gtkSupport = true;
    # ... other overrides
  };
in {
  microvm.qemu.package = customQemu;
}
```

## Notes

- When `null` (default), microvm.nix automatically selects `pkgs.qemu_kvm` for KVM-accelerated VMs or `pkgs.qemu` for emulated VMs
- The option is per-VM, allowing different VMs to use different QEMU builds
- User-provided packages bypass microvm.nix's internal QEMU optimizations