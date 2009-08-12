# Updating the gemspec
#   ruby -e 'Dir["spec/*"].each { |fn| puts "\"#{fn}\," }'

Gem::Specification.new do |s|
  s.name = "relaxdb"
  s.version = "0.3.3"
  s.date = "2009-05-27"
  s.summary = "RelaxDB provides a simple interface to CouchDB"
  s.email = "paul.p.carey@gmail.com"
  s.homepage = "http://github.com/paulcarey/relaxdb/"
  s.has_rdoc = false
  s.authors = ["Paul Carey"]
  s.files = ["LICENSE",
   "README.textile",
   "readme.rb",
   "Rakefile",
   "docs/spec_results.html",
   "lib/relaxdb",
   "lib/relaxdb/all_delegator.rb",
   "lib/relaxdb/belongs_to_proxy.rb",
   "lib/relaxdb/cache.rb",
   "lib/relaxdb/design_doc.rb",
   "lib/relaxdb/document.rb",
   "lib/relaxdb/extlib.rb",
   "lib/relaxdb/has_many_proxy.rb",
   "lib/relaxdb/has_one_proxy.rb",
   "lib/relaxdb/net_http_server.rb",
   "lib/relaxdb/memcache_store.rb",
   "lib/relaxdb/migration.rb",
   "lib/relaxdb/migration_version.rb",
   "lib/relaxdb/paginate_params.rb",
   "lib/relaxdb/paginator.rb",
   "lib/relaxdb/query.rb",
   "lib/relaxdb/references_many_proxy.rb",
   "lib/relaxdb/relaxdb.rb",
   "lib/relaxdb/server.rb",
   "lib/relaxdb/uuid_generator.rb",
   "lib/relaxdb/taf2_curb_server.rb",
   "lib/relaxdb/validators.rb",
   "lib/relaxdb/view_object.rb",
   "lib/relaxdb/view_result.rb",
   "lib/relaxdb/view_uploader.rb",
   "lib/relaxdb/views.rb",
   "lib/more/grapher.rb",
   "lib/relaxdb.rb",
   "lib/more/atomic_bulk_save_support.rb",
   "spec/belongs_to_spec.rb",
   "spec/callbacks_spec.rb",
   "spec/derived_properties_spec.rb",
   "spec/design_doc_spec.rb",
   "spec/doc_inheritable_spec.rb",
   "spec/document_spec.rb",
   "spec/has_many_spec.rb",
   "spec/has_one_spec.rb",
   "spec/migration_spec.rb",
   "spec/migration_version_spec.rb",
   "spec/paginate_params_spec.rb",
   "spec/paginate_spec.rb",
   "spec/query_spec.rb",
   "spec/references_many_spec.rb",
   "spec/relaxdb_spec.rb",
   "spec/server_spec.rb",
   "spec/spec.opts",
   "spec/spec_helper.rb",
   "spec/spec_models.rb",
   "spec/view_by_spec.rb",
   "spec/view_object_spec.rb",
   "spec/view_spec.rb"]
  s.bindir = "bin"
  s.autorequire = "relaxdb"
  s.add_dependency "extlib", ">= 0.9.4" # removed ", runtime" as was failing locally
  s.add_dependency "json", ">= 0" # removed ", runtime" as was failing locally
  s.add_dependency "uuid", ">= 0" # removed ", runtime" as was failing locally
  s.require_paths = ["lib"]
end
