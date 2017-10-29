use CGI;
 
# apk and ipa download location, based on the user agent setting of the browser
# it works for Android and iOS

$DOWNLOAD_ROOT = "/var/www/html";

# do not use my !! causing problems!
$cgi = CGI->new();

my $apptype = $cgi->param('apptype');

# detect browser type and fetch from the right location
#my $content = read_from_file("$DOWNLOAD_ROOT/");

#my $length = -s "$DOWNLOAD_ROOT/$fid";

#print "Content-Length: $length\r\n";
#print "Content-Type: application/octectect-stream\r\n\r\n";
#print $content;

#print "Content-Type: text/html\r\n\r\n";
#print "<pre>",$ENV{HTTP_USER_AGENT}, "\napptype:", $apptype, "\n";

if ($ENV{HTTP_USER_AGENT} !~ /iPhone/ && $ENV{HTTP_USER_AGENT} !~ /iPad/) {
	print "Content-Disposition: attachment;filename=\"$apptype.apk\"\r\n";
	print "Content-Type: application/vnd.android.package-archive\r\n\r\n";
	print read_from_file("$DOWNLOAD_ROOT/$apptype.apk");

} else {
	print "Content-Type: text/html\r\n\r\n";

	my $redirect = <<EOF;
 <html xmlns="http://www.w3.org/1999/xhtml">    
  <head>      
    <title>The Tudors</title>      
    <meta http-equiv="refresh" content="0;URL='itms-services://?action=download-manifest&url=https://www.domainname.com/$apptype.plist'" />    
  </head>    
  <body> 
    <p>Download app at <a href="itms-services://?action=download-manifest&url=https://www.domainname.com/$apptype.plist">
      www.suifangyisheng.com</a>.</p> 
  </body>  
</html>    
EOF

	print $redirect;
}

sub read_from_file {
	open FILE, $_[0];
	local $/;
	my $c = <FILE>;
	close FILE;
	return $c;
}
