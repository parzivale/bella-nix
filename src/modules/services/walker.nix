{inputs, ...}: {
  flake.modules.nixos.walker = {config, ...}: let
    user = config.systemConstants.username;
  in {
    nix.settings = {
      extra-substituters = ["https://walker.cachix.org" "https://walker-git.cachix.org"];
      extra-trusted-public-keys = ["walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM=" "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="];
    };

    home-manager.users.${user} = {
      config,
      pkgs,
      ...
    }: {
      imports = [inputs.walker.homeManagerModules.default];
      niri.settings.binds = {
        "Mod+Space".action.spawn = [
          "${pkgs.netcat}/bin/nc"
          "-U"
          "/run/user/1000/walker/walker.sock"
        ];
      };
      programs = {
        elephant = {
          desktopapplications = {
            "qt5ct.desktop" = {
              hidden = true;
            };
            "qt6ct.desktop" = {
              hidden = true;
            };
            "nvidia-settings.desktop" = {
              hidden = true;
            };
            "kvantummanager.desktop" = {
              hidden = true;
            };
          };
        };
        walker = {
          enable = true;
          runAsService = true;
          config = {
            actions_as_menu = false;
            as_window = false;
            autoplay_videos = false;
            click_to_close = true;
            close_when_open = true;
            debug = false;
            disable_mouse = false;
            exact_search_prefix = "'";
            force_keyboard_focus = false;
            global_argument_delimiter = "#";
            hide_action_hints = false;
            hide_action_hints_dmenu = true;
            hide_quick_activation = false;
            hide_return_action = false;
            page_jump_items = 10;
            resume_last_query = false;
            selection_wrap = false;
            single_click_activation = true;
            theme = "default";

            columns.symbols = 3;

            keybinds = {
              close = ["Escape"];
              down = ["Down"];
              left = ["Left"];
              next = ["Down"];
              page_down = ["Page_Down"];
              page_up = ["Page_Up"];
              previous = ["Up"];
              quick_activate = ["F1" "F2" "F3" "F4"];
              resume_last_query = ["ctrl r"];
              right = ["Right"];
              show_actions = ["alt j"];
              toggle_exact = ["ctrl e"];
              up = ["Up"];
            };

            placeholders.default = {
              input = "Search";
              list = "No Results";
            };

            providers = {
              default = ["desktopapplications" "calc" "websearch"];
              empty = ["desktopapplications"];
              ignore_preview = [];
              max_results = 50;

              clipboard.time_format = "relative";

              prefixes = [
                {
                  prefix = ";";
                  provider = "providerlist";
                }
                {
                  prefix = ">";
                  provider = "runner";
                }
                {
                  prefix = "/";
                  provider = "files";
                }
                {
                  prefix = ".";
                  provider = "symbols";
                }
                {
                  prefix = "!";
                  provider = "todo";
                }
                {
                  prefix = "%";
                  provider = "bookmarks";
                }
                {
                  prefix = "=";
                  provider = "calc";
                }
                {
                  prefix = "@";
                  provider = "websearch";
                }
                {
                  prefix = ":";
                  provider = "clipboard";
                }
                {
                  prefix = "$";
                  provider = "windows";
                }
              ];

              actions = {
                bitwarden = [
                  {
                    action = "copypassword";
                    bind = "Return";
                    default = true;
                    label = "copy password";
                  }
                  {
                    action = "typepassword";
                    bind = "ctrl p";
                    default = true;
                    label = "type password";
                  }
                  {
                    action = "copyusername";
                    bind = "shift Return";
                    label = "copy username";
                  }
                  {
                    action = "typeusername";
                    bind = "ctrl u";
                    label = "type username";
                  }
                  {
                    action = "copyotp";
                    bind = "ctrl Return";
                    label = "copy 2fa";
                  }
                  {
                    action = "typeotp";
                    bind = "ctrl t";
                    label = "type 2fa";
                  }
                  {
                    action = "syncvault";
                    bind = "ctrl s";
                    label = "sync";
                  }
                ];

                clipboard = [
                  {
                    action = "copy";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "remove";
                    after = "AsyncClearReload";
                    bind = "ctrl d";
                  }
                  {
                    action = "remove_all";
                    after = "AsyncClearReload";
                    bind = "ctrl shift d";
                    label = "clear";
                  }
                  {
                    action = "show_images_only";
                    after = "AsyncClearReload";
                    bind = "ctrl i";
                    label = "only images";
                  }
                  {
                    action = "show_text_only";
                    after = "AsyncClearReload";
                    bind = "ctrl i";
                    label = "only text";
                  }
                  {
                    action = "show_combined";
                    after = "AsyncClearReload";
                    bind = "ctrl i";
                    label = "show all";
                  }
                  {
                    action = "pause";
                    bind = "ctrl shift p";
                  }
                  {
                    action = "unpause";
                    bind = "ctrl shift p";
                  }
                  {
                    action = "unpin";
                    after = "AsyncClearReload";
                    bind = "ctrl p";
                  }
                  {
                    action = "pin";
                    after = "AsyncClearReload";
                    bind = "ctrl p";
                  }
                  {
                    action = "edit";
                    bind = "ctrl o";
                  }
                  {
                    action = "localsend";
                    bind = "ctrl l";
                  }
                ];

                desktopapplications = [
                  {
                    action = "start";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "start:keep";
                    after = "KeepOpen";
                    bind = "shift Return";
                    label = "open+next";
                  }
                  {
                    action = "new_instance";
                    bind = "ctrl Return";
                    label = "new instance";
                  }
                  {
                    action = "new_instance:keep";
                    after = "KeepOpen";
                    bind = "ctrl alt Return";
                    label = "new+next";
                  }
                  {
                    action = "pin";
                    after = "AsyncReload";
                    bind = "ctrl p";
                  }
                  {
                    action = "unpin";
                    after = "AsyncReload";
                    bind = "ctrl p";
                  }
                  {
                    action = "pinup";
                    after = "AsyncReload";
                    bind = "ctrl n";
                  }
                  {
                    action = "pindown";
                    after = "AsyncReload";
                    bind = "ctrl m";
                  }
                ];

                calc = [
                  {
                    action = "copy";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "delete";
                    after = "AsyncReload";
                    bind = "ctrl d";
                  }
                  {
                    action = "delete_all";
                    after = "AsyncReload";
                    bind = "ctrl shift d";
                  }
                  {
                    action = "save";
                    after = "AsyncClearReload";
                    bind = "ctrl s";
                  }
                ];

                files = [
                  {
                    action = "open";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "opendir";
                    bind = "ctrl Return";
                    label = "open dir";
                  }
                  {
                    action = "copypath";
                    bind = "ctrl shift c";
                    label = "copy path";
                  }
                  {
                    action = "copyfile";
                    bind = "ctrl c";
                    label = "copy file";
                  }
                  {
                    action = "localsend";
                    bind = "ctrl l";
                    label = "localsend";
                  }
                  {
                    action = "refresh_index";
                    after = "AsyncReload";
                    bind = "ctrl r";
                    label = "reload";
                  }
                ];

                runner = [
                  {
                    action = "run";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "runterminal";
                    bind = "shift Return";
                    label = "run in terminal";
                  }
                ];

                websearch = [
                  {
                    action = "search";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "open_url";
                    bind = "Return";
                    default = true;
                    label = "open url";
                  }
                ];

                niriactions = [
                  {
                    action = "execute";
                    bind = "Return";
                  }
                ];

                nirisessions = [
                  {
                    action = "start";
                    bind = "Return";
                    default = true;
                    label = "start";
                  }
                  {
                    action = "start_new";
                    bind = "ctrl Return";
                    label = "start blank";
                  }
                ];

                symbols = [
                  {
                    action = "run_cmd";
                    bind = "Return";
                    default = true;
                    label = "select";
                  }
                ];

                todo = [
                  {
                    action = "save";
                    after = "AsyncClearReload";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "save_next";
                    after = "AsyncClearReload";
                    bind = "shift Return";
                    label = "save & new";
                  }
                  {
                    action = "delete";
                    after = "AsyncClearReload";
                    bind = "ctrl d";
                  }
                  {
                    action = "active";
                    after = "Nothing";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "inactive";
                    after = "Nothing";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "done";
                    after = "Nothing";
                    bind = "ctrl f";
                  }
                  {
                    action = "change_category";
                    after = "Nothing";
                    bind = "ctrl y";
                    label = "change category";
                  }
                  {
                    action = "clear";
                    after = "AsyncClearReload";
                    bind = "ctrl x";
                  }
                  {
                    action = "create";
                    after = "AsyncClearReload";
                    bind = "ctrl a";
                  }
                  {
                    action = "search";
                    after = "AsyncClearReload";
                    bind = "ctrl a";
                  }
                ];

                bookmarks = [
                  {
                    action = "save";
                    after = "AsyncClearReload";
                    bind = "Return";
                  }
                  {
                    action = "open";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "delete";
                    after = "AsyncClearReload";
                    bind = "ctrl d";
                  }
                  {
                    action = "change_category";
                    after = "Nothing";
                    bind = "ctrl y";
                    label = "Change category";
                  }
                  {
                    action = "change_browser";
                    after = "Nothing";
                    bind = "ctrl b";
                    label = "Change browser";
                  }
                  {
                    action = "import";
                    after = "AsyncClearReload";
                    bind = "ctrl i";
                    label = "Import";
                  }
                  {
                    action = "create";
                    after = "AsyncClearReload";
                    bind = "ctrl a";
                  }
                  {
                    action = "search";
                    after = "AsyncClearReload";
                    bind = "ctrl a";
                  }
                ];

                bluetooth = [
                  {
                    action = "find";
                    after = "AsyncClearReload";
                    bind = "ctrl f";
                  }
                  {
                    action = "remove";
                    after = "AsyncReload";
                    bind = "ctrl d";
                  }
                  {
                    action = "trust";
                    after = "AsyncReload";
                    bind = "ctrl t";
                  }
                  {
                    action = "untrust";
                    after = "AsyncReload";
                    bind = "ctrl t";
                  }
                  {
                    action = "pair";
                    after = "AsyncReload";
                    bind = "Return";
                  }
                  {
                    action = "connect";
                    after = "AsyncReload";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "disconnect";
                    after = "AsyncReload";
                    bind = "Return";
                    default = true;
                  }
                  {
                    action = "power_on";
                    after = "AsyncReload";
                    bind = "ctrl e";
                    label = "Power On";
                  }
                  {
                    action = "power_off";
                    after = "AsyncReload";
                    bind = "ctrl e";
                    label = "Power Off";
                  }
                ];

                "1password" = [
                  {
                    action = "copy_password";
                    bind = "Return";
                    default = true;
                    label = "copy password";
                  }
                  {
                    action = "copy_username";
                    bind = "shift Return";
                    label = "copy username";
                  }
                  {
                    action = "copy_2fa";
                    bind = "ctrl Return";
                    label = "copy 2fa";
                  }
                ];

                fallback = [
                  {
                    action = "menus:open";
                    after = "Nothing";
                    label = "open";
                  }
                  {
                    action = "menus:default";
                    after = "Close";
                    label = "run";
                  }
                  {
                    action = "menus:parent";
                    after = "Nothing";
                    bind = "Escape";
                    label = "back";
                  }
                  {
                    action = "erase_history";
                    after = "AsyncReload";
                    bind = "ctrl h";
                    label = "clear hist";
                  }
                ];

                dmenu = [
                  {
                    action = "select";
                    bind = "Return";
                    default = true;
                  }
                ];

                providerlist = [
                  {
                    action = "activate";
                    after = "ClearReload";
                    bind = "Return";
                    default = true;
                  }
                ];

                unicode = [
                  {
                    action = "run_cmd";
                    bind = "Return";
                    default = true;
                    label = "select";
                  }
                ];
              };
            };

            shell = {
              anchor_bottom = true;
              anchor_left = true;
              anchor_right = true;
              anchor_top = true;
              layer = "overlay";
            };
          };
          theme = "default";
        };
      };
    };
  };
}
