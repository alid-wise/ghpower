package GHPowerAPI;
use strict;

use base qw(JSON::RPC::Legacy::Procedure); # Perl 5.6 or more than
use DBI;
use Data::Dumper;

my $dbh;

BEGIN {
	my $dbname = 'ghpower';
	my $dbhost = 'localhost';
	my $dbuser = 'www';
	my $dbpassw = '';

	$dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost", "$dbuser", "$dbpassw", {AutoCommit => 1, RaiseError => 1, pg_enable_utf8 => 1});
}

END {
	$dbh->disconnect;
}

sub echo : Public {    # new version style. called by clients
    # first argument is JSON::RPC::Legacy::Server object.
print STDERR Dumper $_[1];
    return $_[1];
}

# Последние показания счетчика
sub lastcounter : Public {
	my $Usr = $_[1];
	my %Err;
	$Usr->{id} =~ s/\D//g;
	my ($sth, $Ret);
	if($Usr->{id} > 0) {
		$sth = $dbh->prepare("select A.modtime AS tm,A.se1 AS t1,A.se2 AS t2, A.lpower, A.lpower>B.plimit AS over,A.state from status A inner join counters B on A.cid=B.id where A.cid=? order by A.modtime desc LIMIT  1");
		$sth->execute($Usr->{id});
		my $r = $sth->fetchrow_hashref;
		$sth->finish;
		$Ret = _format_lastcounter($r);
	} else {
		$sth = $dbh->prepare("select A.modtime AS tm,A.se1 AS t1,A.se2 AS t2, A.cid, A.lpower, A.lpower>B.plimit AS over,A.state from status A inner join counters B on A.cid=B.id where A.state=0");
		$sth->execute();
		while (my $r = $sth->fetchrow_hashref) {
			$Ret->{$r->{cid}} = _format_lastcounter($r);
		}
		$sth->finish;
	}
	return $Ret;
}
sub _format_lastcounter : Private {
	my $r = shift;
	$r->{t1} = sprintf("%0.2f",$r->{t1});
	$r->{t1} =~ s/\./,/;
	$r->{t2} = sprintf("%0.2f",$r->{t2});
	$r->{t2} =~ s/\./,/;
	$r->{lpower} = sprintf("%0.2f",$r->{lpower});
	$r->{lpower} =~ s/\./,/;
	return $r;
}



# Текущая сумма по лучу
sub grsum : Public {
	my $Usr = $_[1];
	my %Err;
	unless($Usr) {
		$Err{error} = '400';
		$Usr->{error} = \%Err;
		return $Usr;
	}
	$Usr->{gid} =~ s/\D//g;
	my $sth = $dbh->prepare("select sum(lpower) as lpsum from status where cid in (select id from counters where mgroup=? and active=1)");
	$sth->execute($Usr->{gid});
	my $Ret = $sth->fetchrow_hashref;
	$sth->finish;
	$Ret->{lpsum} = sprintf("%0.2f",$Ret->{lpsum});
	$Ret->{lpsum} =~ s/\./,/;
	return $Ret;
}
# Время последнего обновления данных
sub lastime : Public {
	my $sth = $dbh->prepare("select modtime as lastime from status order by modtime desc limit 1");
	$sth->execute();
	my $Ret = $sth->fetchrow_hashref;
	$sth->finish;
	$Ret->{lastime} =~ s/\.\d*$//;
	return $Ret;
}






1;

