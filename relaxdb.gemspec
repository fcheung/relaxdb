# Updating the gemspec
#   ruby -e 'Dir["spec/*"].each { |fn| puts "\"#{fn}\," }'

spec = Gem::Specification.new do |s|
  s.name = "relaxdb"
  s.version = "0.5.3"
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.textile", "LICENSE"]
  s.summary = "RelaxDB provides a simple interface to CouchDB"
  s.description = s.summary
  s.author = "Paul Carey"
  s.email = "paul.p.carey@gmail.com"
  s.homepage = "http://github.com/paulcarey/relaxdb/"
  
  s.add_dependency "extlib", "~> 0.9.4"
  
  s.require_path = 'lib'
  s.autorequire = 'relaxdb'
  s.files = %w(LICENSE README.textile readme.rb Rakefile) + Dir.glob("{docs,lib,spec}/**/*")
end


