DEFAULT_JSON = Sequel::LiteralString.new("'{}'::json")

Sequel.migration do
  change do
    create_table :interactions do
      primary_key :id
      foreign_key :user_id, :users

      String :endpoint, null: false
      Bignum :since_id, unique: true
      column :counts, 'json', default: DEFAULT_JSON, null: false

      DateTime :created_at
      DateTime :updated_at
    end

    alter_table :users do
      drop_column :interactions
      drop_column :tweet_marks
    end
  end
end
