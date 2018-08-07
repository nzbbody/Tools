shPath=$(cd $(dirname $0);pwd)
cd $shPath
set -e

shFile=test-select.sh
port=3307
database=sql_bench
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

sed "20c port            = ${port}" -i my.cnf

mysqladmin create $database -h127.0.0.1 -P${port} -uroot -pletmein

./$shFile --server=mysql --host=127.0.0.1 --user=root --password=letmein --database=${database} --connect-options=mysql_read_default_file=./my.cnf

remove_files "${needfiles[*]}"
