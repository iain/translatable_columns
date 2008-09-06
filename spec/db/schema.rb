ActiveRecord::Schema.define(:version => 0) do
  create_table :topics, :force => true do |t|
    t.string :title_en, :title_nl, :title_de, :title_fr
    t.string :body_en, :body_nl, :body_de, :body_fr
    t.integer :author_id
  end
end
