package App::TogglInvoicer::Command;

use MooseX::App;
use MooseX::App::Utils;
use MooseX::AttributeShortcuts;
use strictures 2;

use App::TogglInvoicer::Boilerplate;
use Config::INI::Reader;
use File::Path 'mkpath';
use Path::Tiny 'path';

option invoice_dir => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'invoice-dir',
    documentation => q[The output directory for invoices. ] .
                     q[Invoices will be stored in a YYYY/YYYYNNN.ext format under this directory]);

has [qw(config_file top_dir output_dir)] => (is => 'lazy', isa => 'Str');

has config => (is => 'lazy', isa => 'HashRef');

app_command_name {
    my $command = MooseX::App::Utils::class_to_command(@_);

    return $command =~ s/_/-/gr;
};

method _build_config_file () {
    my $file = path($self->top_dir)->child('config/config.ini');

    unless ($file->exists) {
        Carp::croak 'Config file ', $file->stringify, ' does not exist';
    }

    $file->stringify;
}

method _build_config () {
    my $config = Config::INI::Reader->read_file($self->config_file);

    # address lines might be multiple lines, but INI files require one value per line.
    # We handle this by rolling all of the address_1, address_2, ... address_N
    # values lines into an arrayref as just "address"
    unless (defined $config->{personal}{address}) {
        my @address_lines = map { delete $config->{personal}{$_} }
            sort grep { /^address_[0-9]+$/ } keys $config->{personal}->%*;
        $config->{personal}{address} = \@address_lines;
    }
    else {
        # convert single line addres to arrayref
        $config->{personal}{address} = [ $config->{personal}{address} ];
    }

    return $config;
}

method _build_client () {
    $self->config->{toggl}{client};
}

method _build_output_dir () {
    my $year = 1900 + (localtime)[5];

    my $path = path($self->invoice_dir)->child($year);

    unless (-d $path) {
        mkpath $path;
    }

    return $path->stringify;
}

method _build_top_dir () {
    path(__FILE__)->parent(4)->stringify;
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

1;
