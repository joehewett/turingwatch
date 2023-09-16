package Redacted::Turingwatch::Util::Prompt;

use strict;
use warnings;

use Moo;
use Carp;
use Common qw(verbose);
use Data::Dumper;
use Redacted::Turingwatch::Database qw(dbi_handle);

use constant {
    GENERIC => 0,
    PROVIDE_PERSONAL_DETAILS => 1,
    REQUEST_PAYMENT_DETAILS => 2
};

=head1 NAME

Redacted::Turingwatch::Util::Prompt

=head1 DESCRIPTION

Class for representing prompts that are fed to a language model

=cut

has 'prompt_text' => (
    is => 'ro'
);

has 'persona' => (
    is => 'ro',
    required => 1
);

has 'scam_email' => (
    is => 'ro',
    required => 1
);

has 'prompt_id' => (
    is => 'ro'
);

=head1 CONSTRUCTION

=over

=item new ( ARGS )

Create a new email object.

B<ARGS> must be a hash that matches the required fields defined above, e.g.

  (
      persona => { # See Persona constructor }
      scam_email => { # See ScamEmail constructor }
  )

=cut

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    # TODO: Die unless type, scam_email, persona are correct
    #
    my $prompt_id = 0;
    if ($args{prompt_id}) {
        $prompt_id = $args{prompt_id};
    }
    my $scam_email = $args{scam_email};
    my $persona = $args{persona};

    my $skeleton_prompt = _load_skeleton($prompt_id);
    #verbose $skeleton_prompt;
    my $prompt_text = _customise_prompt($persona, $scam_email, $skeleton_prompt);
    #verbose $prompt_text;

    $args{prompt_text} = $prompt_text;

    return $class->$orig(%args);
};

=back

=head1 METHODS

=item _load_skeleton ( ARGS )

Load a the skeleton of a prompt from the database, ready to be customised.

=cut

sub _load_skeleton {
    my $prompt_id = shift;

    my $dbh = dbi_handle();
    my $get_prompt_smth = $dbh->prepare(q{
        SELECT prompt_text
        FROM prompts
        WHERE id = ?
    });
    $get_prompt_smth->execute($prompt_id);
    my ($skeleton_prompt) = $get_prompt_smth->fetchrow_array;

    return $skeleton_prompt;
}

=back

=head1 METHODS

=item _customise_prompt ( ARGS )

Take a Persona, ScamEmail and skeleton prompt, and populate the skeleton with relevant information.
Returns a complete prompt ready to pass to a Language Model for inference.

=cut

sub _customise_prompt {
    my $persona = shift;
    my $scam_email = shift;
    my $skeleton_prompt = shift;

    die "Error customising prompt"
        unless $persona and $scam_email and $skeleton_prompt;

    #my $body = join "\n", @{$scam_email->message->body};
    my $body = $scam_email->body;

    #verbose "@@@ Dumping Body @@@";
    #print Dumper($body);
    #verbose $body;
    #verbose "@@@ Dumped Body @@@";
    #
    my $full_name = $persona->first_name . " " . $persona->last_name;
    my $email_address = $persona->email_address;


    # If the scam email body is very long, make it shorter and clip everything after last fullstop
    if (length $body > 1000) {
        ( $body = substr $body, 0, 1000 ) =~ s/[^.]*\z//;
    }

    my $prompt = $skeleton_prompt;
    $prompt =~ s/\$full_name/$full_name/g;
    $prompt =~ s/\$email/$email_address/g;
    $prompt =~ s/\$body/$body/g;

    return $prompt;
}

=back


=cut

1;
