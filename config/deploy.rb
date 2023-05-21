# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

APP_CONFIG = YAML.load(File.open('config/config.yml'))

# set :application, "my_app_name"
# set :repo_url, "git@example.com:me/my_repo.git"

set :application, APP_CONFIG['application']
set :repo_url, APP_CONFIG['repository']

set :rvm_ruby_version, '2.6.3'

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/apps/#{ fetch(:application) }"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/database.yml"
set :linked_files, %w{config/master.key}

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
append :linked_dirs, "lib/setup/data", "lib/setup/data_out"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure


namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end

after "deploy:updated", "deploy:cleanup"

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  task :httpd_graceful do
    on roles(:web), in: :sequence, wait: 5 do
      execute :sudo, "service httpd graceful"
    end
  end

  task :monit do
    on roles(:web), in: :sequence, wait: 5 do
      execute :sudo, "monit restart delayed_job_all_of_us_helper"
    end
  end
end

namespace :deploy_prepare do
  desc 'Configure virtual host'
  task :create_vhost do
    on roles(:web), in: :sequence, wait: 5 do
      vhost_config = <<-EOF
NameVirtualHost *:80
NameVirtualHost *:443

<VirtualHost *:80>
  ServerName #{ APP_CONFIG[ fetch(:stage).to_s ]['server_name'] }
  ServerAlias #{ APP_CONFIG[ fetch(:stage).to_s ]['server_alias'] }
  Redirect permanent / https://#{ APP_CONFIG[ fetch(:stage).to_s ]['server_name'] }/
</VirtualHost>

<VirtualHost *:443>
  PassengerFriendlyErrorPages off
  PassengerAppEnv #{ fetch(:stage) }
  PassengerRuby /usr/local/rvm/wrappers/ruby-#{ fetch(:rvm_ruby_version) }/ruby

  ServerName #{ APP_CONFIG[ fetch(:stage).to_s ]['server_name'] }

  SSLEngine On
  SSLCertificateFile #{ APP_CONFIG[ fetch(:stage).to_s ]['cert_file'] }
  SSLCertificateChainFile #{ APP_CONFIG[ fetch(:stage).to_s ]['chain_file'] }
  SSLCertificateKeyFile #{ APP_CONFIG[ fetch(:stage).to_s ]['key_file'] }

  DocumentRoot #{ fetch(:deploy_to) }/current/public
  RailsBaseURI /
  PassengerDebugLogFile /var/log/httpd/#{ fetch(:application) }_passenger.log

  <Directory #{ fetch(:deploy_to) }/current/public >
    Allow from all
    Options -MultiViews
  </Directory>
</VirtualHost>
EOF
      execute :echo, "\"#{ vhost_config }\"", ">", "/etc/httpd/conf.d/#{ fetch(:application) }.conf"
    end
  end
end

namespace :bundler do
  before 'bundler:install', :config
    desc 'bundle config options'
    task :config do
      on roles(:all), in: :groups, limit: 3, wait: 10 do
      # Required for pg gem to be installed
      # execute 'bundle config build.pg --with-pg-config=/usr/pgsql-10/bin/'
      execute '/usr/local/rvm/bin/rvm 2.6.3 do bundle config build.pg --local --with-pg-config=/usr/pgsql-10/bin/pg_config'
    end
  end
end

after "deploy:updated", "deploy:cleanup"
after "deploy:finished", "deploy_prepare:create_vhost"
after "deploy_prepare:create_vhost", "deploy:httpd_graceful"
after "deploy:httpd_graceful", "deploy:restart"
# after "deploy:restart", "deploy:monit"