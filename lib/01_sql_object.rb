require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= (table = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    table[0].map { |column| column.to_sym })
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end
      
      define_method("#{column}=") do |val|
        attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |attributes|
      self.new(attributes)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ? 
    SQL
    parse_all(results)[0]
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_sym = attr_name.to_sym
      unless self.class.columns.include?(attr_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      send("#{attr_sym}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      attributes[column]
    end
  end

  def insert
    col_names = self.class.columns.join(', ')
    question_marks = (['?'] * self.class.columns.length).join(',')
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks}) 
    SQL
    attributes[:id] = DBConnection.instance.last_insert_row_id
  end

  def update
    col_names = self.class.columns
    update_fields = col_names.map { |name| "#{name} = ?" }
    DBConnection.execute(<<-SQL, *attribute_values, attributes[:id])
      UPDATE
        #{self.class.table_name}
      SET
        #{update_fields.join(',')}  
      WHERE
        id = ?
    SQL
  end

  def save
    if attributes[:id].nil?
      insert
    else
      update
    end
  end
end
