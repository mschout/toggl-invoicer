package App::TogglInvoicer::Role::Compiler;

use Moose::Role;
use App::TogglInvoicer::Boilerplate;
use Path::Tiny qw(path);

method compile_invoice(:$source_content, :$output_file ) {
  my $top_dir = path(__FILE__)->parent(5)->stringify;

  my $driver = LaTeX::Driver->new(
    source    => \$source_content,
    output    => $output_file,
    texinputs => $top_dir,
    format    => 'pdf');

  # We need to use xelatex
  $driver->program_path('/usr/bin/xelatex');

  $driver->run;
}

1;
