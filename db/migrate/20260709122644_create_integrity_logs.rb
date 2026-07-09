class CreateIntegrityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :integrity_logs do |t|
      t.uuid :idfa, null: false
      t.string :ban_status, null: false
      t.string :ip
      t.boolean :rooted_device
      t.string :country
      t.boolean :proxy
      t.boolean :vpn

      t.datetime :created_at, null: false
    end

    add_index :integrity_logs, :idfa
    add_index :integrity_logs, :created_at
  end
end
