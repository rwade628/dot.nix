{ ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig = {
      experimental = true;
      trusted_config_paths = [ "~/git" ];
    };
  };
}
