package Redacted::Turingwatch::Database;

use strict;
use warnings;

use Carp qw(croak);
use Cwd qw(realpath);
use DBI;
use FindBin;
use Redacted::Turingwatch::Util::Config qw(config);
use Readonly;

use base qw( Exporter );
our @EXPORT_OK = qw(
    dbi_handle readonly_dbi_handle
);

Readonly my $SCHEMA_PATH => 'sql/schema.sql';
Readonly my $BASE_DATA_PATH => 'sql/base_data.sql';

my $dbh;
my $readonly_dbh;

sub dbi_handle {
    unless (defined $dbh) {
        $dbh = _init_dbh(\$dbh, _master_config());
    } else {
        return $dbh;
    }
}

sub readonly_dbi_handle {
    unless (defined $readonly_dbh) {
        $readonly_dbh = _init_dbh(\$readonly_dbh, _readonly_config());
    } else {
        return $readonly_dbh;
    }
}

sub _init_dbh {
    my ($dbh, $config) = @_;

    $$dbh = DBI->connect(
        _dbi_dsn($config), $config->{username}, $config->{password},
        {RaiseError => 1, PrintError => 0, AutoCommit => 1, mysql_auto_reconnect => 1}
    );
}


sub _master_config {
    return {
        hostname => config('hostname'),
        database => config('database'),
        username => config('username'),
        password => config('password'),
        port     => config('port', 0),
    };
}

sub _readonly_config {
    my $readonly_config = config('readonly_db');
    $readonly_config->{port} = 0 if !defined $readonly_config->{port};
    return $readonly_config;
}

sub dbi_dsn {
    return _dbi_dsn(_master_config());
}

sub readonly_dbi_dsn {
    return _dbi_dsn(_readonly_config());
}

sub _dbi_dsn {
    my ($config) = @_;

    my $dbstring = "dbi:mysql:database=" . $config->{database} . ";host=" . $config->{hostname};

    if (my $db_port = $config->{port}) {
        $dbstring .= ':' . $db_port;
    }

    my $mysql_use_ssl = config('mysql_use_ssl', 0);
    my $mysql_ssl_ca_file = config('mysql_ssl_ca_file', 0);
    if ($mysql_use_ssl && $mysql_use_ssl eq 'true' && $mysql_ssl_ca_file && $mysql_ssl_ca_file ne 'false') {
        $dbstring .= ';mysql_ssl=1;mysql_ssl_ca_file=' . $mysql_ssl_ca_file;
    }

    return $dbstring;
}


1;

__END__

=head1 NAME

Redacted::Turingwatch::Database - module providing access to the Turingwatch database

=head1 SYNOPSIS

 use Redacted::Turingwatch::Database qw(dbi_handle readonly_dbi_handle);
 my $dbh = dbi_handle();
 my $readonly_dbh = readonly_dbi_handle();

=head1 DESCRIPTION

A module providing functions for accessing the turingwatch database.

=head1 FUNCTIONS

=over

=item dbi_handle

Obtain a DBI handle to the turingwatch master database with read and write
permissions.

=item readonly_dbi_handle

Obtain a DBI handle to a turingwatch database with read only permissions. In
production this could be a slave DB so may have some replica lag.

=back

=cut
