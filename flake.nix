{
  description = "Minimal NixOS configuration for Discourse";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.container = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ({ config, pkgs, ... }: {
          boot.isContainer = true;
          systemd.services.discourse = {
            description = "Discourse web application";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = "\${pkgs.discourse}/bin/rails server -b 0.0.0.0 -p 3000";
              StateDirectory = "discourse";
              DynamicUser = true;
              Restart = "on-failure";
            };
          };

          networking.firewall.allowedTCPPorts = [ 3000 ];

          system.stateVersion = "25.05";

        })
      ];
    };
  };
}
