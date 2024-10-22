{ disks, ... }: {
  disk = {
    disk0 = {
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
            size = "100%";
            priority = 2;

            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
