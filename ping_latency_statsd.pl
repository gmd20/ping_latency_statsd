#!/usr/bin/perl -w

use strict;
use Net::Ping;
use IO::Socket;
use Time::HiRes qw( usleep gettimeofday nanosleep clock_gettime);

my $statsd_host   = "192.168.30.60";
my $statsd_port   = 8125;
my $ping_dest_ip  = "192.168.30.61";
my $ping_interval = 1000000;   #microseconds

my $socket = IO::Socket::INET->new( PeerPort  => $statsd_port,
                                 PeerAddr  => $statsd_host,
                                 Type      => SOCK_DGRAM,
                                 Proto     => 'udp')
      or die "Socket could not be created, failed with error $!\n";

my $p = Net::Ping->new("icmp");
$p->hires();

my $hostname = `hostname`;
chomp($hostname) ;
$hostname =~ s/ //g;
my $metric_name = $hostname . ".ping_latency";

while (1) {
  my ($ret, $duration, $ip) = $p->ping($ping_dest_ip, 5.5);
  # printf("$host [ip: $ip] is alive (packet return time: %.4f ms)\n",
  # 1000 * $duration) if $ret;
  if (not $ret) {
      $duration = 100000;   # timeout
  }
  $duration = $duration *1000;
  # https://github.com/etsy/statsd/blob/master/docs/metric_types.md
  my $packet = $metric_name . sprintf (":%.2f|ms", $duration);
  # print "$packet\n";
  $socket->send($packet);
  usleep($ping_interval);
}

$p->close();
$socket->close();
