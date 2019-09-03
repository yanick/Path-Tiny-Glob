package Path::Tiny::Glob::Visitor;
# ABSTRACT: directory visitor for Path::Tiny::Glob

use Moo;

require Path::Tiny;
use List::Lazy qw/ lazy_fixed_list /;

use experimental qw/
    signatures
    postderef
/;

has path => (
    is	    => 'ro',
    required => 1,
);

has globs => (
    is => 'ro',
    required => 1,
);

has children => (
    is => 'ro',
    lazy => 1,
    default => sub {
        [ Path::Tiny::path($_[0]->path)->children ];
    }
);

has found => (
    is => 'ro',
    default => sub { [] },
);

has next => (
    is => 'ro',
    default => sub { +{} },
);

sub as_list($self) {

    $self->match( $_ ) for $self->globs->@*;

    return lazy_fixed_list $self->found->@*, $self->subvisitors;
}

sub subvisitors($self) {
    return map {
        Path::Tiny::Glob::Visitor->new(
            path => $_,
            globs => $self->next->{$_},
        )->as_list
    } sort keys $self->next->%*;
}

sub match( $self, $glob ) {
    my( $head, $rest ) = split '/', $glob, 2;

    return $self->match( $rest ) if $head eq '.';

    if( $head eq '**' ) {

        return unless $rest;

        push $self->next->{$_}->@*, "**/$rest" for grep { $_->is_dir } $self->children->@*;
        $self->match( split '/', $rest, 2 );

        return;
    }

    # TODO optimize for when there is no globbing (no need
    # to check all the children)
    if( $rest ) {
        no warnings;

        push $self->next->{$_}->@*, $rest for grep {
            $_->basename =~ glob2re($head)
        } grep { $_->is_dir }  $self->children->@*;

        return;
    }

    push $self->found->@*,
        grep { $_->is_file }
        grep { $_->basename =~ glob2re($head) }
                $self->children->@*;
}

# turn a glob into a regular expression
sub glob2re($glob) {
    $glob =~ s/\?/.?/g;
    $glob =~ s/\*/.*/g;
    return qr/^$glob$/;
}

1;
