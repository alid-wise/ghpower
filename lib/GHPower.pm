package GHPower;

use strict;
use vars qw(@ISA @EXPORT);
use utf8;
use open qw(:std :utf8);
use DBI;
use Date::Manip;
use GHPowerLDAP;

sub new {
  my $class = shift;
  my ($dbh) = @_;
  my $self={};
  $self->{dbh} = $dbh;
  bless $self,$class;
  $self->init;
  return $self;
}

sub init {
  my $self = shift;
}


# Загрузка справочника
sub ListLoad {
  my $self = shift;
  my $name = shift;

  my $ret = undef;
  my $sth = $self->{dbh}->prepare("select * from $name");
  $sth->execute();
  while(my $r = $sth->fetchrow_hashref) {
    $ret->{$r->{id}} = $r;
  }
  $sth->finish;
  $ret = {} unless $ret;
  return $ret;
}

# Общая информация
sub Global {
  my $self = shift;

  my $ret = undef;
  my $sth = $self->{dbh}->prepare("select min(setdate),max(setdate) from counters");
  $sth->execute();
  ($ret->{first_sedate},$ret->{last_sedate}) = ($sth->fetchrow_array);
  $sth->finish;
  ($ret->{first_year}) = ($ret->{first_sedate} =~ m/^(\d{4})\-/);
  $ret->{last_year} = UnixDate("1 month ago","%Y");
  $ret->{today_year} = UnixDate("today","%Y");
  $ret = {} unless $ret;
  return $ret;
}

#  Месячные расходы счетчика
sub mExpenses {
  my $self = shift;
  my ($cid,$ymon) = @_;
  $cid ||= 0;

  my $ret = undef;
  my $sth;
  if($cid) {
    $sth = $self->{dbh}->prepare("select id,cid,year,month,exp1,exp2,modtime FROM mexpenses WHERE cid=?");
    $sth->execute($cid);
    while(my $r = $sth->fetchrow_hashref) {
      map { $_=sprintf("%0.2f", $_); s/\./,/; } ($r->{exp1}, $r->{exp2});
      $r->{month} = sprintf("%02d",$r->{month});
      $ret->{$r->{year}}->{$r->{month}} = $r;
    }
  } else {  # Полный список
    $sth = $self->{dbh}->prepare("select id,cid,year,month,exp1,exp2,modtime FROM mexpenses WHERE year=? AND month=?");
    my ($year,$mon) = ($ymon =~ m/(\d{4})\-(\d{2})/);

    $sth->execute($year,$mon);
    while(my $r = $sth->fetchrow_hashref) {
      map { $_=sprintf("%0.2f", $_); s/\./,/; } ($r->{exp1}, $r->{exp2});
      $r->{month} = sprintf("%02d",$r->{month});
      $ret->{$r->{cid}} = $r;
    }
  }
  $sth->finish;
  $ret = {} unless $ret;
  return $ret;
}

#  Параметры счетчика
sub Counter_info {
  my $self = shift;
  my $id = shift;

  my $ret = undef;
  my $sth = $self->{dbh}->prepare("SELECT A.dn,A.id as id,A.name as name,A.addr as addr,A.mgroup as mgroup,A.mgroup as gid,A.passwd as passwd,A.model as model,A.plimit,A.memo,A.active,A.modtime,A.year,A.sn,A.setdate,B.name AS model,B.type as type,D.dev AS iface,D.id AS if,F.name AS tower FROM counters A INNER JOIN counter_type B ON A.model=B.id INNER JOIN mgroup C ON A.mgroup=C.id INNER JOIN iface D ON C.if_id=D.id LEFT OUTER JOIN towers F ON F.id=A.tower_id WHERE A.id=? LIMIT 1");
  $sth->execute($id);
  while(my $r = $sth->fetchrow_hashref) {
    $ret = $r;
  }
  $sth->finish;
  if($ret->{dn} &&  ($ret->{dn} =~ m/ou=([^,]+),\s*ou=([^,]+)/)) {  # Можно получить дополнительную информацию в LDAP
    $ret->{domain} = $1;
    $ret->{street_name} = $2;
    my $ghldap = new GHPowerLDAP;
    $ret->{Dom} = $ghldap->get_Domain($ret->{dn});
  }
  $ret = {} unless $ret;
  return $ret;
}


#    Список счетчиков
sub Counters_list {
  my $self = shift;
  my $showdel = shift;

  my $ret = undef;
  my $sth = $self->{dbh}->prepare("select A.id,A.name,A.addr,A.mgroup,A.passwd,A.sn,A.model,A.setdate,A.memo,A.active,A.modtime,A.passwd2,A.ktrans,A.tower_id,A.year,A.street,A.house,A.owner,A.plimit,A.subscr,B.id as status_id,B.state,B.pstate,B.se1,B.se2,B.modtime as status_modtime,A.dn from counters A left outer join status B on B.cid=A.id".((!$showdel) ? " where not (A.active < 0)":""));
  $sth->execute();
  while(my $r = $sth->fetchrow_hashref) {
    if($r->{dn} &&  ($r->{dn} =~ m/ou=([^,]+),\s*ou=([^,]+)/)) {  # Можно получить дополнительную информацию в LDAP
      $r->{domain} = $1;
      $r->{street_name} = $2;
      my $ghldap = new GHPowerLDAP;
      $r->{Dom} = $ghldap->get_Domain($r->{dn});
    }
    push @{$ret->{$r->{mgroup}}->{items}}, $r;
  }
  $sth->finish;
  $ret = {} unless $ret;
  return $ret;
}

#    Текущая сумма мощностей по лучу
sub grsum {
  my $self = shift;
  my $gid = shift;

  my $sth = $self->{dbh}->prepare("select sum(lpower) as lpsum from status where cid in (select id from counters where mgroup=? and active=1)");
  $sth->execute($gid);
  my $ret = $sth->fetchrow_hashref;
  $sth->finish;
  $ret->{lpsum} = sprintf("%0.2f",$ret->{lpsum});
  $ret->{lpsum} =~ s/\./,/;
  $ret = {} unless $ret;
  return $ret;
}

#  Время последнего обновления данных
sub lastime {
  my $self = shift;

  my $sth = $self->{dbh}->prepare("select modtime as lastime from status order by modtime desc limit 1");
  $sth->execute();
  my $ret = $sth->fetchrow_hashref;
  $sth->finish;
  $ret->{lastime} =~ s/\.\d*$//;
  $ret = {} unless $ret;
  return $ret;
}

# Текущие тарифы
sub tariff {
  my $self = shift;

  my $ret = undef;
  my $sth = $self->{dbh}->prepare("select *,coalesce(sdate<now()) as legal from tariff order by sdate desc limit 20");
  $sth->execute();
  while(my $r = $sth->fetchrow_hashref) {
    unless($ret->{C}) {
      if($r->{legal}) {
        $ret->{C} = $r; # текущий тариф
      }
    }
    $ret->{$r->{id}} = $r;
  }
  $ret = {} unless $ret;
  return $ret;
}

# Последние показания счетчика, дата
sub getcounter_last {
  my $self = shift;
  my $id = shift;

  my $ret = undef;
  my $sth = $self->{dbh}->prepare("SELECT id,date,cid,se1,se2 FROM daily WHERE cid=? ORDER BY date DESC LIMIT 1");
  $sth->execute($id);
  while(my $r = $sth->fetchrow_hashref) {
    map { s/\./,/; } ($r->{se1}, $r->{se2});
    $ret = $r;
  }
  $sth->finish;
  $ret = {} unless $ret;
  return $ret;
}

# Стоимость потраченного электричества
# без учета изменения тарифов
sub getcost_simple {
  my $self = shift;
  my ($flow1, $flow2, $mode) = @_;
  $mode ||= 2;

  # Текущий тариф
  my $T = $self->tariff();
  my ($ret,$ret1,$ret2) = (undef,undef,undef);
  if($mode eq "1") {  # Однотарифник
    $ret = (($flow1 + $flow2) * $T->{C}->{t0}) * $T->{C}->{k};
    $ret1 = ($flow1 * $T->{C}->{t0}) * $T->{C}->{k};
    $ret2 = ($flow2 * $T->{C}->{t0}) * $T->{C}->{k};
  } else {  # Двухтарифник
    $ret = ($flow1 * $T->{C}->{t1} + $flow2 * $T->{C}->{t2}) * $T->{C}->{k};
    $ret1 = ($flow1 * $T->{C}->{t1}) * $T->{C}->{k};
    $ret2 = ($flow2 * $T->{C}->{t2}) * $T->{C}->{k};
  }
  return ($ret,$ret1,$ret2);
}


# Показания счетчика на дату
sub getcounter_date {
  my $self = shift;
  my ($id,$date) = @_;

  return undef  if(!$id || !($date =~ /^\d{4}\-\d{2}\-\d{2}$/));
  my $ret = undef;
  my $sth = $self->{dbh}->prepare("SELECT date AS date,cid AS counter,se1 AS se1ai,se2 AS se2ai,date AS dt FROM daily WHERE cid=? AND date>=? ORDER BY date LIMIT 1");
  $sth->execute($id,$date);
  while(my $r = $sth->fetchrow_hashref) {
    $ret = $r;
  }
  $sth->finish;
  $ret = {} unless $ret;
  return $ret;
}

# Счетчики, привязанные к заданному участку
sub getcounters_dn {
  my $self = shift;
  my $dn = shift; # формат: "ou=3,ou=Улица"

  return undef  unless($dn =~ m/ou=([^,]+),\s*ou=([^,]+)/);

  my $ret = undef;
  my $sth = $self->{dbh}->prepare("SELECT id,active FROM counters WHERE dn=?");
  $sth->execute($dn);
  while(my $r = $sth->fetchrow_hashref) {
    $ret->{$r->{id}} = $r->{active};
  }
  $sth->finish;
  $ret = {} unless $ret;
  return $ret;
}

# Вся структура ou=domains с владельцами и пр.
sub Domains_Struct {
  my $self = shift;
  my $ghldap = new GHPowerLDAP;
  return $ghldap->Domains_Struct();
}


1;