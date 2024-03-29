package Mercury230;
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
# Mercury-230 support module
# 2017-02-04 alid
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
	die "Mercury230: Locked"	if($self->{lock}->set);
	$self->{port} = Device::SerialPort->new($device,0);
	$self->{ctx} = Digest::CRC->new(width=>16, init=>0xffff, xorout=>0x0000, poly=>0x8005, refin=>1, refout=>1, cont=>0);
	$self->{saddr} = $addr;
	$self->{addr} =	sprintf("%x",$addr);	# HEX!
	$self->{pass} = sprintf("%x %x %x %x %x %x", split("",$pass,6));	# $pass;
	$self->{pass2} = sprintf("%x %x %x %x %x %x", split("",$pass2,6)) if($pass2);	# pass2;
	$self->{timeout} = $STALL_DEFAULT * 10;
	$self->{verb} = $verb || 0;
	$self->{retries} = $retries || 1;
	bless $self,$class;
	$self->init();
	die "Cant connect: $addr $device"	unless($self->{port});
	return $self;
}

sub init {
	my $self = shift;
	$self->{tstcmd} = '0';
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
		unless(hex($cnt)==4 && hex($data[0])==hex($self->{addr}) && hex($data[1])==0) {
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
sub sopen {
	my $self = shift;
	my $level = shift || 1;
	my $cmd = 1;
	my $i = $self->{retries};
	my $res;
	my $pass = $level eq '2' ? $self->{pass2} : $self->{pass};
	do {
		$self->_send($cmd,$level,$pass);
		$res = $self->isok();
		return $res	if($res =~ /ok/);
		$i--;
	} while($i);
	return $res;
}

# Закрытие сессии
sub sclose {
	my $self = shift;
	my $cmd = 2;
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

# Counter's Clock
#сек, мин, час, день, число, месяц, год, зима(1)/лето(0)
sub get_time {
	my $self = shift;
	my $cmd = '04 00';
	my $status = $self->sopen(1);
	return $status	unless($status=~/ok/);
	$self->_send($cmd);
	my ($cnt,@data);
	($status,$cnt,@data) = $self->_recv();
	return $status	unless($status=~/ok/);
	return "[$self->{saddr}] 20".$data[7]."-".$data[6]."-".$data[5]." ".$data[4]." ".$data[3].":".$data[2].":".$data[1]." ".(($data[8] eq '00')?'summer':'winter');
}
sub adj_time {
	my $self = shift;
	my ($hh,$mm,$ss) = (@_);
	my $cmd = '03 0D';
	my $status = $self->sopen(1);
	return $status	unless($status=~/ok/);
	$self->_send("$cmd $ss $mm $hh");
	return $self->isok();
	print "$status\n"	if $self->{verb};
}
sub set_time {
	my $self = shift;
	my ($ye,$mon,$md,$wd,$hh,$mm,$ss) = @_;
	my $cmd = '03 0C';
	my $status = $self->sopen(2);
	return $status	unless($status=~/ok/);
	$self->_send("$cmd $ss $mm $hh $wd $md $mon $ye 0");
	return $self->isok();
}
sub get_time_flag {
	my $self = shift;
	my $cmd = '08 09';
	my $status = $self->sopen(2);
	return $status	unless($status=~/ok/);
	$self->_send($cmd);
	my ($cnt,@data);
	($status,$cnt,@data) = $self->_recv();
	return $status	unless($status=~/ok/);
	return "[$self->{saddr}] ".(($data[2] & 0x8)? "0":"1");
}
sub set_time_flag {
	my $self = shift;
	my $flag = shift;
	my $cmd = '03 18';
	my $status = $self->sopen(2);
	return $status	unless($status=~/ok/);
	$self->_send("$cmd $flag");
	return $self->isok();
}

#
# Текущие данные счетчика
sub get_data {
	my $self = shift;

	my $Data;
	my ($status,$cnt,@data);
	$status = $self->sopen(1);
	return $status	unless($status=~/ok/);

	my %types = (
		addr => 'Device netaddr',
		se1	=>	'Stored energy T1',
		se2	=>	'Stored energy T2',
		#	se3	=>	'Stored energy T3',
		#	se4	=>	'Stored energy T4',
		#	seS	=>	'Stored energy Sum',
		#	seL	=>	'Stored energy Leak',
		mv	=>	'Voltage',
		mc	=>	'Currents',	
		ma	=>	'Phase angls',
		mf	=>	'Frequency',
		mp	=>	'Power P',	# мощность P (?)
		mq	=>	'Power Q',	# мощность Q
		ms	=>	'Power S',	# мощность S
		mk	=>	'K-power',	# коэффициент мощности
	);

	#
	# Накопленная энергия
	#
	print "Stored energy ########################\n"	if $self->{verb};
	my $ts;	# команда
	my %ts = (
		se1 => '05 00 01',
		se2 => '05 00 02',
		se3 => '05 00 03',
		se4 => '05 00 04',
		seS => '05 00 00',
		seL => '05 00 05',
	);
	foreach my $type (keys %ts) {
		if(exists $types{$type}) {
			$ts = $ts{$type};
			($status,$cnt,@data) = $self->get($ts);
			return $status	unless($status=~/ok/);
			print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
			@{$Data->{$type}} = $self->_decimal4(@data);
			print $types{$type}." [$type]: ".join(' ',@{$Data->{$type}})."\n"	if $self->{verb};
		}
	}

	#
	# Текущие параметры
	#
	print "Monitoring ########################\n"	if $self->{verb};
	%ts = (
		mv => '08 16 11',	# напряжения
		mc => '08 16 21',	# токи
		ma => '08 16 51',	# углы между фазами
	);
	# три числа по три байта
	foreach my $type (keys %ts) {
		if(exists $types{$type}) {
			$ts = $ts{$type};
			($status,$cnt,@data) = $self->get($ts);
			return $status	unless($status=~/ok/);
			print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
			@{$Data->{$type}} = $self->_decimal3(@data);
			print $types{$type}." [$type]: ".join(' ',@{$Data->{$type}})."\n"	if $self->{verb};
		}
	}
	map {$_ = $_/10} @{$Data->{mc}};	# ток

	%ts = (
		mp => '08 16 00',	# мощность P (?)
		mq => '08 16 04',	# мощность Q
		ms => '08 16 08',	# мощность S
		mk => '08 16 30',	# коэффициент мощности
	);
	# четыре числа по три байта
	foreach my $type (keys %ts) {
		if(exists $types{$type}) {
			$ts = $ts{$type};
			($status,$cnt,@data) = $self->get($ts);
			return $status	unless($status=~/ok/);
			print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
			@{$Data->{$type}} = $self->_decimal43(@data);
			print $types{$type}." [$type]: ".join(' ',@{$Data->{$type}})."\n"	if $self->{verb};
		}
	}
	map {$_ = $_/10; $_=1 if($_>1);} @{$Data->{mk}};	# коэффициент мощности

	%ts = (
		mf => '08 16 40',	# частота
	);
	# одно число три байта
	foreach my $type (keys %ts) {
		if(exists $types{$type}) {
			$ts = $ts{$type};
			($status,$cnt,@data) = $self->get($ts);
			return $status	unless($status=~/ok/);
			print "[$status][$cnt][".join(' ',@data)."]\n"	if $self->{verb};
			@{$Data->{$type}} = $self->_decimal1(@data);
			print $types{$type}." [$type]: ".join(' ',@{$Data->{$type}})."\n"	if $self->{verb};
		}
	}
	return $Data;
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

#############################################################################
# data unpacking
#
sub _decimal4 {	# 4 четырехбайтовых числа в строке
	my $self = shift;
	my (@data) = @_;
	# контрольная сумма и байт адреса
	pop @data; pop @data; shift @data;
	my @a;
	foreach my $i (0,4,8,12) {
		my $num = hex(join("",$data[1+$i],$data[0+$i],$data[3+$i],$data[2+$i]));
		push @a, (($num == 4294967295)?'null':$num/1000);
	}
	return @a;
}

sub _decimal3 {	# 3 трехбайтных числа в строке
	my $self = shift;
	my (@data) = @_;
	# контрольная сумма и байт адреса
	pop @data; pop @data; shift @data;
	my @a;
	foreach my $i (0,3,6) {
		my $num = hex(join("",sprintf("%02X",(hex($data[0+$i]) & hex("3F"))),$data[2+$i],$data[1+$i]));
		push @a, (($num == 4194303)?'null':$num/100);
	}
	return @a;
}

sub _decimal1 {	# 1 трехбайтное число в строке
	my $self = shift;
	my (@data) = @_;
	# контрольная сумма и байт адреса
	pop @data; pop @data; shift @data;
	my @a;
	foreach my $i (0) {
		my $num = hex(join("",sprintf("%02X",(hex($data[0+$i]) & hex("3F"))),$data[2+$i],$data[1+$i]));
		push @a, (($num == 4194303)?'null':$num/100);
	}
	return @a;
}

sub _decimal43 {	# 4 трехбайтных числа в строке
	my $self = shift;
	my (@data) = @_;
	# контрольная сумма и байт адреса
	pop @data; pop @data; shift @data;
	my @a;
	foreach my $i (0,3,6,9) {
		my $num = hex(join("",sprintf("%02X",(hex($data[0+$i]) & hex("3F"))),$data[2+$i],$data[1+$i]));
		push @a, (($num == 4194303)?'null':$num/100);
	}
	return @a;
}

1;

