# Telepathy daemon.
{
  config,
  lib,
  pkgs,
  ...
}:
{

  meta = {
    maintainers = [ ];
  };

  ###### interface

  options = {

    services.telepathy = {

      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable Telepathy service, a communications framework
          that enables real-time communication via pluggable protocol backends.
        '';
      };

    };

  };

  ###### implementation

  config = lib.mkIf config.services.telepathy.enable {

    environment.systemPackages = [ pkgs.telepathy-mission-control ];

    services.dbus.packages = [ pkgs.telepathy-mission-control ];
  };

}
