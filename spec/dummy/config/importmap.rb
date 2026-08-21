# Pin npm packages by running ./bin/importmap

pin "application"
pin "@rails/activestorage", to: "activestorage.esm.js"

# Stimulus and RailsPress controllers are auto-pinned by the engine's importmap.rb
