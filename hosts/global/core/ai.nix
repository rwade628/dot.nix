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

      # GLM-4.7-Flash - Fixed with scoring_func sigmoid metadata
      # General use: --temp 1.0 --top-p 0.95, Tool-calling: --temp 0.7 --top-p 1.0
      "glm-4.7-flash:q4":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf noctrex/GLM-4.7-Flash-MXFP4_MOE-GGUF:MXFP4_MOE \
          --port ''${PORT}
          --ctx-size 8192 \
          --n-gpu-layers 99 \
          --cache-type-k q4_0 \
          --cache-type-v q4_0 \
          --flash-attn \
          --no-cap-moe \
          --lookup-ngram-min 2 \
          --batch-size 2048
          --ubatch-size 512
          --threads 8 \
          --jinja

      # Uploaded 2025-12-10, size 13.5 GB, max ctx: 393216, layers: 40
      "devstral-2:24b-q4":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF:UD-Q4_K_XL
          --port ''${PORT}
          --ctx-size 65536
          --jinja

      # settings: https://www.reddit.com/r/LocalLLaMA/comments/1oo7kqy/comment/nn2dn8l/
      # settings: https://www.reddit.com/r/LocalLLaMA/comments/1n61mm7/comment/nc99fji/
      # question: https://www.reddit.com/r/LocalLLaMA/comments/1ow1v5i/help_whats_the_absolute_cheapest_build_to_run_oss/

      # Uploaded 2025-08-02, size 11.3 GB, max ctx: 131072, layers: 24
      "gpt-oss-high:20b":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf ggml-org/gpt-oss-20b-GGUF
          --port ''${PORT}
          --ctx-size 0
          --batch-size 4096
          --ubatch-size 2048
          --threads 1
          --chat-template-kwargs '{"reasoning_effort": "high"}'
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
