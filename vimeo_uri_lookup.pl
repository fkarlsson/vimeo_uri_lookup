# 
# Vimeo Irssi plugin 
# Decode and print information from Vimeo URIs 
# 

# 
# Changes 
# 0.1 First version!
# 1.0 First stable

use strict; 
use Irssi; 
use JSON;
use feature qw(switch say);
use Data::Dumper;

use Irssi::Irc; 
use LWP::UserAgent; 
use vars qw($VERSION %IRSSI);

$VERSION = '1.0'; 
%IRSSI = ( 
    authors     => 'Fredrik Karlsson', 
    contact     => 'fkarlsson@gmail.com', 

    name        => 'vimeo_uri_lookup', 
    description => 'Lookup Vimeo URIs and output info to proper window.', 
    license     => '', 
    url         => '', 
); 

sub vimeouri_public { 
    my ($server, $data, $nick, $mask, $target) = @_; 
    my $retval = vimeouri_get($data); 
    my $win = $server->window_item_find($target); 
    Irssi::signal_continue(@_);

    if ($win) { 
        $win->print("%_Vimeo:%_ $retval", MSGLEVEL_CRAP) if $retval; 
    } else { 
        Irssi::print("%_Vimeo:%_ $retval") if $retval; 
    } 
} 
sub vimeouri_private { 
    my ($server, $data, $nick, $mask) = @_; 
    my $retval = vimeouri_get($data); 
    my $win = Irssi::window_find_name('(msgs)'); 
    Irssi::signal_continue(@_);

    if ($win) { 
        $win->print("%_Vimeo:%_ $retval", MSGLEVEL_CRAP) if $retval; 
    } else { 
        Irssi::print("%_Vimeo:%_ $retval") if $retval; 
    } 
} 
sub vimeouri_parse { 
    my ($url) = @_; 
    if ($url =~ /(vimeo.com\/|http:\/\/vimeo.com\/|http:\/\/www.vimeo.com\/)([0-9]+)\/?/) { 
        return "http://vimeo.com/api/v2/video/$2.json";
    } 
    return 0; 
} 
sub vimeouri_get { 
    my ($data) = @_; 

    my $url = vimeouri_parse($data);

    my $ua = LWP::UserAgent->new(env_proxy=>1, keep_alive=>1, timeout=>5); 
    $ua->agent("irssi/$VERSION " . $ua->agent()); 

    my $req = HTTP::Request->new('GET', $url); 
    my $res = $ua->request($req);

    if ($res->is_success()) { 
        my $json = JSON->new->utf8;
        my @json_data = @{$json->decode($res->content())};
        my $result_string = '';

        # If I want to implement something else later
        my $type = 'video';
        given ($type) {
            when ('video') {
                $result_string = @json_data[0]->{title};
            }
            default {
                $result_string = 'Error';
            }
        }

        return $result_string; 
    } 
    return 0; 
} 

Irssi::signal_add_last('message public', 'vimeouri_public'); 
Irssi::signal_add_last('message private', 'vimeouri_private'); 