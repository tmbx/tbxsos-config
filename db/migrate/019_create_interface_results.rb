class CreateInterfaceResults < ActiveRecord::Migration
  def self.up
    create_table :interface_results do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :interface_results
  end
end
