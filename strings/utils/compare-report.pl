use strict;

# run in the strings dir: perl utils/compare-report.pl en_US ja_JP

my $dir1 = $ARGV[0];
my $dir2 = $ARGV[1];

unless (-d $dir1 && -d $dir2) {
    print "Please specify to strings directories.\n";
    exit();
}

opendir DIR1, $dir1 or die $!;
opendir DIR2, $dir2 or die $!;

while (my $file = readdir(DIR1)) {
    next if ($file =~ /^\./);
    unless (-T "$dir2/$file") {
        print "MATCHING FILE DOESN'T EXIST: $dir2/$file\n";
        next;
    }
    my @compare = `perl utils/compare.pl -presence -contentsame -nonempty $dir1/$file $dir2/$file`;
    print "--------------------------------\n\n";
    print "FILES: $dir1/$file vs $dir2/$file\n";
    print @compare;
}

