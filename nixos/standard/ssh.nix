{ ... }: {
  programs.ssh = {
    startAgent = true;
    # extraConfig = ''
    #   AddKeysToAgent yes
    # '';
  };

  services.openssh.enable = true;

  users.users =
    let
      keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3/B6lqoz+fG6QqerYS4kMCtrgl+hCvN6OhuXgcG9yCf0QhRfPFuPGqq/X5DgmyZsLAheH5YgaXxmtPnfO3+t4k9JEFgDRr8SB3dDxzfoQJfHi7SGk1dyjJ9CGgTzrc9Kgs1Zvp76NAug3VkPHv+J92oytprFEiBRzLg0HV8NWtFkDiR0TtjLbxt28UAHyD1v0VjjC9WRuzRPiiQonye5Tk3fz6Z9PGItWht+3Jhnvhb6CHxHcio8582w9xRpP9Ho+yFYINgipQDfU2MDcZxIaqnM4tWS0ExTdneIWqWcmP28EyWWQo0DayY/lxp2WIL/AbQ94bjCSzlgy29KVAU13T2ct/m70VGo8xqB3cBhd/bhIQlamGc5D8pS2XipRmPXrdMGW4tkr9k4La0SOkS1kb47solf5K1AXtMgslFh7844+mQbMfYVRbnAtjOMtZjsOmzOwxtVaZLdmYLPSgTZO0a92UXyZRd8/apx+erg+Oak9pHHfp4rZi86/sUue8d8= teemu@DESKTOP-J8H46CI"
      ];
    in
    {
      teevik.openssh.authorizedKeys.keys = keys;
      root.openssh.authorizedKeys.keys = keys;
    };
}
