package App::TogglInvoicer::LineItem;

use Moose;
use MooseX::AttributeShortcuts;
use Function::Parameters;
use List::Util 'sum';
use namespace::autoclean;

has [qw(project description)] => (is => 'ro', isa => 'Str', required => 1);

has tasks => (
    is       => 'ro',
    isa      => 'ArrayRef[App::TogglInvoicer::Task]',
    required => 1);

has [qw(start end)] => (is => 'lazy', isa => 'DateTime');

has duration => (is => 'lazy', isa => 'Int');

with 'App::TogglInvoicer::Role::Times';

method _build_start () {
    $self->tasks->[0]->start;
}

method _build_end () {
    $self->tasks->[-1]->end;
}

method _build_duration () {
    sum map { $_->duration } $self->tasks->@*;
}

__PACKAGE__->meta->make_immutable;
