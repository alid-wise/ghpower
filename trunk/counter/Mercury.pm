package Mercury;
use strict;
use vars qw($VERSION);

$VERSION="1.0";

#
#       Copyright (C) 2008-2012 áÌÅËÓÁÎÄÒ äÅ×ÑÔËÉÎ, "úÅÌ£ÎÁÑ ÇÏÒËÁ"
#
#       òÁÚÒÅÛÁÅÔÓÑ ĞÏ×ÔÏÒÎÏÅ ÒÁÓĞÒÏÓÔÒÁÎÅÎÉÅ É ÉÓĞÏÌØÚÏ×ÁÎÉÅ ËÁË × ×ÉÄÅ ÉÓÈÏÄÎÏÇÏ
#       ËÏÄÁ, ÔÁË É × Ä×ÏÉŞÎÏÊ ÆÏÒÍÅ, Ó ÉÚÍÅÎÅÎÉÑÍÉ ÉÌÉ ÂÅÚ, ĞÒÉ ÓÏÂÌÀÄÅÎÉÉ ÓÌÅÄÕÀİÉÈ
#       ÕÓÌÏ×ÉÊ:
#
#       * ğÒÉ ĞÏ×ÔÏÒÎÏÍ ÒÁÓĞÒÏÓÔÒÁÎÅÎÉÉ ÉÓÈÏÄÎÏÇÏ ËÏÄÁ ÄÏÌÖÎÏ ÏÓÔÁ×ÁÔØÓÑ ÕËÁÚÁÎÎÏÅ
#         ×ÙÛÅ Õ×ÅÄÏÍÌÅÎÉÅ ÏÂ Á×ÔÏÒÓËÏÍ ĞÒÁ×Å, ÜÔÏÔ ÓĞÉÓÏË ÕÓÌÏ×ÉÊ É ĞÏÓÌÅÄÕÀİÉÊ
#         ÏÔËÁÚ ÏÔ ÇÁÒÁÎÔÉÊ.
#       * ğÒÉ ĞÏ×ÔÏÒÎÏÍ ÒÁÓĞÒÏÓÔÒÁÎÅÎÉÉ Ä×ÏÉŞÎÏÇÏ ËÏÄÁ ÄÏÌÖÎÁ ÓÏÈÒÁÎÑÔØÓÑ ÕËÁÚÁÎÎÁÑ
#         ×ÙÛÅ ÉÎÆÏÒÍÁÃÉÑ ÏÂ Á×ÔÏÒÓËÏÍ ĞÒÁ×Å, ÜÔÏÔ ÓĞÉÓÏË ÕÓÌÏ×ÉÊ É ĞÏÓÌÅÄÕÀİÉÊ ÏÔËÁÚ
#         ÏÔ ÇÁÒÁÎÔÉÊ × ÄÏËÕÍÅÎÔÁÃÉÉ É/ÉÌÉ × ÄÒÕÇÉÈ ÍÁÔÅÒÉÁÌÁÈ, ĞÏÓÔÁ×ÌÑÅÍÙÈ ĞÒÉ
#         ÒÁÓĞÒÏÓÔÒÁÎÅÎÉÉ.
#       * îÉ ÎÁÚ×ÁÎÉÅ "úÅÌ£ÎÁÑ ÇÏÒËÁ", ÎÉ ÉÍÅÎÁ ÅÅ ÓÏÔÒÕÄÎÉËÏ× ÎÅ ÍÏÇÕÔ ÂÙÔØ
#         ÉÓĞÏÌØÚÏ×ÁÎÙ × ËÁŞÅÓÔ×Å ĞÏÄÄÅÒÖËÉ ÉÌÉ ĞÒÏÄ×ÉÖÅÎÉÑ ĞÒÏÄÕËÔÏ×, ÏÓÎÏ×ÁÎÎÙÈ
#         ÎÁ ÜÔÏÍ ğï ÂÅÚ ĞÒÅÄ×ÁÒÉÔÅÌØÎÏÇÏ ĞÉÓØÍÅÎÎÏÇÏ ÒÁÚÒÅÛÅÎÉÑ.
#
#       üôá ğòïçòáííá ğòåäïóôá÷ìåîá ÷ìáäåìøãáíé á÷ôïòóëéè ğòá÷ é/éìé äòõçéíé óôïòïîáíé
#	"ëáë ïîá åóôø" âåú ëáëïçï-ìéâï ÷éäá çáòáîôéê, ÷ùòáöåîîùè ñ÷îï éìé ğïäòáúõíå÷áåíùè,
#	÷ëìàşáñ, îï îå ïçòáîéşé÷áñóø éíé, ğïäòáúõíå÷áåíùå çáòáîôéé ëïííåòşåóëïê ãåîîïóôé
#	é ğòéçïäîïóôé äìñ ëïîëòåôîïê ãåìé. îé ÷ ëïåí óìõşáå, åóìé îå ôòåâõåôóñ
#	óïïô÷åôóô÷õàıéí úáëïîïí, éìé îå õóôáîï÷ìåîï ÷ õóôîïê æïòíå, îé ïäéî ÷ìáäåìåã
#	á÷ôïòóëéè ğòá÷ é îé ïäîï äòõçïå ìéãï, ëïôïòïå íïöåô éúíåîñôø é/éìé ğï÷ôïòîï
#	òáóğòïóôòáîñôø ğòïçòáííõ, ëáë âùìï óëáúáîï ÷ùûå, îå îåó³ô ïô÷åôóô÷åîîïóôé,
#	÷ëìàşáñ ìàâùå ïâıéå, óìõşáêîùå, óğåãéáìøîùå éìé ğïóìåäï÷á÷ûéå õâùôëé,
#	÷óìåäóô÷éå éóğïìøúï÷áîéñ éìé îå÷ïúíïöîïóôé éóğïìøúï÷áîéñ ğòïçòáííù (÷ëìàşáñ,
#	îï îå ïçòáîéşé÷áñóø ğïôåòåê äáîîùè, éìé äáîîùíé, óôá÷ûéíé îåğòá÷éìøîùíé, éìé
#	ğïôåòñíé ğòéîåóåîîùíé éú-úá ÷áó éìé ôòåôøéè ìéã, éìé ïôëáúïí ğòïçòáííù òáâïôáôø
#	óï÷íåóôîï ó äòõçéíé ğòïçòáííáíé), äáöå åóìé ôáëïê ÷ìáäåìåã éìé äòõçïå ìéãï âùìé
#	éú÷åıåîù ï ÷ïúíïöîïóôé ôáëéè õâùôëï÷.
#

#       Copyright (C) 2008-2012 Aleksandr Deviatkin, "Green Hill"
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
# Mercury support module
# 2011-08-01 alid
#

use Device::SerialPort;
use Digest::CRC;
use Lock;

my $MAXLENGTH = 255;	# ÎÁÉÂÏÌØÛÁÑ ÄÌÉÎÁ ĞÁËÅÔÁ
my $STALL_DEFAULT = 2; # how many seconds to wait for new input


sub new {
        my $class = shift;
        my ($device,$mercury_type,$addr,$pass,$level,$retries,$verb)=@_;
        my $self={};
	$self->{maxlength} = $MAXLENGTH;
	$self->{device} = $device;
	my $lockfile = $device;
	$lockfile =~ s(/)(_)g;
	$self->{lock} = Lock->new("/tmp/".$lockfile.".PM");
	die "Mercury: Locked"	if($self->{lock}->set);
#	$self->{port} = Device::SerialPort->new($device,0,"/tmp/".$lockfile.".PM");
	$self->{port} = Device::SerialPort->new($device,0);
        $self->{ctx} = Digest::CRC->new(width=>16, init=>0xffff, xorout=>0x0000, poly=>0x8005, refin=>1, refout=>1, cont=>0);
	$self->{model} = $mercury_type;
	$self->{addr} = $addr;
	$self->{pass} = $pass;
	$self->{level} = $level || 1;
	$self->{timeout} = $STALL_DEFAULT * 10;
        $self->{_verb} = $verb || 0;
	$self->{retries} = $retries || 1;
	bless $self,$class;
        $self->init();
        return $self;
}

sub init {
        my $self = shift;
	$self->{tstcmd} = '0';
	if($self->{model} =~ /M230/i) {
		$self->{tstcmd} = '0';
	}
	elsif($self->{model} =~ /M203/i) {
		$self->{tstcmd} = '2f';
	}
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
		if($self->{model} =~ /M230/i) {
			unless(hex($cnt)==4 && hex($data[0])==hex($self->{addr}) && hex($data[1])==0) {
				$status = 'fail';
			}
		}
		elsif($self->{model} =~ /M203/i) {
			unless($cnt eq '11' && $data[4] eq '2f') {
				$status = 'fail';
			}
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

# ĞÒÏ×ÅÒËÁ Ó×ÑÚÉ
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

# ïÔËÒÙÔÉÅ ÓÅÓÓÉÉ
sub sopen {
	my $self = shift;
	my $cmd = 1;
	my $i = $self->{retries};
	my $res;
	do {
		$self->_send($cmd,$self->{level},$self->{pass});
		$res = $self->isok();
		return $res	if($res =~ /ok/);
		$i--;
	} while($i);
	return $res;
}

# úÁËÒÙÔÉÅ ÓÅÓÓÉÉ
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

