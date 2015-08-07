Sequel.migration do
  change do
    alter_table(:users) do
      add_column :access_token, String
      add_column :access_token_secret, String
    end
  end
end
