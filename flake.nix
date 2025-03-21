{
  description = "Minimal NixOS configuration for Discourse";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; # unstable for up to date software, 24.11 might be quite outdated
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (
            { ... }:
            {
              boot.isContainer = true;

              services.discourse = {
                enable = true;
                hostname = "localhost";
                enableACME = false;
                database.ignorePostgresqlVersion = true;
                admin.skipCreate = true;
              };

              networking.firewall.allowedTCPPorts = [ 80 ];

              system.stateVersion = "24.11";
            }
          )
        ];
      };
    };
}