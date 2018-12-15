#!/opt/perl/bin/perl

my $PROJ = $ARGV[0]; # lower case project codename
die unless -f "/var/www/games/app/$PROJ/app.pl";

do "/var/www/games/app/$PROJ/app.pl";

# first line of the document is the title
my %titles = ();

my $CAP_PROJ = uc($PROJ);
my @TYPES;
my @INTERFS;

foreach my $v (keys %{$CAP_PROJ.'::'}) {
			
	if (substr($v, 0, 2) eq "p_") {
		# simple linting, both persona must exist
		
		#print "fatal: $v sub routine is not defined!\n" and exit if (defined(${$CAP_PROJ."::$v"}) && !defined(&{$CAP_PROJ."::$v"}));
		#print "fatal: $v manual fragment is not defined!\n" and exit if (!defined(${$CAP_PROJ."::$v"}) && defined(&{$CAP_PROJ."::$v"}));
		#print "fatal: $v WTF?!\n" and exit if (!defined(${$CAP_PROJ."::$v"}) && !defined(&{$CAP_PROJ."::$v"}));
		
		if (defined(${$CAP_PROJ."::$v"})) {
			${$CAP_PROJ."::$v"} =~ s/^([^\n]*)\n//s;
			$titles{$v} = $1;
		} else {
			${$CAP_PROJ."::$v"} = "";
			$titles{$v} = "document missing";
		}
		
		push @INTERFS, $v;
	}
	
	# these vars define the datastructure (mongodb collection record structure)
	if (substr($v, 0, 7) eq "man_ds_") {
	
		${$CAP_PROJ."::$v"} =~ s/^([^\n]*)\n//s;
		
		my $type = substr($v, 7);
		$titles{$type} = $1;
		
		push @TYPES, $type;
	}
}

print "<head><meta charset=utf-8><title>Server Manual - $CAP_PROJ</title></head>\n";
print "<body style='background:#ddd;margin-top:0px'><div style='height:5px'></div><a name='top'><table style='width:100%;padding:5px;background:#fff;'><tr><td>";
print "<div style='font-size:24px;margin-top:0px'>Server Manual</div>\n";
print "<div style='height:10px'></div>";

################################################################################################################################################################
# print table of content

foreach my $t (sort @TYPES) {
	print_toc($t, "collection: ".$t, $titles{$t});
}

my $last_obj = "";
foreach my $k (sort @INTERFS) {
	# grouping of sections
	my ($p, $obj, $act) = split /_/, $k, 3;
	
	if ($obj ne $last_obj) {
		print "<div style='height:10px'></div>";
		$last_obj = $obj;
	}
	print_toc("$obj:$act", "$obj $act", $titles{$k});
}

print "</td></tr></table>";

print "<div style='height:20px'></div>";

################################################################################################################################################################
foreach my $t (sort @TYPES) {
	print_ds($t, $titles{$t});
}

foreach my $k (sort @INTERFS) {
	print_section($k, $titles{$k});
}

print "<div style='height:10px'></div>";

################################################################################################################################################################
sub print_toc {
	my($anchor, $label, $title) = @_;
	print "<a href='#$anchor' style='font-size:18px'>$label</a> <span style='color:#000;font-style:italic;font-size:12px'>$title</span><br>\n";
}

# construct a html page
sub print_section {
	my($k, $title) = @_;
	
	# uniformed split
	my ($p, $obj, $act) = split /_/, $k, 3;
	
	my $content = ${uc($PROJ)."::$k"};
	
	my $code_key = "p_$obj"."_$act";
	$code_key = $k unless defined(${$CAP_PROJ."::$code_key"});;
	
	# add hyper link to content if pattern obj:act patterns are found 
	my %pats = ();
	while($content =~ /(\S+:\S+)/g) {
		my ($obj, $act) = split /:/, $1;
		
		next unless defined(${$CAP_PROJ."::p_$obj"."_$act"});
		
		$pats{"$obj:$act"} = "<a href='#$obj:$act'>$obj:$act</a>";
	}
	
	foreach my $k (keys %pats) {
		$content =~ s/$k/$pats{$k}/g;
	}
		
	print "<a name='$obj:$act'><table style='width:100%;padding:5px;background:#fff;'><tr><td style='font-weight:bold;color:#333;font-size:18px'><b>$obj $act</b> <span style='color:#000;font-style:italic;font-size:12px'>$title</span><td>";
	print "<td style='text-align:right;font-size:14px'><a href='#top'>TOP &uarr;</a></td></tr>\n";
	
	print "<tr><th colspan=2 style='text-align:left;padding:5px;font-weight:normal;font-size:14px'><pre style='-moz-tab-size:4;-o-tab-size:4;tab-size:4;'>$content</pre></th></tr>\n";
	
	print "<tr><th colspan=2 style='text-align:left;font-weight:normal;font-style:italic;font-size:14px'>$code_key (end) <a href='#top'>top&uarr;</a></th></tr></table>\n";
	
	print "<div style='height:20px'></div>";
}

sub print_ds {
	my($key, $title) = @_;
	
	my $content = ${uc($PROJ)."::man_ds_$key"};
		
	print "<a name='$key'><table style='width:100%;padding:5px;background:#fff;'><tr><td style='font-weight:bold;color:#333;font-size:18px'>collection: <b>$key</b> <span style='color:#000;font-style:italic;font-size:12px'>$title</span><td>";
	print "<td style='text-align:right;font-size:14px'><a href='#top'>TOP &uarr;</a></td></tr>\n";
	
	print "<tr><th colspan=2 style='text-align:left;padding:5px;font-weight:normal;font-size:14px'><pre style='-moz-tab-size:4;-o-tab-size:4;tab-size:4;'>$content</pre></th></tr>\n";
	
	print "<tr><th colspan=2 style='text-align:left;font-weight:normal;font-style:italic;font-size:14px'>man_ds_$key (end) <a href='#top'>top&uarr;</a></th></tr></table>\n";
	
	print "<div style='height:20px'></div>";
}
