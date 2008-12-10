module TranslatableColumns

  # A config class for TranslatableColumns
  # Stores configuration options, so global settings can be changed.
  # These options are available:
  #
  # <ul>
  # <li>+full_locale+, when *true* it uses the full locale in 
  # the column names (e.g. _title_en_us_), when *false* (default!) it 
  # uses only the language part (e.g. _title_en_)</li>
  # <li>+use_default+, when *false* it will not try to find a value
  # from other languages, when the request locale is nil. (default = true)
  # </li>
  # </ul>
  #
  # To change the config globally, create an initializer or add to your 
  # environtment-file:
  #
  #   ActiveRecord::Base.translatable_columns_config.full_locale = false
  #   ActiveRecord::Base.translatable_columns_config.set_default = true
  #
  class Config#nodoc:
    attr_accessor :full_locale, :use_default
    
    def initialize
      set_defaults
    end

    def set_defaults
      @full_locale = false
      @use_default = true
    end
  
  end

  module ClassMethods

    # Accessor for the config, which makes sure you read from the same config 
    # every time. See +Config+
    def translatable_columns_config
      @@translatable_columns_config ||= TranslatableColumns::Config.new
    end

    
    # Used to define which columns can be translatable
    #   
    #   class Topic < ActiveRecord::Base
    #     translatable_columns :title, :body, :use_default => false
    #   end
    #
    # The use of the option +:use_default+ is optional and used to overwrite
    # the global config. See +Config+ for that.
    def translatable_columns(*columns)
      
      options = columns.extract_options!
      options[:use_default] = translatable_columns_config.use_default unless options.has_key?(:use_default)

      columns.each do |column|
        define_translated_setter(column)
        if options[:use_default]
          define_translated_getter_with_defaults(column)
        else
          define_translated_getter_without_defaults(column)
        end
      end

    end

    # Defines the method needed to get the translated value, defaults
    # to values from other columns when needed.
    # If a column doesn't exist, it'll default to the I18n.default_locale.
    def define_translated_getter_with_defaults(column)
      define_method column do
        self.send(self.class.column_translated(column)) or 
        self.send(self.class.column_name_localized(column, I18n.default_locale)) or
        self.find_translated_value_for(column)
      end
    end

    # Defines the method needed to get the translated value, but
    # doesn't look beyond its own value, even if it's nil. It will still
    # look for the column belonging to I18n.default_locale if the locale
    # doesn't have it's own column.
    def define_translated_getter_without_defaults(column)
      define_method column do
        self.send(self.class.column_translated(column))
      end
    end

    # Defines the method needed to fill the proper column. Will set the
    # default column if no column is found for this locale.
    def define_translated_setter(column)
      define_method :"#{column}=" do |value|
        self.send(:"#{self.class.column_translated(column)}=", value)
      end
    end

    # Returns the column associated with the locale specified.
    #
    #   column_translated("name") # => "name_en"
    def column_translated(name, locale = I18n.locale)
      translated_column_exists?(name, locale) ? column_name_localized(name, locale) : column_name_localized(name, I18n.default_locale)
    end

    # Finds all localized columns belonging to the given column.
    #
    #   available_translatable_columns_of("name") # => [ "name_en", "name_nl" ]
    #
    # TODO It will also find non localized columns, if they start with the same name as the translatable name.
    def available_translatable_columns_of(name)
      self.column_names.select { |column| column =~ /^#{name}_\w{2,}$/ }
    end

    # Returns true if a column exist for the supplied attribute name.
    def translated_column_exists?(name, locale = I18n.locale)
      available_translatable_columns_of(name).include?(column_name_localized(name, locale))
    end

    # Makes the column
    def column_name_localized(name, locale = I18n.locale)
      "#{name}_#{column_locale(locale)}"
    end

    # Returns the proper column name
    def column_locale(locale = I18n.locale)
      translatable_columns_config.full_locale ? locale.to_s.sub('-','_').downcase : locale.to_s.split('-').first
    end

    # Validates presence of at least one of the localized columns.
    # Usage is the same as +validates_presence_of+ 
    #
    # Translation scope of the error message is:
    #
    # # activerecord.errors.models.topic.attributes.title.must_have_translation
    # # activerecord.errors.models.topic.must_have_translation
    # # activerecord.errors.messages.must_have_translation
    # # activerecord.errors.messages.blank
    def validates_translation_of(*attr_names)
      configuration = { :on => :save }
      configuration.update(attr_names.extract_options!)
      send(validation_method(configuration[:on]), configuration) do |record|
        attr_names.each do |attr_name|
          if record.find_translated_value_for(attr_name).blank?
            custom_message = configuration[:message] || :must_have_translation
            record.errors.add(attr_name, :blank, :default => custom_message)
          end
        end
      end
    end

  end

  module InstanceMethods

    # Finds a value for a translatable column. Just iterates, returns first value found.
    def find_translated_value_for(name)
      self.class.available_translatable_columns_of(name).each do |column|
        return send(column) unless send(column).blank?
      end
      nil
    end
  end

end
