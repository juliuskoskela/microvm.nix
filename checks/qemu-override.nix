{ self, nixpkgs, system, makeTestConfigs }:

let
  pkgs = nixpkgs.legacyPackages.${system};
  lib = nixpkgs.lib;

  # Create a dummy QEMU package that just logs the execution
  dummyQemu = pkgs.writeShellScriptBin "qemu-system-${builtins.head (builtins.split "-" system)}" ''
    echo "DUMMY QEMU EXECUTED WITH ARGS: $@" >&2
    echo "This is the custom QEMU package test"
    # Exit after showing we were called
    exit 0
  '';

  configs = makeTestConfigs {
    name = "qemu-override";
    inherit system;
    modules = [
      ({ config, lib, ... }: {
        networking = {
          hostName = "microvm-qemu-override-test";
          useDHCP = false;
        };
        microvm = {
          # Only set qemu.package when hypervisor is qemu
          qemu.package = lib.mkIf (config.microvm.hypervisor == "qemu") dummyQemu;
          # Minimal config to keep test fast
          mem = 256;
          vcpu = 1;
          # Only enable test for qemu hypervisor
          testing.enableTest = config.microvm.hypervisor == "qemu";
        };
        system.stateVersion = lib.mkDefault lib.trivial.release;
      })
    ];
  };

in
# Return tests only for qemu configs
lib.filterAttrs (_: v: v != null) (
  builtins.mapAttrs (_: nixos:
  if nixos.config.microvm.hypervisor == "qemu" then
    pkgs.runCommandLocal "microvm-test-qemu-override" {
    nativeBuildInputs = [
      nixos.config.microvm.declaredRunner
    ];
    requiredSystemFeatures = [ "kvm" ];
    meta.timeout = 60;
  } ''
    # Check that our custom QEMU binary is in the runner
    if ! ${pkgs.gnugrep}/bin/grep -q "${dummyQemu}/bin/qemu-system-" ${nixos.config.microvm.declaredRunner}/bin/microvm-run; then
      echo "ERROR: Custom QEMU package not found in runner script"
      exit 1
    fi

    # Try to run and capture the output
    set +e
    ${nixos.config.microvm.declaredRunner}/bin/microvm-run 2>&1 | tee output.log
    
    # Check that our dummy QEMU was actually called
    if ${pkgs.gnugrep}/bin/grep -q "DUMMY QEMU EXECUTED WITH ARGS:" output.log && \
       ${pkgs.gnugrep}/bin/grep -q "This is the custom QEMU package test" output.log; then
      echo "SUCCESS: Custom QEMU package was used"
      touch $out
    else
      echo "ERROR: Custom QEMU package was not executed"
      cat output.log
      exit 1
    fi
  ''
  else null
  ) configs
)