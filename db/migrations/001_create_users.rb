Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      String :access_token, null: false
      String :access_token_secret, null: false
    end
  end

  down do
    drop_table(:users)
  end
end
