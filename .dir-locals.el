((nix-mode
  (eglot-workspace-configuration
   (:nixd :options (:nixpkgs (:expr "import ./. {config={allowUnfree=true;};}"))))))
