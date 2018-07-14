package App::TogglInvoicer::Role::Times;

use Moose::Role;
use App::TogglInvoicer::Boilerplate;

requires qw(start end seconds);

method hours () {
    sprintf '%.02f', $self->seconds / 3600;
}

method minutes () {
    int($self->seconds / 60);
}

1;
