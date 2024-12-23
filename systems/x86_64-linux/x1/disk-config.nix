# { disks, ... }: {
#   disk = {
#     disk0 = {
#       device = builtins.elemAt disks 0;
#       type = "disk";

#       content = {
#         type = "table";
#         format = "gpt";

#         partitions = [
#           {
#             name = "ESP";
#             start = "1MiB";
#             end = "512MiB";

#             bootable = true;

#             content = {
#               type = "filesystem";
#               format = "vfat";
#               mountpoint = "/boot";
#             };
#           }

#           {
#             name = "root";
#             start = "512MiB";
#             end = "100%";

#             part-type = "primary";
#             bootable = true;

#             content = {
#               type = "filesystem";
#               format = "bcachefs";
#               mountpoint = "/";
#             };
#           }


#         ];
#       };
#     };
#   };
# }

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
            # priority = 1;

            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            # size = "100%";
            # priority = 2;
            end = "-16G";

            content = {
              type = "filesystem";
              format = "bcachefs";
              mountpoint = "/";
            };
          };

          swap = {
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
