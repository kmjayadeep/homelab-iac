{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    eza # better ls
    bat # better cat
    tldr # better man
    fzf # used by kubectx, notes
    alejandra # format nix files
    unzip
    tree
    tmux
    python3

    # Other apps
    neofetch
    restic # for backup
    dig
    btop # Better htop
    nodePackages_latest.http-server
    postgresql
    rclone
    hugo

    # programming
    go
    docker-compose
    ripgrep
    jq
    ansible
    kubeseal
    httpie
    terraform
    coder
  ];
}

