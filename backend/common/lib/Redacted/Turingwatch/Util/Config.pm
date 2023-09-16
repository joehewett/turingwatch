package Redacted::Turingwatch::Util::Config;

use strict;
use warnings;

use Carp;
use Readonly;
use YAML qw(LoadFile);

use base qw( Exporter );
our @EXPORT_OK = qw( config );

Readonly my $default_config => "/home/jh/turingwatch/backend/common/etc/turingwatch/turingwatch.yaml";
my $global_mode = "live";

my %config;

# Load the YAML config file into an in-memory hash. Tries locations in the
# following order of precedence:
# - First argument to function
# - TURINGWATCH_CONFIG environment variable
# - Default location /etc/redacted/turingwatch.yaml
sub _load_config_file {
    my $config_hash = shift;
    my $configfile = shift;

    my $args = LoadFile($configfile);
    croak "Failed to load configuration" unless ref $args eq 'HASH';

    $config_hash->{live} = $args->{turingwatch};
}

sub config {
    my $config_file = $ENV{'TURINGWATCH_CONFIG'} || $default_config;
    _config(\%config, $config_file, @_);
}

sub _config {
    my $config_hash = shift;
    my $config_file = shift;

    my $mode = $global_mode;

    _load_config_file($config_hash, $config_file) if ($mode eq 'live' && (!defined $config_hash->{$mode}));

    my $key = shift;

    if (defined $config_hash->{$mode}{$key}) {
        return $config_hash->{$mode}{$key};
    } else {
        my $default = shift;
        croak("Configuration value for $key not defined and no default specified") if (!defined $default);
        return $default;
    }
}

1;

__END__

=head1 NAME

Redacted::Turingwatch::Util::Config - Functions for accessing the turingwatch configuration file

=head1 SYNOPSIS

use Redacted::Turingwatch::Util::Config qw(config);
my $value = config($key, $default_value);

=back

=cut

