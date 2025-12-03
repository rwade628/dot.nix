{ pkgs, lib, ... }:
{
  fonts = {
    packages = with pkgs; [
      # icon fonts
      material-symbols

      # Sans(Serif) fonts
      lexend
      noto-fonts
      noto-fonts-color-emoji
      roboto
      (google-fonts.override {
        fonts = [
          "Inter"
          "Laila"
        ];
      })

      # monospace fonts
      monocraft
      nerd-fonts.roboto-mono
      nerd-fonts.jetbrains-mono

      # nerdfonts
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
    ];

    # causes more issues than it solves
    enableDefaultPackages = false;

    # user defined fonts
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Laila" ];
        sansSerif = [ "Lexend" ];
        monospace = [ "Jetbrains" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
