#! /usr/bin/perl
#
# Reads raw calltrace log file and the file /tmp/gdbsyms (hardcoded path)
# To generate human-readable log file of stack.
# Use stacks.pl on output to process further.
use strict;
use POSIX qw(strftime);

my $LEVEL = 100;

sub get_fields($) {
    my $buf = shift;
    my @ret = unpack('Q6', $buf);

    return @ret;
}

die "usage: $0 /tmp/calltrace-PID.log" unless(scalar(@ARGV) == 1);
my $calltracefile = $ARGV[0];

my %syms; # Maps address -> symbol name
# Value is incremented by 2 for every entry, and decremented on exit

my %indents;
open(SYMLOG, "/tmp/gdbsyms") or die "Can't open /tmp/gdbsyms";
while (<SYMLOG>) {
    # parse this:
    #0x8046743d0 <NpfsFindFCB at /.automount/nfs.panwest.panasas.com/root/sb11/smukherjee/trunk-doc/src/likewise/lwio/server/npfs/fcb.c:86>: 0xe5894855
    if (/(0x[\dabcdef]+) <(\w+)/) {
        $syms{$1} = $2;
    }
}

close SYMLOG;

#foreach(keys(%syms)) {
#   print "$_ = $syms{$_}\n";
#}

my $buf;
open(CIFSLOG, $calltracefile) or die "Cannot read $calltracefile: $!";
while(read CIFSLOG, $buf, 6 * 8) { # 6 64-bit unsigned ints.
    my ($type, $this_fn, $call_site, $timestamp, $pid, $tid) = get_fields($buf);
    my $timestr = strftime('%H:%M:%S', localtime($timestamp));
    my $printit = ($LEVEL * 2 >= $indents{$tid});
    if ($type == 1) {
            # Function entry
            my $arrow = '-->';
            printf("%s: %x %s", $timestr, $tid, $arrow) if ($printit);
            $indents{$tid} += 2;
            print ' ' x $indents{$tid} if ($printit);
     } else {
            my $arrow = '<--';
            printf("%s: %x %s", $timestr, $tid,$arrow) if ($printit);
            print ' ' x $indents{$tid} if ($printit);
            $indents{$tid} -= 2;
            $indents{$tid}  = 0 if ($indents{$tid}) < 0;
    }
    my $sym = sprintf("0x%x", $this_fn);
    my $func = ($syms{$sym} ? $syms{$sym} : $sym);
    print "$func\n" if ($printit);
}

# Split threads into files using:
# mkdir tmp/
# awk -e '{print $1}' flow.txt | sort | uniq | xargs -I TID sh -c "grep TID flow.txt > tmp/TID"

