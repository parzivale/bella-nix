{
  # What opens a file that is not a web page, which until now was nothing.
  #
  # Three separate things were missing and only the last of them is an association:
  # `xdg-utils` was not installed, so there was no `xdg-open` to dispatch with; no image or
  # video viewer was installed at all, so there was nothing to dispatch to; and
  # `~/.config/mimeapps.list` did not exist, so every `xdg-mime query default` answered
  # nothing. A PNG had no path to a window from any direction.
  #
  # The browser is the answer to the middle one. It is already here, it already renders
  # everything below, and a second application whose only job is to show a picture is a
  # package and a theme and a keybinding set to maintain. The cost is codecs: Firefox's
  # media support is the limit, so mp4 and webm play and Matroska, AVI and QuickTime
  # generally will not. If that becomes the thing that matters, `mpv` is the usual answer
  # and this list is where its share would be named.
  flake.modules.homeManager.zen =
    { pkgs, ... }:
    let
      # The entry zen-twilight ships. It declares only text/html, the XML family and the
      # http/https schemes in its own `MimeType=`, which is not a problem: `mimeapps.list`
      # is the user's statement about what handles what, and it is consulted ahead of
      # whatever a desktop file claims about itself.
      browser = "zen-twilight.desktop";

      types = [
        # what the renderer actually handles natively
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/avif"
        "image/svg+xml"
        "image/bmp"
        "image/x-icon"

        "video/mp4"
        "video/webm"
        "video/ogg"

        "audio/mpeg"
        "audio/ogg"
        "audio/wav"
        "audio/flac"

        # pdf.js, which is a better reader than most of the dedicated ones
        "application/pdf"

        # the ones it was already claiming, said here as well so that the file is the whole
        # answer rather than half of it
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    in
    {
      # `xdg-open` itself, which is the piece that reads everything below. Without it the
      # associations are a file nobody opens.
      home.packages = [ pkgs.xdg-utils ];

      xdg.mimeApps = {
        enable = true;

        # Worth knowing what `enable` does to the runtime: home-manager writes
        # ~/.config/mimeapps.list as a symlink into the store, so it is read-only. An
        # application offering to "set as default" then fails with a permissions error
        # rather than quietly rewriting it. That is the right trade on a machine configured
        # declaratively - the alternative is a file that drifts and is never noticed - but
        # it is a behaviour to expect rather than to be surprised by.
        defaultApplications = builtins.listToAttrs (
          map (t: {
            name = t;
            value = browser;
          }) types
        );
      };
    };
}
