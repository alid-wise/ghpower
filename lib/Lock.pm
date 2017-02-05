#
#       Copyright (C) 2008-2012 Александр Девяткин, "Зелёная горка"
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

package Lock;
use strict;
use vars qw($VERSION);
use Fcntl qw (:DEFAULT :flock);

$VERSION="1.0";

#
# Блокировка
# 2011-02-11 alid
#

sub new {
	my $class = shift;
	my ($file,$nowait,$timeout)=@_;
	die unless defined $file;
	my $self={};
	$self->{_file} = $file;
	$self->{_nowait} = $nowait;
	$self->{timeout} = $timeout || 10;
	bless $self,$class;
	return $self;
}

sub set {
	my $self=shift;
	my $pid;
	return $self->_set()	if($self->{_nowait});
	eval{
		$SIG{ALRM} = sub { die "timeout"; };
		alarm($self->{timeout});
		do { $pid=$self->_set(); }while($pid); 
		alarm(0);
	};
	return $pid	if($pid);
	return 0;
}

sub _set {
	my $self=shift;
	if(open LCK, $self->{_file}){
		my $pid = <LCK>;
		close LCK;
		return($pid)	if $pid && kill(0, $pid);	# Процесс еще живой
	}
	# Ставим свою блокировку
	sysopen(LCK, $self->{_file}, O_RDWR|O_CREAT)	or die "Can't open $self->{_file}: $!";
	flock(LCK, LOCK_EX|LOCK_NB)		or die "Can't lock $self->{_file}: $!";
	seek(LCK, 0, 0)				or die "Can't rewind $self->{_file}: $!";
	truncate(LCK, 0)				or die "Can't truncate $self->{_file}: $!";
	print LCK "$$";
	close(LCK)				or die "Can't close $self->{_file}: $!";
	system("chmod 664 $self->{_file}");
	return 0;
}
sub clear {
	my $self=shift;
	my $pid;
	open(LCK, $self->{_file})	or return undef;
	if(flock(LCK, 1|4)){
		$pid = <LCK>;
	}
	close LCK;
	if($pid && $pid eq $$){
		return unlink $self->{_file};
	}
	return undef;
}
sub get {
	my $self=shift;
	if(open LCK, $self->{_file}){
		my $pid = <LCK>;
		close LCK;
		return($pid)	if $pid && kill(0, $pid);
	}
	return 0;
}

1;
