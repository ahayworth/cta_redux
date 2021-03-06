# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cta_redux/version'

Gem::Specification.new do |spec|
  spec.name          = "cta_redux"
  spec.version       = CTA::VERSION
  spec.authors       = ["Andrew Hayworth"]
  spec.email         = ["ahayworth@gmail.com"]
  spec.summary       = %q{A clean, integrated API for CTA BusTracker, TrainTracker, customer alerts, and GTFS data.}
  spec.description   = %q{cta_redux takes the data provided by the CTA in its various forms, and turns it into a clean,
                          cohesive client API that can be used to easily build a transit related project. Using Sequel,
                          we integrate GTFS scheduled service data with live data provided by the CTA's various APIs (like
                          BusTracker, TrainTracker, and the CTA customer alerts feed.}
  spec.homepage      = "http://ctaredux.ahayworth.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.extensions    = ["ext/inflate_database/extconf.rb"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # TODO - Support 1.8.7, I doubt it'll be that difficult.
  spec.required_ruby_version = ">= 1.9.3"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2.0"
  spec.add_development_dependency "yard", ">= 0.8.7.6"

  spec.add_dependency "sequel", ">= 4.19.0"
  spec.add_dependency "sqlite3", ">= 1.3.10"
  spec.add_dependency "faraday", ">= 0.9.1"
  spec.add_dependency "faraday_middleware", ">= 0.9.1"
  spec.add_dependency "multi_xml", ">= 0.5.5"
end
