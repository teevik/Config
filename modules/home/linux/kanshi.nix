{ ... }:
{
  services.kanshi = {
    enable = true;

    settings = [
      {
        output = {
          alias = "samsung";
          criteria = "Samsung Electric Company Odyssey G85SB H1AK500000";
          mode = "3440x1440@174.962Hz";
          position = "0,0";
          adaptiveSync = false;
        };
      }
      {
        output = {
          alias = "portable";
          criteria = "PNP(YMK) EM160TP-A 0x00000001";
          mode = "2560x1600@119.998Hz";
          position = "3440,0";
          scale = 1.5;
        };
      }
      {
        profile = {
          name = "home";
          outputs = [
            {
              criteria = "$samsung";
              status = "enable";
            }
            {
              criteria = "$portable";
              status = "enable";
            }
          ];
        };
      }
    ];
  };
}
