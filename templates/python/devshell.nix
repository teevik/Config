{ pkgs }:
pkgs.mkShell {
  packages = [
    (pkgs.python3.withPackages
      (python-pkgs: with python-pkgs; [
        numpy
        sympy
        z3-solver
      ]))
  ];

  # Workaround: make vscode's python extension read the .venv
  shellHook = /* bash */ ''
    venv="$(cd $(dirname $(which python)); cd ..; pwd)"
    ln -Tsf "$venv" .venv
  '';
}
