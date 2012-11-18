# Statsagent

Statsagent is a ruby daemon that runs collectors in an EM defer threadpool. The
collector class collects metrics and retuns a Hash of key value pairs.
Statsagent dumps the metrics into graphite (carbon).

# Directory Structure

- statsagent
  | - Readme.txt - this document
  | - config.ru - Rack configuration used to run App
  | - config.yml - App configuration
  | - statsagent.rb - The application
  | - lib
    | - statsmanager.rb - Keeps track of loaded collectors
    | - collectors/base.rb - base collection logic
    | - collectors/* - collector plugins

# How To

1) Run bundle install
2) run bundle exec rackup
3) The app starts up and adds collectors configured in config.yml

## Adding a collector

The web API allows adding collectors

curl localhost:9293/add/<collector>/<type>/<interval>?<params>

## Collector API

Statsagent schedules the method with the same name as the 'type' parameter. The method returns a hash of key, value pairs containing metrics. The response is formatted and sent to graphite
