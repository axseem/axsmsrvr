{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgHsajKdoFryzgVP5H7wL5BoKBKX6WjSBYiGZNJuM2F max@axseem.me"
      ];
      hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    postCommands = ''
      echo 'cryptsetup-askpass' >> /root/.profile
    '';
  };
  boot.initrd.luks.devices."crypted" = {
    device = "/dev/disk/by-partlabel/root";
    allowDiscards = true;
    preLVM = true;
  };

  networking.hostName = "axsmsrvr";
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 2222 80 443 ];
  # Note: IPP listens on an internal port we don't open to the internet.

  security.sudo.wheelNeedsPassword = false;
  users.users = {
    root.hashedPassword = lib.mkDefault "!";
    axseem = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgHsajKdoFryzgVP5H7wL5BoKBKX6WjSBYiGZNJuM2F max@axseem.me"
      ];
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "max@axseem.me";
  };

  services.immich = {
    enable = true;
    port = 2283;
    settings.server.externalDomain = "https://photo.cloud.axseem.me";
  };

  services.immich-public-proxy = {
    enable = true;
    immichUrl = "http://127.0.0.1:${toString config.services.immich.port}";
    port = 4005;
    openFirewall = false;

    settings = {
      ipp = {
        showHomePage = false;
        downloadOriginalPhoto = false;
      };
      responseHeaders = {
        "access-control-allow-origin" = "https://axseem.me";
        "access-control-allow-methods" = "GET, OPTIONS";
        "access-control-allow-headers" = "Content-Type, Range";
      };
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    appendHttpConfig = ''
      proxy_cache_path /var/cache/nginx/immich
        levels=1:2
        keys_zone=immich_cache:20m
        max_size=5g
        inactive=30d
        use_temp_path=off;
    '';

    virtualHosts."photo.cloud.axseem.me" = {
      enableACME = true;
      forceSSL = true;

      locations."^~ /share/video/" = {
        proxyPass = "http://127.0.0.1:4005";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_http_version 1.1;

          add_header Access-Control-Allow-Origin https://axseem.me always;
          add_header Vary Origin always;

          # No proxy cache for video
          proxy_no_cache 1;
          proxy_cache_bypass 1;
        '';
      };

      locations."^~ /share/" = {
        proxyPass = "http://127.0.0.1:4005";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_http_version 1.1;

          add_header Access-Control-Allow-Origin https://axseem.me always;
          add_header Vary Origin always;

          # Cache thumbnails/HTML for a while to reduce load
          proxy_cache immich_cache;
          proxy_cache_key $scheme$proxy_host$uri$is_args$args;
          proxy_cache_valid 200 301 302 7d;
          proxy_cache_lock on;
          proxy_cache_use_stale updating error timeout http_500 http_502 http_503 http_504;
        '';
      };

      locations."/" = {
        proxyPass = "http://127.0.0.1:2283";
        proxyWebsockets = true;
        extraConfig =
          "proxy_ssl_server_name on;" +
          "proxy_pass_header Authorization;";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  system.stateVersion = "24.11";
}
