package App::TogglInvoicer::Command::ListClients;

use MooseX::App::Command;
use strictures 2;

use App::TogglInvoicer::Boilerplate;
use WebService::Toggl;

extends 'App::TogglInvoicer::Command';

with 'App::TogglInvoicer::Role::Toggl';

method run() {
    my @clients = $self->toggl->me->clients->all;

    unless (@clients) {
        say 'No available clients';
        return;
    }

    say 'Clients';
    say '';

    for my $client (@clients) {
        say join(': ', $client->id, $client->name);
    }

    return;
}

1;

__END__

=head1 SYNOPSIS

 toggl-invoicer list-clients

=head1 DESCRIPTION

This command will list your available clients in Toggl

=cut
