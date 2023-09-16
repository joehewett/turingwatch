package Redacted::Turingwatch::Util::ReplyEmail;

use strict;
use warnings;

use Moo;
use Carp;
use Common qw(verbose);

=head1 NAME

Redacted::Turingwatch::Util::ReplyEmail

=head1 DESCRIPTION

Class for representing reply emails

=cut

has 'subject' => (
    is => 'ro',
    required => 1
);

has 'body' => (
    is => 'ro',
    required => 1
);

has 'victim_address' => (
    is => 'ro',
    required => 1
);

has 'fraudster_address' => (
    is => 'ro',
    required => 1,
);

=head1 CONSTRUCTION

=over

=item new ( ARGS )

Create a new ReplyEmail object.

B<ARGS> must be a hash that matches the required fields defined above, e.g.

  (
      subject "RE: Hello!",
      body => "body text",
      victim_address => "persona@easymail.info",
      fraudster_address => "attacker@scam.net"
  )

=cut

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    return $class->$orig(%args);
};

=back

=cut

1;
