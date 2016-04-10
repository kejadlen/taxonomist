Sequel.migration do
  change do
    create_table(:lists) do
      primary_key :id
      column :twitter_id, "bigint", :null=>false
      column :member_ids, "bigint[]"
      column :raw, "json"
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"

      index [:twitter_id]
      index [:twitter_id], :name=>:lists_twitter_id_key, :unique=>true
    end

    create_table(:que_jobs) do
      column :priority, "smallint", :default=>100, :null=>false
      column :run_at, "timestamp with time zone", :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      column :job_id, "bigint", :default=>Sequel::LiteralString.new("nextval('que_jobs_job_id_seq'::regclass)"), :null=>false
      column :job_class, "text", :null=>false
      column :args, "json", :default=>Sequel::LiteralString.new("'[]'::json"), :null=>false
      column :error_count, "integer", :default=>0, :null=>false
      column :last_error, "text"
      column :queue, "text", :default=>"", :null=>false

      primary_key [:priority, :run_at, :job_id, :queue]
    end

    create_table(:schema_info) do
      column :version, "integer", :default=>0, :null=>false
    end

    create_table(:users) do
      primary_key :id
      column :twitter_id, "bigint", :null=>false
      column :raw, "json", :default=>Sequel::LiteralString.new("'{}'::json"), :null=>false
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"
      column :access_token, "text"
      column :access_token_secret, "text"
      column :friend_ids, "bigint[]"
      column :list_ids, "bigint[]"

      index [:twitter_id]
      index [:twitter_id], :name=>:users_twitter_id_key, :unique=>true
    end

    create_table(:interactions) do
      primary_key :id
      foreign_key :user_id, :users, :key=>[:id]
      column :endpoint, "text", :null=>false
      column :since_id, "bigint"
      column :counts, "json", :default=>Sequel::LiteralString.new("'{}'::json"), :null=>false
      column :created_at, "timestamp without time zone"
      column :updated_at, "timestamp without time zone"

      index [:since_id], :name=>:interactions_since_id_key, :unique=>true
    end
  end
end
