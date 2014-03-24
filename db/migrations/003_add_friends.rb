Sequel.migration do
  up do
    create_table(:friends) do
      primary_key :id
      String :twitter_id
      String :screen_name
      column :friends, 'Text[]'
    end

    add_column :users, :friend_id, Integer
  end

  down do
    drop_table(:friends)
    drop_column :users, :friend_id
  end
end
