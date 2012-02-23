class CreateTestResults < ActiveRecord::Migration
  def self.up
    create_table :test_results do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :test_results
  end
end
