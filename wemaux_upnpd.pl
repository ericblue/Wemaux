#!/usr/bin/perl

use IO::Select;
use IO::Socket;
use IO::Socket::Multicast;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use strict;
use vars qw /$logger/;

Log::Log4perl->init("conf/logger_upnpd.conf");
$logger = get_logger();

my $version         = "Wemaux UPNP/1.0";
my $mcast_addr      = "239.255.255.250";
my $mcast_port      = 1900;
my $mcast_sock_addr = sprintf( "%s:%d", $mcast_addr, $mcast_port );
my $interface       = "eth0";
my $ip              = "192.168.2.106";

my $s_announce = IO::Socket::Multicast->new(
    ReuseAddr => 1,
    Blocking  => 0
  )
  || die "ERROR: " . $!;

my $s_listen = IO::Socket::Multicast->new(
    LocalPort => $mcast_port,
    ReuseAddr => 1,
    Blocking  => 0
  )
  || die "ERROR: " . $!;

$s_announce->mcast_loopback(0);
$s_listen->mcast_loopback(0);

# Outgoing multicast interface
$s_announce->mcast_add( $mcast_addr, $interface );
$s_listen->mcast_add( $mcast_addr,   $interface );

my $read_set = IO::Select->new() || die "new select: " . $!;
$read_set->add($s_listen) || die "add select: " . $!;

my $notify;
my $last_anounced = 0;

while (1) {
    my ($rh_set) = IO::Select->select( $read_set, undef, undef, 10 );
    foreach my $sh (@$rh_set) {

        #printf "Reading DATA from socket\n";
        my $data;
        $sh->recv( $data, 4096 );
        if ( defined($data) ) {
            my @lines = split( /\r\n/, $data );

            my %headers = ();
            $headers{'STATUS'} = $lines[0];

            undef $lines[0];
            foreach my $line (@lines) {
                if ( defined($line) ) {
                    my ( $name, $value ) = split( /: /, $line );

                    $headers{$name} = $value;
                }
            }

            $logger->debug( "Found: " . Dumper( \%headers ) );

            if ( $headers{'STATUS'} eq "M-SEARCH * HTTP/1.1" ) {

                if ( $headers{'ST'} eq "urn:Belkin:service:basicevent:1" ) {
                    $logger->debug("Found Belkin M-SEARCH from mobile app");

                    #$logger->debug(Dumper \%headers);
                }

                $logger->debug("Multi-Cast send to " .  $sh->peerhost() . ":" . $sh->peerport());
                $s_listen->mcast_send( create_notify($headers{'ST'}), $sh->peerhost() . ":" . $sh->peerport() )                
                  or die "send: $!";
                  
            }

        }
    }
}

sub create_notify {

    my ($st) = @_;

    my $notify;

    #$notify = sprintf "NOTIFY * HTTP/1.1\n";
    #$notify .= sprintf "HOST: $mcast_sock_addr\n";

    $notify  = sprintf "HTTP/1.1 200 ok\r\n";
    $notify .= sprintf "CACHE-CONTROL: max-age=1800\r\n";
    $notify .= sprintf "EXT: \r\n";
    $notify .= sprintf "LOCATION: http://$ip:49153/setup.xml\r\n";
    $notify .= sprintf "OPT: \"http://schemas.upnp.org/upnp/1/0/\"; ns=01\r\n";
    $notify .= sprintf "01-NLS: 7af96e40-1aa2-22c1-bcfc-eac9223a69cc\r\n";
    $notify .= sprintf "X-User-Agent: redsonic\r\n";
    $notify .= sprintf "NT: urn:Belkin:device:controllee:1\r\n";
    
    if (defined($st)) {
         $notify .= sprintf "ST: $st\n";
    }
    $notify .= sprintf "SERVER: Unspecified, UPnP/1.0, Unspecified\n";
    $notify .= sprintf "USN: uuid:Socket-1_0-221332K1100068::urn:Belkin:device:controllee:1\n";
    $notify .= sprintf "\n";

    $logger->debug("Returning notify $notify");

    return $notify;
}

