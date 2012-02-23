class CreateLicences < ActiveRecord::Migration
  def self.up
    create_table :licences do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :licences
  end
end
