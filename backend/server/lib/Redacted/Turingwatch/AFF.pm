package Redacted::Turingwatch::AFF;

use Moo;
use Carp;
use Common;

use Redacted::Turingwatch::Util::Prompt;
use Redacted::Turingwatch::Util::Emailer;
use Redacted::Turingwatch::Util::Persona;
use Redacted::Turingwatch::Util::ScamEmail;
use Redacted::Turingwatch::Util::ReplyEmail;
use Redacted::Turingwatch::Util::ResponseGenerator;

use Redacted::EmailBlacklist::Util::DBI qw(eb_read_dbh);
use Redacted::Turingwatch::Database qw(dbi_handle);

sub run {
    my ($self, %options) = @_;

    $self->_assert_valid_options(%options);

    my $dbh = eb_read_dbh();

    # Instantiate an emailer with which we can send reply emails to scammers
    my $mailer = Redacted::Turingwatch::Util::Emailer->new(
        dbh => $dbh,
        dry_run => $options{dry_run}
    );
    # Instantiate a response generator that we can use to generate a humanlike email response
    my $response_generator = Redacted::Turingwatch::Util::ResponseGenerator->new();

    # Instantiate a ScamEmail object to allow us to easily extract useful info from the email
    my $scam_email = Redacted::Turingwatch::Util::ScamEmail->new(
        eb_id  => $options{eb_id},
        raw_email => $options{raw_email}
    );
    verbose "Loaded scam email";

    my $victim_address    = $scam_email->victim_address;
    my $subject           = $scam_email->subject;
    my $fraudster_address = $scam_email->fraudster_address;

    die "Fraudster address is $fraudster_address, not sending reply email." if $fraudster_address =~ /garyspt.com/;

    #my $fraudster_address = 'jh@redacted.com';
    verbose "Subject is:";
    verbose $subject;

    verbose "This email was sent by $fraudster_address";
    verbose "This email was sent to $victim_address. Trying to find a persona with that name..";
    my $persona = $self->_fetch_persona($victim_address);
    $victim_address = $persona->{email_address};

    # Use victim_address and fraudster_address to search for an existing Thread
    # If a Thread is found, store it and load the associated Persona into Persona by passing the Persona ID to the constructor
    # If a Thread is not found, Persona should force a new Persona to be created and stored in the database
    # A Thread should then be created here linking the Persona to the Thread and scammer_address
    my $thread_id = $self->_get_thread_id($persona->{persona_id}, $fraudster_address);

    # Save the received message
    $self->_store_received_message($thread_id, $scam_email);

    # Using the persona and the ScamEmail, generate a prompt for our language model
    my $prompt = Redacted::Turingwatch::Util::Prompt->new(
        prompt_id  => 1,
        persona    => $persona,
        scam_email => $scam_email
    );

    my $response = $response_generator->fetch_response($prompt);

    # Create a ReplyEmail object that we can pass to our Emailer for sending
    my $reply_email = Redacted::Turingwatch::Util::ReplyEmail->new(
        subject           => "Re: $subject",
        body              => $response,
        fraudster_address => $fraudster_address,
        victim_address    => $victim_address
    );

    verbose "Sending email to fraudster:";
    verbose $fraudster_address;

    # Send the ReplyEmail back to the scammer, and record our response
    if ($mailer->send_reply($reply_email)) {
        $self->_store_sent_message($thread_id, $reply_email, $prompt, $persona);
    } else {
        verbose "Reply mail to $fraudster_address was unsuccessful";
    }
}

sub _fetch_persona {
    my $self = shift;
    my $victim_address = shift;

    my $persona = Redacted::Turingwatch::Util::Persona->new(
        email_address => $victim_address
    );

    return $persona;
}

sub _get_thread_id {
    my $self = shift;
    my $persona_id = shift;
    my $fraudster_address = shift;

    die "persona_id or fraudster_address missing from _get_thread_id" unless $persona_id && $fraudster_address;

    my $thread_id;

    # If we have a persona and fraudster, we may or may not have an existing email thread ongoing
    my $dbh = dbi_handle();
    my $get_thread_sth = $dbh->prepare(q{
        SELECT id
        FROM threads
        WHERE persona_id = ?
        AND scammer_address = ?
    });
    $get_thread_sth->execute($persona_id, $fraudster_address);
    ($thread_id) = $get_thread_sth->fetchrow_array;

    # If we didn't have an existing thread, create a new one
    if (!$thread_id) {
        verbose "Could not find a thread_id between $persona_id and $fraudster_address, creating new thread..";
        $thread_id = $self->_create_new_thread($persona_id, $fraudster_address);
    }
    verbose "Using thread_id $thread_id";
    return $thread_id;

}

sub _create_new_thread {
    my $self = shift;
    my $persona_id = shift;
    my $fraudster_address = shift;

    my $dbh = dbi_handle();
    my $insert_thread_sth = $dbh->prepare(q{
        INSERT INTO threads
        (persona_id, scammer_address, last_updated, created)
        VALUES (?, ?, NOW(), NOW())
    });
    $insert_thread_sth->execute($persona_id, $fraudster_address);

    my $thread_id = $insert_thread_sth->{mysql_insertid};

    return $thread_id;
}

sub _store_received_message {
    my $self = shift;
    my ($thread_id, $received_message) = @_;

    my $dbh = dbi_handle();

    my $message_sth = $dbh->prepare(qq{
        INSERT INTO received_messages
        (thread_id, subject, body, date_received)
        VALUES (?,?,?,NOW())
    });
    $message_sth->execute($thread_id, $received_message->subject, $received_message->body);
}

sub _store_sent_message {
    my $self = shift;
    my ($thread_id, $reply_email, $prompt, $persona) = @_;

    my $dbh = dbi_handle();

    my $message_sth = $dbh->prepare(qq{
        INSERT INTO sent_messages
        (thread_id, prompt_id, subject, body, date_sent, sent)
        VALUES (?,?,?,?,NOW(),?)
    });
    $message_sth->execute($thread_id, $prompt->prompt_id, $reply_email->subject, $reply_email->body,1);
}

# Validate runtime options
sub _assert_valid_options {
    my ($self, %options) = @_;

    die 'Invalid source option specified, must be db'
        unless ($options{source} eq 'db' or $options{source} eq 'stdin');

    die 'Cannot read from both db and stdin'
        if ($options{eb_id} and $options{raw_email});

}

sub _get_scam_email_ids {
    my ($self, %options) = @_;

    my $dbh = eb_read_dbh();

    my $records = $dbh->selectall_arrayref(qq{
        SELECT m.id
        FROM messages m
        INNER JOIN raw_bodies r
        ON m.body_hash = r.body_hash
        INNER JOIN addresses a
        ON m.id = a.message_id
        WHERE m.status='confirmed'
        AND a.status='confirmed'
        AND a.context='reply_to'
        ORDER BY id DESC
        LIMIT ?
    }, { Slice => {} }, $options{limit});

    return @$records;
}

1;

=head1 NAME

Redacted::Turingwatch::AFF

=head1 SYNOPSIS

    Redacted::Turingwatch::AFF->run();

=head1 DESCRIPTION

Automatically respond to AFF emails either from the emailblacklist database or directly from an inbox

=cut
