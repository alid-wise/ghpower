package GHPowerUtils;

use strict;
use vars qw(@ISA @EXPORT);
use Encode qw(encode decode is_utf8);
use open qw(:std :utf8);
use utf8;
use POSIX;
use Carp;
use Time::Local;
use Exporter;
use JSON;
@ISA = ('Exporter');
@EXPORT = qw(&SendMail &SendMailCharset &Time &UTime &Now);

sub SendMail_ {
        my ($from, $to, $subj, $body, %opts) = @_;

        my $charset = $opts{charset} || "utf-8";
        eval{ require MIME::Words };
        unless($@ || $subj =~ /^\=\?/){
                Encode::_utf8_off($subj);
                $subj = MIME::Words::encode_mimeword($subj, 'B', $charset);
        }

        my $ctype = $opts{content} || 'text/plain';
#        open XMAIL, "| /usr/local/sbin/sendmail -t -fbounce\@nomail.com"   or croak "Can't open sendmail: $!";
        open XMAIL, "| /usr/local/sbin/sendmail -t"   or croak "Can't open sendmail: $!";
        my $xheaders = $opts{xheaders} || '';
        $xheaders .= "\n"       if $xheaders && $xheaders !~ /\n$/;
#        Encode::_utf8_off($body);
        print XMAIL "MIME-Version: 1.0\nContent-Type: $ctype;charset=\"$charset\"\nSubject: $subj\nFrom: $from\nTo: $to\n$xheaders\n$body";
        close(XMAIL);
}

# Сообщение - в очередь
sub SendMail_queue {
        my ($dbh, $from, $to, $subj, $body, $opts) = @_;
        my $opts2 = to_json($opts);
        my $ins = $dbh->prepare("INSERT INTO feeds_queue (\"from\",\"to\",subj,body,opts) VALUES (?,?,?,?,?)");
        $ins->execute($from, $to, $subj, $body, $opts2);
        $dbh->commit  unless($dbh->{AutoCommit});
}

sub SendMail {
        my ($from, $to, $subj, $body, %opts) = @_;

        my $charset = $opts{charset} || "utf8";
        eval{ require MIME::Words };
        unless($@ || $subj =~ /^\=\?/){
                Encode::_utf8_off($subj);
                $subj = MIME::Words::encode_mimeword($subj, 'B', $charset);
        }

        my $ctype = $opts{content} || 'text/plain';
        open XMAIL, "| /usr/sbin/sendmail -t"   or croak "Can't open sendmail: $!";
        my $xheaders = $opts{xheaders} || '';
        $xheaders .= "\n"       if $xheaders && $xheaders !~ /\n$/;
#                Encode::_utf8_off($body);
        print XMAIL "MIME-Version: 1.0\nContent-Type: $ctype;charset=\"$charset\"\nSubject: $subj\nFrom: $from\nTo: $to\n$xheaders\n$body";
        close(XMAIL);
}

sub Time {
        my ($tm) = @_;
        return 0        unless $tm;
        my ($wk) = $tm =~ /(\d+)\s*w\D*/i;      $tm =~ s/\d+\s*w\D*//i;
        my ($dy) = $tm =~ /(\d+)\s*d\D*/i;      $tm =~ s/\d+\s*d\D*//i;
        my ($hr) = $tm =~ /(\d+)\s*h\D*/i;      $tm =~ s/\d+\s*h\D*//i;
        my ($mn) = $tm =~ /(\d+)\s*m\D*/i;      $tm =~ s/\d+\s*m\D*//i;
        $tm =~ s/\D//g;
        return (((($wk || 0) * 7 + ($dy || 0)) * 24 + ($hr || 0)) * 60 + ($mn || 0)) * 60 + ($tm || 0);
}

sub UTime {
  my ($date, %opts) = @_;
  my ($mday, $month, $year);
  if($date =~ /^\d+-\d+\-\d+/){
        ($year, $month, $mday) = $date =~ /^(\d+)\-(\d+)\-(\d+)\s*/;
  }elsif($date =~ /^\d+\.\d+\.\d+/){
        ($mday, $month, $year) = $date =~ /^(\d+)\.(\d+)\.(\d+)\s*/;
        ($mday, $year) = ($year, $mday) if $mday > 1000;
  }elsif($date =~ /^(\d\d)(\d\d)(\d\d\d\d)\s+(\d\d)(\d\d)/){
        return eval{ $opts{gmtime} ? timegm(0, $5, $4, $1, $2 - 1, $3) : timelocal(0, $5, $4, $1, $2 - 1, $3) };
  }elsif($date =~ /^\d+$/){
        return $date;
  }else{
        return;
  }
  $year += ($year >= 70 ? 1900:2000)    if $year < 1000;
  my ($hour, $min, $sec) = $date =~ /\s+(\d+):(\d+):?(\d*)$/;
  my $offs = 0;
  if($year > 2037){
        $offs = ($year - 2037) * 365 * 24 * 3600;
        $year = 2037;
  }
  my $ctime = $opts{gmtime} ? timegm($sec || 0, $min || 0, $hour || 0, $mday, $month - 1, $year - 1900) : timelocal($sec || 0, $min || 0, $hour || 0, $mday, $month - 1, $year - 1900);
  return $ctime + $offs;
}

sub Now {
        my ($stamp, %opts) = @_;
        $stamp = time()         unless defined $stamp;
        my ($sec, $min, $hour, $mday, $mon, $year) = localtime( $stamp );
        return $opts{iso} ?
                sprintf("%.4d-%.2d-%.2d %.2d:%.2d:%.2d", $year+1900, $mon+1, $mday, $hour, $min, $sec) :
                sprintf("%.2d.%.2d.%.4d %.2d:%.2d:%.2d", $mday, $mon+1, $year+1900, $hour, $min, $sec) ;
}

sub ClipStr {
  my ($str, $len, $tail) = @_;
  croak "Usage: ClipStr(\$str, \$len, [\$tail])"        unless $len;
  $tail ||= '...';
  my $kind = '';
  foreach( split /([ ,;:])/, $str){
    last if length($kind.$_) > $len;
    $kind .= $_;
  }
  $kind =~ s/\s*$//;
  return $kind.(length($str) <= $len ? '' : $tail);
}

1;

