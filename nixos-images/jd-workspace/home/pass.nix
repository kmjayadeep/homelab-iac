{
  config,
  lib,
  inputs,
  ...
}: {
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/private/password-store";
    };
  };
}
