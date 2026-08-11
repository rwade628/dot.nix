# SSH access, provisioned declaratively via nix-darwin's built-in sshd support
{ ... }:
{
  services.openssh.enable = true;
}
