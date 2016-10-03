
require 'java_buildpack/component/versioned_dependency_component'
#require 'java_buildpack/container'
#require 'java_buildpack/container/tomcat/tomcat_utils'
require 'java_buildpack/logging/logger_factory'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for Tomcat Liferay support.
    class TomcatLiferaySupport < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Container

      # (see JavaBuildpack::Component::ModularComponent#command)
      def compile
        # super
        return unless supports?

        @logger.debug { "IN TomcatLiferaySupport::compile" }

        #Install the liferay WAR
        @logger.debug{ "Version::#{@droplet.sandbox}/webapps/ROOT/" }

        download_jar(war_name, "#{@droplet.sandbox}/webapps/ROOT/")
        
        deploy_liferay_war
        # Get the Portlets WAR and move them to auto deploy folder
        deploy_portlet_wars

        #Configure any bound MySQL DB
        configure_liferay_db

      end

      def release
      end

      protected


      # (see JavaBuildpack::Component::ModularComponent#supports?)
      def supports?
        @logger       = JavaBuildpack::Logging::LoggerFactory.instance.get_logger TomcatLiferaySupport
        true
        #@application.services.one_service? FILTER, KEY_USERNAME, KEY_PASSWORD
      end

      private

      FILTER = /lf-mysqldb/

      KEY_PASSWORD = 'password'.freeze

      KEY_USERNAME = 'username'.freeze

     
      private_constant :FILTER, :KEY_PASSWORD, :KEY_USERNAME
              

      def deploy_liferay_war
  
        with_timing "Deploying Liferay war" do
          @logger.info{ "Extracting Liferay.war" }
          @logger.debug{ "war_file= #{war_file}" }
          # Download the Liferay version and extract it in the ROOT folder
          shell "unzip -q #{@droplet.sandbox}/webapps/ROOT/#{war_name} -d #{@droplet.sandbox}/webapps/ROOT/  2>&1"
          shell "rm #{@droplet.sandbox}/webapps/ROOT/#{war_name}"

        end
      end

      # The war is presented to the buildpack exploded, so we need to repackage it in a war
      def deploy_portlet_wars

        destination = "#{@droplet.sandbox}/deploy/"
        with_timing "Deploying war files in #{@application.root} to #{destination} " do

          FileUtils.mkdir_p "#{@droplet.sandbox}/deploy"
          shell "cp #{@application.root}/*.war #{destination} "
          shell "rm #{@application.root}/*.war"
        end
      end

      # In this method we check if the application is bound to a service. If that is the case then we create the portal-ext.properties
      # and store it in Liferay Portal classes directory.
      def configure_liferay_db
        @logger.info{ "In TomcatLiferay::configuring liferay db" }
        credentials = @application.services.find_service(FILTER)['credentials']
      
        if credentials.to_s ==''
          @logger.info {'--->No lf-mysqldb SERVICE FOUND'}
        else
          file = "#{@droplet.sandbox}/webapps/ROOT/WEB-INF/classes/portal-ext.properties"
          #if File.exist? (file)
          #  @logger.info {"--->Portal-ext.properties file already exist, so skipping MySQL configuration" }
          #else
            with_timing "Creating portal-ext.properties in #{file}" do       
              host_name     = credentials['hostname']
              username      = credentials['username']
              password      = credentials['password']
              db_name       = credentials['name']
              port          = credentials['port']
              
              File.open(file, 'w') do  |file| 
                file.puts("#\n")
                file.puts("# MySQL\n")
                file.puts("#\n")

                jdbc_url      = "jdbc:mysql://#{host_name}:#{port}/#{db_name}"
                file.puts("jdbc.default.driverClassName=com.mysql.jdbc.Driver\n")
                file.puts("jdbc.default.url=" + jdbc_url + "\n")
                file.puts("jdbc.default.username=" + username + "\n")
                file.puts("jdbc.default.password=" + password + "\n")

                @logger.debug {"--->  Port:  #{port} \n"}
                        
                file.puts("#\n")
                file.puts("# Configuration Connextion Pool\n") # This should be configurable through ENV
                file.puts("#\n")
                file.puts("jdbc.default.acquireIncrement=5\n")
                file.puts("jdbc.default.connectionCustomizerClassName=com.liferay.portal.dao.jdbc.pool.c3p0.PortalConnectionCustomizer\n")
                file.puts("jdbc.default.idleConnectionTestPeriod=60\n")
                file.puts("jdbc.default.maxIdleTime=3600\n")

                #Check if the user specify a maximum pool size
                user_max_pool = ENV["LIFERAY_MAX_POOL_SIZE"]
                if user_max_pool ==""
                    file.puts("jdbc.default.maxPoolSize=100\n") #This is the default value from Liferay
                    @logger.info {"--->  No value set for LIFERAY_MAX_POOL_SIZE so taking the default (100) \n"}
                else
                    file.puts("jdbc.default.maxPoolSize=" + user_max_pool + "\n")
                    @logger.debug {"--->  LIFERAY_MAX_POOL_SIZE:  #{user_max_pool} \n"}
                end
                file.puts("jdbc.default.minPoolSize=10\n")
                file.puts("jdbc.default.numHelperThreads=3\n")


                file.puts("#\n")
                file.puts("# Configuration of the auto deploy folder\n")
                file.puts("#\n")
                file.puts("auto.deploy.dest.dir=${catalina.home}/webapps\n")
                file.puts("auto.deploy.deploy.dir=${catalina.home}/deploy\n")
                file.puts("#\n")
                file.puts("setup.wizard.enabled=false\n")
                file.puts("#\n")
                file.puts("auth.token.check.enabled=false\n")  
                
                file.puts("# Configuration of the media library\n")
                file.puts("#\n")
                file.puts("dl.store.impl=com.liferay.portlet.documentlibrary.store.DBStore\n")
                        
                file.puts("# Configuration of Quartz\n")
                file.puts("#\n")
                file.puts("org.quartz.jobStore.isClustered=true\n")
                        
                        @logger.info {"--->  configuring Cluster \n"}
               
                        file.puts("# Configuration of Cluster Link\n")
                        file.puts("#\n")
                        file.puts("cluster.link.enabled=true\n")
                        host_port = "#{host_name}:#{port}"
                        file.puts("cluster.link.autodetect.address=" + host_port +"\n")
                        
                        #@logger.info {"--->  Disabling Caching \n"}
                        #file.puts("browser.cache.disabled=true\n")
                        
                        
                        @logger.info {"--->  Configuring unicast \n"}
                        file.puts("# Configuration of Unicast\n")
                        file.puts("#\n")
                        file.puts("cluster.link.enabled=cluster.link.channel.properties.control=unicast.xml\n")
                        file.puts("cluster.link.channel.properties.transport.0=unicast.xml\n")
                        file.puts("ehcache.bootstrap.cache.loader.factory=com.liferay.portal.cache.ehcache.JGroupsBootstrapCacheLoaderFactory\n")
                        file.puts("ehcache.cache.event.listener.factory=net.sf.ehcache.distribution.jgroups.JGroupsCacheReplicatorFactory\n")
                        file.puts("ehcache.cache.manager.peer.provider.factory=net.sf.ehcache.distribution.jgroups.JGroupsCacheManagerPeerProviderFactory\n")
                        file.puts("net.sf.ehcache.configurationResourceName.peerProviderProperties=file=/unicast.xml\n")
                        file.puts("ehcache.multi.vm.config.location.peerProviderProperties=file=/unicast.xml\n")
                        
              end
              
            end # end with_timing
          #end
        end
      end

      def war_name
        "liferay-portal-#{@version}.war"
      end
    

      def portal_ext_properties_path
        @droplet.sandbox + 'webapps/ROOT/WEB-INF/classes/portal-ext.properties'
      end

    
    end

  end
end
