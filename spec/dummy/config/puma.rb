port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")
threads 0, ENV.fetch("RAILS_MAX_THREADS", 2).to_i
