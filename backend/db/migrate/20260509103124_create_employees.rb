class CreateEmployees < ActiveRecord::Migration[7.1]
  def change
    create_table :employees do |t|
      t.string  :full_name,        null: false
      t.string  :job_title,        null: false
      t.string  :department,       null: false
      t.string  :country,          null: false
      t.decimal :salary,           null: false, precision: 12, scale: 2
      t.string  :currency,         null: false, default: "USD"
      t.string  :employment_type,  null: false, default: "full_time"
      t.string  :email,            null: false
      t.date    :hired_on,         null: false

      t.timestamps
    end

    add_index :employees, :country
    add_index :employees, :job_title
    add_index :employees, :department
    add_index :employees, :employment_type
    add_index :employees, [:country, :job_title]
    add_index :employees, :email, unique: true
  end
end
