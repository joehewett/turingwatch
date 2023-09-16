package Redacted::Turingwatch::Util::Emailer;

use strict;
use warnings;

use Moo;
use Carp;
use Common qw(verbose);
use Try::Tiny;
use MIME::Lite;

has 'dbh' => (
    is => 'ro',
    required => 1,
);

has 'dry_run' => (
    is => 'ro',
    default => 1
);

has 'config' => (
    is => 'ro',
);

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $config = {
        bcc   => 'jh@redacted.com',
        relay => 'garyspt.com'
    };

    $args{config} = $config;

    return $class->$orig(%args);
};

sub send_reply {
    my ($self, $email) = @_;

    my $from = $email->victim_address;
    my $to = $email->fraudster_address;
    my $subject = $email->subject;
    my $body = $email->body;

    verbose "Sending email from victim:";
    verbose $from;
    my $msg = MIME::Lite->new(
        From    => $from,
        To      => $to,
        Bcc     => $self->{config}->{bcc},
        Subject => $subject,
        Data    => $body
    ) or return;

    MIME::Lite->send('smtp', $self->{config}->{relay});

    unless ($self->{dry_run}) {
        try {
            $msg->send();
        } catch {
            verbose("Failed to send to $to, error was: $_");
            return;
        };
    }
    else {
        $self->print_details($email);
    }
    return 1;
}

sub print_details {
    my $self = shift;
    my $email = shift;

    verbose $email->fraudster_address;
    verbose $email->subject;

    # Hack to remove newlines
    my $response = $email->body;
    #my @data = split("\n",$response);
    #$response = join("",@data);

    #verbose $response;
}

1;
