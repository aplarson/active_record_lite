require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      through_val = self.send(through_options.foreign_key)
      source_table = source_options.table_name
      through_table = through_options.table_name
      results = DBConnection.execute(<<-SQL, through_val)
        SELECT
          #{source_table}.*
        FROM
          #{source_table}
        JOIN
          #{through_table}
        ON
          #{source_table}.#{source_options.primary_key}
          = #{through_table}.#{source_options.foreign_key}
        WHERE
          #{through_table}.#{through_options.primary_key} = ?
      SQL
      source_options.model_class.parse_all(results).first
    end
  end
end


class Relation
  attr_accessor :table_name
  include Searchable
  
  def self.import_array_methods
    Array.new.methods.each do |method_name|
      puts method_name
      define_method(method_name) do
        if @results.nil?
          search
        end
        @results.send(method_name)
      end
    end
  end
  
  def initialize(table_name, where_values)
    @table_name = table_name
    @where_values_hash = where_values
  end
  
  def where_values_hash
    @where_values_hash ||= {}
  end
  
  def search
    where_clause = where_values_hash.keys.map { |column| "#{column} = ?"}
                                         .join(' AND ')
    values_to_find = where_values_hash.values.map { |val| val.to_s }
    results = DBConnection.execute(<<-SQL, *values_to_find)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_clause} 
    SQL
    @results = table_name.camelize.singularize.constantize.parse_all(results)
  end
  
  import_array_methods
end