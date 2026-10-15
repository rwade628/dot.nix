# SSH access, provisioned declaratively via nix-darwin's built-in sshd support.
# Off on Work hosts: nothing logs into them (no authorized keys) and they have
# no sops host key to derive, the two reasons a personal Mac needs it.
{ host, ... }:
{
  services.openssh.enable = !host.isWork;
}
