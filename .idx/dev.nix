{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-23.11"; # Or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.flutter
    pkgs.dart
    pkgs.chromium
    pkgs.webkitgtk
    pkgs.clang
    pkgs.cmake
    pkgs.ninja
    pkgs.pkg-config
    pkgs.firebase-tools
  ];
  # Sets environment variables in the workspace
  env = {
    CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
  };

  # IDE Support
  idx.previews = {
    enable = true;
    previews = [
      {
        command = [
          "flutter"
          "run"
          "-d"
          "chrome"
          "--web-port"
          "8080"
          "--web-hostname"
          "0.0.0.0"
        ];
        manager = "flutter";
      }
    ];
  };

  # Firebase Genkit
  idx.genkit = {
    enable = true;
  };

  # Enable the mcp server
  idx.mcp.enable = true;
}