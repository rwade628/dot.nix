# AI and machine learning services (Ollama, llama-swap, Wyoming, Qdrant)
{ pkgs, ... }:

{
  # --- Ollama ---
  # services.ollama = {
  #   enable = true;
  #   package = pkgs.ollama-cuda;
  #   host = "0.0.0.0";
  #   openFirewall = true;
  #   environmentVariables = {
  #     OLLAMA_KEEP_ALIVE = "1h";
  #   };
  # };

  # --- llama-swap Service ---
  # Transparent proxy for automatic model swapping with llama.cpp
  # GPT-OSS chat template directly from HuggingFace
  environment.etc."llama-templates/openai-gpt-oss-20b.jinja".source = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/gpt-oss-20b-GGUF/resolve/main/template";
    sha256 = "sha256-UUaKD9kBuoWITv/AV6Nh9t0z5LPJnq1F8mc9L9eaiUM=";
  };

  environment.etc."llama-templates/apriel-thinker.jinja".source = ./apriel-thinker.jinja;

  environment.etc."llama-swap/config.yaml".text = ''
    # llama-swap configuration
    # This config uses llama.cpp's server to serve models on demand

    models:  # Ordered from newest to oldest

      "Qwen3.6-35B-A3B-GGUF":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_M
          --fit on
          --fit-ctx 128000
          --fit-target 256
          -np 1
          -fa on
          --no-mmproj-offload
          --no-mmap
          --mlock
          -b 2048
          -ub 2048
          -ctk q8_0
          -ctv q8_0
          --temp 0.6
          --top-p 0.95
          --top-k 20
          --min-p 0.0
          --presence-penalty 0.0
          --repeat-penalty 1.0
          --reasoning-budget -1
          --chat-template-kwargs "{\"preserve_thinking\": true}"
          --port ''${PORT}

      "gemma-4-26B-A4B-it-GGUF":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/gemma-4-26B-A4B-it-GGUF:UD-IQ4_NL
          --ctx-size 32768
          --no-mmproj-offload
          --temp 0.2
          --top-p 0.95
          --top-k 64
          --cache-type-k q8_0
          --cache-type-v q8_0
          --port ''${PORT}

      # unsloth/Qwen3.5-35B-A3B-GGUF - Fixed with scoring_func sigmoid metadata
      # General use: --temp 1.0 --top-p 0.95, Tool-calling: --temp 0.7 --top-p 1.0
      "Qwen3.5-35B-A3B-GGUF":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_XL
          --port ''${PORT}
          --ctx-size 100000
          --n-predict 32768
          --temp 0.6
          --top-p 0.95
          --top-k 20
          --min-p 0.00
          --presence-penalty 0.0
          --repeat-penalty 1.0
          --jinja

      # GLM-4.7-Flash - Fixed with scoring_func sigmoid metadata
      # General use: --temp 1.0 --top-p 0.95, Tool-calling: --temp 0.7 --top-p 1.0
      "glm-4.7-flash:q4":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/GLM-4.7-Flash-GGUF:UD-Q4_K_XL
          --port ''${PORT}
          --ctx-size 100000
          --temp 0.7
          --top-p 1.0
          --min-p 0.01
          --repeat-penalty 1.0
          --cache-type-k q4_0
          --cache-type-k q4_0
          --threads 8
          --jinja

    healthCheckTimeout: 28800  # 8 hours for large model download + loading

    # TTL keeps models in memory for specified seconds after last use
    ttl: 3600  # Keep models loaded for 1 hour (like OLLAMA_KEEP_ALIVE)

    # Groups allow running multiple models simultaneously
    groups:
      embedding:
        # Keep embedding model always loaded alongside any other model
        persistent: true  # Prevents other groups from unloading this
        swap: false       # Don't swap models within this group
        exclusive: false  # Don't unload other groups when loading this
        members:
          - "embeddinggemma:300m"
  '';

  systemd.services.llama-swap = {
    description = "llama-swap - OpenAI compatible proxy with automatic model swapping";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "ryan";
      Group = "users";
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config /etc/llama-swap/config.yaml --listen 0.0.0.0:9292 --watch-config";
      Restart = "always";
      RestartSec = 10;
      # Environment for CUDA support
      Environment = [
        "PATH=/run/current-system/sw/bin"
        "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib"
        # llama-swap can use both GPUs (0,1), but Ollama is restricted to GPU 0
      ];
      # Environment needs access to cache directories for model downloads
      # Simplified security settings to avoid namespace issues
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  # --- Qdrant Vector Database ---
  services.qdrant = {
    enable = true;
    settings = {
      storage = {
        storage_path = "/var/lib/qdrant/storage";
        snapshots_path = "/var/lib/qdrant/snapshots";
      };
      service = {
        host = "0.0.0.0";
        http_port = 6333;
      };
      telemetry_disabled = true;
    };
  };
}
