{ disks, ... }: {
  disk = {
    main = {
      device = builtins.elemAt disks 0;
      type = "disk";

      content = {
        type = "gpt";

        partitions = {
          ESP = {
            type = "EF00";
            size = "500M";
            priority = 1;

            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            priority = 2;
            end = "-16G";

            content = {
              type = "filesystem";
              format = "bcachefs";
              mountpoint = "/";
            };
          };

          swap = {
            priority = 3;
            size = "100%";
            content = {
              type = "swap";
              discardPolicy = "both";
              resumeDevice = true; # resume from hiberation from this device
            };
          };
        };
      };
    };
  };
}
