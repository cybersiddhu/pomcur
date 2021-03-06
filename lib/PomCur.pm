package PomCur;

use strict;
use warnings;

use feature ':5.10';

use Catalyst::Runtime 5.80;

use parent qw/Catalyst/;
use Catalyst qw/ConfigLoader
                StackTrace
                Authentication
                Session
                Session::State::Cookie
                Session::Store::DBI
                Session::PerUser
                Static::Simple/;

use Moose;
use CatalystX::RoleApplicator;

our $VERSION = '0.01';

__PACKAGE__->config(name => 'PomCur',
                    session => { flash_to_stash => 1 },
                    'Plugin::Session' => {
                      expires   => 3600,
                      dbi_dbh   => 'TrackModel',
                      dbi_table => 'sessions',
                      dbi_id_field => 'id',
                      dbi_data_field => 'session_data',
                      dbi_expires_field => 'expires',
                    },
                    'View::Graphics::Primitive' => {
                      driver => 'Cairo',
                      driver_args => { format => 'pdf' },
                      content_type => 'application/pdf',
                    },
                    'View::JSON' => {
                      expose_stash => 'json_data',
                    },
                    static => {
                      dirs => [
                        'static'
                       ],
                    },
                   );



extends 'Catalyst';

__PACKAGE__->apply_request_class_roles(qw/
                                       Catalyst::TraitFor::Request::ProxyBase
                                       /);

sub debug
{
  return $ENV{POMCUR_DEBUG};
}

# Start the application
__PACKAGE__->setup();

my $config = __PACKAGE__->config();

# this is hacky, but allows us to call methods on the config object
bless $config, 'PomCur::Config';

use PomCur::Config;

$config->setup();

my %_model_map = ( track => "TrackModel",
                   meta => "MetaModel",
                   chado => "ChadoModel" );

=head2 schema

 Usage   : my $schema = $c->schema();
 Function: Return the appropriate schema object, based on the model parameter
           of the request, or explicitly if a model_name is pass as an argument.
 Args    : $model_name - the name of model to return (optional)

=cut
sub schema
{
  my $self = shift;
  my $model_name = shift || $self->req()->param('model');

  die "no model passed to schema()\n" unless defined $model_name;

  my $model = $_model_map{$model_name};

  die "unknown model ($model_name) passed to schema()\n" unless defined $model;

  return $self->model($model)->schema();
}

=head2

 Usage   : my $local_path = $c->local_path();
 Function: If Catalyst::TraitFor::Request::ProxyBase is enable use, the
           'X-Request-Base' header to find the base path, remove it from
           the request path, then return the result.  If ProxyBase isn't
           enabled, just return the path from the URI of the current request
 Args    : None
 Return  : The local path

=cut
sub local_path
{
  my $self = shift;

  my $path = $self->req->uri()->path();
  my $base = $self->req()->header('X-Request-Base');

  if ($base) {
    $path =~ s/\Q$base//;
  }

  return $path;
}

1;
