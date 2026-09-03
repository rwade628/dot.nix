# The shared ghostty config (modules/home/core/ghostty.nix) sets font-size with
# lib.mkDefault, sized against the fontconfig DPI of the Linux desktop. macOS
# renders the same point size noticeably smaller on this Retina panel, so idun
# overrides it here rather than the shared module branching on platform - the
# variable is the display, not the OS.
{
  programs.ghostty.settings.font-size = "14";
}
