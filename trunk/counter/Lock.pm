#
#       Copyright (C) 2008-2012 ��������� ��������, "��̣��� �����"
#
#       ����������� ��������� ��������������� � ������������� ��� � ���� ���������
#       ����, ��� � � �������� �����, � ����������� ��� ���, ��� ���������� ���������
#       �������:
#
#       * ��� ��������� ��������������� ��������� ���� ������ ���������� ���������
#         ���� ����������� �� ��������� �����, ���� ������ ������� � �����������
#         ����� �� ��������.
#       * ��� ��������� ��������������� ��������� ���� ������ ����������� ���������
#         ���� ���������� �� ��������� �����, ���� ������ ������� � ����������� �����
#         �� �������� � ������������ �/��� � ������ ����������, ������������ ���
#         ���������������.
#       * �� �������� "��̣��� �����", �� ����� �� ����������� �� ����� ����
#         ������������ � �������� ��������� ��� ����������� ���������, ����������
#         �� ���� �� ��� ���������������� ����������� ����������.
#
#       ��� ��������� ������������� ����������� ��������� ���� �/��� ������� ���������
#	"��� ��� ����" ��� ������-���� ���� ��������, ���������� ���� ��� ���������������,
#	�������, �� �� ������������� ���, ��������������� �������� ������������ ��������
#	� ����������� ��� ���������� ����. �� � ���� ������, ���� �� ���������
#	��������������� �������, ��� �� ����������� � ������ �����, �� ���� ��������
#	��������� ���� � �� ���� ������ ����, ������� ����� �������� �/��� ��������
#	�������������� ���������, ��� ���� ������� ����, �� ���� ���������������,
#	������� ����� �����, ���������, ����������� ��� ������������� ������,
#	���������� ������������� ��� ������������� ������������� ��������� (�������,
#	�� �� ������������� ������� ������, ��� �������, �������� �������������, ���
#	�������� ������������ ��-�� ��� ��� ������� ���, ��� ������� ��������� ��������
#	��������� � ������� �����������), ���� ���� ����� �������� ��� ������ ���� ����
#	�������� � ����������� ����� �������.
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
# ����������
# 2011-02-11 alid
#

sub new {
	my $class = shift;
	my ($file,$nowait)=@_;
	die unless defined $file;
	my $self={};
	$self->{_file} = $file;
	$self->{_nowait} = $nowait;
	$self->{timeout} = 10;
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
		return($pid)	if $pid && kill(0, $pid);	# ������� ��� �����
	}
	# ������ ���� ����������
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
