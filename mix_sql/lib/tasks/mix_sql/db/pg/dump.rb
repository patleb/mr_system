module Db
  module Pg
    class Dump < Base
      SPLIT_SCALE = Rails.env.vagrant? ? 'MB' : 'GB'
      SPLIT_SIZE = 2
      PIGZ_CORES = (Etc.nprocessors - 2) > 0 ? Etc.nprocessors - 2 : 1

      def self.args
        {
          name:     ['--name=NAME',                'Dump file name (default to dump)'],
          base_dir: ['--base-dir=BASE_DIR',        'Dump file(s) base directory (default to ENV["RAILS_ROOT"]/db)'],
          includes: ['--includes=INCLUDES', Array, 'Included tables (only for pg_dump and COPY command)'],
          excludes: ['--excludes=EXCLUDES', Array, 'Excluded tables (only for pg_dump and COPY command)'],
          compress: ['--[no-]compress',            'Compress the dump (default to true)'],
          split:    ['--[no-]split',               'Compress and split the dump'],
          md5:      ['--[no-]md5',                 'Generate md5 file after successful dump'],
          physical: ['--[no-]physical',            'Use pg_basebackup instead of pg_dump'],
          csv:      ['--[no-]csv',                 'Use COPY command instead of pg_dump'],
          where:    ['--where=WHERE',              'WHERE condition for the COPY command'],
        }
      end

      def self.defaults
        {
          name: 'dump',
          base_dir: ExtRake.config.rails_root.join('db'),
          includes: [],
          excludes: [],
          compress: true,
        }
      end

      def dump
        case
        when options.physical then pg_basebackup
        when options.csv      then copy_to
        else pg_dump
        end
        generate_md5 if options.md5
      end

      private

      def generate_md5
        input = case
          when options.physical then tar_file
          when options.csv      then "#{dump_path}~*.csv"
          else pg_file.to_s
          end
        if options.physical
          input = "$(sudo chmod +r #{dump_path} && sudo find #{input.dirname} -type f -not -name '*.md5' -printf '%p ')"
        else
          input << '.gz' if compress?
          input << '-*' if options.split
        end
        sh "sudo md5sum #{input} | sudo tee #{md5_file} > /dev/null"
      end

      def pg_basebackup
        pg_receivewal do
          sh "sudo mkdir -p #{dump_path.dirname}"
          sh "sudo chown postgres:postgres #{dump_path.dirname}"
          output = case
            when options.split    then "-D- | #{split_cmd(tar_file)}"
            when options.compress then "-D- | #{compress_cmd(tar_file)}"
            else "-D #{dump_path}"
            end
          sh su_postgres "pg_basebackup -v -Xnone -Ft #{self.class.pg_options} #{output}"
        end
      end

      def pg_receivewal
        sh "sudo mkdir -p #{dump_wal_dir}"
        sh "sudo chown postgres:postgres #{dump_wal_dir}"
        sh "sudo rm -f #{dump_wal_dir}/*"
        psql! "SELECT * FROM pg_create_physical_replication_slot('#{options.name}')"
        pid = spawn su_postgres "pg_receivewal -S #{options.name} -D #{dump_wal_dir}"
        yield
        psql! "SELECT pg_switch_wal()"
        sh "sudo pkill pg_receivewal"
        Process.kill('TERM', pid)
        Process.detach(pid)
        sleep 1 while system("sudo pgrep pg_receivewal")
        psql! "SELECT * FROM pg_drop_replication_slot('#{options.name}')"
        if compress
          sh su_postgres "tar cvf - -C #{dump_wal_dir} . | #{compress_cmd(wal_file)}"
        else
          sh su_postgres "tar -cvf #{wal_file} -C #{dump_wal_dir} ."
        end
      end

      def copy_to
        dump_path.dirname.mkpath
        where = "WHERE #{options.where}" if options.where.present?
        tables = (options.includes.reject(&:blank?) - options.excludes.reject(&:blank?)).uniq
        tables.each do |table|
          file = csv_file(table)
          output = case
            when options.split    then "PROGRAM '#{split_cmd(file)}'"
            when options.compress then "PROGRAM '#{compress_cmd(file)}'"
            else "'#{file}'"
            end
          psql! "\\COPY (SELECT * FROM #{table} #{where}) TO #{output} DELIMITER ',' CSV #{self.class.pg_options}"
        end
      end

      def pg_dump
        only = options.includes.reject(&:blank?)
        skip = options.excludes.reject(&:blank?)
        skip << ActiveRecord::Base.internal_metadata_table_name
        with_db_config do |host, db, user, pwd|
          cmd_options = <<-CMD.squish
            --host #{host} --username #{user} --verbose --no-owner --no-acl --clean --format=c --compress=0
            #{self.class.pg_options}
            #{only.map{ |table| "--table='#{table}'" }.join(' ')}
            #{skip.map{ |table| "--exclude-table='#{table}'" }.join(' ')}
            #{db}
          CMD
          output = case
            when options.split    then "| #{split_cmd(pg_file)}"
            when options.compress then "| #{compress_cmd(pg_file)}"
            else pg_file
            end
          sh <<~CMD, verbose: false
            export PGPASSWORD=#{pwd};
            pg_dump #{cmd_options} #{output}
          CMD
        end
      end

      def split_cmd(file)
        "pigz -p #{PIGZ_CORES} | split -a 4 -b #{SPLIT_SIZE}#{SPLIT_SCALE} - #{file}.gz-"
      end

      def compress_cmd(file)
        "pigz -p #{PIGZ_CORES} > #{file}.gz"
      end

      def md5_file
        options.physical ? tar_file.sub(/\.tar$/, '.md5') : dump_path.sub_ext('.md5')
      end

      def tar_file
        dump_path.join('base.tar')
      end

      def wal_file
        dump_path.join('pg_wal.tar')
      end

      def csv_file(table)
        dump_path.sub_ext("~#{table}.csv")
      end

      def pg_file
        dump_path.sub_ext('.pg')
      end

      def compress
        options.compress || options.split
      end

      def dump_wal_dir
        @dump_wal_dir ||= dump_path.sub_ext('_wal')
      end

      def dump_path
        @dump_path ||= Pathname.new(options.base_dir).join(options.name).expand_path
      end
    end
  end
end