#!/usr/bin/perl
# Copyright (C) 2000-2001, 2003 MySQL AB
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; version 2
# of the License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
# MA 02111-1307, USA
#
# Test of selecting on keys that consist of many parts
#
##################### Standard benchmark inits ##############################

use Cwd;
use DBI;
use Getopt::Long;
use Benchmark;

$opt_loop_count=10000;
$opt_medium_loop_count=1000;
$opt_small_loop_count=10;
$opt_regions=6;
$opt_groups=100;

$pwd = cwd(); $pwd = "." if ($pwd eq '');
require "$pwd/bench-init.pl.sh" || die "Can't read Configuration file: $!\n";

$columns=min($limits->{'max_columns'},500,($limits->{'query_size'}-50)/24,
	     $limits->{'max_conditions'}/2-3);

if ($opt_small_test)
{
  $opt_loop_count/=10;
  $opt_medium_loop_count/=10;
  $opt_small_loop_count/=10;
  $opt_groups/=10;
}

print "Testing the speed of selecting on keys that consist of many parts\n";
print "The test-table has $opt_loop_count rows and the test is done with $columns ranges.\n\n";

####
####  Connect and start timeing
####

$dbh = $server->connect();
$start_time=new Benchmark;

####
#### Create needed tables
####

goto select_test if ($opt_skip_create);

print "Creating table\n";
$dbh->do("drop table bench1" . $server->{'drop_attr'});

do_many($dbh,$server->create("bench1",
			     ["region char(1) NOT NULL",
			      "idn integer(6) NOT NULL",
			      "rev_idn integer(6) NOT NULL",
			      "grp integer(6) NOT NULL"],
			     ["primary key a (region,idn)",
			      "unique b (region,rev_idn)",
			      "unique c (region,grp,idn)"]));
if ($opt_lock_tables)
{
  do_query($dbh,"LOCK TABLES bench1 WRITE");
}

if ($opt_fast && defined($server->{vacuum}))
{
  $server->vacuum(1,\$dbh);
}

####
#### Insert $opt_loop_count records with
#### region:	"A" -> "E"
#### idn: 	0 -> count
#### rev_idn:	count -> 0,
#### grp:	distributed values 0 - > count/100
####

print "Inserting $opt_loop_count rows\n";

$loop_time=new Benchmark;

if ($opt_fast && $server->{transactions})
{
  $dbh->{AutoCommit} = 0;
}

$query="insert into bench1 values (";
$half_done=$opt_loop_count/2;
for ($id=0,$rev_id=$opt_loop_count-1 ; $id < $opt_loop_count ; $id++,$rev_id--)
{
  $grp=$id*3 % $opt_groups;
  $region=chr(65+$id%$opt_regions);
  do_query($dbh,"$query'$region',$id,$rev_id,$grp)");
  if ($id == $half_done)
  {				# Test with different insert
    $query="insert into bench1 (region,idn,rev_idn,grp) values (";
  }
}

if ($opt_fast && $server->{transactions})
{
  $dbh->commit;
  $dbh->{AutoCommit} = 1;
}

$end_time=new Benchmark;
print "Time to insert ($opt_loop_count): " . timestr(timediff($end_time, $loop_time),"all") . "\n\n";


####
#### End of benchmark
####

if ($opt_lock_tables)
{
  do_query($dbh,"UNLOCK TABLES");
}
if (!$opt_skip_delete)
{
  # do_query($dbh,"drop table bench1" . $server->{'drop_attr'});
}

if ($opt_fast && defined($server->{vacuum}))
{
  $server->vacuum(0,\$dbh);
}
$dbh->disconnect;				# close connection

end_benchmark($start_time);
