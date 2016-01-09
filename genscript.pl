#!/usr/bin/perl
# Reads a raw ftrace log file and prints a gdb script file to stdout.
# The gdb script file should be run from within gdb:
# gdb> source /tmp/gdbscript
# When run in this manner, a file called /tmp/gdbsysms is created which
# is used further during processing
use strict;

sub get_fields($) {
    my $buf = shift;
    my @ret = unpack('Q6', $buf);

    return @ret;
}

my $logfile = shift or die "usage: $0 ftrace-log-file";

my $buf;
open (FD, $logfile) or die "Could not read $logfile: $!";
my %syms;
print "set height 0\n";
print "set logging file /tmp/gdbsyms\n";
print "set logging on\n";
while(read FD, $buf, 6 * 8) { # 6 64-bit unsigned ints.
    my ($type, $this_fn, $call_site, $timestamp, $pid, $tid) = get_fields($buf);
    #printf("%llu   0x%x\n", $timestamp, $this_fn);
    $syms{$this_fn} = 1;
}

foreach(keys(%syms)) {
    printf("x 0x%x\n", $_);
}
print "set logging off\n";
