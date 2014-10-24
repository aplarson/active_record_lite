require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    unless @where_values_hash.nil?
      params = @where_values_hash.merge(params)
    end
    Relation.new(self.table_name, params)
  end
end

class SQLObject
  extend Searchable
end
