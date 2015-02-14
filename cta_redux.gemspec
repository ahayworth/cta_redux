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
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2.0", ">= 3.2.0"
  spec.add_dependency "sequel", "~> 4.19.0", ">= 4.19.0"
  spec.add_dependency "sqlite3", "~> 1.3.10", ">= 1.13.0"
  spec.add_dependency "faraday", "~> 0.9.1"
  spec.add_dependency "faraday_middleware", "~> 0.9.1"
  spec.add_dependency "multi_xml", "~> 0.5.5"
end
