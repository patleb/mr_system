module Geoserver
  module Workspace
    class Create < Base
      def create
        post('workspaces', { workspace: { name: workspace_name } }, default: true)
        post("workspaces/#{workspace_name}/datastores", data_store)
      end

      private

      def data_store
        {
          dataStore: {
            name: workspace_name,
            type: 'PostGIS',
            enabled: true,
            connectionParameters: {
              entry: [
                { '@key': 'host',      '$': Setting[:db_host] || '127.0.0.1' },
                { '@key': 'port',      '$': Setting[:db_port] || 5432 },
                { '@key': 'database',  '$': Setting[:db_database] },
                { '@key': 'user',      '$': Setting[:db_username] },
                { '@key': 'passwd',    '$': Setting[:db_password] },
                { '@key': 'dbtype',    '$': 'postgis' },
                { '@key': 'schema',    '$': 'public' },
                { '@key': 'namespace',                      '$': "http://#{workspace_name}" },
                { '@key': 'Expose primary keys',            '$': false },
                { '@key': 'max connections',                '$': 10 },
                { '@key': 'min connections',                '$': 1 },
                { '@key': 'fetch size',                     '$': 1000 },
                { '@key': 'Batch insert size',              '$': 1 },
                { '@key': 'Connection timeout',             '$': 20 },
                { '@key': 'validate connections',           '$': true },
                { '@key': 'Test while idle',                '$': true },
                { '@key': 'Evictor run periodicity',        '$': 300 },
                { '@key': 'Max connection idle time',       '$': 300 },
                { '@key': 'Evictor tests per run',          '$': 3 },
                { '@key': 'Loose bbox',                     '$': true },
                { '@key': 'Estimated extends',              '$': true },
                { '@key': 'preparedStatements',             '$': false },
                { '@key': 'Max open prepared statements',   '$': 50 },
                { '@key': 'encode functions',               '$': true },
                { '@key': 'Support on the fly geometry simplification', '$': true },
              ],
            },
          }
        }
      end
    end
  end
end
