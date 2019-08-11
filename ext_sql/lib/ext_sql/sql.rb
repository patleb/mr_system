module Sql
  def self.value_changed?(variable)
    <<-SQL.strip_sql
      SELECT #{variable}_was IS NULL AND #{variable} IS NOT NULL
          OR #{variable}_was IS NOT NULL AND #{variable} IS NULL
          OR #{variable}_was != #{variable} INTO #{variable}_changed;
    SQL
  end

  def self.execute(name, *args, **options)
    <<-SQL.strip_sql
      EXECUTE #{send(name, *args, **options)};
    SQL
  end

  def self.debug(*rb_vars, pg_vars: [], record: 'NEW', **)
    if pg_vars.any?
      pg_vars_values = "{#{' %' * pg_vars.size} }"
      pg_vars_names = ", #{pg_vars.join(', ')}"
    end
    <<-SQL.strip_sql
      RAISE NOTICE '#{record} % % [#{rb_vars.join(', ')}] #{pg_vars_values}', _debug, #{record}#{pg_vars_names};
    SQL
  end

  def self.debug_var
    <<-SQL.strip_sql if ExtSql.config.debug?
      _debug RECORD;
    SQL
  end

  def self.debug_init
    <<-SQL.strip_sql if ExtSql.config.debug?
      _debug = ROW(NULL);
    SQL
  end

  private_class_method

  def self.get_value_cmd(column, variable, record: 'NEW', **)
    <<-SQL.compile_sql
      SELECT ($1).[#{column}] [INTO #{variable}] [USING #{record}]
    SQL
  end
end
