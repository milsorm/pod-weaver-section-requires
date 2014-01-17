package Pod::Weaver::Section::Requires 0.01;
# ABSTRACT: Add section with all used modules from package excluding listed ones

use strict;
use warnings;

use Class::Inspector;
use Module::Load;
use Moose;
use Module::Extract::Use;

with 'Pod::Weaver::Role::Section';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';

has ignore => (
	is 		=> 'ro',
	isa		=> 'Str',
);

has extra_args => (
    is  => 'rw',
    isa => 'HashRef',
);

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    my $copy = {%$args};
    delete $copy->{$_}
        for map { $_->init_arg } $self->meta->get_all_attributes;
    $self->extra_args($copy);
}

sub weave_section {
    my ( $self, $doc, $input ) = @_;

    my $filename = $input->{filename};

    return if $filename !~ m{\.pm$};

	my $ignorelist = $self->ignore;
	my %exclude = map { $_ => 1 } split /\s+/, $ignorelist;
	
    my @modules = sort grep { ! exists $exclude{ $_ } } $self->_get_requires( $filename );

    return unless @modules;

    my @pod = (
        Command->new( {
            command => 'over',
               content => 4
        } ),
        (
            map {
                Command->new( {
                    command => 'item',
                    content => "* L<$_>",
                } ),
            } @modules
        ),
        Command->new( {
            command => 'back',
            content => ''
        } )
    );

    push @{ $doc->children },
		Nested->new( {
            type     => 'command',
            command  => 'head1',
            content  => 'REQUIRES',
            children => \@pod
        } );
}

sub _get_requires {
    my ( $self, $module ) = @_;
	
	my $extor = new Module::Extract::Use;
	
	my @modules = $extor->get_modules( $module );
    print "Possibly harmless: $@" if $extor->error;

    return @modules;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
