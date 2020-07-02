#!/usr/bin/perl

# get/post HTTP

use LWP::UserAgent;
use LWP::Simple;
use HTTP::Request::Common;
use JSON;
use Data::Dump qw(dump);
use MIME::Base64;

post_hash_to_server("http://47.92.169.34/cgi-bin/posttest.pl");

# POST: application/x-www-form-urlencoded
# by default, LWP POST initialize a request using the application/x-www-form-urlencoded content type
sub post_hash_to_server {

    my ($url) = @_;
    my $ua = LWP::UserAgent->new(cookie_jar=>{});

    # sending form data
    my $request = POST $url,
        [
            key1 => "value1",
            key2 => "value2",
        ];

    my $response = $ua->request($request);
    return dump($response) unless $response->is_success();
    my $json = JSON->new();
    my $ref = $json->decode($response->content());
    print $json->pretty()->encode($ref);
}

# POST: multipart/form-data
# utility to send file attachment over to server, get a fid and thumb in return
sub post_file_to_server {

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
    return dump($response) unless $response->is_success();
    return $response->content();
}
