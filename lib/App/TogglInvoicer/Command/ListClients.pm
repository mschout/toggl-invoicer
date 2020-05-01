package App::TogglInvoicer::Command::ListClients;

use MooseX::App::Command;
use strictures 2;

use App::TogglInvoicer::Boilerplate;
use Text::Table;
use WebService::Toggl;

extends 'App::TogglInvoicer::Command';

with 'App::TogglInvoicer::Role::Toggl';

method run() {
    my @clients = $self->toggl->me->clients->all;

    unless (@clients) {
        say 'No available clients';
        return;
    }

    my $table = Text::Table->new('Id', 'Name', 'Alias');

    for my $client (@clients) {
        $table->add( $client->id, $client->name, $self->client_aliases->{ $client->id } || '' );
    }

    say 'Clients';
    say '';

    say $table;

    return;
}

1;

__END__

=head1 SYNOPSIS

 toggl-invoicer list-clients

=head1 DESCRIPTION

This command will list your available clients in Toggl

=cut
