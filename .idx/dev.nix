{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-23.11"; # Or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.flutter
    pkgs.dart
  ];
  # Sets environment variables in the workspace
  env = {};
  # Fast way to run commands without creating a full environment
  scripts = {
    "hello" = {
      "exec" = "echo "Hello world"";
    };
  };

  # IDE Support
  idx.previews = {
    enable = true;
    previews = [
      {
        # Example of running a command that serves a website
        command = "flutter run -d web-server --web-port $PORT --web-hostname 0.0.0.0";
        manager = "flutter";
      }
    ];
  };

  # Used by `nix generate-dev-file` to generate a development environment file
  idx.devcontainer = {
    name = "Flutter";
    image = "ubuntu:22.04";
  };
}