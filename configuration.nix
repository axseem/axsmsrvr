{ config, lib, pkgs, ... }:

{
  imports =
    [
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
          hostKeys = [
            "/etc/ssh/ssh_host_ed25519_key"
          ];
          
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

  security.sudo.wheelNeedsPassword = false;

  users.users = {
    root.hashedPassword = lib.mkDefault "!";

    axseem = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgHsajKdoFryzgVP5H7wL5BoKBKX6WjSBYiGZNJuM2F max@axseem.me"
      ];
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  system.stateVersion = "24.11";
}
