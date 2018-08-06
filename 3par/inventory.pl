#!/usr/bin/perl -w
use strict;
use Readonly;
use Data::Dumper;
use v5.14;

sub trim_line {
	my $line = shift @_;

	$line =~ s/^\s*//g;
	$line =~ s/^\-*//g;
	$line =~ s/\s+$//g;
	$line =~ s/\-+$//g;

	return $line;
}
sub get_params {
	my $line = shift @_;

	my %params;

	my $skip=1;
	my $index=0;
	my $count=0;
	my $value="";

	for my $i (0..length($line)-1) {
		my $char = substr($line, $i, 1);
		given ($char) {
			when(/\s/) { 
				if ($skip == 0) {
					$count = $i - $index;
					$value = substr($line,$index,$count);
					$value = trim_line($value);
					$params{"$value"}="$index,$count";
			
					$index = $i + 1; 
				}
			}
			default { $skip=0;  }
		}
	}

	$count = length($line) - $index;
	$value = substr($line,$index,$count);
	$params{"$value"}="$index,$count";

	return %params;
}

sub print_lines {
	my ($line,$hash) = @_;

	my %params = %$hash;

	my $comma = "";

	while (my ($key,$param) = each %params) {
		my ($index,$count) = split/,/, $param;
		my $value = substr($line,$index,$count);
		$value = trim_line($value);
		print "$comma\"$key\": \"$value\"\n";
		$comma=",";
	}
}
sub process_simple_inventory {
	my @inventory = @_;
	my $i = 0; 
	my %params = {};
	my $comma = "";

	#print Dumper(@inventory)."\n";

	foreach my $line (@inventory) {
		$i++;
		given ($i) {
			when (1) {
				my $inventory_name = trim_line($line);
				print "\"$inventory_name\":[\n";
			} # do nothing
			when (2) {
				%params = get_params($line);
			} 
			default  {
				print "$comma\{\n";
				print_lines($line, \%params);
				print "}\n";
				$comma=",";
			}
		}
	}
	print "]\n";
}
sub process_nested_inventory {
	my @lines = @_;

	my @inventory = ();
	my $i = 0;
	my $comma = "";

	foreach my $line (@lines) {
		$i++;

		given ($i) {
			when (1) {
				my $inventory_name = trim_line($line);
				print ",\"$inventory_name\":{\n";
			}
			default {
				given ($line) {
					when (/^$/) {} # do nothing
					when (/^\s*$/) {} # do nothing
					when (/^\-*$/) {} # do nothing
					when (/^\-*\w+\-*$/) { # found new inven
						if (scalar @inventory > 0) { process_simple_inventory(@inventory); @inventory = (); }
						push @inventory, $line;
					}
					when (/^\-*\w+\s\w+\-*$/) {
						if (scalar @inventory > 0) { process_simple_inventory(@inventory); @inventory = (); }
						push @inventory, $line;
					}
					default {
						push @inventory, $line;
					}
				}
			}
		}
	}
	print "\}\n";
}

# process inventory
sub process_inventory {

	my @lines = @_;

	# test for nested arrays;
	my $i = 0;
	my $isfound = 0;

	foreach my $line (@lines) {
		$i++;
		given ($i) {
			when (1) {	
			}
			default {
				given ($line) {
					when (/^-*\w+\s\w+-*$/) {
						$isfound = 1;
					}
				}
			}
		}
	}

	given ($isfound) {
		when (0) {
			print ",\n";
			process_simple_inventory(@lines);
		}
		when (1) { 
			process_nested_inventory(@lines);
		}
	}

	
}


my $id = 0;
my $comma = "";
my %params;
my $hyphenwords = "";
my $count = 0;
my $i = 0; 

my @lines; 

foreach my $line (<STDIN>) {
	$i++;

	chomp($line);
	given ($i) {
		when (1) { %params = get_params($line); } 	# setting mainitems params
		when (2) { 									# getting mainitems value
			print "{\n";
			print "\"MainItems:{\n";
			print_lines($line,\%params);
			print "}\n";
		}
		default {									# process other lines
			given ($line) {
				when (/^$/) 	{ 	} # do nothing
				when (/^\s+$/) 	{ 	} # do nothing 
				when (/^-*$/) 	{ 
					$count++;
					given ($count) {
						when (1) { 
							# new hyphenline is found, clear $hyphenwords
							# new inventory is found, time to process old inventory
	
							if (scalar @lines > 0) { process_inventory(@lines); @lines = (); }
						}
						when (2) {
							# some error is occured
						}
						when (3) {
							$count = 0;
						}
					}
				}
				when (/^-*\w+\s\w+-*$/) {
					given($count) {
						when (1) { $count++; $hyphenwords = trim_line($line); }
					}
					default { push @lines, $line; }
				}
				when (/^\s+\d+\s+$/) {
					given ($count) {
						when (1) { $count = 0; }
					}
				}
				when (/^\s+\d+\stotal\s+$/) {
					given ($count) {
						when (1) { $count = 0; }
					}
				}
				default {
					push @lines, $line;
				}
			}
		}
	}	
}

