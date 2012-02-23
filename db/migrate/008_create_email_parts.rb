class CreateEmailParts < ActiveRecord::Migration
  def self.up
    create_table :email_parts do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :email_parts
  end
end
