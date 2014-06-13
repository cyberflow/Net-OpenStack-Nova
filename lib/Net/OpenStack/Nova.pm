# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

use strict;
use warnings;

package Net::OpenStack::Nova;
use Moose;
use 5.014002;

use Carp;
use LWP;
use JSON qw(from_json to_json);

our $VERSION = '0.02';

has auth_url     => (is => 'rw', required => 1);
has user         => (is => 'ro', required => 1);
has password     => (is => 'ro', required => 1);
has tenant       => (is => 'ro', required => 1);
has service_name => (is => 'ro', default => 'nova');
has region       => (is => 'ro');
has verify_ssl   => (is => 'ro', default => 1);
has verbose      => (is => 'rw', default => 0);
    
has base_url => (
    is      => 'rw',
    lazy    => 1,
    default => sub { shift->_auth_info->{base_url} },
    writer  => '_set_base_url',
);
has token => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->_auth_info->{token} },
);
has _auth_info => (
    is => 'ro',
    lazy => 1,
    builder => '_build_auth_info',
);

has _agent => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $agent = LWP::UserAgent->new(
            ssl_opts => { verify_hostname => $self->verify_ssl });
        return $agent;
    },
);
    
with 'Net::OpenStack::AuthRole';

sub BUILD {
    my ($self) = @_;
    # Make sure trailing slashes are removed from auth_url
    my $auth_url = $self->auth_url;
    $auth_url =~ s|/+$||;
    $self->auth_url($auth_url);
}
    
sub set_base_url {
    my ($self, $url) = @_;
    return $self->_set_base_url($url);
}   

sub _build_auth_info {
    my ($self) = @_;
    my $auth_info = $self->get_auth_info();
    $self->_agent->default_header(x_auth_token => $auth_info->{token});
    return $auth_info;
}
    
sub _get_query {
    my %params = @_;
    my $q = $params{query} or return '';
    for ($q) { s/^/?/ unless /^\?/ }
    return $q;
};

#Nova
sub list {
	my ($self, %params) = @_;	
    my $q = _get_query(%params);
    my $res = $self->_get($self->_url("/servers", $params{detail}, $q, $params{filter}));
    return from_json($res->content)->{servers};
}

sub list_all_tenant {
    my ($self, $name) = @_;
    my $filter = 'all_tenants=1';
    $filter .= '&host='.$name if $name; 
    my $servers = $self->list(detail => 1, filter => $filter);
    return $servers;
}

sub _url {
    my ($self, $path, $is_detail, $query, $filter) = @_;
    my $url = $self->base_url . $path;
    $url .= '/detail' if $is_detail;
    $url .= '?'.$filter if $filter;
    $url .= $query if $query;
    say "_url: ".$url if $self->verbose == 1;
    return $url;
}

sub _get {
    my ($self, $url) = @_;
    return $self->_agent->get($url);
}

sub _delete {
    my ($self, $url) = @_;
    my $req = HTTP::Request->new(DELETE => $url);
    return $self->_agent->request($req);
}

sub _post {
    my ($self, $url, $data) = @_;
    return $self->_agent->post(
        $self->_url($url),
        content_type => 'application/json',
        content      => to_json($data),
    );
}

sub _check_res {
    my ($res) = @_;
    die $res->status_line . "\n" . $res->content
        if ! $res->is_success and $res->code != 404;
    return 1;
}

around qw( _get _delete _post ) => sub {
    my $orig = shift;
    my $self = shift;
    my $res = $self->$orig(@_);
    _check_res($res);
    return $res;
};

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::OpenStack::Nova - Bindings for the OpenStack Nova API

=head1 SYNOPSIS

  use Net::Openstack::Nova;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Net::Openstack::Nova, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Dmitry, E<lt>cyberflow@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Dmitry

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
