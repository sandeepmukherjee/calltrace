#!/usr/bin/perl


use strict;

# Check if stack1 is part of stack 2. For example this is true:
# stack1: a->b->c
# stack2: a->b->c->d
# Both are strings in above form.
sub is_substack($$) {
    my ($stack1, $stack2) = @_;

    return 0 if(length($stack1) > length($stack2));
    return $stack2 =~ m/^$stack1/;

}

sub parse_line($) {
    my $inline = shift;
    my %ret;
    # parse:
    #22:28:43: 80330e3d0 -->    SomeFunction
    # OR
    #18:34:02: 7f7ff7a10700 -->  sqlite3_config
    $ret{'timestamp'} = substr($inline, 0, 8);
    my $remain = substr($inline, 10);
    if ($remain =~ m/^([0-9a-fA-F]+) ([-<>]+)(\s+)(\w+)/) {
        $ret{'tid'} = $1;
        $ret{'direction'} = ($2 eq '-->') ? 'IN' : 'OUT';
        $ret{'level'} = length($3)/2;
        $ret{'function'} = $4;
    } else {
        die "Invalid input line: $inline";
    }

    return %ret;
}

my %stacklist; # Key = tid, value = ref to array representing a stack.
my %statelist; # Key = tid, value = 'INGRESS' or 'EGRESS'
my $state;
# Parse next line.
while (<>) {
    chomp;
    my %parsed = parse_line($_);
    my $tid = $parsed{tid};
    my @stack;
    if (defined($stacklist{$tid})) {
        my $stackref = $stacklist{$tid};
        @stack = @$stackref;
    } else {
        @stack = ();
    }
    if ($parsed{'direction'} eq 'IN') {
        $statelist{$tid} = 'INGRESS';
        # If -->:
        #     Add to current stack.
        push(@stack, $parsed{'function'})
    } else {
        my $state = $statelist{$tid};
        # else:
        #     Current stack complete if direction is reversed
        #     Check if stack exists in list.
        #     Increment refcount or create if doesn't exist.
        if ($state eq 'INGRESS') {
            print $parsed{timestamp}, " ", $parsed{tid}, " ", join('->', @stack), "\n";
        }
        pop(@stack);
        $statelist{$tid} = 'EGRESS';
    }
    $stacklist{$tid} = \@stack;

}
