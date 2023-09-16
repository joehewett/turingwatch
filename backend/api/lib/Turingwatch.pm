package Turingwatch;
use JSON::XS;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->_init_plugins;
    $self->_init_paths;
    $self->_init_routes;
}

sub _init_plugins {
    my $self = shift;

    $self->plugin(
        "OpenAPI" => {
            url => $self->home->rel_file("static/docs/v1/api.json")
        }
    );
}

sub _init_paths {
    my $self = shift;

    $self->static->paths(
        ['static']
    );

    $self->renderer->paths(
        ['templates']
    );
}

sub _init_routes {
    my $self = shift;

    my $api = $self->routes->any('/api');

    # Render docs page on /api/docs
    $api->get('/v1/docs' => sub {
        shift->render('apidocs',
            mode       => 'api',
            version    => 'v1',
            deprecated => 0
        )
    });

    # Redirect /api to /api/v1
    $api->get('/' => sub {
        shift->redirect_to('/api/v1');
    });

    # Render api.json in json format when user hits /api/v1/api.json
    $api->get("v1/api.json" => sub {
        my $c = shift;
        $c->reply->static("docs/v1/api.json");
    });
}

1;
