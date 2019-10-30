lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "davinci_threader/version"

Gem::Specification.new do |spec|
  spec.name          = "davinci_threader"
  spec.version       = DavinciThreader::VERSION
  spec.authors       = ["onlyexcellence"]
  spec.email         = ["will@wambl.com"]

  spec.summary       = %q{Thread Throttling}
  spec.description   = %q{Useful for APIs that limit requests}
  spec.homepage      = "https://github.com/onlyexcellence/davinci-theader"
  spec.license       = "MIT"

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
  #   `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # end
  spec.files         = Dir["{bin,lib}/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "awesome_print", "~> 1.8"

  spec.add_dependency "activesupport", "~> 5.1"
  spec.add_dependency "colorize", "~> 0.8.1"
end
