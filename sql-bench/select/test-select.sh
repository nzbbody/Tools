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
use Time::HiRes qw(gettimeofday);

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
#### Do some selects on the table
####

sub exeSelect
{
  print "test select[$exeSQL] \n";
  ($begin_sec, $begin_usec) = gettimeofday;
  for ($tests=0 ; $tests < $opt_loop_count ; $tests++)
  {
    fetch_all_rows($dbh,"$exeSQL$tests");
  }
  ($end_sec, $end_usec) = gettimeofday;
  $time_used = ($end_sec - $begin_sec)*1000000 + ($end_usec - $begin_usec);
  print "Time to select ($opt_loop_count): ", $time_used, "\n\n";
}


sub exeSelect_Benchmark
{
  print "test select[$exeSQL] \n";
  $loop_time=new Benchmark;
  for ($tests=0 ; $tests < $opt_loop_count ; $tests++)
  {
    fetch_all_rows($dbh,"$exeSQL$tests");
  }
  $end_time=new Benchmark;
  print "Time to select ($opt_loop_count): ", timestr(timediff($end_time, $loop_time),"noc"), "\n\n";
}


select_test:
{
  local $exeSQL;
  $exeSQL="select sql_no_cache idn, rev_idn from bench1 where idn=";
  exeSelect($exeSQL);
  
  #$exeSQL="select sql_no_cache idn+rev_idn from bench1 where idn=100";
  #exeSelect($exeSQL);

  #$exeSQL="select sql_no_cache idn, rev_idn from bench1 where idn<100";
  #exeSelect($exeSQL);
  
  #$exeSQL="select sql_no_cache idn+rev_idn from bench1 where idn<5";
  #exeSelect($exeSQL);
  
}


$dbh->disconnect;				# close connection

end_benchmark($start_time);
