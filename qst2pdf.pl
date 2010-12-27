#!/usr/bin/env perl

#	qst2pdf.pl -- a script to process the QST View .tif files into one
#	PDF per issue

#	Copyright (C) 2002,2004,2010 by Nate Bargmann, n0nb@arrl.net
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#  
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Cwd;

my $debug = 1;			# 0 == no debugging output, 1 == debugging output
my $ver = "2010-12-20";
my $copy = "2002,2004,2010";
my $count;
my $year;
my $month;
my $file;
my $tmp_file;
my $ps_file;
my $mrg_file;
my $pdf_file;
my $merge = "";
my $line;
my $yy;
my $mm;
my $in;
my $cd_dir;
my $out_dir;
my @years;
my @months;
my @files;
my @temp;
my @bbox;

sub get_files;

print "qst2pdf version $ver, Copyright (C) $copy Nate Bargmann N0NB\n";
print "qst2pdf comes with ABSOLUTELY NO WARRANTY. This is free software,\n";
print "and you are welcome to redistribute it.  See the file COPYING.\n\n";

print "An interactive helper script to convert .tif graphics files (used by\n";
print "QST View into one PDF per issue.  This script will create output\n";
print "directories for each year/month converted.  You will need write\n";
print "permissions in the output directory.\n\n\n";

# The QST CDROM has the title of QSTXXXX[_XX] where XXXX is a four digit year,
# e.g. QST1960, or QST1966_67.  Each year is in a two-digit directory, e.g. 60,
# and each issue month is in its own directory 1-12.  The complete path to the
# January 1960 issue would be QST1960/60/1.

# Check HAL mounted CDROM first on /media
@files = get_files("/media", "d");

if (@files) {
	foreach $file (@files) {
		if ($file =~ /^QST\d+_?\d?\d?/) {
			if ($debug) {print $file, "\n"};
			$cd_dir = "/media/" . $file;
		}
	}
} else {
	$cd_dir = "/cdrom";		# fallback for older systems
}

print "Path to the QST VIEW CD: [$cd_dir] ";
chomp($in = <STDIN>);

if ($in eq "") {
	# don't do anything
} elsif ($in ne $cd_dir) {
	$cd_dir = $in;
}

$out_dir = cwd();
print "Path for the .pdf file(s): [$out_dir] ";
chomp($in = <STDIN>);

if ($in eq "") {
} elsif ($in ne $out_dir) {
	$out_dir = $in;
}

@years = get_files($cd_dir, "d");

print "\nThe following years were found and will be processed:\n";


while (1) {
	print "@years\n\n";
	$yy = shift @years;
	print "year: [$yy]\n";
#	chomp($in = <STDIN>);

#	if ($in eq "") {
#	} elsif ($in ne $yy) {
#		$yy = $in;
#	}

	unless (-d "$out_dir/$yy") {
		`mkdir $out_dir/$yy`;
	}
	chdir("$out_dir/$yy") or die "Cannot chdir to $out_dir/$yy: $!";

	@temp = get_files("$cd_dir/$yy", "d");
	@months = sort { $a <=> $b } @temp;
	print "\nThe following months will be converted to PDF:\n";

	while (1) {
		print "@months\n\n";
		$mm = shift @months;
		print "month: [$mm]\n";
#		chomp($in = <STDIN>);

#		if ($in eq "") {
#		} elsif ($in ne $mm) {
#			$mm = $in;
#		}

		unless (-d "$out_dir/$yy/$mm") {
			`mkdir $out_dir/$yy/$mm`;
		}
		chdir("$out_dir/$yy/$mm") or die "Cannot chdir to $out_dir/$yy/$mm: $!";

		$count = 0;
		$merge = '';
		@files = get_files("$cd_dir/$yy/$mm", "r");
		foreach $file (@files) {
			$tmp_file = $ps_file = $file;
			$tmp_file =~ s/\.tif/.tmp/;
			$ps_file =~ s/\.tif/.ps/;
			`tiff2ps -1 -e $cd_dir/$yy/$mm/$file -O $tmp_file`;
			
			open(TMP, "< $tmp_file") or die "Cannot open $tmp_file: $!\n";
			while ($line = <TMP>) {
				if ($line =~ /^\%\%BoundingBox:/) {
					last;
				}
			}
			close(TMP);
			chomp $line;
			
			@bbox = split ' ', $line;
			shift @bbox;
			$bbox[0] = int((612 - $bbox[2]) / 2);
			$bbox[1] = int((792 - $bbox[3]) / 2);
			$bbox[2] += $bbox[0];
			$bbox[3] += $bbox[1];
			`epsffit $bbox[0] $bbox[1] $bbox[2] $bbox[3] $tmp_file $ps_file`;
			$merge = $merge . $ps_file . " ";
			$count++;
			unlink($tmp_file);
			print ".";
		}
		
		$mrg_file = $ps_file;
		$mrg_file =~ s/(^\d{4}).*/$1.ps/;
		`gs -dNOPAUSE -sDEVICE=pswrite -dBATCH -sOutputFile=$mrg_file $merge`;
		
		print "\n$count .ps files merged into $mrg_file\n";
		
		unless($count == unlink(split(' ', $merge))) {
			warn "Could not remove all the .ps files after merge: $!";
		}
		
		print "Converting $mrg_file into PDF\n";
		`ps2pdf $mrg_file`;
		unlink($mrg_file);
		
#		print "Would you like to process another month in $cd_dir/$yy? [Y/n] ";
#		chomp($in = <STDIN>);

#		unless ($in =~ /^y/i || $in eq "") {
		unless (@months) {
			chdir("$out_dir/$yy");
			last;
		}
	}
#	print "Would you like to process another year in $cd_dir? [Y/n] ";
#	chomp($in = <STDIN>);
	
#	unless ($in =~ /^y/i || $in eq "") {
	unless (@years) {
		chdir("$out_dir");
		last;
	}
}

sub get_files {
	my $name;
	my @names;
  
	opendir(CD, "$_[0]") || die "Cannot open $_[0]: $!";
	while ($name = readdir(CD)) {
		SWITCH: {
			if ($_[1] eq "r") {
				if (-r "$_[0]/$name") {
					unless ($name =~ /^\.+$/) {
						push(@names, $name);
					}
				}
				last SWITCH;
			}
			if ($_[1] eq "d") {
				if (-d "$_[0]/$name") {
					unless ($name =~ /^\.+$/) {
						push(@names, $name);
					}
				}
				last SWITCH;
			}
		}
	}
	closedir(CD);
	return @names;
}
