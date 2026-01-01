# frozen_string_literal: true

# Grover is only available in development/CI (for OGP image generation)
# Production Docker builds exclude development gems, so skip this configuration
return unless defined?(Grover)

Grover.configure do |config|
  config.options = {
    viewport: {
      width: 1200,
      height: 630
    },
    emulate_media: "screen",
    cache: false,
    timeout: 30_000,
    launch_args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage",
      "--disable-gpu"
    ],
    executable_path: ENV.fetch("PUPPETEER_EXECUTABLE_PATH", nil)
  }
end
