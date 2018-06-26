package App::TogglInvoicer::Boilerplate;

use 5.020;
use Modern::Perl;
use Import::Into;

sub import {
    my $class = shift;

    my $target = caller;

    Modern::Perl->import::into($target, @_);

    # postfix dereferencing without warnings
    feature->import::into($target, 'postderef');
    warnings->unimport::out_of($target, 'experimental::postderef');
    warnings->unimport::out_of($target, 'uninitialized');

    require Function::Parameters;

    Function::Parameters->import::into($target, ':strict');
}

1;
