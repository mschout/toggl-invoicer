package App::TogglInvoicer::Role::Times;

use Moose::Role;
use MooseX::AttributeShortcuts;
use App::TogglInvoicer::Boilerplate;
use DateTime::Duration;
use DateTime::Format::Duration;

requires qw(seconds);

has duration => (is => 'lazy', isa => 'DateTime::Duration');

has hms => (is => 'lazy', isa => 'Str');

has _duration_formatter => (is => 'lazy', isa => 'DateTime::Format::Duration');

method _build_duration () {
    DateTime::Duration->new(seconds => $self->seconds);
}

method _build_hms () {
    $self->_duration_formatter->format_duration($self->duration);
}

method hours () {
    sprintf '%.02f', $self->seconds / 3600;
}

method minutes () {
    int($self->seconds / 60);
}

method _build__duration_formatter () {
    DateTime::Format::Duration->new(
        pattern   => '%H:%M:%S',
        normalize => 1);
}

1;
