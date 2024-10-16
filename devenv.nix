{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    python3
    cmake
    m4
    parallel
    gnuplot
    time
  ];

  # https://devenv.sh/languages/
  languages.c.enable = true;

  # https://devenv.sh/processes/

  # https://devenv.sh/services/

  # https://devenv.sh/scripts/

  enterShell = ''
    git --version
  '';

  # https://devenv.sh/tasks/

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/pre-commit-hooks/

  # See full reference at https://devenv.sh/reference/options/
}
