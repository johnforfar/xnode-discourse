{
  description = "Minimal NixOS configuration for Discourse";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.\${system};
  in
  {
    nixosConfigurations.xnode-discourse = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ({ config, ... }: {
          # Install Discourse package
          environment.systemPackages = [ pkgs.discourse ];

          # Define a minimal systemd service for Discourse
          systemd.services.discourse = {
            description = "Discourse web application";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = "\${pkgs.discourse}/bin/rails server -b 0.0.0.0 -p 3000";
              User = "discourse";
              WorkingDirectory = "/var/lib/discourse";
              Restart = "always";
            };
          };

          # Create a system user and directory for Discourse
          users.users.discourse = {
            isSystemUser = true;
            group = "discourse";
            home = "/var/lib/discourse";
            createHome = true;
          };
          users.groups.discourse = {};

          # Open firewall for port 3000
          networking.firewall.allowedTCPPorts = [ 3000 ];

          # Set the system state version
          system.stateVersion = "24.11";

          # Boot loader configuration (GRUB on /dev/vda)
          boot.loader.grub = {
            enable = true;
            device = "/dev/vda";
          };

          # Root file system configuration (/ on /dev/vda1)
          fileSystems."/" = {
            device = "/dev/vda1";
            fsType = "ext4";
          };
        })
      ];
    };
  };
}