#! /usr/bin/perl
#
# Reads raw calltrace log file and the file $CALLTRACEDIR/gdbsyms to generate
# human-readable log file of stack.
# Use stacks.pl on output to process further.
use strict;
use POSIX qw(strftime);

my $LEVEL = 100;

sub get_fields($) {
    my $buf = shift;
    my @ret = unpack('Q6', $buf);

    return @ret;
}

my $dir = '/tmp';
$dir = $ENV{'CALLTRACEDIR'} if($ENV{'CALLTRACEDIR'});

die "usage: $0 $dir/calltrace-PID.log" unless(scalar(@ARGV) == 1);
my $calltracefile = $ARGV[0];

my %syms; # Maps address -> symbol name
# Value is incremented by 2 for every entry, and decremented on exit

my %indents;
open(SYMLOG, "$dir/gdbsyms") or die "Can't open $dir/gdbsyms";
while (<SYMLOG>) {
    # parse lines like these:
    #0x8046743d0 <funcname at /path/to/file.c:86>: 0xe5894855
    #0x406718 <WTP::WorkerThreadPool::getTotalProcessing()>:	0xe5894855
    #0x407806 <std::queue<WTP::WorkItem*, std::deque<WTP::WorkItem*, std::allocator<WTP::WorkItem*> > >::empty() const>:	0xe5894855
    if (/(0x[\dabcdef]+) <(.+)>:\t/) {
        my $sym = $2;
        my $addr = $1;
        $sym =~ s/ at .+$//;
        $syms{$addr} = $sym
    }
}

close SYMLOG;

#foreach(keys(%syms)) {
#   print "$_ = $syms{$_}\n";
#}

my $buf;
open(FD, $calltracefile) or die "Cannot read $calltracefile: $!";
while(read FD, $buf, 6 * 8) { # 6 64-bit unsigned ints.
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
            $indents{$tid}  = 2 if ($indents{$tid}) < 2;
            my $arrow = '<--';
            printf("%s: %x %s", $timestr, $tid,$arrow) if ($printit);
            print ' ' x $indents{$tid} if ($printit);
            $indents{$tid} -= 2;
    }
    my $sym = sprintf("0x%x", $this_fn);
    my $func = ($syms{$sym} ? $syms{$sym} : $sym);
    print "$func\n" if ($printit);
}

close FD;
