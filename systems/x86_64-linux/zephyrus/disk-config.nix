{ disks, ... }: {
  disk = {
    disk0 = {
      device = builtins.elemAt disks 0;
      type = "disk";

      content = {
        type = "table";
        format = "gpt";

        partitions = [
          {
            start = "1MiB";
            end = "512MiB";
            name = "ESP";

            bootable = true;

            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }

          {
            name = "root";
            end = "-32Gb";

            part-type = "primary";
            bootable = true;

            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          }

          {
            name = "swap";
            size = "100%";

            content = {
              type = "swap";
              randomEncryption = false;
              resumeDevice = true;
            };
          }
        ];
      };
    };
  };
}
