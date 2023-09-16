package Redacted::Turingwatch::Util::ScamEmail;

use strict;
use warnings;

use Moo;
use Carp;
use Common qw(verbose);
use Email::Valid;
use Data::Dumper;
use JSON::MaybeXS;
use LWP::UserAgent;
use MIME::Parser;
use MIME::Entity;
use MIME::Head;
use MIME::Body;
use Data::Dumper;

use Redacted::EmailBlacklist::Util::DBI qw(eb_read_dbh);

=head1 NAME

Redacted::Turingwatch::Util::Email

=head1 DESCRIPTION

Class for representing emails

=cut

has 'eb_id' => (
    is => 'ro',
);

has 'dbh' => (
    is => 'ro',
);

has 'raw_email' => (
    is => 'ro'
);

has 'message' => (
    is => 'ro'
);

has 'body' => (
    is => 'ro'
);

has 'subject' => (
    is => 'ro'
);

has 'victim_address' => (
    is => 'ro'
);

has 'fraudster_address' => (
    is => 'ro'
);

=head1 CONSTRUCTION

=over

=item new ( ARGS )

Create a new ScamEmail object.

B<ARGS> must be a hash that matches the required fields defined above, e.g.

  (
      id => 1234569
  )

=cut

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    $parser->extract_nested_messages(1);

    $args{dbh} = eb_read_dbh();

    my $entity;
    my $message;
    my $body;
    my $subject;
    my $fraudster_address;
    my $victim_address;

    # If we've got an ID, fetch message from database, otherwise parse from raw_email input
    # This means that if we pass both an ID and raw_email, ID will take precedent
    if ($args{eb_id}) {
        my $raw_email = _load($args{dbh}, $args{eb_id});
        $args{raw_email} = $raw_email;
    }

    # Get a MIME::Entity from the raw_email text
    $message = $parser->parse_data($args{raw_email});

    # Extract relevant features from our MIME::Entity
    $body = _extract_body($message);
    $subject = _extract_subject($message);
    $victim_address = _extract_victim_address($message);
    $fraudster_address = _extract_fraudster_address($message);

    $args{message} = $message;
    $args{body} = $body;
    $args{subject} = $subject;
    $args{victim_address} = $victim_address;
	$args{fraudster_address} = $fraudster_address;

    return $class->$orig(%args);
};

=back

=head1 METHODS

=item load ( ARGS )

Given an EmailBlacklist ID, load the email

=cut

sub _load {
    my $dbh = shift;
    my $id = shift;

    # TODO: This only loads 1 email, so could be done more cleanly
    verbose "Loading email with id $id";
    my $records = $dbh->selectall_arrayref(qq{
        SELECT UNCOMPRESS(r.raw_body) AS body, header
        FROM messages m
        INNER JOIN raw_bodies r
        ON m.body_hash = r.body_hash
        WHERE m.id = ?
        ORDER BY id DESC
    }, { Slice => {} }, $id);

    die "No scam email with ID $id found" unless $records;

    my $raw_email;
    foreach my $email (@$records) {
        my $head = $email->{header};
        # Trim everything after the last full stop from this message
        ( my $body = $email->{body} ) =~ s/[^.]*\z//;
        $raw_email = $head . $body;
    }

    return $raw_email;
}

=back

=cut

=item _extract_subject ( ARGS )

Get the subject from the email headers

=cut

sub _extract_subject {
    my $message = shift;

    my MIME::Head $head = $message->head;
    my $subject = $head->get('subject');

    return $subject;
}

=back

=cut

=item _extract_fraudster_address ( ARGS )

Get the fraudster address from the email headers

=cut

sub _extract_fraudster_address {
    my $message = shift;

    my MIME::Head $head = $message->head;
    my $from = $head->get('From');

    return $from;
}

=back

=cut

=item _extract_victim_address ( ARGS )

Get the email address of the receiver of this scam email
Depending on how this email entered the system, this will either be
one of our Persona email addresses, the email of a real victim email address.

=cut

sub _extract_victim_address {
    my $message = shift;

    my MIME::Head $head = $message->head;
    my $victim_address = Email::Valid->address($head->get('To'));

    return $victim_address;
}


=back

=cut

=item _extract_body ( ARGS )

Get the body text from the message

=cut

sub _extract_body {
    my $message = shift;

    # The MIME::Entity might be multipart, so we need to flatten it
    # Note that the MIME::Entity is a recursive (contains nested MIME::Entities)
    my @entities;
    push @entities, _flatten_mime_list($message);

    my $body;
    # We want to find the text/plain
    foreach my $entity (@entities) {
        if ($entity->mime_type() eq "text/plain") {
            my $bh = $entity->bodyhandle;
            # Try decoding the body
            if ($bh and $bh->as_string) {
                return $bh->as_string;
            # Forget about decoding, try extracting body
            # This is not good - it will result in MIME content in the email
            } elsif ($entity->stringify_header and
                $entity->stringify_body !~ m/\A\s*\Z/) {
                return $entity->stringify_body;
            }
        }
    }

    return "";;
}


=back

=cut

sub _flatten_mime_list {
    my $mime_entity = shift or croak "No MIME entity provided.";

    my @ret_array = ();
    if ($mime_entity->is_multipart) {
        foreach my $p ($mime_entity->parts()) {
            # mime entity objects are recurive data structures
            push @ret_array, _flatten_mime_list($p);
        }
    # skip images, the like, and unparseable-multiparts
    } elsif ($mime_entity->effective_type =~ m/text/) {
        push @ret_array, $mime_entity;
    }

    return @ret_array;
}

1;
