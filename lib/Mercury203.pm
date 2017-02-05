package Mercury203;
use strict;
use vars qw($VERSION);

$VERSION="1.0";

#
#       Copyright (C) 2008-2017 Александр Девяткин, "Зелёная горка"
#
#       Разрешается повторное распространение и использование как в виде исходного
#       кода, так и в двоичной форме, с изменениями или без, при соблюдении следующих
#       условий:
#
#       * При повторном распространении исходного кода должно оставаться указанное
#         выше уведомление об авторском праве, этот список условий и последующий
#         отказ от гарантий.
#       * При повторном распространении двоичного кода должна сохраняться указанная
#         выше информация об авторском праве, этот список условий и последующий отказ
#         от гарантий в документации и/или в других материалах, поставляемых при
#         распространении.
#       * Ни название "Зелёная горка", ни имена ее сотрудников не могут быть
#         использованы в качестве поддержки или продвижения продуктов, основанных
#         на этом ПО без предварительного письменного разрешения.
#
#       ЭТА ПРОГРАММА ПРЕДОСТАВЛЕНА ВЛАДЕЛЬЦАМИ АВТОРСКИХ ПРАВ И/ИЛИ ДРУГИМИ СТОРОНАМИ
#	"КАК ОНА ЕСТЬ" БЕЗ КАКОГО-ЛИБО ВИДА ГАРАНТИЙ, ВЫРАЖЕННЫХ ЯВНО ИЛИ ПОДРАЗУМЕВАЕМЫХ,
#	ВКЛЮЧАЯ, НО НЕ ОГРАНИЧИВАЯСЬ ИМИ, ПОДРАЗУМЕВАЕМЫЕ ГАРАНТИИ КОММЕРЧЕСКОЙ ЦЕННОСТИ
#	И ПРИГОДНОСТИ ДЛЯ КОНКРЕТНОЙ ЦЕЛИ. НИ В КОЕМ СЛУЧАЕ, ЕСЛИ НЕ ТРЕБУЕТСЯ
#	СООТВЕТСТВУЮЩИМ ЗАКОНОМ, ИЛИ НЕ УСТАНОВЛЕНО В УСТНОЙ ФОРМЕ, НИ ОДИН ВЛАДЕЛЕЦ
#	АВТОРСКИХ ПРАВ И НИ ОДНО ДРУГОЕ ЛИЦО, КОТОРОЕ МОЖЕТ ИЗМЕНЯТЬ И/ИЛИ ПОВТОРНО
#	РАСПРОСТРАНЯТЬ ПРОГРАММУ, КАК БЫЛО СКАЗАНО ВЫШЕ, НЕ НЕСЁТ ОТВЕТСТВЕННОСТИ,
#	ВКЛЮЧАЯ ЛЮБЫЕ ОБЩИЕ, СЛУЧАЙНЫЕ, СПЕЦИАЛЬНЫЕ ИЛИ ПОСЛЕДОВАВШИЕ УБЫТКИ,
#	ВСЛЕДСТВИЕ ИСПОЛЬЗОВАНИЯ ИЛИ НЕВОЗМОЖНОСТИ ИСПОЛЬЗОВАНИЯ ПРОГРАММЫ (ВКЛЮЧАЯ,
#	НО НЕ ОГРАНИЧИВАЯСЬ ПОТЕРЕЙ ДАННЫХ, ИЛИ ДАННЫМИ, СТАВШИМИ НЕПРАВИЛЬНЫМИ, ИЛИ
#	ПОТЕРЯМИ ПРИНЕСЕННЫМИ ИЗ-ЗА ВАС ИЛИ ТРЕТЬИХ ЛИЦ, ИЛИ ОТКАЗОМ ПРОГРАММЫ РАБОТАТЬ
#	СОВМЕСТНО С ДРУГИМИ ПРОГРАММАМИ), ДАЖЕ ЕСЛИ ТАКОЙ ВЛАДЕЛЕЦ ИЛИ ДРУГОЕ ЛИЦО БЫЛИ
#	ИЗВЕЩЕНЫ О ВОЗМОЖНОСТИ ТАКИХ УБЫТКОВ.
#

#       Copyright (C) 2008-2017 Aleksandr Deviatkin, "Green Hill"
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are
#       met:
#       
#       * Redistributions of source code must retain the above copyright
#         notice, this list of conditions and the following disclaimer.
#       * Redistributions in binary form must reproduce the above
#         copyright notice, this list of conditions and the following disclaimer
#         in the documentation and/or other materials provided with the
#         distribution.
#       * Neither the name of the Green Hill nor the names of its
#         contributors may be used to endorse or promote products derived from
#         this software without specific prior written permission.
#       
#       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#       "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#       LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#       A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#       OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#       SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#       LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#       DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#       THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#       OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#


#
# Mercury-203 support module
# 2017-02-05 alid
#

use Device::SerialPort;
use Digest::CRC;
use Lock;

my $MAXLENGTH = 255;	# наибольшая длина пакета
my $STALL_DEFAULT = 2; # how many seconds to wait for new input


sub new {
	my $class = shift;
	my ($device,$addr,$pass,$pass2,$retries,$verb)=@_;
	my $self={};
	$self->{maxlength} = $MAXLENGTH;
	$self->{device} = $device;
	my $lockfile = $device;
	$lockfile =~ s(/)(_)g;
	$self->{lock} = Lock->new("/tmp/".$lockfile.".PM");
	die "Mercury: Locked"	if($self->{lock}->set);
	$self->{port} = Device::SerialPort->new($device,0);
	$self->{ctx} = Digest::CRC->new(width=>16, init=>0xffff, xorout=>0x0000, poly=>0x8005, refin=>1, refout=>1, cont=>0);
	$self->{addr} = $addr;
	$self->{pass} = $pass;
	$self->{pass2} = $pass2;
	$self->{timeout} = $STALL_DEFAULT * 10;
	$self->{_verb} = $verb || 0;
	$self->{retries} = $retries || 1;
	bless $self,$class;
	$self->init();
	return $self;
}

sub init {
	my $self = shift;
	$self->{tstcmd} = '2f';
}

END {
#	my $self = shift;
#	$self->{lock}->clear();
}

sub quit {
	my $self = shift;
	$self->{lock}->clear();
}

sub isok {
	my $self = shift;
	my ($status,$cnt,@data) = $self->_recv();
	if($status =~ /ok/) {
		unless($cnt eq '11' && $data[4] eq '2f') {
			$status = 'fail';
		}
	}
	return $status;
}

sub iscrc {
	my $self = shift;
	my (@data) = @_;
	my $hstr = '';
	for my $i (@data) { $hstr .= sprintf "%02x", hex($i); }
	my $data = pack ("H*", $hstr);
	$self->{ctx}->reset;
	$self->{ctx}->add($data);
	my $crc16 = $self->{ctx}->digest;
	return $crc16 ? 'crc-error' : 'ok';
}

sub get {
	my $self = shift;
	my ($ts) = @_;
	my $i = $self->{retries};
	my ($status,$cnt,@data);
	do {
		$self->_send($ts);
		($status,$cnt,@data) = $self->_recv();
		$i--;
		$i=0	if($status =~ /ok/);
	} while($i);
	return($status,$cnt,@data);
}

# проверка связи
sub tst {
	my $self = shift;
	my $cmd = $self->{tstcmd};
	my $i = $self->{retries};
	my $res;
	do {
		$self->_send($cmd);
		$res = $self->isok();
		return $res	if($res =~ /ok/);
		$i--;
	} while($i);
	return $res;
}

# Открытие сессии
#sub sopen {
#	my $self = shift;
#	my $cmd = 1;
#	my $i = $self->{retries};
#	my $res;
#	do {
#		$self->_send($cmd,$self->{level},$self->{pass});
#		$res = $self->isok();
#		return $res	if($res =~ /ok/);
#		$i--;
#	} while($i);
#	return $res;
#}

# Закрытие сессии
#sub sclose {
#	my $self = shift;
#	my $cmd = 2;
#	my $i = $self->{retries};
#	my $res;
#	do {
#		$self->_send($cmd);
#		$res = $self->isok();
#		return $res	if($res =~ /ok/);
#		$i--;
#	} while($i);
#	return $res;
#}

# get time from device
sub get_time {
	my $self = shift;
	my ($status,$cnt,@data) = $self->get('21');
	return $status	unless($status=~/ok/);
	print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
	my ($year,$mons,$mday,$hour,$min,$sec,$dow) = ("20".$data[11],$data[10],$data[9],$data[6],$data[7],$data[8],$data[5]);
	($status,$cnt,@data) = $self->get('24');
	return $status	unless($status=~/ok/);
	print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
	return "[$self->{addr}] $year-$mons-$mday $hour:$min:$sec [".(($data[5] eq '00')? 'none':'auto')."] weekday: $dow";
}
sub set_time {
	my $self = shift;
	my ($ye,$mon,$md,$wd,$hh,$mm,$ss) = @_;
	my $cmd = '02';
	my $Y;
	if($ye =~ /(\d\d)$/) { $Y = $1; }
	my ($status,$cnt,@data) = $self->get("$cmd $wd $hh $mm $ss $md $mon $Y");
	return $status;
}
sub get_time_flag {
	my $self = shift;
	my ($status,$cnt,@data) = $self->get('24');
	return $status	unless($status=~/ok/);
	print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
	return "[$self->{addr}] Flag: [".(($data[5] eq '00')? 'none':'auto')."]";
}
sub set_time_flag {
	my $self = shift;
	my $flag = shift;
	$flag = sprintf("%02X", $flag);	# автоматический переход на летнее время
	my $cmd = '05';
	my ($status,$cnt,@data) = $self->get("$cmd $flag");
	return $status;
}

#
# Текущие данные счетчика
sub get_data {
	my $self = shift;

	my $Data;
	my ($status,$cnt,@data);

	#
	# Накопленная энергия
	#
	print "Stored energy ########################\n"	if $self->{verb};
	($status,$cnt,@data) = $self->get('27');
	return $status	unless($status=~/ok/);
	print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};

	my @a;
	foreach my $i (5,9) {
		my $num = join("",$data[0+$i],$data[1+$i],$data[2+$i],$data[3+$i]);
		push @{$Data->{se}}, $num/100;
	}
	print "se [27h]: ".join(' ',@{$Data->{se}})."\n"	if $self->{verb};

	#
	# Текущие параметры
	#
	print "Monitoring ########################\n"	if $self->{verb};
	# мощность
	($status,$cnt,@data) = $self->get('26');
	return $status	unless($status=~/ok/);
	print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
	push @{$Data->{mp}}, join("",$data[5],$data[6])*10;
	print "mp [26h]: ".join(' ',@{$Data->{mp}})."\n"	if $self->{verb};

	# частота
	($status,$cnt,@data) = $self->get('81');
	return $status	unless($status=~/ok/);
	print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
	push @{$Data->{mf}}, join("",$data[5],$data[6])/100;
	print "mf [81h]: ".join(' ',@{$Data->{mf}})."\n"	if $self->{verb};

	# напряжение, ток, мощность (1 сек)
	($status,$cnt,@data) = $self->get('63');
	return $status	unless($status=~/ok/);
	print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
	push @{$Data->{mv}}, join("",$data[5],$data[6])/10;
	print "mv [63h]: ".join(' ',@{$Data->{mv}})."\n"	if $self->{verb};
	push @{$Data->{mc}}, join("",$data[7],$data[8])/100;
	print "mv [63h]: ".join(' ',@{$Data->{mc}})."\n"	if $self->{verb};
	push @{$Data->{ms}}, join("",$data[9],$data[10],$data[11])*1;
	print "ms [63h]: ".join(' ',@{$Data->{ms}})."\n"	if $self->{verb};

	return $Data;
}

# Состояние встроенного реле
sub get_switch {
	my $self = shift;
	my ($status,$cnt,@data) = $self->get('6d');
	return $status	unless($status=~/ok/);
	print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
	my $RELE = $data[5];
	if($RELE =~ /55/) {
		$status = "[$RELE] limit";
	} elsif($RELE =~ /aa/i) {
		$status = "[$RELE] off";
	} else {
		$status = "[$RELE] on";
	}
	return "[$self->{addr}] Switch: $status";
}
# Управление встроенным реле <<<Not Tested!!!>>>
sub set_switch {
	my $self = shift;
	my $cmd = shift;
	my ($status,$cnt,@data) = $self->get("71 $cmd");
	return "[$status][$cnt][".join(' ',@data)."]"	if $self->{verb};
}

# Тарифное расписание
sub get_tar {
	my $self = shift;
	my $i = shift;
	#($status,$cnt,@data)
	return $self->get("31 $i");
}
sub set_tar {
	my $self = shift;
	my $cs = shift;
	#($status,$cnt,@data)
	return $self->get("11 $cs");
}



################ local subs
sub _send {
	my $self = shift;
	my (@str) = @_;
	my $hstr = $self->{addr}." ".join(' ',@str);
	my @a = split / /, $hstr;
	$hstr = '';
	foreach my $i (@a) { $hstr .= sprintf "%02x", hex($i); }
	my $data = pack ("H*", $hstr);
	$self->{ctx}->reset;
	$self->{ctx}->add($data);
	my $crc16 = $self->{ctx}->digest;
	$data .= chr($crc16 & 0xff);
	$data .= chr(($crc16 >> 8) & 0xff);
	$self->{port}->write($data);
}

sub _recv {
        my $self = shift;
	my $timeout = $self->{timeout};
	$self->{port}->read_char_time(0);     # don't wait for each character
	$self->{port}->read_const_time(200); # 0,15 second per unfulfilled "read" call
	my $status='ok';
	my $chars=0;
	my @data;
	my $buffer="";
	my ($count,$saw);
	while ($timeout>0) {
		($count,$saw)=$self->{port}->read($MAXLENGTH); # will read _up to_ $MAXLENGTH chars
		if ($count) {
			$chars+=$count;
			$buffer.=$saw;
			@data = map {/(..)/gm} unpack("H*",$buffer);
			last;
		}
		else {
			$timeout--;
		}
	}
	if ($timeout==0) {
		$status = 0;	# Waited $STALL_DEFAULT seconds and never saw what I wanted
	}
	$status = $self->iscrc(@data)	if(@data);
	return($status,$count,@data);
}

1;

