#!/usr/bin/env perl
 
use 5.20.0;

use Log::Any '$log';

use Log::Any::Adapter;
Log::Any::Adapter->set('Stdout');

use experimental qw/ signatures postderef /;

use Path::Tiny; 

say for wildglob( '~/work/blog_entries/*/entry' );

sub wildglob($path) {
    my $dir = $path =~ s!^(~[^/]*)/!! ? path($1)
            : $path =~ s!^/!!         ? Path::Tiny->rootdir 
            : path('.');

    return _wildglob( $dir, $path );
}

use List::AllUtils qw/ pairmap uniq /;

use lib 'tools/lib';
use Wildglob::Entry;


sub _wildglob( $path, @choices ) {
    $log->info( '>', $path );

    my $entry = Wildglob::Entry->new(path => $path);

    for my $c ( @choices ) {
        $entry->match( split '/', $c, 2 );
    }

    return $entry->found->@*, pairmap { _wildglob(path($a), uniq @$b ) } 
        $entry->next->%*;
}

