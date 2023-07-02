install TARGET-IP:
  nix run github:numtide/nixos-anywhere -- --no-reboot --flake '.#x1' root@{{TARGET-IP}}

  ssh teevik@{{TARGET-IP}} "mkdir /mnt/home/teevik/.ssh"

  scp /home/teevik/.ssh/id_rsa teevik@{{TARGET-IP}}:/mnt/home/teevik/.ssh/id_rsa

  scp /home/teevik/.ssh/id_rsa.pub teevik@{{TARGET-IP}}:/mnt/home/teevik/.ssh/id_rsa.pub

  ssh teevik@{{TARGET-IP}} "git clone https://github.com/teevik/Config.git /mnt/home/teevik/Documents/Config"

  ssh teevik@{{TARGET-IP}} "cd /mnt/home/teevik/Documents/Config && git remote set-url origin git@github.com:teevik/Config.git"

  ssh root@{{TARGET-IP}} "reboot"