Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id

      String :access_token, null: false
      String :access_token_secret, null: false

      Bignum :friend_id

      Time :created_at
      Time :updated_at
    end

    create_table(:friends) do
      primary_key :id

      Bignum :twitter_id, null: false
      String :screen_name

      column :friend_ids, 'bigint[]'

      Time :created_at
      Time :updated_at
    end
  end

  down do
    drop_table(:users)
    drop_table(:friends)
  end
end
