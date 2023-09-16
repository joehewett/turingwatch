package Turingwatch::Controller::Threads;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw(encode_json);
use Turingwatch::Model::Data;
use Redacted::Turingwatch::Database qw(dbi_handle);
use Data::Dumper;

=head1 NAME

Redacted::Turingwatch::Util::Prompt

=head1 DESCRIPTION

Controller for email Thread related activities

=head1 METHODS

=item get_threads_info ( ARGS )

Get all Threads from the database

=cut

sub get_threads_info {
    my $self = shift;

    # Do not continue on invalid input and render a default 400 error document.
    my $app = $self->openapi->valid_input or return;
    $app->res->headers->access_control_allow_origin($app->req->headers->origin)
        if $app->req->headers->origin;

    # my $data = Turingwatch::Model::Data->new();
    # my $data_in_json = $data->get_thread_data();
    my $dbh = dbi_handle();
    my $get_threads_sth = $dbh->prepare(q{
        SELECT t.id, t.persona_id, t.scammer_address, t.last_updated, t.created,
        p.first_name, p.last_name
        FROM threads t
        INNER JOIN personas p
        ON t.persona_id = p.id 
    });
    $get_threads_sth->execute();
    my $threads = $get_threads_sth->fetchall_arrayref({});

    print Dumper($threads);
    # $output will be validated by the OpenAPI spec before rendered
    my $output = {threads => $threads};
    $app->render(openapi => $output);
}

=back

=item get_thread_info ( ARGS )

Get all Threads from the database

=cut

sub get_thread_info {
    my $self = shift;

    # Do not continue on invalid input and render a default 400 error document.
    my $app = $self->openapi->valid_input or return;
    $app->res->headers->access_control_allow_origin($app->req->headers->origin)
        if $app->req->headers->origin;

    my $thread_id = $self->param('id');

    # my $data = Turingwatch::Model::Data->new();
    # my $data_in_json = $data->get_thread_data();
    my $dbh = dbi_handle();
    my $get_threads_sth = $dbh->prepare(q{
        SELECT t.id, t.persona_id, t.scammer_address, t.last_updated, t.created,
        p.first_name, p.last_name, p.email_address
        FROM threads t
        INNER JOIN personas p
        ON t.persona_id = p.id 
        WHERE t.id = ?
    });
    $get_threads_sth->execute($thread_id);
    my $thread = $get_threads_sth->fetchall_arrayref({});

    print Dumper($thread);
    # $output will be validated by the OpenAPI spec before rendered
    my $output = {thread => $thread};
    $app->render(openapi => $output);
}

=back

=item get_thread_messages ( ARGS )

Get the sent and received messges related to a given thread_id 

=cut

sub get_thread_messages {
    my $self = shift;

    # Do not continue on invalid input and render a default 400 error document.
    my $app = $self->openapi->valid_input or return;
    $app->res->headers->access_control_allow_origin($app->req->headers->origin)
        if $app->req->headers->origin;

    my $thread_id = $self->param('id');

    my $dbh = dbi_handle();
    my $get_sent_thread_messages_sth = $dbh->prepare(q{
        SELECT s.id, s.thread_id, s.subject, s.body, s.date_sent AS datetime
        FROM sent_messages s
        WHERE s.thread_id = ?
    });
    $get_sent_thread_messages_sth->execute($thread_id);
    my $sent_messages = $get_sent_thread_messages_sth->fetchall_arrayref({});

    my $get_received_thread_messages_sth = $dbh->prepare(q{
        SELECT r.id, r.thread_id, r.subject, r.body, r.date_received AS datetime
        FROM received_messages r
        WHERE r.thread_id = ?
    });
    $get_received_thread_messages_sth->execute($thread_id);
    my $received_messages = $get_received_thread_messages_sth->fetchall_arrayref({});

    print Dumper($sent_messages);

    # $output will be validated by the OpenAPI spec before rendered
    my $output = {
      sent_messages => $sent_messages,
      received_messages => $received_messages
    };
    $app->render(openapi => $output);
}

=item get_thread_credentials ( ARGS )

Get the sent and received messges related to a given thread_id 

=cut

sub get_thread_credentials {
    my $self = shift;

    # Do not continue on invalid input and render a default 400 error document.
    my $app = $self->openapi->valid_input or return;
    $app->res->headers->access_control_allow_origin($app->req->headers->origin)
        if $app->req->headers->origin;

    my $thread_id = $self->param('id');

    my $dbh = dbi_handle();

    my $get_credentials_sth = $dbh->prepare(q{
        SELECT c.id, c.message_id, c.category, c.value 
        FROM credentials c
        INNER JOIN received_messages r 
        ON r.id = c.message_id
        INNER JOIN threads t 
        ON t.id = r.thread_id
        WHERE r.thread_id = ?
    });
    $get_credentials_sth->execute($thread_id);
    my $credentials = $get_credentials_sth->fetchall_arrayref({});

    # $output will be validated by the OpenAPI spec before rendered
    my $output = {
      credentials => $credentials
    };
    $app->render(openapi => $output);
}
1;
