# Archive URLs

use strict;
use warnings;
use Irssi;
use Irssi::Irc;
use DateTime;
use IO::Handle;

require URI::Find;

use vars qw($VERSION %IRSSI);
use vars qw(@uris @observedChans $logPath $fileHandle $logEntireMessage);

$logPath = "/home/pi/.irssi/archiveurls.log";
$logEntireMessage = 1;
@observedChans = ("#openbsd"); 

$VERSION = "0.1";
%IRSSI = (
        authors     => "Eduard Roccatello, master^shadow",
        contact     => "info\@roccatello.com",
        name        => "archive-urls",
        description => "Archive URLs into a plain text file",
        license     => "MIT",
        url         => "https://github.com/mastershadow/archive-urls",
    );

@uris = ();
my $finder = URI::Find->new(sub {
      my($uri) = shift;
      push @uris, $uri;
});

sub openFile { 
	open($fileHandle, '>>:encoding(UTF-8)', $logPath) or die "Could not open file '$logPath' $!";
	$fileHandle->autoflush(1);
}

sub closeFile { 
	close $fileHandle;
}

sub parseMessage {
	my ($server, $data, $nick, $target) = @_;
	if (!@observedChans || (grep { $target eq $_} @observedChans)) { 
		my $dt = DateTime->now;
		my $timeStamp = join(' ', $dt->ymd, $dt->hms);
		my $messageToParse = $data;
		@uris = ();
		$finder->find(\$messageToParse);
		if (@uris) {
			if ($logEntireMessage) {
				logURL($timeStamp, $server, $target, $nick, $data);
			} else {
				for (@uris) {
					my $uri = $_;
					Irssi::print($uri);
					logURL($timeStamp, $server, $target, $nick, $uri);
				}
			}
		}
	}
	return 1;
}

sub onOwnPublicMessage {
	my ($server, $data, $target) = @_;
	my $nick = $server->{nick};
	return parseMessage($server, $data, $nick, $target);
}

sub onPublicMessage {
	my ($server, $data, $nick, $mask, $target) = @_;
	return parseMessage($server, $data, $nick, $target);
}  

sub logURL {
	my ($timeStamp, $server, $target, $nick, $uri) = @_;
	my $line = sprintf("[%s] %s@%s: <%s> %s\n", $timeStamp, $target, $server->{tag}, $nick, $uri);
	print $fileHandle $line;
}

openFile();
Irssi::signal_add_last('message public', 'onPublicMessage');
Irssi::signal_add_last('message own_public', 'onOwnPublicMessage');
Irssi::signal_add_last('gui exit', 'closeFile');

Irssi::print("Archive URLs script by master^shadow.");


