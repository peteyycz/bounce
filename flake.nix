{
  description = "bounce — a standalone Qt6/QML app with a liquid-glass look";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        qtDeps = with pkgs.qt6; [
          qtbase
          qtdeclarative
          qt5compat
          qtnetworkauth
          qtwebengine
        ] ++ [ pkgs.qt6Packages.qtkeychain ];
      in
      {
        packages.default = pkgs.qt6.qtbase.stdenv.mkDerivation {
          pname = "bounce";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            qt6.wrapQtAppsHook
          ];

          buildInputs = qtDeps;
        };

        packages.bounce = self.packages.${system}.default;

        devShells.default = pkgs.mkShell {
          packages =
            qtDeps
            ++ (with pkgs; [
              cmake
              ninja
              qt6.qttools
            ]);

          # qmlls reads QML_IMPORT_PATH to resolve imports; modules live under
          # lib/qt-6/qml on Nix.
          QML_IMPORT_PATH = pkgs.lib.makeSearchPath "lib/qt-6/qml" qtDeps;
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
