#/bin/sh
set -x
shPath=$(cd $(dirname $0);pwd)
cd $shPath
rm -f test-*
rm -f server-cfg.sh
rm -f bench-init.pl.sh
rm -f my.cnf
