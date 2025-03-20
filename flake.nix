{
  description = "NixOS configuration with PostgreSQL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Latest packages
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux"; # Adjust to your system, e.g., "aarch64-linux" for ARM
  in
  {
    nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ({ config, pkgs, ... }: {
          # Enable PostgreSQL service
          services.postgresql = {
            enable = true;
            package = pkgs.postgresql_16; # Latest stable PostgreSQL as of nixos-unstable
            ensureDatabases = [ "mydatabase" ];
            ensureUsers = [
              {
                name = "myuser";
                ensurePermissions = {
                  "DATABASE mydatabase" = "ALL PRIVILEGES";
                };
              }
            ];
            initialScript = pkgs.writeText "postgresql-init.sql" ''
              ALTER USER myuser WITH PASSWORD 'your_password_here';
            '';
          };

          # Open PostgreSQL port (optional)
          networking.firewall.allowedTCPPorts = [ 5432 ];

          # Use a modern state version for a fresh setup
          system.stateVersion = "24.11"; # Reflects a recent baseline, not a version lock
        })
      ];
    };
  };
}