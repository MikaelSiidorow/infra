# Waybar status bar — replaces GNOME top bar + Vitals extension
# Runs as a separate process, no GNOME Shell GC crash risk
_: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 4;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "cpu"
          "memory"
          "battery"
          "pulseaudio"
          "network"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };

        "hyprland/window" = {
          max-length = 50;
          separate-outputs = true;
        };

        clock = {
          format = "{:%a %d.%m.  %H:%M:%S}";
          interval = 1;
          tooltip-format = "<tt>{calendar}</tt>";
        };

        cpu = {
          format = " {usage}%";
          interval = 5;
        };

        memory = {
          format = "󰍛 {percentage}%";
          interval = 5;
          tooltip-format = "{used:0.1f}G / {total:0.1f}G";
        };

        battery = {
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-full = "󰁹";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          states = {
            warning = 30;
            critical = 15;
          };
        };

        pulseaudio = {
          format = "󰕾 {volume}%";
          format-muted = "󰖁";
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        network = {
          format-wifi = "󰤨 {essid}";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        tray = {
          spacing = 8;
        };
      };
    };

    style = ''
      * {
        font-family: "Inter", "Symbols Nerd Font";
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background: transparent;
        color: #eceff4;
      }

      /* Workspace buttons */
      #workspaces {
        margin: 4px 4px;
        background: #2e3440;
        border-radius: 12px;
        padding: 0 4px;
      }

      #workspaces button {
        padding: 2px 10px;
        margin: 3px 2px;
        color: #4c566a;
        border-radius: 10px;
      }

      #workspaces button.active {
        color: #eceff4;
        background: #5e81ac;
      }

      #workspaces button:hover {
        color: #d8dee9;
        background: #434c5e;
      }

      /* Window title */
      #window {
        margin: 4px 4px;
        padding: 2px 12px;
        color: #d8dee9;
      }

      /* All right-side modules in one pill */
      #cpu, #memory, #battery, #pulseaudio, #network, #tray {
        padding: 2px 10px;
        margin: 4px 0;
        background: #2e3440;
        color: #d8dee9;
      }

      #cpu {
        border-radius: 12px 0 0 12px;
        margin-left: 4px;
      }

      #tray {
        border-radius: 0 12px 12px 0;
        margin-right: 4px;
      }

      /* Clock as center pill */
      #clock {
        padding: 2px 16px;
        margin: 4px 2px;
        background: #2e3440;
        border-radius: 12px;
        font-weight: bold;
        color: #eceff4;
      }

      #battery.warning { color: #ebcb8b; }
      #battery.critical {
        color: #bf616a;
        animation: blink 1s linear infinite;
      }

      @keyframes blink {
        to { color: #eceff4; }
      }
    '';
  };
}
