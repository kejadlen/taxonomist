Sequel.migration do
  change do
    create_table(:schema_info) do
      column :version, "integer", :default=>0, :null=>false
    end

    create_table(:users) do
      primary_key :id
      column :twitter_id, "bigint", :null=>false
      column :raw, "json"
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"
      column :access_token, "text"
      column :access_token_secret, "text"

      index [:twitter_id]
      index [:twitter_id], :name=>:users_twitter_id_key, :unique=>true
    end
  end
end
