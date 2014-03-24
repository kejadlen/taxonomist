Sequel.migration do
  up do
    drop_column :users, :screen_name
  end

  down do
    add_column :users, :screen_name, String
  end
end
