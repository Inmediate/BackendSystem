class ChangeDefaultValueToSetting < ActiveRecord::Migration[5.1]
  def change
    remove_column :settings, :default_value
    add_column :settings, :value, :text
  end
end
