# Source of truth for Helios Postgres databases.
#
# Passwords and other secrets do not belong here. Keep credentials in the
# relevant app secret store and use this catalog for platform metadata only.
{
  databases = {
    bookorbit = {
      owner = "bookorbit";
      backup = true;
      criticality = "P2";
      extensions = [ "uuid-ossp" "pg_trgm" "unaccent" "vector" ];
      restorePriority = "normal";
    };

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
      extensions = [ "vector" ];
      restorePriority = "high";
    };

    k3s = {
      owner = "k3s";
      backup = true;
      criticality = "P1";
      extensions = [];
      restorePriority = "high";
    };

    litellm = {
      owner = "litellm";
      backup = true;
      criticality = "P2";
      extensions = [];
      restorePriority = "normal";
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

    streakslap = {
      owner = "streakslap";
      backup = true;
      criticality = "P3";
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

    wallabag = {
      owner = "wallabag";
      backup = true;
      criticality = "P2";
      extensions = [];
      restorePriority = "normal";
    };
  };

  extraUsers = [
    {
      name = "pgweb";
      reason = "pgweb admin/visualization connection user";
    }
  ];
}
