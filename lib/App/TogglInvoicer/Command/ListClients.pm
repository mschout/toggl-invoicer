package App::TogglInvoicer::Command::ListClients;

use MooseX::App::Command;
use strictures 2;

use App::TogglInvoicer::Boilerplate;
use Text::Table;
use WebService::Toggl;

extends 'App::TogglInvoicer::Command';

method run() {
    my $table = $self->clients_table or do {
        say 'No available clients';
        return;
    };

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
