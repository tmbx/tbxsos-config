class CreateKeys < ActiveRecord::Migration
  def self.up
    create_table :keys do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :keys
  end
end
