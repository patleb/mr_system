module Db
  module Pg
    class Base < ActiveTask::Base
      include ExtRake::Pg::Rescuable

      def self.args
        { db: ['--db=DB', 'DB type (ex.: --db=record would use Record::Base connection'] }
      end

      def self.pg_options
        ENV['PG_OPTIONS']
      end

      def before_run
        super
        reload_settings
      end

      protected

      def with_config
        db = ExtRake.config.db_config
        yield db[:host],
          db[:database],
          db[:username],
          db[:password]
      end

      def psql(command, *sh_rest)
        command_end = ';' unless command.strip.end_with? ';'
        sh(<<~CMD, *sh_rest, verbose: false)
          psql --quiet -c "#{command}#{command_end}" "#{ExtRake.config.db_url}"
        CMD
      end
    end
  end
end
