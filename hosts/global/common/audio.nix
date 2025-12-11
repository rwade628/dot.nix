{ pkgs, inputs, ... }:
{
  # TODO fix Topping MX3 low latency issues
  # imports = [
  #   inputs.nix-gaming.nixosModules.pipewireLowLatency
  # ];

  services.pulseaudio = {
    enable = false;
    package = pkgs.pulseaudioFull;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
    # lowLatency.enable = true;

  };

  environment.systemPackages = with pkgs; [
    alsa-utils
  ];

  # Enable surround sound (5.1) support in PipeWire by fixing ALSA configuration
  environment.etc = {
    # fix for cause #1
    "alsa/conf.d/60-a52-encoder.conf".source =
      pkgs.alsa-plugins + "/etc/alsa/conf.d/60-a52-encoder.conf";

    # fix for cause #2
    "alsa/conf.d/59-a52-lib.conf".text = ''
      pcm_type.a52 {
        lib "${pkgs.alsa-plugins}/lib/alsa-lib/libasound_module_pcm_a52.so"
      }
    '';
  };

  # services.easyeffects = {
  #   enable = true;
  # };

  # environment.systemPackages = with pkgs; [
  #   gnomeExtensions.easyeffects-preset-selector
  # ];
}
