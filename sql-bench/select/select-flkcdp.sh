shPath=$(cd $(dirname $0);pwd)
cd $shPath
set -e

shFile=test-select.sh
port=3307
database=sql_bench

sed "20c port            = ${port}" -i my.cnf

mysqladmin create $database -h127.0.0.1 -P${port} -uroot -pletmein

./$shFile --server=mysql --host=127.0.0.1 --user=root --password=letmein --database=${database} --connect-options=mysql_read_default_file=./my.cnf

remove_files "${needfiles[*]}"
