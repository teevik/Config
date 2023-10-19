{ disks, ... }: {
  disk = {
    disk0 = {
      device = builtins.elemAt disks 0;
      type = "disk";

      content = {
        type = "table";
        format = "gpt";

        partitions = {
          ESP = {
            size = "512MiB";

            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            end = "-32Gb";

            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };

          swap = {
            size = "100%";

            content = {
              type = "swap";
              randomEncryption = false;
              resumeDevice = true;
            };
          };
        };
      };
    };
  };
}
