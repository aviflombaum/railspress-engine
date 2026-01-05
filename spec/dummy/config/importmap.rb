# Pin npm packages by running ./bin/importmap

pin "application"
pin "lexxy", to: "lexxy.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js"

# RailsPress controllers are auto-pinned by the engine's importmap.rb
