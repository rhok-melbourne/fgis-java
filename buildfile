require 'buildr/git_auto_version'
require 'buildr/top_level_generate_dir'

download(artifact(:postgis_jdbc) => 'https://github.com/realityforge/repository/raw/master/org/postgis/postgis-jdbc/2.0.2SVN/postgis-jdbc-2.0.2SVN.jar')

desc 'FGIS: Fire Ground Information System'
define 'fgis' do
  project.group = 'org.realityforge.fgis'

  compile.options.source = '1.7'
  compile.options.target = '1.7'
  compile.options.lint = 'all'

  bootstrap_path = add_bootstrap_media(project)
  leaflet_path = add_leaflet_media(project)
  sass_path = define_process_sass_dir(project)
  coffee_script_path = define_coffee_script_dir(project)
  jquery_path = define_jquery_dir(project)

  assets = [bootstrap_path, leaflet_path, sass_path, coffee_script_path, jquery_path]

  desc 'Build assets'
  task 'assets' do
    assets.each do |asset|
      file(asset).invoke
    end
  end

  desc 'Generate assets and move them to idea artifact'
  task 'assets:artifact' => %w(assets) do
    target = _(:artifacts, project.name)
    mkdir_p target
    ([_(:source, :main, :webapp)] + assets).each do |asset|
      cp_r Dir["#{asset}/*"], "#{target}/"
    end
  end

  project.resources do
    task('assets').invoke
  end

  Domgen::GenerateTask.new(:FGIS,
                           "server",
                           [:ee],
                           _(:target, :generated, "domgen"),
                           project) do |t|
    t.description = 'Generates the Java code for the persistent objects'
    t.verbose = !!ENV['DEBUG_DOMGEN']
  end

  compile.with :javax_persistence,
               :javax_transaction,
               :eclipselink,
               :postgresql,
               :postgis_jdbc,
               :jts,
               :geolatte_geom,
               :ejb_api,
               :javaee_api,
               :javax_validation,
               :javax_annotation,
               :json,
               :jackson_core,
               :jackson_mapper,
               :javax_validation

  package(:war).tap do |war|
    assets.each do |asset|
      war.include asset, :as => '.'
    end
  end

  project.clean { rm_rf _(:artifacts) }
  project.clean { rm_rf _('.sass-cache') }

  iml.add_ejb_facet
  iml.add_jpa_facet
  iml.add_web_facet(:webroots => [_(:source, :main, :webapp)] + assets)
  iml.excluded_directories << _('.sass-cache')

  ipr.add_exploded_war_artifact(project,
                                :build_on_make => true,
                                :enable_ejb => true,
                                :enable_jpa => true,
                                :dependencies => [project,
                                                  :jts,
                                                  :geolatte_geom])
end
