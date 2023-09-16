package Redacted::Turingwatch::Util::Persona;

use strict;
use warnings;

use Moo;
use Carp;
use Common qw(verbose);
use Data::Dumper;
use JSON::MaybeXS;
use LWP::UserAgent;
use Data::Dumper;

use Redacted::EmailBlacklist::Util::DBI qw(eb_read_dbh);
use Redacted::Turingwatch::Database qw(dbi_handle);

=head1 NAME

Redacted::Turingwatch::Util::Persona

=head1 DESCRIPTION

Class for representing a persona that Turingwatch can use while communicating with fraudsters

=cut

has 'persona_id' => (
    is => 'ro'
);

has 'first_name' => (
    is => 'ro',
);

has 'last_name' => (
    is => 'ro',
);

has 'full_name' => (
    is => 'ro',
);

has 'email_address' => (
    is => 'rw',
    required => 1
);

=head1 CONSTRUCTION

=over

=item new ( ARGS )

Create a new persona object

B<ARGS> must be a hash that matches the required fields defined above, e.g.

  (
      email_address => "victim@email.com"
  )

=cut

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $details = _load_persona($args{email_address});
    print Dumper($details);
    die "Could not load or generate all necessary Persona details"
        unless $details->{persona_id} && $details->{first_name} && $details->{last_name} && $details->{email_address};

    $args{persona_id}    = $details->{persona_id};
    $args{email_address} = $details->{email_address};
    $args{first_name}    = $details->{first_name};
    $args{last_name}     = $details->{last_name};
    $args{full_name}     = $args{first_name} . ' ' . $args{last_name};

    return $class->$orig(%args);
};

=back

=head1 METHODS

=item _load_persona ( ARGS )

Get the information relating to this persona_id
If we haven't been given a persona_id, it means this is a fresh scam email that we're replying to
Therefore, we need to generate a new persona to start communicating with

=cut

sub _load_persona {
    my $email_address = shift;

    my $details;
    my $first_name;
    my $last_name;
    my $persona_id;

    # If we have a persona_id, this email thread already exists, so load the Persona being used
    # Otherwise, this is a new conversation that we're engaging in, and we need to generate a new Persona
    if ($email_address) {
        verbose "Loading persona";
        my $dbh = dbi_handle();
        my $get_persona_sth = $dbh->prepare(q{
            SELECT id, first_name, last_name
            FROM personas
            WHERE email_address = ?
        });
        $get_persona_sth->execute($email_address);
        my $row = $get_persona_sth->fetchrow_hashref;

        $first_name = $row->{first_name};
        $last_name = $row->{last_name};
        $persona_id = $row->{id};
    }

    if (!($first_name and $last_name and $email_address and $persona_id)) {

        verbose "Generating new persona..";
        my $name = _generate_new_name();
        $first_name = $name->{first_name};
        $last_name = $name->{last_name};

        $email_address = _generate_new_email($name);
        $persona_id = _store_new_persona($first_name, $last_name, $email_address);
    }

    $details = {
        persona_id    => $persona_id,
        first_name    => $first_name,
        last_name     => $last_name,
        email_address => $email_address
    };
    return $details;
}

=back

=cut

=item _store_new_persona ( ARGS )

Store the details of a newly generated persona and return the insert ID

=cut

sub _store_new_persona {
    my $first_name = shift;
    my $last_name = shift;
    my $email = shift;

    die "Can't store persona, missing information" unless $first_name && $last_name && $email;

    my $dbh = dbi_handle();
    my $insert_persona_sth = $dbh->prepare(q{
        INSERT INTO personas
        (first_name, last_name, email_address)
        VALUES (?, ?, ?)
    });
    $insert_persona_sth->execute($first_name, $last_name, $email);

    my $persona_id = $insert_persona_sth->{mysql_insertid};

    return $persona_id;
}

=back

=cut

=item _generate_new_name ( ARGS )

Generates a new random name

=cut

sub _generate_new_name {
    # Declare a variable for the names txt file
    my $names_fh = '/home/jh/turingwatch/backend/server/names.txt';
    # Connect to and open the text file
    open (FH, "< $names_fh") or die "Can't open $names_fh for reading: $!";

    my @names;
    while (<FH>) {
        push (@names, $_);
    }
    close FH or die "Cannot close $names_fh: $!";

    # Choose a random name and remove any newlines
    my $first_name = $names[rand @names];
    my $last_name = $names[rand @names];
    chomp($first_name);
    chomp($last_name);

    # Box up the names and return them
    my $name = {
        first_name => $first_name,
        last_name => $last_name
    };

    return $name;
}

=back

=cut

=item _generate_new_email ( ARGS )

Generates a new email, given a name

=cut

sub _generate_new_email {
    my $name = shift;
    my $first = $name->{first_name};
    my $last = $name->{last_name};

    my @dividers = ('.', '-', '_', '');
    my $divider = $dividers[rand @dividers];

    my @domains = ('garyspt.com');
    my $domain = $domains[rand @domains];

    # 50% of the time, append a number to the email
    my $number = '';
    if (rand() > 0.5) {
        my $number = int(rand(2000));
    }

    my $email = $first . $divider . $last . $number . '@' . $domain;

    return lc $email;
}

=back

=cut

1;
