shPath=$(cd $(dirname $0);pwd)
cd $shPath

shFile=test-connect.sh

needfiles=("$shFile" "server-cfg.sh" "bench-init.pl.sh" "my.cnf")

function copy_files()
{
    files=$1
    for i in ${files[*]}; do
        cp ../$i ./
    done
}

function remove_files()
{
    files=$1
    for i in ${files[*]}; do
        rm -f ./$i
    done
}

copy_files "${needfiles[*]}"

sed "20c port            = 3307" -i my.cnf

./$shFile --server=mysql --host=127.0.0.1 --user=root --password=letmein --connect-options=mysql_read_default_file=./my.cnf

remove_files "${needfiles[*]}"
