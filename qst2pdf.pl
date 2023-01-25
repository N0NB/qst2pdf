#!/usr/bin/env perl

#   qst2pdf.pl -- a script to process the QST View .tif and .jpg
#   files into one PDF per issue. (1950 through 2004)

#   Copyright (C) 2002,2003,2004,2010,2011 by Nate Bargmann, n0nb@n0nb.us
#   Additions to handle all cases Copyright (C) 2023 by Bill Weinel, w4whw@arrl.net
#
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Cwd;
use Getopt::Long;
use Pod::Usage;

my $ver = "2011-01-27";
my $copy = "2002,2003,2004,2010,2011";
my $newver = "2023-01-13";
my $newcopy = "2023";
my $year;
my $month;
my $file;
my $cc;
my $yy;			# 2 digit year directory name
my $YY;			# raw CD year directory name
my $mm;
my $in;
my $cd_dir;
my $out_dir;
my $help;
my $man;
my $single;         # defined, single issue mode
my $debug;          # defined, debugging output
my @years;
my @months;
my @files;
my @temp;

# Parse command line options
argv_opts();

sub get_files;

print "Original qst2pdf version $ver, Copyright (C) $copy Nate Bargmann N0NB\n";
print "qst2pdf version $newver, portions Copyright (C) $newcopy Bill Weinel W4WHW\n";
print "qst2pdf comes with ABSOLUTELY NO WARRANTY. This is free software,\n";
print "and you are welcome to redistribute it.  See the file GPL-3.\n\n";

# The QST CDROM has the title of QSTXXXX[_XX] where XXXX is a four digit year,
# e.g. QST1960, or QST1966_67.  Each year is in a two-digit directory, e.g. 60,
# and each issue month is in its own directory 1-12.  The complete path to the
# January 1960 issue would be QST1960/60/1.


# Check HAL mounted CDROM first on /media
@files = get_files("/media/$ENV{'USER'}/", "d");

if (@files) {
DIR:    foreach $file (@files) {
            if ($file =~ /^QST(\d+)_?\d?\d?/) {
                if ($debug) {print "CDROM title: $file\n"};
                $cd_dir = "/media/$ENV{'USER'}/" . $file;
                if ($debug) {print "cd_dir string: $cd_dir\n"};
                $cc = substr($1, 0, -2);
                if ($debug) {print "Century: $cc\n"};
                last DIR;
            }
             elsif ($file =~ /^qst(\d+)_?\d?\d?/) {		#handle a lower case cd name
                 if ($debug) {print "CDROM title: $file\n"};
                 $cd_dir = "/media/$ENV{'USER'}/" . $file;
                 if ($debug) {print "cd_dir string: $cd_dir\n"};
                 $cc = substr($1, 0, -2);
                 if ($debug) {print "Century: $cc\n"};
                 last DIR;
             }
    }
} else {
    $cd_dir = "/cdrom";						# fallback for older systems
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

unless ($single) {
    print "\nThe following year subdirectories were found on CD and will be processed:\n";
    print "@years\n\n";
} else {
    print "\nPlease select one of the following years:\n";
}


while (1) {					# process years
    unless ($single) {
        $YY = shift @years;			# get raw year subdirectory names from CD
        $yy = substr($YY, -2);			# only use last two characters of year CD subdirectory for processing
        print "Processing year $yy\n";
    } else {
        print "@years\n\n";			# initialize year variables
        $yy = $YY = $years[0];
        print "year: [$yy]\n";
        chomp($in = <STDIN>);

        if ($in eq "") {
        } elsif ($in ne $yy) {
            $yy = $YY = $in;			# get year from user
        }
    }

    unless (-d "$out_dir/$cc$yy") {
        `mkdir $out_dir/$cc$yy`;
    }
    chdir("$out_dir/$cc$yy") or die "Cannot chdir to $out_dir/$cc$yy: $!";

    if ($debug) {print "\nDirectory to get files from CD is: $cd_dir/$YY\n";
                 print "Directory to save files to is: $out_dir/$cc$yy\n";
                }

    @temp = get_files("$cd_dir/$YY", "d");				# get files off the CD year directory
    @months = sort { $a <=> $b } @temp;					# find months from files

    unless ($single) {
        print "\nThe following months will be converted to PDF:\n";
        print "@months\n\n";
    } else {
        print "\nPlease select one of the following months:\n";
    }

    while (1) {								# process months
        unless ($single) {
            $mm = shift @months;
            print "Processing month $mm\n";
        } else {
            print "@months\n\n";					# initialize months variable
            $mm = $months[0];
            print "month: [$mm]\n";
            chomp($in = <STDIN>);

            if ($in eq "") {
            } elsif ($in ne $mm) {
                $mm = $in;						# get month from user
            }
        }

        convert_files($cc, $yy, $YY, $mm, $cd_dir, $debug);		# main conversion process
 c$envelope_#10_template.roffc$envelope_#10_template.roff
        unless ($single) {
            unless (@months) {
                chdir("$out_dir/$cc$yy");
                last;
            }
        } else {
            print "Would you like to process another month in $cd_dir/$yy? [Y/n] ";
            chomp($in = <STDIN>);

            unless ($in =~ /^y/i || $in eq "") {
                chdir("$out_dir/$cc$yy");
                last;
            }
        }
    }

    unless ($single) {
        unless (@years) {
            chdir("$out_dir");
            last;
        }
    } else {
        print "Would you like to process another year in $cd_dir? [Y/n] ";
        chomp($in = <STDIN>);

        unless ($in =~ /^y/i || $in eq "") {
            chdir("$out_dir");
            last;
        }
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


# Convert the image files into an intermediate PS file, mangle the BoundingBox
# property and convert to PDF.  Also removes all intermediate files.
#
# Expected arguments:
#   $cc     two digit century
#   $yy     two digit year
#   $YY     Raw CD directory name (may be 2 or 3 characters)
#   $mm     two digit month
#   $cd_dir mounted CDROM directory
#   $debug  debugging flag (set on command line)
#
sub convert_files {
    my ($cc, $yy, $YY, $mm, $cd_dir, $debug) = @_;

my $test_cnt = 0;

    my $bbox;
    my $count = 0;
    my $file;
    my $line;
    my $merge = '';
    my $mrg_file;
    my $out_debug;
    my $pdf_file;
    my $pgm_file;
    my $ps_file;
    my $tmp_file;

    my @bbox;
    my @files;

    if ($debug) {
        $out_debug = '';
    } else {
        $out_debug = ' 2> /dev/null'
    }

    @files = get_files("$cd_dir/$YY/$mm", "r");					# use raw directory $YY to get files
    foreach $file (@files) {
        if ($file =~ m#.*\.tif$#) {
            $tmp_file = $ps_file = $file;
            $tmp_file =~ s/\.tif/.tmp/;
            $ps_file =~ s/\.tif/.ps/;
            `tiff2ps -1 -e $cd_dir/$YY/$mm/$file -O $tmp_file$out_debug`;	# use raw $YY to read
        }
        elsif ($file =~ m#.*\.jpg$#) { # 1995 issues and later have graphics in jpg and text in tif
            $tmp_file = $ps_file = $pgm_file = $file;
            $pgm_file =~ s/\.jpg/.pgm/;
            $tmp_file =~ s/\.jpg/.tmp/;
            $ps_file =~ s/\.jpg/.ps/;
            `jpegtopnm $cd_dir/$YY/$mm/$file > $pgm_file$out_debug`;		# use raw $YY to read
            `pnmtops $pgm_file > $tmp_file$out_debug`;
            unlink($pgm_file);
        }
        elsif ($file =~ m#.*\.TIF$#) {						# Handle uppercase filenames
             $tmp_file = $ps_file = $file;
             $tmp_file =~ s/\.TIF/.tmp/;
             $ps_file =~ s/\.TIF/.ps/;
             `tiff2ps -1 -e $cd_dir/$YY/$mm/$file -O $tmp_file$out_debug`;	# use raw $YY to read
        }
        elsif ($file =~ m#.*\.JPG$#) { 						# Handle uppercase filenames
             $tmp_file = $ps_file = $pgm_file = $file;
             $pgm_file =~ s/\.JPG/.pgm/;
             $tmp_file =~ s/\.JPG/.tmp/;
             $ps_file =~ s/\.JPG/.ps/;
             `jpegtopnm $cd_dir/$YY/$mm/$file > $pgm_file$out_debug`;		# use raw $YY to read
             `pnmtops $pgm_file > $tmp_file$out_debug`;
             unlink($pgm_file);
        }
	else {
	     next;								# not a tif or jpg.. skip
	}

        if ($debug) {print "ps_file name read is: $ps_file\n"};

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
        $bbox[1] = int((798 - $bbox[3]) / 2);
        $bbox[2] += $bbox[0];
        $bbox[3] += $bbox[1];
        `epsffit -c $bbox[0] $bbox[1] $bbox[2] $bbox[3] $tmp_file $ps_file$out_debug`;
        $merge = $merge . $ps_file . " ";
        $count++;
        unlink($tmp_file);
        print ".";
    }										# end for loop

    # Mangle filename for final output
    if ($debug) {print "Original ps_file name is: $ps_file\n"};
    if ( length($ps_file) > 10 ) {
    $ps_file = substr($ps_file, -10, 10);	        # fix longer 2000+ file names by truncating to 10 characters
     }
    $mrg_file = $cc . $ps_file;							# Add century digits to filename
    $mrg_file =~ s/(^\d{4})(\d{2}).*/$1\-$2.ps/;				# Cut to six_digits.ps
    if ($debug) {print "Completed mrg_file name after mangle is: $mrg_file\n"};

    `gs -dNOPAUSE -sDEVICE=ps2write -dBATCH -sOutputFile=$mrg_file $merge$out_debug`;

    print "\n$count .ps files merged into $mrg_file\n";

    unless($count == unlink(split(' ', $merge))) {
        warn "Could not remove all the .ps files after merge: $!";
    }

    print "Converting $mrg_file into a PDF\n";
    `ps2pdf $mrg_file$out_debug`;
    unlink($mrg_file);
    print "\n";
}


# Parse the command line for supported options.  Print help text as needed.
sub argv_opts {

    # Parse options and print usage if there is a syntax error,
    # or if usage was explicitly requested.
    GetOptions('help|?'     => \$help,
                man         => \$man,
#               "port=i"    => \$port,
#               "host=s"    => \$host,
                single      => \$single,
                debug       => \$debug
            ) or pod2usage(2);
    pod2usage(1) if $help;
    pod2usage(-verbose => 2) if $man;

}


# POD for pod2usage

__END__

=head1 NAME

qst2pdf.pl - Collates QST View CDROM page files to a PDF per issue.

=head1 SYNOPSIS

qst2pdf.pl [options]

 Options:
    --single    Process an arbitrary issue from a CDROM
    --help      Brief help message
    --man       Full documentation
    --debug     Enable debugging output

=head1 DESCRIPTION

B<qst2pdf.pl> collates individual QST View CDROM page files into a single PDF
per issue.

A script to convert .tif graphics files (used by QST View) into one PDF per
issue.  This script will create output directories for each year/month
converted and features a batch mode (default) or single issue mode for
processing an entire CDROM or arbitrary issues.  You will need write
permissions in the output directory.

The program parses the QST View CDROM file system and processes the TIFF
files by first centering them on the page and then reducing the effective
page size to US Letter (8.5 inches by 11 inches) and writes the output to a
PostScript file.  Once the issue's pages are converted to one PS file per
page all of the PS files are collated together and the conversion to PDF is
performed.  The output directory structure is a year directory containing
the relevant year's PDF files .  Each PDF is named as YYYY-MM.pdf for easy
identification.

=head1 OPTIONS

=over 8

=item B<--single>

Process each issue singly using interactive prompts.  Can be used to process
an arbitrary issue from a given CDROM rather than in the default batch mode.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints this manual page and exits.

=item B<--debug>

Enables debugging output to the console.

=back

=head1 SEE ALSO

The included README file contains the complete documentation.

=cut
