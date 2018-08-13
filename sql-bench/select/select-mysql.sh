shPath=$(cd $(dirname $0);pwd)
cd $shPath

shFile=test-select.sh
host=127.0.0.1
port=3306
database=sql_bench

sed "20c port            = ${port}" -i my.cnf

./$shFile --server=mysql --host=$host --user=root --password=letmein --database=${database} --connect-options=mysql_read_default_file=./my.cnf
