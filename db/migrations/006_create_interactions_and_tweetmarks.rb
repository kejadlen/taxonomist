Sequel.migration do
  change do
    alter_table(:users) do
      default_json = Sequel::LiteralString.new("'{}'::json")
      add_column :interactions, 'json', default: default_json, null: false
      add_column :tweet_marks, 'json', default: default_json, null: false
    end
  end
end
