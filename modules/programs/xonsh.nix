{ config, lib, pkgs, ... }:
let
  cfg = config.programs.xonsh;
  inherit (lib) types mkOption;
in {
  options.programs.xonsh = {
    enable = lib.mkEnableOption "xonsh";
    enablePromptToolkit =
      lib.mkEnableOption "advanced prompt based on prompt_toolkit";

    package = lib.mkPackageOption pkgs "xonsh" { };
    finalPackage = lib.mkOption {
      type = types.package;
      internal = true;
      description = "Package that will actually get installed";
    };
    xonshrc = mkOption {
      type = types.lines;
      default = "";
      description = ''
        The contents of .xonshrc
      '';
    };
    shellAliases = mkOption {
      type = with types; attrsOf (listOf str);
      default = { };
      example = { ll = [ "ls" "-l" ]; };
      description = ''
        An attribute set that maps aliases (the top level attribute names in
        this option) to commands
      '';
    };
    extraPackages = mkOption {
      type = with types; functionTo (listOf package);
      default = _: [ ];
      defaultText = "_: []";
      description = ''
        List of python packages and xontrib to make avaiable
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];
    programs.xonsh = {
      xonshrc = lib.mkMerge
        (lib.mapAttrsToList (n: v: "aliases['${n}']=${builtins.toJSON v}")
          cfg.shellAliases);
      shellAliases = lib.mapAttrs (n: v: lib.mkDefault (lib.splitString " " v))
        config.home.shellAliases;
      extraPackages =
        lib.mkIf cfg.enablePromptToolkit (ps: [ ps.prompt_toolkit ]);
      finalPackage =
        cfg.package.override (old: { inherit (cfg) extraPackages; });
    };
    xdg.configFile."xonsh/rc.xsh" = {
      enable = cfg.xonshrc != "";
      text = cfg.xonshrc;
    };
  };
}
