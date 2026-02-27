# Puma configuration for Hatchbox deployment
#
# Hatchbox uses systemd socket activation (LISTEN_FDS).
# When present, Puma inherits the socket instead of binding its own.

if ENV["LISTEN_FDS"]
  bind "inherited://"
else
  port ENV.fetch("PORT", 3000)
end

environment ENV.fetch("RAILS_ENV", "development")

threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads 0, threads_count
