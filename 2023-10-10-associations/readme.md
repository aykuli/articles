# Ассоциация родитель-ребенок

## Исполнение 1

Миграция:

```ruby
    create_enum :gender_enum, %i[female male]
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :first_name
      t.string :last_name
      t.enum :gender, enum_type: :gender_enum, null: false
      t.integer :parent_id, default: nil
      t.string :member
      t.boolean :confirmed, default: false, null: false

      t.timestamps
    end

    create_table :parents_children, id: false do |t|
      t.integer :parent_id, null: false
      t.integer :child_id, null: false
    end
```

Модель:

```ruby
class User < ApplicationRecord

  belongs_to :parent, ->(p) { where "id = ?", p.parent_id}, class_name: 'User'
  
  has_many :parents_children, foreign_key: :parent_id, dependent: :destroy
  
  has_many :children, through: :parents_children, source: :child, foreign_key: :parent_id

end
```

## Исполнение 2

Источник:

* [has_and_belongs_to_many](https://guides.rubyonrails.org/association_basics.html#has-and-belongs-to-many-association-reference)
