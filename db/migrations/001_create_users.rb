Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id

      Bignum :twitter_id, null: false, unique: true
      json :raw

      DateTime :created_at
      DateTime :updated_at

      index :twitter_id
    end
  end
end
