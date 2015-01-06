# Add URL to pyload

use strict;
use warnings;
use Irssi;
use Irssi::Irc;
use Data::Validate::URI qw(is_uri);
use LWP::UserAgent;
use JSON;
use URI::Escape;

use vars qw($VERSION %IRSSI);

$VERSION = "0.1";
%IRSSI = (
        authors     => "Eduard Roccatello, master^shadow",
        contact     => "info\@roccatello.com",
        name        => "add-pyload-url",
        description => "Add an URL to PyLoad",
        license     => "MIT",
        url         => "https://github.com/mastershadow/irssi-scripts",
    );

Irssi::settings_add_str('add-pyload-url', 'pyload_host', 'http://localhost');
Irssi::settings_add_int('add-pyload-url', 'pyload_port', '8000');
Irssi::settings_add_str('add-pyload-url', 'pyload_username', '');
Irssi::settings_add_str('add-pyload-url', 'pyload_password', '');
Irssi::settings_add_str('add-pyload-url', 'pyload_allowed', '');
Irssi::settings_add_str('add-pyload-url', 'pyload_pin', '12345');

my $trigger = "!pyload";

sub parseMessage {
	my ($nick, $data) = @_;
	utf8::decode($data);

	if ($data =~ /^\Q$trigger/) {
		my @tokens = split(' ', $data);
		my $upin = $tokens[1];
		my $url = $tokens[2];
		my $pkg = $url;
		$pkg =~ s/[\W_]//g;
		
		my $host = Irssi::settings_get_str('pyload_host');
		my $port = Irssi::settings_get_int('pyload_port');
		my $user = Irssi::settings_get_str('pyload_username');
		my $pass = Irssi::settings_get_str('pyload_password');
		my $allowed = Irssi::settings_get_str('pyload_allowed');
		my $pin = Irssi::settings_get_str('pyload_pin');
		if ($allowed =~ /\Q$nick/ && $pin eq $upin && is_uri($url)) {
			Irssi::print("Downloading: $url");
			my $loginApi = $host.":".$port."/api/login";
			my $req = HTTP::Request->new('POST', $loginApi );
			$user = uri_escape($user);
			$pass = uri_escape($pass);
			my $json = "username=$user&password=$pass";
			$req->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
			$req->content($json);

			my $ua = LWP::UserAgent->new();
			my $resp = $ua->request($req);
			if ($resp->is_success) {
				my $sessid = $resp->decoded_content;
				$sessid =~ s/\"//g;
				my $addApi = $host.":".$port."/api/addPackage";
				$req = HTTP::Request->new( 'POST', $addApi);
				$req->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
				$url = uri_escape("[\"$url\"]");
				$pkg = uri_escape("\"$pkg\"");

				$json = "session=$sessid&name=$pkg&links=".$url."";
				$req->content($json);
				$resp = $ua->request($req);
				if ($resp->is_success) {
					Irssi::print("Item ".$resp->decoded_content." added to queue");
				} else {
					Irssi::print($resp->status_line);
				}
			} else {
				Irssi::print($resp->status_line);
			}

		}
	}
	return 1;
}

sub onQuery {
	my ($server, $data, $nick, $address) = @_;
	return parseMessage($nick, $data);
}

Irssi::signal_add_last('message private', 'onQuery');

Irssi::print("Pyload script by master^shadow.");

