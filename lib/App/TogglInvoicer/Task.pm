package App::TogglInvoicer::Task;

use Moose;
use MooseX::AttributeShortcuts;
use App::TogglInvoicer::Boilerplate;
use App::TogglInvoicer::Types qw(DateTime);
use namespace::autoclean;

has project => (is => 'ro', isa => 'Str');

has description => (is => 'ro', isa => 'Str', required => 1);

has duration => (is => 'ro', isa => 'Int', required => 1);

has [qw(start end)] => (is => 'ro', isa => DateTime, required => 1, coerce => 1);

with 'App::TogglInvoicer::Role::Times';

__PACKAGE__->meta->make_immutable;
