{ config, lib, pkgs, ... }:
with lib;

let
  swiftPack = ../swift/TerminalPack.swift;
  swiftSync = ../swift/SyncPrefs.swift;
  cfg = config.programs.terminal;
  frac = t: types.addCheck t (x: x >= 0.0 && x <= 1.0);
in {
  options.programs.terminal = {
    enable = mkEnableOption "Terminal.app profiles via .terminal import (Swift under the hood)";

    startupWindowSettings = mkOption { type = types.nullOr types.str; default = null; };
    defaultWindowSettings = mkOption { type = types.nullOr types.str; default = null; };

    profiles = mkOption {
      type = with types; attrsOf (submodule ({ name, ... }: {
        options = {
          backgroundBlur  = mkOption {
            type = types.nullOr (frac types.number);
            default = null; };
          backgroundColor = mkOption { type = types.nullOr types.str; default = null; };
          textColor       = mkOption { type = types.nullOr types.str; default = null; };
          textBoldColor   = mkOption { type = types.nullOr types.str; default = null; };
          selectionColor  = mkOption { type = types.nullOr types.str; default = null; };

          cursor = mkOption {
            type = types.submodule {
              options = {
                type = mkOption {
                  type = types.nullOr (types.enum [ "block" "underline" "bar" ]);
                  default = null;
                  description = "Cursor shape: block | underline | bar";
                };
                color = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Cursor color (#RRGGBB[AA]).";
                };
                blink = mkOption {
                  type = types.nullOr types.bool;
                  default = null;
                  description = "Enable cursor blinking.";
                };
              };
            };
            default = { };
            description = "Cursor settings.";
          };

          boldUsesBrightColors = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "If true, bold text uses bright ANSI colors.";
          };

          disableAnsiColors = mkOption {
            type = types.bool;
            default = false;
            description = "Disable ANSI colors entirely (maps to DisableANSIColor, only written when true).";
          };

          inactiveSettings = mkOption {
            type = types.submodule {
              options = {
                enable = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Enable separate inactive window settings.";
                };
                backgroundAlpha = mkOption {
                  type = types.nullOr (frac types.number);
                  default = null;
                  description = "Inactive window background alpha (0..1).";
                };
                backgroundBlur = mkOption {
                  type = types.nullOr (frac types.number);
                  default = null;
                  description = "Inactive window background blur (0..1).";
                };
              };
            };
            default = { enable = false; };
          };

          ansi = mkOption {
            type = types.submodule {
              options = {
                enable = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Enable ANSI colors.";
                };
                colors = mkOption {
                  type = types.attrsOf types.str;
                  default = {};
                  description = "ANSI palette.";
                };
              };
            }; default = { enable = true; colors = {}; };
          };

          font = mkOption {
            type = types.submodule {
              options = {
                name = mkOption { type = types.str; default = "Menlo-Regular"; };
                size = mkOption { type = types.number; default = 12; };
                antialias = mkOption { type = types.bool; default = true; };
                widthSpacing = mkOption { type = types.nullOr types.number; default = null; };
                fallback = mkOption {
                  type = types.listOf types.str;
                  default = [ "MesloLGS Nerd Font Mono" "JetBrainsMono Nerd Font Mono" "SFMono-Regular" "Menlo-Regular" ];
                };
              };
            };
            default = { };
          };
        };
      }));
      default = {};
    };
  };

  config = mkIf cfg.enable (let
    profilesJson =
      builtins.toJSON (mapAttrsToList (n: v: {
        name = n;
        backgroundColor = v.backgroundColor or null;
        backgroundBlur = v.backgroundBlur or null;
        textColor = v.textColor or null;
        textBoldColor = v.textBoldColor or null;
        selectionColor = v.selectionColor or null;
        cursor = v.cursor or { };
        boldUsesBrightColors = v.boldUsesBrightColors or null;
        font = v.font;
        inactiveSettings = v.inactiveSettings or { enable = false; };

        ansi = {
          enable = (v.ansi.enable or true);
          colors = (v.ansi.colors or {});
        };

      }) cfg.profiles);
  in
    {
      home.activation.terminalProfiles = hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

        JSON="${config.xdg.cacheHome}/terminal-profiles.json"
        mkdir -p "$(dirname "$JSON")"
        cat >"$JSON" <<'JSON_EOF'
      ${profilesJson}
      JSON_EOF

        MAP=$(/usr/bin/xcrun swift ${escapeShellArg (toString swiftPack)} "$JSON")

        PREFS="$HOME/Library/Preferences/com.apple.Terminal.plist"

        while IFS=$'\t' read -r NAME XML; do
          if [ -z "$NAME" ] || [ -z "$XML" ] || [ ! -f "$XML" ]; then
            echo "Skip invalid line: $NAME $XML" >&2
            continue
          fi
          /usr/bin/plutil -replace "Window Settings.''${NAME}" -xml "$(<"$XML")" "$PREFS"
        done <<< "$MAP"

        /usr/bin/xcrun swift ${escapeShellArg (toString swiftSync)}

        /usr/bin/defaults read com.apple.Terminal >/dev/null 2>&1 || true
    '';

      targets.darwin.defaults."com.apple.Terminal" = mkMerge [
        (mkIf (cfg.startupWindowSettings != null) {
          "Startup Window Settings" = cfg.startupWindowSettings;
        })
        (mkIf (cfg.defaultWindowSettings != null) {
          "Default Window Settings" = cfg.defaultWindowSettings;
        })
      ];
    }
  );
}
