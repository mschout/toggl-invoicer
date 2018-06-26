package App::TogglInvoicer::Types;

use strict;
use warnings;
use MooseX::Types -declare  => [qw(DateTime)];
use MooseX::Types::Moose qw(Str);
use DateTime::Format::ISO8601;

class_type DateTime, { class => 'DateTime' };

coerce DateTime,
    from Str,
    via { DateTime::Format::ISO8601->parse_datetime($_) };

1;
