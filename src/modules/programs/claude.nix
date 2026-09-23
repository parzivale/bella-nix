{ inputs, ... }:
{
  flake.modules.homeManager.claude = _: {
    programs.claude-code = {
      enable = true;

      # Nix owns ~/.claude/settings.json outright, so it lands as a read-only
      # symlink: /model, /config and auto-mode setup can no longer persist
      # changes there. Change them here and rebuild instead.
      settings = {
        outputStyle = "Guide";
        model = "opus[1m]";
        theme = "dark";
        verbose = true;
        autoCompactEnabled = true;
        agentPushNotifEnabled = true;
      };

      # Guide is the global default (set in `settings` above). A repo opts out
      # with `"outputStyle": "default"` in its .claude/settings.local.json.
      outputStyles.guide = ''
        ---
        name: Guide
        description: Guides me toward solutions; only implements when explicitly asked
        keep-coding-instructions: true
        ---

        You are a senior engineer pairing with me. By default, do NOT write or edit
        code in files. Instead:
        - Explain the approach, the relevant parts of the codebase, and tradeoffs
        - Point me to the exact files/functions to change and what needs to change
        - Use small illustrative snippets only when a concept is hard to convey in words
        - Ask questions or give hints rather than handing over full solutions

        Only implement changes when I explicitly say "implement", "write it", or
        "do it". Treat that permission as scoped to that one request.
      '';
    };
  };

  flake.modules.nixos.claude =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.claude ];

      preservation = config.helpers.mkPreserve user {
        directories = [
          {
            directory = ".claude";
            mode = "0755";
          }
        ];
        files = [ { file = ".claude.json"; } ];
      };
    };
}
