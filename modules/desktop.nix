{ config, lib, pkgs, ... }:
let
  cfg = config.programs.plasma;

  widgets = import ./widgets { inherit lib; };

  setDesktopApplet = pkgs.writeShellApplication {
    name = "set_desktop_applet";
    runtimeInputs = [ pkgs.python3 ];
    text = "python ${../script/set_desktop_applet.py} \"$@\"";
  };

  desktopIconSortingModeId = {
    manual = -1;
    name = 0;
    size = 1;
    date = 2;
    type = 6;
  };

  mouseActions = {
    applicationLauncher = "org.kde.applauncher";
    contextMenu = "org.kde.contextmenu";
    paste = "org.kde.paste";
    switchActivity = "switchactivity";
    switchVirtualDesktop = "org.kde.switchdesktop";
    switchWindow = "switchwindow";
  };

  mouseActionNamesEnum = lib.types.enum (builtins.attrNames mouseActions);

  # Becomes true if any option under "cfg.desktop.icons" is set to something other than null.
  anyDesktopFolderSettingsSet =
    let
      recurse =
        l: lib.any (v: if builtins.isAttrs v then recurse v else v != null) (builtins.attrValues l);
    in
    recurse cfg.desktop.icons;

  # Becomes true if any option under "cfg.desktop.mouseActions" is set to something other than null.
  anyDesktopMouseActionsSet = lib.any (v: v != null) (builtins.attrValues cfg.desktop.mouseActions);
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "icons"
        "arrangement"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "icons"
        "arrangement"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "icons"
        "alignment"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "icons"
        "alignment"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "icons"
        "lockInPlace"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "icons"
        "lockInPlace"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "icons"
        "sorting"
        "mode"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "icons"
        "sorting"
        "mode"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "icons"
        "sorting"
        "descending"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "icons"
        "sorting"
        "descending"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "icons"
        "sorting"
        "foldersFirst"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "icons"
        "sorting"
        "foldersFirst"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "icons"
        "size"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "icons"
        "size"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "icons"
        "folderPreviewPopups"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "icons"
        "folderPreviewPopups"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "icons"
        "previewPlugins"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "icons"
        "previewPlugins"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "mouseActions"
        "leftClick"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "mouseActions"
        "leftClick"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "mouseActions"
        "middleClick"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "mouseActions"
        "middleClick"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "mouseActions"
        "rightClick"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "mouseActions"
        "rightClick"
      ]
    )
    (lib.mkRenamedOptionModule
      [
        "programs"
        "plasma"
        "workspace"
        "desktop"
        "mouseActions"
        "verticalScroll"
      ]
      [
        "programs"
        "plasma"
        "desktop"
        "mouseActions"
        "verticalScroll"
      ]
    )
  ];

  options.programs.plasma.desktop = {
    icons = {
      arrangement = lib.mkOption {
        type =
          with lib.types;
          nullOr (enum [
            "leftToRight"
            "topToBottom"
          ]);
        default = null;
        example = "topToBottom";
        description = ''
          The direction in which desktop icons are to be arranged.
        '';
      };

      alignment = lib.mkOption {
        type =
          with lib.types;
          nullOr (enum [
            "left"
            "right"
          ]);
        default = null;
        example = "right";
        description = ''
          Whether to align the icons on the left (the default) or right
          side of the screen.
        '';
      };

      lockInPlace = lib.mkOption {
        type = with lib.types; nullOr bool;
        default = null;
        example = true;
        description = ''
          Locks the position of all desktop icons to the order and placement
          defined by `arrangement`, `alignment` and the `sorting` options,
          so they cannot be manually moved.
        '';
      };

      sorting = {
        mode = lib.mkOption {
          type = with lib.types; nullOr (enum (builtins.attrNames desktopIconSortingModeId));
          default = null;
          example = "type";
          description = ''
            Specifies the sort mode for the desktop icons. By default, they are
            sorted by `name`.
          '';
          apply = sortMode: if (sortMode == null) then null else desktopIconSortingModeId.${sortMode};
        };

        descending = lib.mkOption {
          type = with lib.types; nullOr bool;
          default = null;
          example = true;
          description = ''
            Reverses the sorting order if enabled. Sorting is ascending by default.
          '';
        };

        foldersFirst = lib.mkOption {
          type = with lib.types; nullOr bool;
          default = null;
          example = false;
          description = ''
            Folders are sorted separately from files by default. This means
            folders appear first, sorted, for example, ascending by name,
            followed by files, also sorted ascending by name.
            If this option is disabled, all items are sorted regardless
            of type.
          '';
        };
      };

      size = lib.mkOption {
        type = with lib.types; nullOr (ints.between 0 6);
        default = null;
        example = 2;
        description = ''
          The desktop icon size, which is normally configured via a slider
          with seven possible values ranging from small (`0`) to large (`6`).
          The fourth position (`3`) is the default.
        '';
      };

      folderPreviewPopups = lib.mkOption {
        type = with lib.types; nullOr bool;
        default = null;
        example = false;
        description = ''
          Enables the arrow button when hovering over a folder on the desktop
          which shows a preview popup of the folder’s contents.

          Enabled by default.
        '';
      };

      previewPlugins = lib.mkOption {
        type = with lib.types; nullOr (listOf str);
        default = null;
        example = [
          "audiothumbnail"
          "fontthumbnail"
        ];
        description = ''
          Configures the preview plugins used to preview desktop files and folders.
        '';
      };
    };

    mouseActions = {
      leftClick = lib.mkOption {
        type = lib.types.nullOr mouseActionNamesEnum;
        default = null;
        example = "appLauncher";
        description = "Action for a left mouse click on the desktop.";
        apply = value: if (value == null) then null else mouseActions.${value};
      };

      middleClick = lib.mkOption {
        type = lib.types.nullOr mouseActionNamesEnum;
        default = null;
        example = "switchWindow";
        description = "Action for a middle mouse click on the desktop.";
        apply = value: if (value == null) then null else mouseActions.${value};
      };

      rightClick = lib.mkOption {
        type = lib.types.nullOr mouseActionNamesEnum;
        default = null;
        example = "contextMenu";
        description = "Action for a right mouse click on the desktop.";
        apply = value: if (value == null) then null else mouseActions.${value};
      };

      verticalScroll = lib.mkOption {
        type = lib.types.nullOr mouseActionNamesEnum;
        default = null;
        example = "switchVirtualDesktop";
        description = "Action for scrolling (vertically) while hovering over the desktop.";
        apply = value: if (value == null) then null else mouseActions.${value};
      };
    };

    wallpaperOnly = lib.mkOption {
      type = with lib.types; nullOr bool;
      default = null;
      example = true;
      description = ''
        Selects the applet which renders the desktop. When `true`, the
        "Desktop" applet (`org.kde.desktopcontainment`) is used, leaving a
        clean layout with no icons (the contents of the Desktop directory
        are not shown). When `false`, the "Folder View" applet
        (`org.kde.plasma.folder`) is used, which displays the contents of
        the Desktop directory as icons. When `null` (the default), the
        current desktop applet is kept.

        At activation time, the saved Plasma layout is scanned and the
        `plugin` of every desktop containment (i.e. the desktops of all
        activities) is set accordingly; it takes effect when the session
        (re)loads the layout, e.g. at login. Sections for panels, widgets
        and other applets are left untouched. The layout file must already
        exist (it is created by the running shell): a user without a
        session yet is unaffected and the shell loads its default layout
        on first start. In-session changes by the user (System Settings)
        set the applet back on the next hm activation, as with any
        managed setting.
      '';
    };

    widgets = lib.mkOption {
      type = with lib.types; nullOr (listOf widgets.desktopType);
      default = null;
      example = [
        {
          name = "org.kde.plasma.digitalclock";
          position = {
            horizontal = 51;
            vertical = 100;
          };
          size = {
            width = 250;
            height = 250;
          };
          config.Appearance.showDate = false;
        }
        {
          plasmusicToolbar = {
            position = {
              horizontal = 51;
              vertical = 300;
            };
            size = {
              width = 250;
              height = 400;
            };
            background = "transparentShadow";
          };
        }
      ];
      description = ''
        A list of widgets to be added to the desktop.
      '';
      apply = option: if option == null then null else (map widgets.desktopConvert option);
    };
  };

  config = (
    lib.mkIf cfg.enable {
      programs.plasma.startup = {
        desktopScript."set_desktop_folder_settings" = (
          lib.mkIf anyDesktopFolderSettingsSet {
            text = ''
              // Desktop folder settings
              let allDesktops = desktops();
              for (const desktop of allDesktops) {
                desktop.currentConfigGroup = ["General"];
                ${
                  lib.optionalString (
                    cfg.desktop.icons.arrangement == "topToBottom"
                  ) ''desktop.writeConfig("arrangement", 1);''
                }
                ${
                  lib.optionalString (cfg.desktop.icons.alignment == "right") ''desktop.writeConfig("alignment", 1);''
                }
                ${
                  lib.optionalString (cfg.desktop.icons.lockInPlace == true) ''desktop.writeConfig("locked", true);''
                }
                ${widgets.lib.stringIfNotNull cfg.desktop.icons.size ''desktop.writeConfig("iconSize", ${builtins.toString cfg.desktop.icons.size});''}
                ${
                  lib.optionalString (
                    cfg.desktop.icons.folderPreviewPopups == false
                  ) ''desktop.writeConfig("popups", false);''
                }
                ${widgets.lib.stringIfNotNull cfg.desktop.icons.previewPlugins ''desktop.writeConfig("previewPlugins", "${lib.strings.concatStringsSep "," cfg.desktop.icons.previewPlugins}");''}
                ${widgets.lib.stringIfNotNull cfg.desktop.icons.sorting.mode ''desktop.writeConfig("sortMode", ${builtins.toString cfg.desktop.icons.sorting.mode});''}
                ${
                  lib.optionalString (
                    cfg.desktop.icons.sorting.descending == true
                  ) ''desktop.writeConfig("sortDesc", true);''
                }
                ${
                  lib.optionalString (
                    cfg.desktop.icons.sorting.foldersFirst == false
                  ) ''desktop.writeConfig("sortDirsFirst", false);''
                }
              }
            '';
            priority = 3;
          }
        );

        desktopScript."set_desktop_mouse_actions" = (
          lib.mkIf anyDesktopMouseActionsSet {
            text = ''
              // Mouse actions
              let configFile = ConfigFile('plasma-org.kde.plasma.desktop-appletsrc');
              configFile.group = 'ActionPlugins';
              // References the section [ActionPlugins][0].
              let actionPluginSubSection = ConfigFile(configFile, 0)
              ${widgets.lib.stringIfNotNull cfg.desktop.mouseActions.leftClick ''actionPluginSubSection.writeEntry("LeftButton;NoModifier", "${cfg.desktop.mouseActions.leftClick}");''}
              ${widgets.lib.stringIfNotNull cfg.desktop.mouseActions.middleClick ''actionPluginSubSection.writeEntry("MiddleButton;NoModifier", "${cfg.desktop.mouseActions.middleClick}");''}
              ${widgets.lib.stringIfNotNull cfg.desktop.mouseActions.rightClick ''actionPluginSubSection.writeEntry("RightButton;NoModifier", "${cfg.desktop.mouseActions.rightClick}");''}
              ${widgets.lib.stringIfNotNull cfg.desktop.mouseActions.verticalScroll ''actionPluginSubSection.writeEntry("wheel:Vertical;NoModifier", "${cfg.desktop.mouseActions.verticalScroll}");''}
            '';
            priority = 3;
            restartServices = [ "plasma-plasmashell" ];
          }
        );

        desktopScript."set_desktop_widgets" = (
          lib.mkIf (cfg.desktop.widgets != null) {
            text = ''
              // Desktop widgets
              let allDesktops = desktops();

              // Remove all desktop widgets
              allDesktops.forEach((desktop) => {
                desktop.widgets().forEach((widget) => {
                  widget.remove();
                });
              });

              ${widgets.lib.addDesktopWidgetStmts "desktopWidgets" cfg.desktop.widgets}
            '';
            priority = 2;
          }
        );
      };

      # The saved layout is scanned at activation time and the `plugin` of
      # every desktop containment (i.e. the desktops of all activities) is
      # updated; sections for panels, widgets and other applets are left
      # untouched. Independent of the desktop scripts, so it cannot race
      # with the loading of the desktops. The layout file must already
      # exist (it is created by the running shell); if it does not, nothing
      # is written and the shell loads its default layout on first start.
      home.activation."set-desktop-applet" =
        lib.mkIf (cfg.desktop.wallpaperOnly != null) (
          let
            targetPlugin = if cfg.desktop.wallpaperOnly then "org.kde.desktopcontainment" else "org.kde.plasma.folder";
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD ${setDesktopApplet}/bin/set_desktop_applet "${config.xdg.configHome}/plasma-org.kde.plasma.desktop-appletsrc" "${targetPlugin}"
          ''
        );
    }
  );
}
