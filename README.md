# My Server Configuration
====

Sure I could have used capistrano or puppet or anything, but I really have only one server and I dislike how capistrano has some very strange bugs.  Specifically the one where :no_release doesn't always seem to work properly.

```
./deploy.rb [arg]
  - deploy ( default )
  - check_syntax
  - restart_all_server_processes
  - link_nginx_sites
  - copy_files
  - setup
  - update_git
  - test
