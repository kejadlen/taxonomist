Various useful shell commands for working with this project:

``` zsh
$ for i in `cat .env`; do; export $i; done
$ . ./bin/activate
$ honcho start
```
