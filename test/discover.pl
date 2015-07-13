#!/usr/bin/perl

use Net::UPnP::ControlPoint;

my $obj = Net::UPnP::ControlPoint->new();

@dev_list = $obj->search( st => 'upnp:rootdevice', mx => 3 );

$devNum = 0;
foreach $dev (@dev_list) {
    $device_type = $dev->getdevicetype();
#    if ( $device_type ne 'urn:schemas-upnp-org:device:MediaServer:1' ) {
#        next;
#    }
    print $dev->getfriendlyname() . "=" . $device_type . "\n";
   
}

print Dumper \@dev_list;