{ ... }:
{
  services.kanshi = {
    enable = true;

    settings = {
      home = {
        outputs = [
          {
            criteria = "Samsung Electric Company Odyssey G85SB H1AK500000";
            position = "0,0";
            mode = "3440x1440@174.962";
            adaptiveSync = true;
          }
          {
            criteria = "PNP(YMK) EM160TP-A 0x00000001";
            position = "3440,0";
            mode = "2560x1600@119.998";
            scale = 1.5;
          }
        ];
      };
    };
  };
}
