# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rollbacker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Marcos G. Zimmermann"]
  gem.email         = ["mgzmaster@gmail.com"]
  gem.homepage      = "http://github.com/marcosgz/rollbacker"
  gem.name          = "rollbacker"
  gem.summary       = %q{Rollbacker is a manage tool for auditing changes to your ActiveRecord}
  gem.description   = %q{Rollbacker allows you to declaratively specify what CRUD operations should be audited. The changes of objects are added to a queue where the auditor can approve and reject those changes.}
  gem.version       = Rollbacker::VERSION

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

  gem.add_dependency('activerecord', '>= 3.0')

  gem.add_development_dependency('rspec')
  gem.add_development_dependency('sqlite3-ruby')
end
