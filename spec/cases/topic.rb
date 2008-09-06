class Topic < ActiveRecord::Base
  translatable_columns :title, :body
  validates_translation_of :title, :body
end
