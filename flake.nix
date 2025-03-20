{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/172b7298869362d6f58dbf19976ff2241d9eacee";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs =
    {
      self,
      nixpkgs-stable,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs-stable.legacyPackages.${system};
    in
    {
      nixosConfigurations.xnode-discourse = nixpkgs-stable.lib.nixosSystem {
        inherit system;
        modules = [
          (
            { ... }:
            {
              # Install Discourse package
              environment.systemPackages = [ pkgs.discourse ];

              # Enable and configure PostgreSQL for Discourse
              services.postgresql = {
                enable = true;
                package = pkgs.postgresql_16;
                ensureDatabases = [ "discourse" ];
                ensureUsers = [
                  {
                    name = "discourse";
                    ensurePermissions = {
                      "DATABASE discourse" = "ALL PRIVILEGES";
                    };
                  }
                ];
                initialScript = pkgs.writeText "postgresql-init.sql" ''
                  ALTER USER discourse WITH PASSWORD 'your_secure_password';
                '';
              };

              # Enable and configure Redis for Discourse
              services.redis.servers."discourse" = {
                enable = true;
                port = 6379;
              };

              # Configure Nginx as a reverse proxy for Discourse
              services.nginx = {
                enable = true;
                virtualHosts."discourse.example.com" = {
                  forceSSL = true;
                  enableACME = true;
                  locations."/" = {
                    proxyPass = "http://localhost:3000";
                  };
                };
              };

              # Define a systemd service for Discourse
              systemd.services.discourse = {
                description = "Discourse web application";
                after = [ "network.target" "postgresql.service" "redis.service" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  ExecStart = "${pkgs.discourse}/bin/rails server -b 0.0.0.0 -p 3000";
                  User = "discourse";
                  WorkingDirectory = "/var/lib/discourse";
                  Restart = "always";
                };
                preStart = ''
                  # Run database migrations
                  ${pkgs.discourse}/bin/rake db:migrate
                '';
              };

              # Create a system user and group for Discourse
              users.users.discourse = {
                isSystemUser = true;
                group = "discourse";
                home = "/var/lib/discourse";
                createHome = true;
              };
              users.groups.discourse = {};

              # Open firewall ports for Nginx
              networking = {
                firewall.allowedTCPPorts = [ 80 443 ];
              };

              # Set the system state version
              system.stateVersion = "24.11";
            }
          )
        ];
      };
    };
}