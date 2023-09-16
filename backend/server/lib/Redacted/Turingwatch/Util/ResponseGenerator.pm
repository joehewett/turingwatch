package Redacted::Turingwatch::Util::ResponseGenerator;

# Subject of the fraudulent email we're going to reply to
use strict;
use warnings;

use Moo;
use Carp;
use Common qw(verbose);
use JSON::MaybeXS;
use LWP::UserAgent;

use Redacted::EmailBlacklist::Util::DBI qw(eb_read_dbh);

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

=head1 NAME

Redacted::Turingwatch::Util::ResponseGenerator

=head1 DESCRIPTION

Class for generating responses to fraudulent emails

=cut

has 'response' => (
    is => 'ro'
);

has 'api_config' => (
    is => 'ro',
);

has 'api' => (
    is => 'ro',
    default => 'https://api.openai.com/v1/engines/davinci/completions'
);

has 'api_key' => (
    is => 'ro',
    default => 'Bearer '
);

has 'prompt' => (
    is => 'rw'
);

=head1 CONSTRUCTION

=over

=item new ( ARGS )

Create a new generator

B<ARGS> must be a hash that matches the required fields defined above, e.g.

  (
      unfinished => "to do"
  )

=cut

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    ## TODO add logit_bias here
    ## TODO respect passed config if it exists
    my $api_config = {
      max_tokens  => 150, # Length of response
      temperature => 0.7, # High value means model takes more risks
      top_p       => 1,   # Nucleus sampling, see documentation for explanation
      n           => 1,   # Run n times, pick top result. Anything > 1 burns tokens rapidly
      stop        => ["Response from", "Email from", "scam", "scammer"], # Stop after seeing any of these
      logit_bias  => { "50256" => -100 }
    };
    $args{api_config} = $api_config;

    return $class->$orig(%args);
};

=back

=head1 METHODS

=over

=item fetch_response ( ARGS )

=cut

# TODO: Make this less bad
sub fetch_response {
    my $self = shift;
    my $prompt = shift;

    die "No prompt found. Generate a prompt and pass it to this function" unless $prompt;

    verbose "### Querying API using the following prompt: ###";
    verbose $prompt->prompt_text;


    my $config = $self->api_config;
    $config->{prompt} = $prompt->prompt_text;

    my $encoded_data = encode_json($config);
    my $ua = LWP::UserAgent->new(timeout => 10);
	my $response = $ua->post(
        $self->api,
		Content => $encoded_data,
        'Content-Type' => 'application/json',
        Authorization => $self->api_key
    );

    my $text;
    # Decode the API response and extract our text
    if ($response->is_success) {
        my $content = decode_json($response->decoded_content);
        $text = $content->{choices}[0]->{text};
    } else {
        die $response->status_line;
    }
    my $processed_text = $self->_postprocess_response($text, $prompt);

    verbose "### Got the following response from GPT-3 ###";
    verbose $processed_text;

    return $processed_text;
}

=back

=item _postprocess_response ( ARGS )

=cut

sub _postprocess_response {
    my $self = shift;
    my $text = shift;
    my $prompt = shift;

    $text =~ s/Scam.*//;
    $text =~ s/scam.*//;
    $text =~ s/victim.*//;
    $text =~ s/Reply from.*//;
    $text =~ s/<br>/ /;

    ( my $truncated_text = $text ) =~ s/[^.]*\z//;

    # If the response is now too short, try again
    #if (length($truncated_text) < 100) {
    #    $truncated_text = $self->fetch_response($prompt);
    #}

    return $truncated_text;
}

=back

=cut

1;
