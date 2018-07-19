class CreateInsurers < ActiveRecord::Migration[5.1]
  def change
    create_table :insurers do |t|

      t.string :company_name, null: false
      t.text :company_address
      t.string :company_code, null: false, index: true
      t.string :website_url
      t.integer :company_phone
      t.boolean :activation_status, default: false
      t.string :contact_person_name, null: false
      t.string :contact_person_phone
      t.string :contact_person_email, null: false

      t.timestamps
    end
  end
end
