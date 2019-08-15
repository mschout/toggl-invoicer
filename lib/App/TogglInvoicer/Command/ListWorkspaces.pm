package App::TogglInvoicer::Command::ListWorkspaces;

use MooseX::App::Command;
use strictures 2;

use App::TogglInvoicer::Boilerplate;
use WebService::Toggl;

extends 'App::TogglInvoicer::Command';

with 'App::TogglInvoicer::Role::Toggl';

method run() {
    my @workspaces = $self->toggl->me->workspaces->all;

    unless (@workspaces) {
        say 'No available workspaces';
        return;
    }

    say 'Workspaces';
    say '';

    for my $workspace (@workspaces) {
        say join(': ', $workspace->id, $workspace->name);
    }

    return;
}

1;

__END__

=head1 SYNOPSIS

 toggl-invoicer list-workspaces

=head1 DESCRIPTION

This command lists your available workspaces in Toggl

=cut
