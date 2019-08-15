package App::TogglInvoicer::Role::Toggl;

use Moose::Role;
use MooseX::AttributeShortcuts;
use App::TogglInvoicer::Boilerplate;
use WebService::Toggl;

has toggl => (is => 'lazy', isa => 'WebService::Toggl');

method _build_toggl () {
    WebService::Toggl->new({api_key => $self->toggl_key});
}

has toggl_key => (is => 'lazy', isa => 'Str');

method _build_toggl_key () {
    my $key = $self->config->{toggl}{api_key}
        or Carp::croak 'toggl.api_key is not set in ', $self->config_file;

    return $key;
}

requires qw(config config_file);

1;
