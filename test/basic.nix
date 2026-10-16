{
  testers,
  home-manager-module,
  plasma-module,
  writeShellScriptBin,
  kdePackages,
}:
let
  script = writeShellScriptBin "plasma-basic-test" ''
    set -eu

    export XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$HOME/.config}
    export PATH="${kdePackages.kconfig}/bin:$PATH"

    assert() {
      if [ $# -lt 4 ]; then
        echo "at least four arguments required"
        exit 1
      fi
      file="$1"
      shift
      want="$1"
      shift
      grpargs=()
      while [ $# -gt 1 ]; do
        grpargs+=(--group "$1")
        shift
      done
      key="$1"
      shift
      actual="$(kreadconfig6 --file "$file" "''${grpargs[@]}" --key "$key")"

      if [ "$actual" != "$want" ]; then
        echo >&2 "FAIL($file|''${grpargs[@]}|$key): Expected \"$want\" but got \"$actual\""
        exit 1
      fi
    }

    #       FILE                EXPECTED          GROUPS ...                    KEY                [COMMENT]
    assert  plasma-org.kde.plasma.desktop-appletsrc org.kde.desktopcontainment \
                                                    Containments 1                plugin               # Set with desktop.wallpaperOnly
    assert  plasma-org.kde.plasma.desktop-appletsrc org.kde.desktopcontainment \
                                                    Containments 3                plugin               # Second activity's desktop
    assert  plasma-org.kde.plasma.desktop-appletsrc org.kde.plasma.panel \
                                                    Containments 26               plugin               # Panel is not a desktop: untouched
    assert  plasma-org.kde.plasma.desktop-appletsrc visible \
                                                    Containments 26 AppletSystemTray HiddenIconsButtonState \
                                                                                             # Pre-existing entry preserved
    assert  kglobalshortcutsrc  bar               services firefox.desktop      foo                # Set with configFile option
    assert  kdeglobals          ' leading space'  group                         ' leading space'   # Set with shorthand
    assert  kdeglobals          /home/fake        group                         'escaped[$i]'      # Set with longhand and immutable
    assert  kdeglobals          false             KDE                           SingleClick        # Nested groups, with group containing /
    assert  kdeglobals          ' value'          'escaped/nested' group        untouched          # Value and key have leading space
    assert  kdeglobals          1                 group                         key1               # Set outside plasma-manager, value has leading space, group contains /
    assert  kdeglobals          2                 group                         key2               # Escaped key with shell expansion
    assert  kdeglobals          3                 'escaped/nested' group        key3               #
    assert  foobarrc            somevalue         somegroup                     somekey            #
    assert  foobarrc            ""                nothing                       nothing            #
    assert  kwinrc              /run/current-system/sw/share/applications/com.github.maliit.keyboard.desktop \
                                                  Wayland                       InputMethod        #
    assert  kwinrc              true              Plugins                       somePluginEnabled  #
    assert  kwinrc              A                 org.kde.kdecoration2          ButtonsOnRight     # Set with kwin option
    assert  kwinrc              MMM               org.kde.kdecoration2          ButtonsOnLeft      # Set with configFile option
    assert  kwinrc              testvalue         testgroup                     testkey            #
  '';
in
testers.nixosTest {
  name = "plasma-basic";

  nodes.machine = {
    environment.systemPackages = [ script ];
    imports = [ home-manager-module ];

    users.users.fake = {
      createHome = true;
      isNormalUser = true;
    };
    users.users.fresh = {
      createHome = true;
      isNormalUser = true;
    };

    home-manager.sharedModules = [
      plasma-module
      {
        programs.plasma.shortcuts."services/firefox.desktop".new-window = [ "Meta+F" ];
      }
    ];

    home-manager.users.fake =
      { lib, ... }:
      {
        home.stateVersion = "23.11";
        programs.plasma = {
          enable = true;
          desktop.wallpaperOnly = true;
          workspace.clickItemTo = "select";
          kwin.titlebarButtons.right = [ "maximize" ];
          configFile.kwinrc = {
            testgroup.testkey = "testvalue";
            Plugins.somePluginEnabled = true;
            "org.kde.kdecoration2".ButtonsOnLeft = "MMM";
            Wayland.InputMethod = "/run/current-system/sw/share/applications/com.github.maliit.keyboard.desktop";
          };
          configFile.kglobalshortcutsrc."services/firefox.desktop".foo = "bar";
          configFile.kdeglobals = {
            group = {
              " leading space" = " leading space";
              key1 = 1;
              key2 = {
                value = 2;
                immutable = true;
              };
              "escaped[$i]" = {
                value = "\${HOME}";
                shellExpand = true;
              };
            };
            "escaped\\/nested/group" = {
              key3 = 3;
            };
          };
          configFile.foobarrc.somegroup.somekey = "somevalue";
        };
        home.activation.preseed = lib.hm.dag.entryBefore [ "configure-plasma" ] ''
          mkdir -p ~/.config
          cat <<EOF >> ~/.config/kdeglobals
          [escaped/nested][group]
          untouched = \svalue
          EOF
          cat <<EOF >> ~/.config/plasma-org.kde.plasma.desktop-appletsrc
          [Containments][1]
          plugin=org.kde.plasma.folder
          placementMode=0

          [Containments][3]
          activityId=50d0a4c1-8b2f-4c6a-9f0e-2d3c4b5a6e7f
          plugin=org.kde.plasma.folder
          placementMode=0

          [Containments][26]
          plugin=org.kde.plasma.panel

          [Containments][26][AppletSystemTray]
          HiddenIconsButtonState = visible
          EOF
        '';
      };

    # A user without a session yet has no layout file: the option must not
    # create a stub layout, or the shell would load it instead of the
    # default layout on first start.
    home-manager.users.fresh =
      { lib, ... }:
      {
        home.stateVersion = "23.11";
        programs.plasma = {
          enable = true;
          desktop.wallpaperOnly = true;
        };
      };
  };

  testScript = ''
    # Boot:
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("nix-daemon.socket")

    machine.wait_until_succeeds(
        "systemctl show -p ActiveState --value home-manager-fake.service | grep -q 'inactive' && " +
        "systemctl show -p Result --value home-manager-fake.service | grep -q 'success'"
    , 10)

    # Run tests:
    machine.succeed("test -e /home/fake/.config/kdeglobals")
    machine.succeed("test -e /home/fake/.config/kwinrc")
    machine.succeed("test -e /home/fake/.config/kglobalshortcutsrc")
    machine.succeed("test -e /home/fake/.config/foobarrc")
    machine.succeed("su - fake -c plasma-basic-test")

    # The fresh user got no stub layout file
    machine.wait_until_succeeds(
        "systemctl show -p ActiveState --value home-manager-fresh.service | grep -q 'inactive' && " +
        "systemctl show -p Result --value home-manager-fresh.service | grep -q 'success'"
    , 10)
    machine.fail("test -e /home/fresh/.config/plasma-org.kde.plasma.desktop-appletsrc")
  '';
}
