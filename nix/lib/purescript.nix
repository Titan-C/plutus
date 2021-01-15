{ stdenv
, nodejs
, easyPS
, nix-gitignore
}:

{ pkgs
  # path to project sources
, src
  # name of the project
, name
  # packages as generated by psc-pacakge2nix
, packages
  # spago packages as generated by spago2nix
, spagoPackages
  # a map of source directory name to contents that will be symlinked into the environment before building
, extraSrcs ? { }
  # node_modules to use
, nodeModules
  # control execution of unit tests
, checkPhase
}:
let
  # Cleans the source based on the patterns in ./.gitignore and the additionalIgnores
  cleanSrcs = nix-gitignore.gitignoreSource [ "/*.adoc" "/*.nix" ] src;

  addExtraSrc = k: v: "ln -sf ${v} ${k}";
  addExtraSrcs = builtins.concatStringsSep "\n" (builtins.attrValues (pkgs.lib.mapAttrs addExtraSrc extraSrcs));
  extraPSPaths = builtins.concatStringsSep " " (map (d: "${d}/**/*.purs") (builtins.attrNames extraSrcs));
in
stdenv.mkDerivation {
  inherit name checkPhase;
  src = cleanSrcs;
  buildInputs = [ nodeModules easyPS.purs easyPS.spago easyPS.psc-package ];
  buildPhase = ''
    set -x
    export HOME=$NIX_BUILD_TOP
    shopt -s globstar
    ${addExtraSrcs}
    ls generated
    sh ${spagoPackages.installSpagoStyle}
    sh ${spagoPackages.buildSpagoStyle} src/**/*.purs test/**/*.purs ${extraPSPaths}
    ${nodejs}/bin/npm run webpack
  '';
  doCheck = true;
  installPhase = ''
    mv dist $out
  '';
}
