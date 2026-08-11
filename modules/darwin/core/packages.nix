# System packages shared by all Darwin hosts
#
# OWNERSHIP: These are system-level packages installed via nix-darwin.
# User-specific apps should go in modules/home/core/packages.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    git
    git-crypt
    gnupg
    openssh
    wget
  ];
}
