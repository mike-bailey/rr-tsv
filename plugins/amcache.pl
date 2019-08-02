#-----------------------------------------------------------
# amcache.pl 
#   
# Change history
#   20180311 - updated to support newer version files, albeit without parsing devices
#   20170315 - added output for Product Name and File Description values
#   20160818 - added check for value 17
#   20131218 - fixed bug computing compile time
#   20131213 - updated 
#   20131204 - created
#
# References
#   https://binaryforay.blogspot.com/2017/10/amcache-still-rules-everything-around.html
#   http://www.swiftforensics.com/2013/12/amcachehve-in-windows-8-goldmine-for.html
#
# Copyright (c) 2018 QAR, LLC
# Author: H. Carvey, keydet89@yahoo.com
#-----------------------------------------------------------
package amcache;
use strict;

my %config = (hive          => "amcache",
              hasShortDescr => 1,
              hasDescr      => 1,
              hasRefs       => 1,
              osmask        => 22,
              category      => "program execution",
              version       => 20180311);
my $VERSION = getVersion();
mkdir("results/amcache/");
# Functions #
sub getConfig {return %config}
sub getHive {return $config{hive};}
sub getVersion {return $config{version};}
sub getDescr {}
sub getShortDescr {
	return "Parse AmCache\.hve file";
}
sub getRefs {}

sub pluginmain {
	my $class = shift;
	my $hive = shift;

	::logMsg("Launching amcache v.".$VERSION);
	::logMsg("(".$config{hive}.") ".getShortDescr()."\n");     
	my $reg = Parse::Win32Registry->new($hive);
	my $root_key = $reg->get_root_key;
	my $key;

# Newer version Amcache.hve files
# Devices not parsed at this time
  my $key_path = 'Root\\InventoryApplicationFile';
  if ($key = $root_key->get_subkey($key_path)) {
		parseInventoryApplicationFile($key);
		
	}
	else {
		::logMsg($key_path." not found.");
	}
  
  my $key_path = 'Root\\InventoryApplication';
  if ($key = $root_key->get_subkey($key_path)) {
		parseInventoryApplication($key);
		
	}
	else {
		::logMsg($key_path." not found.");
	}
	
# Older version AmCache.hve files
# Root\Files subkey	
	my $key_path = 'Root\\File';
	if ($key = $root_key->get_subkey($key_path)) {
		parseFile($key);
		
	}
	else {
		::logMsg($key_path." not found.");
	}
	
# Root\Programs subkey	
	$key_path = 'Root\\Programs';
	if ($key = $root_key->get_subkey($key_path)) {
		parsePrograms($key);
	}
	else {
		::logMsg($key_path." not found.");
	}
}

sub parseInventoryApplicationFile {
	my $key = shift;
	my @sk = $key->get_list_of_subkeys();
	if (scalar(@sk) > 0) {
		::rptMsg("results/amcache/InventoryApplicationFile.csv","Path|Time|Hash");	
		foreach my $s (@sk) {
		  my $lw = $s->get_timestamp();
		  
		  my $path;
		  eval {
		  	$path = $s->get_value("LowerCaseLongPath")->get_data();
		  };
			
			my $hash;
			eval {
				$hash = $s->get_value("FileID")->get_data();
				$hash =~ s/^0000//;
			};
			::rptMsg("results/amcache/InventoryApplicationFile.csv",$path."|".gmtime($lw)."|".$hash);	
		}
	}
	else {
		
	}		
}

sub parseInventoryApplication {
	my $key = shift;
	my @sk = $key->get_list_of_subkeys();
	if (scalar(@sk) > 0) {
		::rptMsg("results/amcache/inventory_apps.csv","Time|Name|Version");
		foreach my $s (@sk) {
		  my $lw = $s->get_timestamp();		
			my $name;
			eval {
				$name = $s->get_value("Name")->get_data();
			};	
			
			my $version;
			eval {
				$version = "v.".$s->get_value("Version")->get_data();
			};	
			::rptMsg("results/amcache/inventory_apps.csv",gmtime($lw)."|".$name."|".$version);
		}
	}
	else {
		
	}		
}


sub parseFile {
	my $key = shift;
	::rptMsg("results/amcache/files_amcache_results.csv","Reference|Last Write|Path|Company Name|Prodect Name|Lang Code|SHA1|Last Mod Time|Last Mod Time2|Create Time");
	my (@t,$gt);
	my @sk1 = $key->get_list_of_subkeys();
	foreach my $s1 (@sk1) {
		my $tsvstr;
# Volume GUIDs			
			
		my @sk = $s1->get_list_of_subkeys();
		if (scalar(@sk) > 0) {
			foreach my $s (@sk) {
				$tsvstr .= $s->get_name();
				$tsvstr .=  "|".gmtime($s->get_timestamp())." Z";
# update 20131213: based on trial and error, it appears that not all file
# references will have all of the values, such as Path, or SHA-1		
				eval {
					$tsvstr .=  "|".$s->get_value("15")->get_data();
				};
					
				eval {
					$tsvstr .=  "|".$s->get_value("1")->get_data();
				};
					
				eval {
					$tsvstr .=  "|".$s->get_value("0")->get_data();
				};
					
				eval {
					$tsvstr .=  "|".$s->get_value("c")->get_data();
				};
					
				eval {
					$tsvstr .=  "|".$s->get_value("3")->get_data();
				};
					
				eval {
					$tsvstr .=  "|".$s->get_value("101")->get_data();
				};
					
				eval {
					@t = unpack("VV",$s->get_value("11")->get_data());
					$gt = gmtime(::getTime($t[0],$t[1]));
					$tsvstr .=  "|".$gt." Z";
				};
					
				eval {
					@t = unpack("VV",$s->get_value("17")->get_data());
					$gt = gmtime(::getTime($t[0],$t[1]));
					$tsvstr .=  "|".$gt." Z";
				};
					
				eval {
					@t = unpack("VV",$s->get_value("12")->get_data());
					$gt = gmtime(::getTime($t[0],$t[1]));
					$tsvstr .=  "|".$gt." Z";
				};
					
				eval {
					$gt = gmtime($s->get_value("f")->get_data());
#						$gt = gmtime(unpack("V",$s->get_value("f")->get_data()));
					$tsvstr .=  "|".$gt." Z\n";
				};
				::rptMsg("results/amcache/files_amcache_results.csv",$tsvstr);
			}
		}
		else {
#				::rptMsg("results/amcache_results.csv","Key ".$s1->get_name()." has no subkeys.");
		}		
	}
	
}

# Root\Programs subkey
sub parsePrograms {
	my $key = shift;
	::rptMsg("results/amcache/programs_results.csv","Name|Version|Category|Uninstall");
	my @sk1 = $key->get_list_of_subkeys();
	if (scalar(@sk1) > 0) {
		foreach my $s1 (@sk1) {
			my $str;
			$str = $s1->get_value("0")->get_data();
			
			eval {
				$str .= "|".$s1->get_value("1")->get_data();
			};
			::rptMsg("results/amcache/programs_results.csv",$str);
			eval {
				$str .= "|".$s1->get_value("6")->get_data();
			};
			
			eval {
				$str .= "|".$s1->get_value("7")->get_data();
			};
				
			::rptMsg("results/amcache/programs_results.csv",$str);
		}
	}
}


1;
