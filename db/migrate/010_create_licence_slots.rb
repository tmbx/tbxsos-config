class CreateLicenceSlots < ActiveRecord::Migration
  def self.up
    create_table :licence_slots do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :licence_slots
  end
end
