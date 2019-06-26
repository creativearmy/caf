#!/opt/perl/bin/perl

# file transfer client utlities, files downloaded to /tmp/fid
# if the file has already been downloaded, it will do nothing
# for post, it will print two id's, fid and thumb

# usage: getpost.pl proj get|post fid|filename
#

use LWP::UserAgent;
use HTTP::Request::Common;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

# project HTTP server for development and production
$HTTP_URLS = {
	xxx => {
	    upload_to => "http://1.2.3.4/cgi-bin/upload.pl",
	    download_path => "http://1.2.3.4/cgi-bin/download.pl",
	},
};

# normally they are the same
$HTTP_URLS->{xxx_ga} = $HTTP_URLS->{xxx} unless $HTTP_URLS->{xxx_ga};

my ($proj, $getpost, $fidfilename) = @ARGV;

exit unless $proj && scalar($getpost =~ /^get|post$/) && $fidfilename;

if ($getpost eq "get") {
    if ($fidfilename =~ /^f\d{23}$/) {
        unless (-s "/tmp/$fidfilename") {
            my $url = $HTTP_URLS->{$proj}->{download_path};
            $url = $url."?proj=$proj&fid=$fidfilename";
            print_to_file("/tmp/$fidfilename", download_file_from_server($url));
        }
        print "/tmp/$fidfilename\n";
    }
}

if ($getpost eq "post") {
    my $url = $HTTP_URLS->{$proj}->{upload_to};
    my $ret = upload_file_to_server($proj, $url, $fidfilename);
    if ($ret =~ /"fid":"([^"]+)"/) {
        print $1;
    }
    if ($ret =~ /"thumb":"([^"]+)"/) {
        print " $1";
    }
    print "\n";
}

################################################################################################################################################################
# utilities

sub print_to_file {
	open FILE, ">$_[0]";
	print FILE $_[1];
	close FILE;
}

sub read_from_file {
	local $/;
	open FILE, $_[0];
	my $c = <FILE>;
	close FILE;
	return $c;
}

sub upload_file_to_server {

        # utility to send file attachment over to server, get a fid and thumb in return
        my ($proj, $url, $filename) = @_;

        my $ua = LWP::UserAgent->new(cookie_jar=>{});

        # sending form data
        my $request = POST $url,

                Content_Type => 'multipart/form-data',

                Content => [
                        local_file => [$filename],
                        proj => $proj,
                        ];

        my $response = $ua->request($request);

        return unless $response->is_success();

        return $response->content();
}

sub download_file_from_server {
	
	# utility to download file from server
	my ($url) = @_;
	
	my $ua = LWP::UserAgent->new(cookie_jar=>{});
	
	# sending form data
	my $request = GET $url;
			
 	my $response = $ua->request($request);
		
	return unless $response->is_success();
	
	return $response->content();
}
