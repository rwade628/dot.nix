{ ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig = {
      settings = {
        experimental = true;
        trusted_config_paths = [ "~/git" ];
      };
    };
  };
}
