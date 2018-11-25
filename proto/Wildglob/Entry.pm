=pod 

    wildpath( './**/*/foo?' );

=cut

    package Wildglob::Entry;

    require Path::Tiny; 

    use Moose;

    use experimental qw/
        signatures
        postderef
    /;

    has path => (
        is	    => 'ro',
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
    
    sub match( $self, $head=undef, $rest=undef ) {
        if( $head eq '**' ) {
            if( $rest) {
                push $self->next->{$_}->@*, "**/$rest" for grep { $_->is_dir } $self->children->@*;
                $self->match( split '/', $rest, 2 );
                return;
            }

            push $self->found->@*, grep { $_->is_file } $self->children->@*;
            return;
        }

        if( $rest ) {
            no warnings;
            push $self->next->{$_}->@*, $rest for grep { 
                $_->basename =~ glob2re($head) }
                grep { $_->is_dir }  $self->children->@*;
            return;
        }
        else {
            push $self->found->@*, grep { $_->is_file } grep { $_->basename =~ glob2re($head) } $self->children->@*;
        }
    }

sub glob2re($glob) {
    $glob =~ s/\?/.?/g;
    $glob =~ s/\*/.*/g;
    return qr/^$glob$/;
}

    1;
