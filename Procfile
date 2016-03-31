elm: rerun --dir elm --exit --no-notify --pattern {*.elm} -- rake elm
postgres: postgres -D /usr/local/var/postgres
que: rerun --dir lib --no-notify -- que --log-level info ./config/que.rb
web: rerun --dir lib --no-notify -- rackup lib/taxonomist/config.ru
