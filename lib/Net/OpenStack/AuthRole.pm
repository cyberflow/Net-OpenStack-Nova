# Taken from Net::OpenStack::Compute::AuthRole by Naveed Massjouni
# https://github.com/ironcamel/Net-OpenStack-Compute

package Net::OpenStack::AuthRole;
use Moose::Role;

use JSON qw(from_json to_json);

requires qw(
    auth_url
    user
    password
    tenant
    region
    service_name
    verify_ssl
    _agent
);

sub get_auth_info {
    my ($self) = @_;
    return $self->_parse_catalog({
        auth =>  {
            tenantName => $self->tenant,
            passwordCredentials => {
                username => $self->user,
                password => $self->password,
            }
        }
    });    
}

sub _parse_catalog {
    my ($self, $auth_data) = @_;
    my $res = $self->_agent->post($self->auth_url . "/tokens",
        content_type => 'application/json', content => to_json($auth_data));
    die $res->status_line . "\n" . $res->content unless $res->is_success;
    my $data = from_json($res->content);
    my $token = $data->{access}{token}{id};
    my $tenant_id = $data->{access}{token}{tenant}{id};

    my @catalog = @{ $data->{access}{serviceCatalog} };
    # We do not look for compute services in Net::OpenStack::Networking
    #@catalog = grep { $_->{type} eq 'compute' } @catalog;
    #die "No compute catalog found" unless @catalog;
    if ($self->service_name) {
        @catalog = grep { $_->{name} eq $self->service_name } @catalog;
        die "No catalog found named " . $self->service_name unless @catalog;
    }
    my $catalog = $catalog[0];
    my $base_url = $catalog->{endpoints}[0]{publicURL};
    $self->_set_base_url($base_url);
    if ($self->region) {
        for my $endpoint (@{ $catalog->{endpoints} }) {
            my $region = $endpoint->{region} or next;
            if ($region eq $self->region) {
                $base_url = $endpoint->{publicURL};
                last;
            }
        }
    }

    return { base_url => $base_url, token => $token, tenant_id => $tenant_id };
}

=head1 DESCRIPTION

This role is used by L<Net::OpenStack::Compute> for OpenStack authentication.
It supports the L<Keystone|https://github.com/openstack/keystone> auth.

=cut

1;

