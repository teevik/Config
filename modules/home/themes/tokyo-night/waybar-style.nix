{ colors }: with colors; /* css */ ''
  * {
    font-family: "JetBrains Mono Nerd Font", sans-serif;
    font-size: 14px;
  }

  window#waybar {
    background: transparent;
    color: #f1fcf9;
  }

  .modules-left {
    margin-left: 16px;
  }

  .modules-right {
    margin-right: 16px;
  }

  .modules-left,
  .modules-right {
    margin-top: 5px;
    background-color: rgba(0, 0, 0, 0.5);
    border-radius: 8px;
  }

  #workspaces button {
    padding: 0 5px;
    margin: 5px 0px;
    background-color: transparent;
    color: rgba(241, 252, 249, 0.5);
    transition-property: color;
    transition-duration: 0.2s;
  }

  #workspaces button.active {
    color: ${base0F};
  }

  #backlight,
  #battery,
  #clock,
  #cpu,
  #disk,
  #memory,
  #pulseaudio,
  #network {
    /* margin-top: 7px;
    margin-bottom: 0px; */
    padding: 0px 16px;
    color: #f1fcf9;
    font-size: 12px;
    font-weight: bold;
  }

  /* #custom-power {
    color: #b4a1db;
    font-size: 16px;
    padding: 0px 16px;
  } */
''
