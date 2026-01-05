# copy this script into the parent directory and run it like this: ../99-pull-new.sh
rm -rf suuppldev-bootstrap-main/ 
curl -L https://github.com/suuppl/suuppldev-bootstrap/archive/refs/heads/main.tar.gz | tar xz
cd suuppldev-bootstrap-main/