package GHPower;

use strict;
use vars qw(@ISA @EXPORT);
use utf8;
use open qw(:std :utf8);
use DBI;
use Date::Manip;
#use GHPowerLDAP;

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
#    $sth = $self->{dbh}->prepare("select id,cid,year,month,exp1,exp2,modtime FROM mexpenses WHERE year=? AND month=?");
    $sth = $self->{dbh}->prepare("select A.id,A.cid,year,month,A.exp1,A.exp2,A.modtime,D.se1,D.se2,D.id AS did FROM mexpenses A inner join daily D ON A.cid=D.cid WHERE A.year=? AND A.month=? AND D.date=?");

    my ($year,$mon) = ($ymon =~ m/(\d{4})\-(\d{2})/);
    my $edate = sprintf("%4d-%02d-01", $year, $mon);

    $sth->execute($year,$mon,$edate);
    while(my $r = $sth->fetchrow_hashref) {
      map { $_=sprintf("%0.2f", $_); s/\./,/; } ($r->{exp1}, $r->{exp2}, $r->{se1}, $r->{se2});
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
#  my $sth = $self->{dbh}->prepare("SELECT A.subscr,A.dn,A.id as id,A.name as name,A.addr as addr,A.mgroup as mgroup,A.mgroup as gid,A.passwd as passwd,A.model as model,A.plimit,A.memo,A.active,A.modtime,A.year,A.sn,A.setdate,B.name AS model,B.type as type,D.dev AS iface,D.id AS if,F.name AS tower,A.ktrans AS ktrans FROM counters A INNER JOIN counter_type B ON A.model=B.id INNER JOIN mgroup C ON A.mgroup=C.id INNER JOIN iface D ON C.if_id=D.id LEFT OUTER JOIN towers F ON F.id=A.tower_id WHERE A.id=? LIMIT 1");
  my $sth = $self->{dbh}->prepare("SELECT A.subscr,A.parcel_id,P.number as domain,S.name as street_name,S.sname as street_sname,P.owner,A.id as id,A.name as name,A.addr as addr,A.mgroup as mgroup,A.mgroup as gid,A.passwd as passwd,A.model as model,A.plimit,A.plimiter,A.memo,A.active,A.modtime,A.year,A.sn,A.setdate,B.name AS model,B.type as type,D.dev AS iface,D.id AS if,F.name AS tower,A.ktrans AS ktrans FROM counters A INNER JOIN counter_type B ON A.model=B.id INNER JOIN mgroup C ON A.mgroup=C.id INNER JOIN iface D ON C.if_id=D.id LEFT OUTER JOIN towers F ON F.id=A.tower_id LEFT OUTER JOIN parcels P ON A.parcel_id=P.id LEFT OUTER JOIN street S ON P.street_id=S.id WHERE A.id=? LIMIT 1");
  $sth->execute($id);
  while(my $r = $sth->fetchrow_hashref) {
    $ret = $r;
  }
  $sth->finish;
#  if($ret->{dn} &&  ($ret->{dn} =~ m/ou=([^,]+),\s*ou=([^,]+)/)) {  # Можно получить дополнительную информацию в LDAP
#    $ret->{domain} = $1;
#    $ret->{street_name} = $2;
##    my $ghldap = new GHPowerLDAP;
##    $ret->{Dom} = $ghldap->get_Domain($ret->{dn});
#  }
  $ret = {} unless $ret;
  return $ret;
}

#    Список счетчиков
sub Counters_list {
  my $self = shift;
  my $showdel = shift;
  my $hidehidden = shift;

  my $ret = undef;
  my $usr = $self->{dbh}->prepare("SELECT lname,fname,mname FROM persons WHERE id=?");
  my $sth = $self->{dbh}->prepare("SELECT A.id,A.name,A.addr,A.mgroup,A.passwd,A.sn,A.model,A.setdate,A.memo,A.active,A.modtime,A.passwd2,A.ktrans,A.tower_id,A.year,A.plimit,A.plimiter,A.subscr,B.id AS status_id,B.state,B.pstate,B.se1,B.se2,B.modtime AS status_modtime,A.parcel_id,P.number AS domain,S.name AS street_name,S.sname AS street_sname,P.owner FROM counters A LEFT OUTER JOIN status B ON B.cid=A.id LEFT OUTER JOIN parcels P ON A.parcel_id=P.id LEFT OUTER JOIN street S ON P.street_id=S.id WHERE A.mgroup IN (SELECT id FROM mgroup".($hidehidden ? " WHERE hidden=false":"").")".((!$showdel) ? " AND NOT (A.active < 0)":""));
  $sth->execute();
  while(my $r = $sth->fetchrow_hashref) {
#    if($r->{dn} &&  ($r->{dn} =~ m/ou=([^,]+),\s*ou=([^,]+)/)) {  # Можно получить дополнительную информацию в LDAP
#      $r->{domain} = $1;
#      $r->{street_name} = $2;
#      my $ghldap = new GHPowerLDAP;
#      $r->{Dom} = $ghldap->get_Domain($r->{dn});
#    }
    foreach my $uid (@{$r->{owner}}) {
      $usr->execute($uid);
      my ($lname,$fname,$mname) = $usr->fetchrow_array;
      $usr->finish;
      my $h;
      push @{$h->{cn}}, "$lname $fname $mname";
      push @{$r->{Dom}->{owners}}, $h;
    }
    push @{$ret->{$r->{mgroup}}->{items}}, $r;
  }
  $sth->finish;
  $ret = {} unless $ret;
  return $ret;
}

#    Последние показания счетчика
sub lastcounter {
  my $self = shift;
  my ($id, $opts) = @_;

  my $ret = undef;
  my $sth;
  if($id) {
    $sth = $self->{dbh}->prepare("select A.modtime AS tm,A.se1 AS t1,A.se2 AS t2, A.lpower, A.lpower>B.plimit AS over,A.state,A.tmok,B.plimit from status A inner join counters B on A.cid=B.id where A.cid=? order by A.modtime desc LIMIT 1");
    $sth->execute($id);
    while(my $r = $sth->fetchrow_hashref) {
      $r->{t1} = sprintf("%0.2f",$r->{t1});
      $r->{t2} = sprintf("%0.2f",$r->{t2});
      $r->{lpower} = sprintf("%0.2f",$r->{lpower});
      map { s/\./,/; } ($r->{t1}, $r->{t2}, $r->{lpower});
      $ret = $r;
    }
  } else {  # Полный список
    $sth = $self->{dbh}->prepare("select A.modtime AS tm,A.se1 AS t1,A.se2 AS t2, A.cid, A.lpower, A.lpower>B.plimit AS over,A.state,A.tmok,B.plimit from status A inner join counters B on A.cid=B.id where A.state=0".($opts->{plimit} ? " and A.lpower>B.plimit":""));
    $sth->execute();
    while(my $r = $sth->fetchrow_hashref) {
      $r->{t1} = sprintf("%0.2f",$r->{t1});
      $r->{t2} = sprintf("%0.2f",$r->{t2});
      $r->{lpower} = sprintf("%0.2f",$r->{lpower});
      map { s/\./,/; } ($r->{t1}, $r->{t2}, $r->{lpower});
      $ret->{$r->{cid}} = $r;
    }
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
  my $table = shift || 'tariff';

  my $ret = undef;
  my $sth = $self->{dbh}->prepare("select *,coalesce(sdate<now()) as legal from $table order by sdate desc limit 20");
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

# Последние показания счетчика, дата (суточная фиксация - для денежных расчетов)
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


##### DEPRECATED
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
#########

# Баланс по указанному счетчику
sub get_cbalance {
  my $self = shift;
  my ($cid) = @_;
  my $sth = $self->{dbh}->prepare("SELECT id,date,balance FROM balance WHERE cid=? ORDER BY date desc LIMIT 1");
  $sth->execute($cid);
  my ($id,$date,$balance) = $sth->fetchrow_array;
  $sth->finish;
  $sth = $self->{dbh}->prepare("SELECT avg(amount) FROM (SELECT amount FROM mexpenses WHERE cid=? AND amount>0 ORDER BY year DESC,month DESC limit 12) A");
  $sth->execute($cid);
  my ($amount) = $sth->fetchrow_array;
  $sth->finish;

  return ($id,$date,$balance,$amount);
}

# Обновление баланса указанного счетчика
sub re_cbalance {
  my $self = shift;
  my ($cid) = @_;
  return(system("MY=$ENV{MY} $ENV{MY}/counter/daily-balance -F $ENV{database} $cid"));
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


############################### LDAP
# Счетчики, привязанные к заданному участку
# DEPRECATED
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
sub getcounters_parcel_id {
  my $self = shift;
  my $parcel_id = shift; # 
  return undef  unless($parcel_id);

  my $ret = undef;
  my $sth = $self->{dbh}->prepare("SELECT id,active FROM counters WHERE parcel_id=?");
  $sth->execute($parcel_id);
  while(my $r = $sth->fetchrow_hashref) {
    $ret->{$r->{id}} = $r->{active};
  }
  $sth->finish;
  $ret = {} unless $ret;
  return $ret;
}


# Текущий баланс по счетчику
# !!! Добавить учет ktrans !!!
sub get_balance {
	my $self = shift;
	my $cid = shift;
	return undef	unless($cid);

	my $gp = $self->{dbh}->prepare("SELECT id,date,prev1,prev2,current1,current2,amount,balance,mode,init FROM payments WHERE cid=? ORDER BY modtime DESC LIMIT 1");
	# последний платеж по этому счетчику
	$gp->execute($cid);
	my ($p_id,$p_date,$p_prev1,$p_prev2,$p_current1,$p_current2,$p_amount,$p_balance,$t_mode,$init) = $gp->fetchrow_array;
	$gp->finish;
	return undef	unless($p_id);
	# платеж был
	my $C = $self->getcounter_last($cid);
	map {s/\,/\./} ($C->{se1},$C->{se2});
  my (undef,undef,$BALANCE) = $self->get_cbalance($cid);
	return ($BALANCE,$C->{se1},$C->{se2},$t_mode);
}

#
# Прочие (не электрические) платежи
# 2016-07-15
#

# Типы платежей
sub b_tariff_type {
  my %b_tariff_type = (
    0 => 'с участка',
    1 => 'с площади',
  );
  return %b_tariff_type;
}

# Начисление платежа всем по списку
sub set_fee {
  my $self = shift;
  my ($bid,$auth,$verb) = @_;

  $auth ||= 0;
  my $Err;
  unless($bid) {
    $Err->{nobid} = 1;
    return $Err;
  }
  $self->{dbh}->begin_work;
  my $ins = $self->{dbh}->prepare("INSERT INTO b_credit (auth,date,parcel_id,b_tariff_id,amount,debt) VALUES ($auth,now(),?,?,?,?)");
  my $chk = $self->{dbh}->prepare("SELECT b_tariff_id FROM b_credit WHERE parcel_id=? AND b_tariff_id=? AND status<>2");
  my $sth = $self->{dbh}->prepare("SELECT type,amount FROM b_tariff WHERE id=? AND sdate IS NULL LIMIT 1");
  my $upd = $self->{dbh}->prepare("UPDATE b_tariff SET sdate=now() WHERE id=?");

  # Данные взноса
  $sth->execute($bid);
  my ($b_type,$b_amount) = $sth->fetchrow_array;
  $sth->finish;
  unless(defined $b_type && defined $b_amount) {
    $Err->{badpars} = 1;
    return $Err;
  }

  # Список участков
  my $List2 = $self->Domains_Struct;
  foreach my $street (keys %{$List2}) {
    my $Dom = $List2->{$street};
    foreach my $house (sort {$a <=> $b || $a cmp $b} keys %{$Dom}) {
      my $dn = $Dom->{$house}->{id};
      next  unless($dn);
  	  next	unless($Dom->{$house}->{owners});  # Пропускать, если нет владельца

      my ($S,$amount);
      if($b_type == 1)  { # начисление с площади
        $S = $Dom->{$house}->{square};  # Площадь участка из справочника
        unless(defined $S) {
          push @{$Err->{nos}}, $dn;
          next;
        }
        $amount = $b_amount * $S;

      } else {        # начисление с участка
        $amount = $b_amount;
      }
      $amount = sprintf("%0.f",$amount);  # 2016-07-30 Татьяна: Начисление округляется до целого числа
      # Повторно не начислять
      $chk->execute($dn,$bid);
      my ($cbid) = $chk->fetchrow_array;
      $chk->finish;
      if($cbid) {
        print "[$dn] bid=$bid - Already set\n"   if($verb);
        next;
      }
      print "[$dn] S=$S Amount=$amount\n"   if($verb);
      $ins->execute($dn,$bid,$amount,$amount);  # b_credit
    }
  }
  # ставим флаг active
  $upd->execute($bid);

  if($Err) {
    $self->{dbh}->rollback;
    print "Rollback due errors.\n"  if($verb);
    return $Err;
  } else {
    $self->{dbh}->commit;
    print "All committed\n" if($verb);
    return;
  }
}

# Последний платеж
sub last_pay {
  my $self = shift;
  my ($dn) = @_;
  return(undef) unless($dn);

  my $sth = $self->{dbh}->prepare("SELECT id,auth,b_tariff_id,pdate,amount,balance,memo,modtime FROM b_pays WHERE dn=? ORDER BY modtime DESC LIMIT 1");
  $sth->execute($dn);
  my ($r) = $sth->fetchrow_hashref;
  $sth->finish;
print STDERR "DN: [$dn]\n";
use Data::Dumper;
print STDERR Dumper $r;

  return($r);
}

# Получить следующий номер исходящего документа
# Формат номера:
# Целое число - слеш (/) - Две последние цифры года
# Пример: 12345/17
#
sub get_next_outnum {
  my $self = shift;
  my ($auth, $date, $to, $subj) = @_;
  $auth ||= 0;
  my $ynum;
  if($date =~ m/\d{2}(\d{2})-\d{2}-\d{2}/) {
    $ynum = $1;
  } else {
    my $stamp = time();
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime( $stamp );
    $date = sprintf("%.4d-%.2d-%.2d", $year+1900, $mon+1, $mday);
    ($ynum) = (($date) =~ m/^\d{2}(\d{2})/);
  }

#  # Последний существующий номер
#  my $sth = $self->{dbh}->prepare("SELECT id,auth,modtime,docdate,docto,subj FROM outnum WHERE id LIKE ? ORDER BY modtime DESC LIMIT 1");
#  $sth->execute('%/'.$ynum);
#  my ($r) = $sth->fetchrow_hashref;
#  $sth->finish;
#  my $dnum;
#  if($r->{id}) {  # генерим следующий номер
#    ($dnum) = (($r->{id}) =~ m|(\d+)/|);
#  }
#  $dnum++;
#  my $next_ountum = $dnum.'/'.$ynum;
#  my $ins = $self->{dbh}->prepare("INSERT INTO outnum (id,auth,modtime,docdate,docto,subj) VALUES (?,?,now(),?,?,?)");
#  $ins->execute($next_ountum,$auth,$date,$to,$subj);

  my $sth = $self->{dbh}->prepare("WITH w AS (UPDATE outnum_w SET id = outnum_next() RETURNING id) INSERT INTO outnum (id,auth,modtime,docdate,docto,subj) SELECT id,?,now(),?,?,? FROM w RETURNING id");
  $sth->execute($auth,$date,$to,$subj);
  my ($next_ountum) = $sth->fetchrow_array;
  $sth->finish;

  return $next_ountum;
}
# Последний зарегистрированный исходящий номер
sub get_last_outnum {
  my $self = shift;
  # Последний существующий номер
  my $sth = $self->{dbh}->prepare("SELECT id,auth,modtime,docdate,docto,subj FROM outnum ORDER BY modtime DESC LIMIT 1");
  $sth->execute();
  my ($r) = $sth->fetchrow_hashref;
  $sth->finish;
  if($r->{id}) {
    return $r;
  }
  return undef;
}

########################################################################################################################################
# Список улиц
sub Street_List {
  my $self = shift;
  my $sth = $self->{dbh}->prepare("SELECT id as s_id,name,sname,ord as s_ord FROM street");
  $sth->execute();
  my $ret;
  while (my $r = $sth->fetchrow_hashref) {
    my %h; $h{$r->{name}} = $r->{sname};
    push @{$ret}, \%h;
  }
  $sth->finish;
  return $ret;
}

# Список участков
sub Domains_List {
  my $self = shift;
  my $opts = shift;
  my $active = exists $opts->{active};
  my $sth = $self->{dbh}->prepare("SELECT A.id,A.active,A.street_id,S.name as street_name,S.sname as street_sname,S.ord AS s_ord,A.number,A.square,A.owner,A.manager,A.maillist,A.memo FROM parcels A inner join street S on A.street_id=S.id ".($active ? "where A.active=1":"")." order by S.ord,A.number");
  $sth->execute();
  my $ret;
  while (my $r = $sth->fetchrow_hashref) {
    push @{$ret}, $r;
  }
  $sth->finish;
  return $ret;
}

# Вся структура ou=domains с владельцами и пр.
sub Domains_Struct {
  my $self = shift;
  my $opts = shift;
#  my $active = exists $opts->{active};
  my $data = $self->Domains_List({active=>1});
  my $Data;
  foreach my $r (@$data) {
    $Data->{$r->{street_name}}->{$r->{number}} = $self->get_Domain($r->{id});
  }
  return $Data;
}

# Информация о заданном участке
sub get_Domain {
  my $self = shift;
  my $id = shift;
  return undef  unless $id;
  my $sth = $self->{dbh}->prepare("SELECT A.id,A.active,A.street_id,S.name as street_name,S.sname as street_sname,S.ord AS s_ord,A.number,A.square,A.owner,A.manager,A.maillist,A.memo,A.proof,A.proof_date FROM parcels A inner join street S on A.street_id=S.id where A.id=?");
  $sth->execute($id);
  my $Data = $sth->fetchrow_hashref;
  $sth->finish;
  foreach(@{$Data->{owner}}) {
    push @{$Data->{owners}}, $self->get_Person($_);
  }
  foreach(@{$Data->{manager}}) {
    push @{$Data->{managers}}, $self->get_Person($_);
  }
  return $Data;
}

# Информация о персоне
sub get_Person {
  my $self = shift;
  my $id = shift;
  return undef unless ($id);
  my $sth = $self->{dbh}->prepare("SELECT id,active,fname,mname,lname,nicname,birthdate,email,phone,memo,auth,modtime,passport,passport_date,address,address_date,membership,membership_end,CASE WHEN membership is not null AND membership_end is null THEN '+' END AS member FROM persons WHERE id=?");
  my $Data;
  $sth->execute($id);
  while(my $r = $sth->fetchrow_hashref) {
    $r->{cn} = $r->{lname}.' '.$r->{fname}.' '.$r->{mname};
    $Data = $r;
  }
  $sth->finish;
  return $Data;
}

# Реквизиты организации
sub getorg {
  my $self = shift;
  my $sth = $self->{dbh}->prepare("SELECT * FROM details WHERE active=1");
  $sth->execute();
  my $Data = $sth->fetchrow_hashref;
  $sth->finish;
  return $Data;
}

# Адреса для рассылки (У которых проставлен флаг в списке счётчиков или в списке участков)
sub get_Domain_subscr_emails {
  my $self = shift;
  my $dn = shift;
  my $monly = shift;  # Только члены СНТ
  return undef  unless $dn;

  my $P = $self->get_Domain($dn);
  my @emails;
  my $member;
  # Сначала ищем среди управляющих
  foreach my $manager (sort { $a->{cn} cmp $b->{cn} } @{$P->{managers}}) {
    next  unless($manager->{active});
    $member++   if($manager->{member});
    foreach(sort { $a cmp $b } ref $manager->{email} eq 'ARRAY' ? @{$manager->{email}} : ($manager->{email} || ())) {
      push @emails, $_  if($_);
    }
  }
  # Если нет адресов, то смотрим владельцев
  foreach my $owner (sort { $a->{cn} cmp $b->{cn} } @{$P->{owners}}) {
    next  unless($owner->{active});
    $member++   if($owner->{member});
    unless(@emails) {
     foreach(sort { $a cmp $b } ref $owner->{email} eq 'ARRAY' ? @{$owner->{email}} : ($owner->{email} || ())) {
      push @emails, $_  if($_);
      }
    }
  }
  if($monly) {
    return @emails  if($member);
    undef @emails;
  }
  return @emails;
}


1;
