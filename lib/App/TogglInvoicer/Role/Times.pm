package App::TogglInvoicer::Role::Times;

use Moose::Role;
use App::TogglInvoicer::Boilerplate;

requires qw(start end duration);

method hours () {
    sprintf '%.02f', $self->minutes / 60;
}

method minutes () {
    int($self->duration / 60);
}

1;
