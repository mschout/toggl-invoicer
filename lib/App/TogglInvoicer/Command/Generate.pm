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
use MooseX::Types::DateTime::MoreCoercions qw(DateTime);
use Math::Currency 'Money';
use Path::Tiny 'path';
use Template;

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
    documentation => q[The Toggl Client ID, or, configured client name from config file]);

option hourly_rate => (
    is            => 'lazy',
    isa           => 'Maybe[Num]',
    predicate     => 1,
    cmd_flag      => 'hourly-rate',
    documentation => q[Your hourly rate]);

option since => (
    is            => 'lazy',
    isa           => DateTime,
    lazy          => 1,
    coerce        => 1,
    documentation => 'The ending time for the invoice (default: first day of prev month)'
);

option until => (
    is            => 'lazy',
    isa           => DateTime,
    lazy          => 1,
    coerce        => 1,
    documentation => 'The ending time for the invoice (default: end of "since" month)'
);

has client_id => (is => 'lazy', isa => 'Int');

has client_name => (is => 'lazy', isa => 'Str');

has line_items => (is => 'lazy', isa => 'ArrayRef[App::TogglInvoicer::LineItem]');

has seconds => (is => 'lazy', isa => 'Int');

has toggl_report => (is => 'lazy', isa => 'ArrayRef[HashRef]');

has template => (is => 'lazy', isa => 'Template');

with 'App::TogglInvoicer::Role::Times';

method run () {
    unless (defined $self->hourly_rate) {
        say "You must either configure your hourly rate or pass it as an option";
        return;
    }

    unless (defined $self->workspace) {
        return $self->show_workspaces;
    }

    unless (defined $self->client and defined $self->client_id) {
        return $self->show_clients;
    }

    my $client_name = $self->client_name;

    my $tt = $self->template;

    my $amount_due = Money($self->hourly_rate) * $self->hours;
    my $client_details = $self->config->{'client '.$self->client_id} || {};

    my %vars = (
        personal       => $self->config->{personal},
        line_items     => $self->line_items,
        hourly_rate    => Money($self->hourly_rate),
        amount_due     => $amount_due,
        invoice_num    => $self->invoice_number,
        invoice_date   => DateTime->today,
        client_name    => $self->client_name,
        client_country => $client_details->{country},
        client_email   => $client_details->{email},
        total          => {
            seconds => $self->seconds,
            minutes => $self->minutes,
            hours   => $self->hours,
            hms     => $self->hms
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

    say $self->clients_table;

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

method _build_client_id () {
    my $client = $self->client;

    if ($self->client =~ /[^0-9]/) {
        # client is not an integer, try to look it up in the config by name.
        my %aliases = $self->client_aliases->%*;

        while (my ($id, $name) = each %aliases) {
            if ($name eq $self->client) {
                return $id;
            }
        }

        Carp::croak "Could not determine client id for client ", $self->client;
    }
    else {
        # client looks like an id
        return $self->client;
    }
}

method _build_client_name () {
    my $client = $self->client_id;

    my %clients = map { $_->id => $_->name } $self->toggl->me->clients->all;

    return $clients{ $self->client_id };
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

        if (defined $current_page->data) {
          push @report, $current_page->data->@*;
        }

        $pages //= _make_page_count($current_page);
    } until ($page == $pages);

    # Toggl API has a order_desc parameter to specify the ordering, but
    # WebService::Toggl does not support it.  work around by sorting manually
    return [sort { $a->{start} cmp $b->{start} } @report];
}

fun _make_page_count ($report_details_page) {
    unless (defined $report_details_page && defined $report_details_page->per_page) {
        return 1;
    }

    return POSIX::ceil($report_details_page->total_count / $report_details_page->per_page);
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
    my $datetime = DateTime->now->subtract(months => 1)
        ->truncate(to => 'month');
}

method _build_until () {
    my $since = $self->since;

    my $until = DateTime->last_day_of_month(
        year   => $since->year,
        month  => $since->month,
        hour   => 23,
        minute => 59,
        second => 59
    );
}

method _build_workspace () {
    $self->config->{toggl}{workspace};
}

method _build_hourly_rate () {
    $self->config->{_}{hourly_rate};
}

method _build_seconds () {
    my @line_items = $self->line_items->@* or return 0;

    sum map { $_->seconds } @line_items
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
