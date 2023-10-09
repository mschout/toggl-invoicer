package App::TogglInvoicer::Command::Compile;

use MooseX::App::Command;
use MooseX::AttributeShortcuts;
use strictures 2;

use App::TogglInvoicer::Boilerplate;
use Path::Tiny 'path';
use LaTeX::Driver;

extends 'App::TogglInvoicer::Command';

parameter invoice_number => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'invoice-number',
    documentation => q[The invoice number of the invoice to compile]);

has invoice_file => (is => 'lazy', isa => 'Path::Tiny');

has output_file => (is => 'lazy', isa => 'Str');

method BUILD (@args) {
    # If invoice number is the .tex file name, drop .tex
    my $invoice_number = $self->invoice_number;
    if ($invoice_number =~ /\.tex$/) {
        $self->invoice_number($invoice_number =~ s/\.tex$//r);
    }
}

method run () {
    my $source = $self->invoice_file->slurp_utf8;

    my $driver = LaTeX::Driver->new(
        source    => \$source,
        output    => $self->output_file,
        texinputs => path($self->top_dir)->absolute->stringify,
        format    => 'pdf');

    # We need to use xelatex
    $driver->program_path('/usr/bin/xelatex');

    $driver->run;
}

method _build_invoice_file () {
    my $file = path($self->output_dir)->child($self->invoice_number . '.tex');

    unless ($file->exists) {
        die $file->stringify, " does not exist!\n";
    }

    return $file;
}

method _build_output_file () {
    (my $file = $self->invoice_file->stringify) =~ s/\.tex$/.pdf/;

    return $file;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 SYNOPSIS

 toggl-invoicer compile --invoice-dir path/to/invoices 2018003

=head1 DESCRIPTION

This command compiles a PDF of an invoice from the .tex source file generated
by the "generate" command

=cut
