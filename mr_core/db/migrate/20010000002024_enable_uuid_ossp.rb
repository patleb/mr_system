### References
# https://stackoverflow.com/questions/37713131/postgresql-sort-by-uuid-v1-timestamp
class EnableUuidOssp < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'uuid-ossp'

    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          CREATE OR REPLACE FUNCTION uuid_v1_from_seq(seq regclass) RETURNS UUID AS $$
          DECLARE
            uuid TEXT = uuid_generate_v1mc()::TEXT;
            iseq_100nsecs BIGINT = nextval(seq); -- '1582-10-15 00:00:00'::TIMESTAMP + iseq * INTERVAL '0.1 microsecond'
            uuid_100nsecs TEXT = lpad(to_hex(iseq_100nsecs), 16, '0');
          BEGIN
            uuid = overlay(uuid PLACING substring(uuid_100nsecs FROM 2 FOR 3) FROM 16 FOR 3);
            uuid = overlay(uuid PLACING substring(uuid_100nsecs FROM 5 FOR 4) FROM 10 FOR 4);
            uuid = overlay(uuid PLACING substring(uuid_100nsecs FROM 9 FOR 8) FROM 1 FOR 8);
            RETURN uuid::UUID;
          END;
          $$ LANGUAGE plpgsql STRICT PARALLEL SAFE;

          CREATE OR REPLACE FUNCTION uuid_v1_to_timestamp(uuid UUID) RETURNS TIMESTAMP AS $$
          DECLARE
            result TIMESTAMP;
          BEGIN
            SELECT to_timestamp(
              (uuid_v1_to_100nsecs(uuid)::DOUBLE PRECISION - #{122_192_928_000_000_000} ) / #{10_000_000}
            ) INTO result;
            RETURN result;
          END;
          $$ LANGUAGE plpgsql IMMUTABLE;

          CREATE OR REPLACE FUNCTION uuid_v1_to_100nsecs(uuid UUID) RETURNS BIGINT AS $$
          DECLARE
            _uuid TEXT = uuid::TEXT;
            _100nsecs TEXT;
            result BIGINT;
          BEGIN
            SELECT substring(_uuid FROM 16 FOR 3) || substring(_uuid FROM 10 FOR 4) || substring(_uuid FROM 1 FOR 8) INTO _100nsecs;
            SELECT ('x' || lpad(_100nsecs, 16, '0'))::BIT(64)::BIGINT INTO result;
            RETURN result;
          END;
          $$ LANGUAGE plpgsql IMMUTABLE;
        SQL
      end

      change.down do
        execute <<-SQL.strip_sql
          DROP FUNCTION IF EXISTS uuid_v1_from_seq(seq regclass);
          DROP FUNCTION IF EXISTS uuid_v1_to_timestamp(uuid UUID);
          DROP FUNCTION IF EXISTS uuid_v1_to_100nsecs(uuid UUID);
        SQL
      end
    end
  end
end