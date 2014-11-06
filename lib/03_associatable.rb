require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options = {
      foreign_key: ("#{name}_id").to_sym,
      primary_key: :id,
      class_name: name.to_s.camelize
    }.merge(options)
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options = {
      foreign_key: ("#{self_class_name.underscore}_id").to_sym,
      primary_key: :id,
      class_name: name.to_s.camelize.singularize
    }.merge(options)
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name.to_sym] = options
    define_method(name.to_sym) do
      foreign_key_val = self.send(options.foreign_key)
      class_to_search = options.model_class
      class_to_search.where({ options.primary_key => foreign_key_val}).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    assoc_options[name.to_sym] = options
    define_method(name.to_sym) do
      primary_key_val = self.send(options.primary_key)
      class_to_search = options.model_class
      class_to_search.where({ options.foreign_key => primary_key_val })
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
