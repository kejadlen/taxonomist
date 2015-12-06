postgres: postgres -D /usr/local/var/postgres
que: que --log-level info ./config/que.rb
web: rerun --dir lib --no-notify -- rackup lib/taxonomist/config.ru
