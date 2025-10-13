# Terminal profiles for macOS Terminal.app (Home Manager module)

Manage Terminal.app profiles declaratively from Home Manager:

## Usage (flakes)

```nix
{
  inputs.terminal-profiles-hm.url = "github:not-in-stock/terminal-profiles-hm";
  inputs.home-manager.url = "github:nix-community/home-manager";

  outputs = { self, nixpkgs, home-manager, terminal-profiles-hm, ... }: {
    homeConfigurations."me@mac" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-darwin"; };
      modules = [
        terminal-profiles-hm.homeManagerModules.terminal-profiles
        {
          programs.terminal = {
            enable = true;
            startupWindowSettings = "Dracula";
            defaultWindowSettings = "Dracula";

            profiles."Dracula" = {
              backgroundColor = "#282a36";
              textColor       = "#f8f8f2";
              selectionColor  = "#44475a";
              boldUsesBrightColors = true;

              cursor = { type = "underline"; color = "#f8f8f2"; blink = true; };

              ansi = {
                enable = true;
                colors = {
                  black="#21222c";
                  red="#ff5555";
                  green="#50fa7b";
                  yellow="#f1fa8c";
                  blue="#bd93f9";
                  magenta="#ff79c6";
                  cyan="#8be9fd";
                  white="#bfbfbf";
                  brightBlack="#6272a4";
                  brightRed="#ff6e6e";
                  brightGreen="#69ff94";
                  brightYellow="#ffffa5";
                  brightBlue="#d6acff";
                  brightMagenta="#ff92df";
                  brightCyan="#a4ffff";
                  brightWhite="#ffffff";
                };
              };

              backgroundBlur = 0.2;
              inactiveSettings = { enable = true; backgroundAlpha = 0.7; backgroundBlur = 0.5; };

              font = {
                name = "JetBrainsMono Nerd Font Mono";
                size = 13;
                fallback = [ "MesloLGS Nerd Font Mono" "SFMono-Regular" "Menlo-Regular" ];
              };
            };
          };
        }
      ];
    };
  };
}
```
