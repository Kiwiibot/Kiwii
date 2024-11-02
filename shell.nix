{ pkgs ? import <nixpkgs> {} }:


pkgs.mkShell {
  name = "kiwii";

  buildInputs = with pkgs; [
    jdk22
    dart
  ];

  shellHook = ''
    # Set Java environment variables
    export JAVA_HOME=${pkgs.openjdk21.home}
    export PATH=$JAVA_HOME/bin:$PATH
    export PATH="$PATH:${pkgs.dart}/bin"
  '';
}
