{
  config,
  pkgs,
  inputs,
  ...
}: {
  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Include /home/jayadeep/private/ssh/config
    '';
  };
}

