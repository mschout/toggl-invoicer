package App::TogglInvoicer::Command::Generate;

use MooseX::App::Command;
use MooseX::AttributeShortcuts;
use strictures 2;

use App::TogglInvoicer::Boilerplate;
use App::TogglInvoicer::LineItem;
use App::TogglInvoicer::Task;
use DateTime;
use Hash::Ordered;
use List::Util 'sum';
use Math::Currency 'Money';
use Path::Tiny 'path';
use Template;
use WebService::Toggl;

extends 'App::TogglInvoicer::Command';

option invoice_number => (
    is            => 'lazy',
    isa           => 'Int',
    cmd_flag      => 'invoice-number',
    documentation => q[The invoice number.  Default is next in sequence for current year YYYYNNN]);

option workspace => (
    is            => 'lazy',
    isa           => 'Maybe[Str]',
    predicate     => 1,
    documentation => q[The Workspace ID From Toggl]);

option client => (
    is            => 'lazy',
    isa           => 'Maybe[Str]',
    predicate     => 1,
    documentation => q[The Toggl Client ID]);

option hourly_rate => (
    is            => 'lazy',
    isa           => 'Maybe[Num]',
    predicate     => 1,
    cmd_flag      => 'hourly-rate',
    documentation => q[Your hourly rate]);

parameter month => (
    is            => 'lazy',
    isa           => 'Str',
    documentation => q[The YYYY-MM of the month to query in Toggl]);

has [qw(since until)] => (is => 'lazy', isa => 'DateTime');

has [qw(toggl_key client_name)] => (is => 'lazy', isa => 'Str');

has line_items => (is => 'lazy', isa => 'ArrayRef[App::TogglInvoicer::LineItem]');

has total_hours => (is => 'lazy', isa => 'Num');

has total_minutes => (is => 'lazy', isa => 'Int');

has toggl => (is => 'lazy', isa => 'WebService::Toggl');

has toggl_report => (is => 'lazy', isa => 'ArrayRef[HashRef]');

has template => (is => 'lazy', isa => 'Template');

method run () {
    unless (defined $self->hourly_rate) {
        say "You must either configure your hourly rate or pass it as an option";
        return;
    }

    unless (defined $self->workspace) {
        return $self->show_workspaces;
    }

    unless (defined $self->client) {
        return $self->show_clients;
    }

    my $client_name = $self->client_name;

    my $tt = $self->template;

    my $amount_due = Money($self->hourly_rate) * $self->total_hours;
    my $client_details = $self->config->{'client '.$self->client} || {};

    my %vars = (
        line_items     => $self->line_items,
        hourly_rate    => Money($self->hourly_rate),
        amount_due     => $amount_due,
        invoice_num    => $self->invoice_number,
        invoice_date   => DateTime->today,
        client_name    => $self->client_name,
        client_country => $client_details->{country},
        client_email   => $client_details->{email},
        total          => {
            minutes => $self->total_minutes,
            hours   => $self->total_hours
        }
    );

    my $out = path($self->output_dir)->child($self->invoice_number . '.tex')->stringify;
    $self->template->process('template.tex', \%vars, $out)
        or Carp::croak $self->template->error;

    say 'Invoice ', $self->invoice_number, ' saved in ', $out;
}

method show_workspaces () {
    say 'No workspace specified.';
    say 'You can set the workspace in ', $self->config_file, ' or, use --workspace=id';
    say '';
    say 'Available workspaces: ';
    say '';

    for my $ws ($self->toggl->me->workspaces->all) {
        say join(': ', $ws->id, $ws->name);
    }

    return;
}

method show_clients () {
    say 'No Client ID specified.';

    say 'You can set the client ID in ', $self->config_file, ' or, use --client=id';
    say '';
    say 'Available clients: ';
    say '';

    for my $client ($self->toggl->me->clients->all) {
        say join(': ', $client->id, $client->name);
    }

    return;
}

method _combine_tasks ($tasklist) {
    my @out;

    my $tasks = Hash::Ordered->new;

    for my $item (@$tasklist) {
        my $key = join ' ', $item->start->strftime('%Y%m%d'), $item->project, $item->description;

        unless ($tasks->exists($key)) {
            $tasks->set($key, []);
        }

        push $tasks->get($key)->@*, $item;
    }

    return $tasks->values;
}

method _build_client_name () {
    my %clients = map { $_->id => $_->name } $self->toggl->me->clients->all;

    my $client = $self->client;

    return $clients{ $self->client };
}

method _build_month () {
    DateTime->today->strftime('%Y-%m');
}

method _build_toggl_report () {
    my $pages;
    my $page = 0;

    my @report;

    do {
        $page += 1;

        my $current_page = $self->toggl->details({
            workspace_id => $self->workspace,
            since        => $self->since,
            until        => $self->until,
            page         => $page});

        push @report, $current_page->data->@*;

        $pages //= POSIX::ceil($current_page->total_count / $current_page->per_page);
    } until ($page == $pages);

    # Toggl API has a order_desc parameter to specify the ordering, but
    # WebService::Toggl does not support it.  work around by sorting manually
    return [sort { $a->{start} cmp $b->{start} } @report];
}

method _build_line_items () {
    my $report = $self->toggl_report;

    my $client_name = $self->client_name;

    my @tasks;
    for my $entry (grep { $_->{client} eq $client_name } $report->@*) {
        next if $entry->{dur} < 60000; # discard tasks < 1 minute long

        push @tasks, App::TogglInvoicer::Task->new(
            seconds     => int($entry->{dur} / 1000),
            start       => $entry->{start},
            end         => $entry->{end},
            description => $entry->{description},
            project     => $entry->{project});
    }

    my @line_items;

    for my $tasks ($self->_combine_tasks(\@tasks)) {
        push @line_items, App::TogglInvoicer::LineItem->new(
            project     => $tasks->[0]->project,
            description => $tasks->[0]->description,
            tasks       => $tasks);
    }

    return \@line_items;
}

method _build_since () {
    my ($year,$month) = split '-', $self->month;

    DateTime->new(year => $year, month => $month);
}

method _build_until () {
    my $since = $self->since;

    DateTime->last_day_of_month(year => $since->year, month => $since->month);
}

method _build_toggl_key () {
    my $key = $self->config->{toggl}{api_key}
        or Carp::croak 'toggl.api_key is not set in ', $self->config_file;

    return $key;
}

method _build_toggl () {
    WebService::Toggl->new({api_key => $self->toggl_key});
}

method _build_workspace () {
    $self->config->{toggl}{workspace};
}

method _build_hourly_rate () {
    $self->config->{_}{hourly_rate};
}

method _build_total_hours () {
    sprintf '%.02f', $self->total_minutes / 60;
}

method _build_total_minutes () {
    my $total_seconds = sum map { $_->seconds } $self->line_items->@*;

    return int($total_seconds / 60);
}

method _build_template () {
    Template->new({ INCLUDE_PATH => $self->top_dir });
}

method _build_invoice_number () {
    my $year = 1900 + (localtime)[5];

    my $num = 0;

    my $format = "$year\%03d";

    my $dir = path($self->output_dir);

    my $path;

    do {
        $path = $dir->child(sprintf "${format}.tex", ++$num);
    } while ($path->exists);

    return sprintf $format, $num;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 SYNOPSIS

 toggl-invoicer generate --invoice-dir path/to/save/invoices

=head1 DESCRIPTION

This command generates an invoice for the given month (default is the current month).

=cut
