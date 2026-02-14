 # Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixoshi"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.

  programs.hyprland = {
    enable = true;
    withUWSM = true; # recommended for most users
    xwayland.enable = true; # Xwayland can be disabled.
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; 
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting untuk tampilan clean
      
      # Add npm global bin to PATH for Gemini CLI
      fish_add_path ~/.npm-global/bin
      
      # Tide prompt configuration
      set -g tide_prompt_icon_connection ' '
      set -g tide_left_prompt_items pwd git
      set -g tide_right_prompt_items status cmd_duration context jobs time
      set -g tide_cmd_duration_threshold 3000  # Show cmd duration if >3s (fix error)
    '';
  };
    
  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nashiru = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.fish; 
    packages = with pkgs; [
      tree
    ];
  };
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    neovim
    kitty
    foot
    git
    gh                       # GitHub CLI for GitHub operations
    openssh                  # SSH client for GitHub authentication
    curl
    pavucontrol
    wmenu
    wl-clipboard
    grim
    slurp
    swaybg
    nautilus
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    mangohud
    steam-run
    protonup-qt
    rofi
    brightnessctl
    playerctl
    wireplumber
    zoom-us
    feishin
    polkit_gnome
    pear-desktop
    antigravity
    davinci-resolve
    
    nodejs_22                # Node.js runtime
    nodePackages.npm         # npm package manager
    
    # Fish shell plugins - Professional setup
    fzf                      # Fuzzy finder (dependency for fzf-fish)
    fishPlugins.fzf-fish     # MUST HAVE: Fuzzy search files, history, git
    fishPlugins.tide         # Beautiful & modern prompt theme
    fishPlugins.forgit       # Interactive git commands
    fishPlugins.grc          # Colorize command output
    grc                      # Dependency for fishPlugins.grc
    fishPlugins.autopair     # Auto-close brackets, quotes
    fishPlugins.puffer       # Text expansion snippets
  ];
  
  programs.gpu-screen-recorder.enable = true;

  # Fonts - Comprehensive setup for icons/symbols
  fonts = {
    packages = with pkgs; [
      # Nerd Fonts - Icons & Symbols
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.symbols-only
      
      # Modern UI fonts
      inter
      roboto
      roboto-slab
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      
      # Icon fonts
      font-awesome
      material-design-icons
    ];
    
    # Font configuration untuk prioritas
    fontconfig = {
      defaultFonts = {
        serif = [ "Roboto" "Noto Fonts Emoji" ];
        sansSerif = [ "Inter" "Roboto" "Noto Fonts Emoji" ];
        monospace = [ "JetBrainsMono Nerd Font" "Noto Fonts Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

  nixpkgs.config.allowUnfree = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;  # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server hosting
    gamescopeSession.enable = true;
  };
    programs.gamemode.enable = true;
  
  
  services.tailscale = {
    enable = true;
    # Opsional: Kalau mau pakai Exit Node, bisa set ke "client" atau "both"
    useRoutingFeatures = "client"; 
  };
  networking.firewall = {
    enable = true;
  trustedInterfaces = [ "tailscale0" ];
  allowedUDPPorts = [ config.services.tailscale.port ];
  checkReversePath = "loose";
  };
  systemd.network.wait-online.enable = false;  

  # Enable polkit
  security.polkit.enable = true;
  
  # Enable SSH agent for GitHub authentication
  programs.ssh.startAgent = true;
  
  hardware.graphics = {
    enable = true;
  };
}

