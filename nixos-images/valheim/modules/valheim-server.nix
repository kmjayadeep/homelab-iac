{
  config,
  pkgs,
  ...
}: {
  services.valheim = {
    enable = true;
    # crossplay = true;
    password = lib.strings.fileContents ../secrets/secret-valheim-password;
    adminList = [
      lib.strings.fileContents ../secrets/secret-admin-id;
    ];
  };

}

