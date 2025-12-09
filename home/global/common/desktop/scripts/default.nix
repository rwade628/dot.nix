{ ... }:
{
  # Source scripts from the home-manager store
  home.file = {
    ".local/bin" = {
      recursive = true;
      source = ./bin;
    };
  };
}
