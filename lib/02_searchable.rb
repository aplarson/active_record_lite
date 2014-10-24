require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_clause = params.keys.map { |column| "#{column} = ?"}.join(' AND ')
    values_to_find = params.values.map { |val| val.to_s }
    results = DBConnection.execute(<<-SQL, *values_to_find)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_clause} 
    SQL
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
