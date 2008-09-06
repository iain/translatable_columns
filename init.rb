ActiveRecord::Base.extend TranslatableColumns::ClassMethods
ActiveRecord::Base.send :include, TranslatableColumns::InstanceMethods
