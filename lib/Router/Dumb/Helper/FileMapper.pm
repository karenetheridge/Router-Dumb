use 5.14.0;
package Router::Dumb::Helper::FileMapper;
use Moose;
# ABSTRACT: something to build routes out of a dumb tree of files

use File::Find::Rule;
use Router::Dumb::Route;

use Moose::Util::TypeConstraints qw(find_type_constraint);

use namespace::autoclean;

has root => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has target_munger => (
  reader  => '_target_munger',
  isa     => 'CodeRef',
  default => sub {  sub { $_[1] }  },
);

has parts_munger => (
  reader  => '_parts_munger',
  isa     => 'CodeRef',
  default => sub {  sub { $_[1] }  },
);


sub add_routes_to {
  my ($self, $router) = @_;

  my $dir = $self->root;
  my @files = File::Find::Rule->file->in($dir);

  for my $file (@files) {
    my $path = $file =~ s{/INDEX$}{/}gr;
    $path =~ s{$dir}{};
    $path =~ s{^/}{};

    my @parts = split m{/}, $path;

    confess "can't use placeholder-like name in route files"
      if grep {; /^:/ } @parts;

    confess "can't use asterisk in file names" if grep {; $_ eq '*' } @parts;

    my $route = Router::Dumb::Route->new({
      parts  => $self->_parts_munger->( $self, \@parts ),
      target => $self->_target_munger->( $self, $file ),
    });

    $router->add_route($route);
  }
}

1;