{
  flake.modules.nixos.helix = {
    config,
    pkgs,
    ...
  }: let
    user = config.vars.username;
  in {
    home-manager.users.${user}.programs.helix = {
      enable = true;
      defaultEditor = true;
      extraPackages = with pkgs; [
        cargo
      ];
      settings = {
        editor = {
          bufferline = "multiple";
          statusline = {
            left = ["mode" "spinner" "register"];
            center = ["version-control" "spacer" "separator" "file-name"];
            right = [
              "diagnostics"
              "workspace-diagnostics"
              "position"
              "file-encoding"
              "file-line-ending"
              "file-type"
            ];
            separator = "|";
            mode.normal = "NORMAL";
            mode.insert = "INSERT";
            mode.select = "SELECT";
          };
          lsp.display-inlay-hints = true;
          whitespace.characters = {
            space = "·";
            nbsp = "⍽";
            nnbsp = "␣";
            tab = "→";
            newline = "⏎";
            tabpad = "·";
          };
          indent-guides = {
            render = true;
            character = "▏"; # Some characters that work well: "▏", "┆", "┊", "⸽"
            skip-levels = 1;
          };
        };
      };
      languages = {
        language = [
          {
            name = "rust";
            auto-format = true;
            language-servers = ["rust-analyzer" "harper-ls"];
            formatter = {
              command = "${pkgs.rustfmt}/bin/rustfmt";
            };
          }
          {
            name = "markdown";
            soft-wrap.enable = true;
            text-width = 80;
            soft-wrap.wrap-at-text-width = true;
            language-servers = ["marksman" "harper-ls"];
            formatter = {
              command = "${pkgs.prettier}/bin/prettier";
              args = ["--parser" "markdown"];
            };
            auto-format = true;
          }
          {
            name = "typescript";
            auto-format = true;
            language-servers = [
              {
                name = "typescript-language-server";
                except-features = ["format"];
              }
              "biome"
              "harper-ls"
            ];
          }
          {
            name = "javascript";
            auto-format = true;
            language-servers = [
              {
                name = "typescript-language-server";
                except-features = ["format"];
              }
              "biome"
              "harper-ls"
            ];
          }
          {
            name = "tsx";
            auto-format = true;
            language-servers = [
              {
                name = "typescript-language-server";
                except-features = ["format"];
              }
              "biome"
              "harper-ls"
            ];
          }
          {
            name = "jsx";
            auto-format = true;
            language-servers = [
              {
                name = "typescript-language-server";
                except-features = ["format"];
              }
              "biome"
              "harper-ls"
            ];
          }
          {
            name = "html";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettier}/bin/prettier";
              args = ["--parser" "html"];
            };
            language-servers = ["vscode-html-language-server" "harper-ls"];
          }
          {
            name = "css";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettier}/bin/prettier";
              args = ["--parser" "css"];
            };
            language-servers = ["vscode-css-language-server" "harper-ls"];
          }
          {
            name = "nix";
            auto-format = true;
            formatter = {
              command = "${pkgs.alejandra}/bin/alejandra";
            };
            language-servers = ["nil" "harper-ls"];
          }
          {
            name = "nu";
            auto-format = true;
            formatter = {
              command = "${pkgs.nufmt}/bin/nufmt";
              args = ["--stdin"];
            };
            language-servers = ["nu-lsp" "harper-ls"];
          }
        ];

        language-server = {
          rust-analyzer = {
            command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
            config = {
              check.command = "${pkgs.clippy}/bin/clippy";
              cargo.features = "all";
            };
          };
          harper-ls = {
            command = "${pkgs.harper}/bin/harper-ls";
            args = ["--stdio"];
          };
          marksman = {
            command = "${pkgs.marksman}/bin/marksman";
            args = ["server"];
          };
          typescript-language-server = {
            command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
            args = ["--stdio"];
            config.hostInfo = "helix";
          };
          biome = {
            command = "${pkgs.biome}/bin/biome";
            args = ["lsp-proxy"];
          };
          vscode-html-language-server = {
            command = "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server";
            args = ["--stdio"];
            config = {provideFormatter = true;};
          };
          vscode-css-language-server = {
            command = "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server";
            args = ["--stdio"];
            config = {
              provideFormatter = true;
              css = {validate = {enable = true;};};
            };
          };
          nil = {
            command = "${pkgs.nil}/bin/nil";
          };
          nu-lsp = {
            command = "${pkgs.nushell}/bin/nu";
            args = ["--lsp"];
          };
        };
      };
    };
  };
}
