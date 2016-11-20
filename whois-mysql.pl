#!/usr/bin/perl
# SAMPLE EXECUTION
# [etc]# ./whois.pl 119.166.176.125
# country: CN
#
# You must run the following commands so that geo-location works
# and you must download the latest databases after the second tuesday
# of each month
#
# yum install cpan
#cpan Geo::IP
#cpan Socket6
#mkdir /usr/local/share/GeoIP
#mkdir /usr/local/share/GeoIP/backups # Will be used to store older copies of database files
#cd /usr/local/share/GeoIP
#wget geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
#wget geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
#wget http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz
#gunzip GeoIP.dat.gz
#gunzip GeoLiteCity.dat.gz
#gunzip GeoIPv6.dat.gz
#

my $DEBUG=0;
my $SCRIPT_DIR="/usr/local/etc/";
my $ip=$ARGV[0];

use strict;
use warnings;
use DBI;
use Geo::IP;
my $INPUT;
my $new_record;
my $record;
my $print_record;
my $account;
my $what;
my $password;
my $files;
my $trash ;
my $who;
my $action;
my $date;
my $munged_date;
my $munged_time;
my $dbh;
my @date_array;
my $country;
my $city;
my $line_counter;
my $mysql_account="longtail";
my $mysql_password="password";

######################################################################
#
# Initialize a bunch of stuff
#
sub init {
	my $country="";
	my $city="";
}	


sub geolocate_ip{
  my $ip=shift;
	my $local_ip_1;
	my $local_ip_2;
	$local_ip_1="10.";
	$local_ip_2="148.100";

	#print (STDERR "In geolocate for $ip\n");
	my $tmp;
	my $tmp2;
	#print "DEBUG in geolocate_ip now, $ip is -->$ip<--\n";
	if ($ip =~ /^$local_ip_1/){return ("US:Poughkeepsie");}
	#if ($ip =~ /^$local_ip_2/){return ("US:Poughkeepsie");}
	#print "DEBUG: not marist or local address\n";
	my $gi = Geo::IP->open("/usr/local/share/GeoIP/GeoLiteCity.dat", GEOIP_STANDARD);
	my $record = $gi->record_by_addr($ip);
	#print $record->country_code,
	#      $record->country_code3,
	#      $record->country_name,
	#      $record->region,
	#      $record->region_name,
	#      $record->city,
	#      $record->postal_code,
	#      $record->latitude,
	#      $record->longitude,
	#      $record->time_zone,
	#      $record->area_code,
	#      $record->continent_code,
	#      $record->metro_code;
	# ericw note: I have no idea what happens if there IS a record
	# but there is no country code
	undef ($tmp);
	if (defined $record){
		$tmp=$record->country_code;
		$tmp2=$record->city;
		#print "DEBUG: $ip found in geolocate_ip, returning $tmp:$tmp2\n";
		return ("$tmp:$tmp2");
	}
	else {
		#print "DEBUG: $ip not found in geolocate_ip, returning undefined:undefined\n";
		return ("undefined:undefined");
	}
}

sub geo_locate_country{
	$ip=shift;
	my $tmp;
  my $gi = Geo::IP->open("/usr/local/share/GeoIP/GeoLiteCity.dat", GEOIP_STANDARD);
  my $record = $gi->record_by_addr($ip);
	# ericw note: I have no idea what happens if there IS a record
	# but there is no country code
	undef ($tmp);
	if (defined $record){
		$tmp=$record->country_code;
		return ($tmp);
	}
	return ("undefined");
}


sub find_country {
	my $tmp;
	my $country="";
	my $city="";
	my $file_country;
  my $ip_table;
	my %ip_table;
	my $country_code="";
	my $ip_address;
	my $use_mysql_database=1;

	# Lets make sure we were really passed an ip address, if not
	# then error out with undefined and don't write it to the database
	# or the file
	use Data::Validate::IP;
	my $validator=Data::Validate::IP->new;
	if(! $validator->is_ipv4($ip)) {
		print "country: undefined\n";
		return ("undefined");
	}

	# Open a connection to the database
#	my $dbh = DBI->connect("DBI:mysql:database=whois;host=localhost",
#		"$mysql_account", "$mysql_password",
#		{'RaiseError' => 1});
	my $dbh = DBI->connect("DBI:mysql:database=whois;host=localhost",
		"$mysql_account", "$mysql_password") or $use_mysql_database=0; 
	
	if (! $use_mysql_database ) {
		print "Can't connect to  mysql database, assuming use of files\n";
	}


	# Create the darn table if it doesn't exist already
	my $sth=$dbh->prepare("create table if not exists ip_to_country ( ip varchar(15) DEFAULT NULL, src_country_code varchar(2) DEFAULT NULL, PRIMARY KEY (ip))") or die "Could not prepare sql statement";
	$sth->execute() or die "execution failed: $dbh->errstr()";

	$sth = $dbh->prepare("SELECT src_country_code FROM ip_to_country WHERE ip = '$ip' ")
                or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute() or die "execution failed: $dbh->errstr()";
#	if ($DEBUG){print $sth->rows . " rows found.\n";}
#
	while (my $ref = $sth->fetchrow_hashref()) {
	#	if ($DEBUG){print "Found a row: id = $ref->{'src_country_code'}\n";}
		#print "Found a row: id = $ref->{'src_country_code'}\n";
		$country_code= $ref->{'src_country_code'};
		print "country: $country_code\n";
  	$sth->finish;
		return; #Yeah, this isn't true structured programming....
	}
  $sth->finish;

	# Time to look through the flat file If we are't using mysql
	if (! $use_mysql_database ) {
		open (FILE, "$SCRIPT_DIR/ip-to-country") || die "can not open /usr/local/etc/ip-to-country\n";
		while (<FILE>){
			chomp;
			($ip_address,$file_country)=split (/\s+/,$_,2);
			$ip_table{"$ip_address"}=$file_country;
			if ($ip_table{$ip}){  last; }
		}
		close (FILE);
		$country ="";
		if ($ip_table{$ip}){
			$tmp=$ip_table{$ip};
			#print "country: $tmp\n";
			$country=$tmp;
		}
	}


	if ( $country eq ""){
  #It's not in the file or the array :-(
		if ( -e "/usr/local/share/GeoIP/GeoIP.dat" ){
			#print "Calling geolocate_ip now\n";
			$country=&geolocate_ip("$ip");
			($country,$city)=split(/:/,$country,2);
			#print "country is now $country\n";
			#print "Back from calling geolocate_ip\n";
		}
	}
	
	if ( $country eq ""){
	# Look it up via the files and then whois data
	# This is because hacker owned whois data disappears
	# when it is taken away from them
	# &look_up_country;
	}

	# Still no country code, then set it to undefined
	if ( $country eq ""){
		$country="undefined";
	}

	# So if we got this far, then the IP Address is not in the database
	# or in the flat file ip-to-to-country and we should probably add it
	# to one or the other :-)
	if ( $use_mysql_database ){
		#print "DEBUG trying to add to the database now\n";
		# I still need to "Safe" $country before inserting into the database
		$dbh->do("INSERT ignore INTO ip_to_country VALUES ('$ip','$country' );");
	}
	else { #We are using flatfiles
		#print "DEBUG trying to add to the flat file now\n";
		open (FILE, ">>$SCRIPT_DIR/ip-to-country") || die "can not open $SCRIPT_DIR/ip-to-country\n";
		print (FILE "$ip $country\n");
		close (FILE);
	}


	# Disconnect from the database.
	if ( $use_mysql_database ){
		$dbh->disconnect();
	}
	if ( $country ne ""){
		print "country: $country\n";
	}
	else {
		print "country: undefined\n";
	}
} # sub find_country

&init;
&find_country;


