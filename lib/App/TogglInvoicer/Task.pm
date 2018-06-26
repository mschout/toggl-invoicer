package App::TogglInvoicer::Task;

use Moose;
use MooseX::AttributeShortcuts;
use App::TogglInvoicer::Boilerplate;
use App::TogglInvoicer::Types qw(DateTime);
use namespace::autoclean;

has description => (is => 'ro', isa => 'Str', required => 1);

has duration => (is => 'ro', isa => 'Int', required => 1);

has [qw(start end)] => (is => 'ro', isa => DateTime, required => 1, coerce => 1);

has hours => (is => 'lazy', isa => 'Str');

has minutes => (is => 'lazy', isa => 'Int');

has project => (is => 'ro', isa => 'Str');

method _build_minutes () {
    int($self->duration / 60);
}

method _build_hours () {
    sprintf '%.02f', $self->minutes / 60;
}

__PACKAGE__->meta->make_immutable;
