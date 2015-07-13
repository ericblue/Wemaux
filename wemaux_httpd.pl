#!/usr/bin/perl

{

    package MyWebServer;

    use HTTP::Server::Simple::CGI;
    use base qw(HTTP::Server::Simple::CGI);
    use Log::Log4perl qw(:easy);
    use vars qw /$logger/;

    Log::Log4perl->init("conf/logger_httpd.conf");
    $logger = get_logger();

    my %dispatch = (
        # Default paths that app requests for discovery
        '/setup.xml'             => \&handle_setup,
        '/eventservice.xml'      => \&handle_service,
        '/deviceinfoservice.xml' => \&handle_device,
        '/firmwareupdate.xml'    => \&handle_firmware,
        # UPNP/SOAP requests
        '/upnp/control/firmwareupdate1' => \&handle_firmware_response

        # ...
    );

    sub handle_request {
        my $self = shift;
        my $cgi  = shift;

        $logger->debug("Request from $ENV{'REMOTE_ADDR'}");

        my $path    = $cgi->path_info();
        my $handler = $dispatch{$path};

        if ( ref($handler) eq "CODE" ) {           
            print "HTTP/1.0 200 OK\r\n";
            $handler->($cgi);

        }
        else {
            $logger->debug("404 for $path");
            print "HTTP/1.0 404 Not found\r\n";
            print $cgi->header, $cgi->start_html('Not found'), $cgi->h1('Not found'),
              $cgi->end_html;
        }
    }

    sub handle_setup {

        my $cgi = shift;    # CGI.pm object
        return if !ref $cgi;

        $logger->debug("Request for sample/setup.xml");

        open( IN, "sample/setup.xml" );
        local $/ = undef;
        my $xml = <IN>;
        close(IN);

        print "Content-type: text/xml\n";
        print "\n";
        print $xml;

    }

    sub handle_service {

        my $cgi = shift;    # CGI.pm object
        return if !ref $cgi;

        $logger->debug("Request for sample/eventservice.xml");

        open( IN, "sample/eventservice.xml" );
        local $/ = undef;
        my $xml = <IN>;
        close(IN);

        print "Content-type: text/xml\n";
        print "\n";
        print $xml;

    }

    sub handle_device {

        my $cgi = shift;    # CGI.pm object
        return if !ref $cgi;

        $logger->debug("Request for sample/deviceinfoservice.xml");

        open( IN, "sample/deviceinfoservice.xml" );
        local $/ = undef;
        my $xml = <IN>;
        close(IN);

        print "Content-type: text/xml\n";
        print "\n";
        print $xml;

    }

    sub handle_firmware {

        my $cgi = shift;    # CGI.pm object
        return if !ref $cgi;

        $logger->debug("Request for sample/firmwareupdate.xml");

        open( IN, "sample/firmwareupdate.xml" );
        local $/ = undef;
        my $xml = <IN>;
        close(IN);

        print "Content-type: text/xml\n";
        print "\n";
        print $xml;

    }
    
    
    sub print_xml {
        
        my ($name) = @_;
        

        open( IN, "$name" ) || die "Can't open $name!";
        local $/ = undef;
        my $xml = <IN>;
        close(IN);

        print "Content-type: text/xml\n";
        print "\n";
        print $xml;
        
    }
    
    sub handle_firmware_response {

        my $cgi = shift;    # CGI.pm object
        return if !ref $cgi;

        $logger->debug("Request for sample/firmwareupdate.xml");

        print_xml("sample/upnp/firmware.xml");
  
        print "Content-type: text/xml\n";
        print "\n";
        print $xml;

    }

}

# start the server on port 49153
#$SIG{INT}=\&shutdown;
$pid = MyWebServer->new(49153)->background();
print "Use 'kill $pid' to stop server.\n";

