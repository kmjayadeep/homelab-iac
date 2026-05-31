# Source of truth for Helios Postgres databases.
#
# Passwords and other secrets do not belong here. Keep credentials in the
# relevant app secret store and use this catalog for platform metadata only.
{
  databases = {
    coder = {
      owner = "coder";
      backup = true;
      criticality = "P2";
      extensions = [];
      restorePriority = "normal";
    };

    immich = {
      owner = "immich";
      backup = true;
      criticality = "P1";
      extensions = [ "pgvector" ];
      restorePriority = "high";
    };

    k3s = {
      owner = "k3s";
      backup = true;
      criticality = "P1";
      extensions = [];
      restorePriority = "high";
    };

    planka = {
      owner = "planka";
      backup = true;
      criticality = "P2";
      extensions = [];
      restorePriority = "normal";
    };

    shoppinglist = {
      owner = "shoppinglist";
      backup = true;
      criticality = "P2";
      extensions = [];
      restorePriority = "normal";
    };

    taskplanner = {
      owner = "taskplanner";
      backup = true;
      criticality = "P2";
      extensions = [];
      restorePriority = "normal";
    };

    totp = {
      owner = "totp";
      backup = true;
      criticality = "P2";
      extensions = [];
      restorePriority = "normal";
    };

    uptimekuma = {
      owner = "uptimekuma";
      backup = true;
      criticality = "P1";
      extensions = [];
      restorePriority = "high";
    };
  };

  extraUsers = [
    {
      name = "pgweb";
      reason = "pgweb admin/visualization connection user";
    }
  ];
}
