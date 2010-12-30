# Updating the gemspec
#   ruby -e 'Dir["spec/*"].each { |fn| puts "\"#{fn}\," }'

PLUGIN = "relaxdb"
NAME = "relaxdb"
GEM_VERSION = "0.5.3"
AUTHOR = "Paul Carey"
EMAIL = "paul.p.carey@gmail.com"
HOMEPAGE = "http://github.com/paulcarey/relaxdb/"
SUMMARY = "RelaxDB provides a simple interface to CouchDB"

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.textile", "LICENSE"]
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  
  s.add_dependency "extlib", "~> 0.9.4"
  
  s.require_path = 'lib'
  s.autorequire = PLUGIN
  s.files = %w(LICENSE README.textile readme.rb Rakefile) + Dir.glob("{docs,lib,spec}/**/*")
end


