package M225;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $CMD);

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw( 	cmds );

use Inline C;
use strict;

$VERSION="1.0";

################################################# commands
my $CMD = {
	'GET_ENERGY' => {
				'01' => '40 27',
				'02' => '00 00',
			},
	'GET_POWER' =>	{
				'01' => '40 26',
				'02' => '00 00',
			},
	'GET_TIMEDATE' => {
				'01' => '40 21',
				'02' => '00 00',
			},
};

###########################################################
sub new {
	my $class = shift;
	my ($device, $debug)= @_;
	die unless defined $device;
	my $self={};
	$self->{_dev} = $device;
	$self->{_debug} = $debug;
	bless $self,$class;
	$self->init($device);
	return $self;
}

sub init {
	my $self = shift;
	die unless defined $self->{_dev};
	$self->{_so}  = init_port($self->{_dev})	or die;
}

sub close {
	my $self = shift;
	close_port($self->{_so});
}

sub sendheader {
	my $self = shift;
	my $str = shift;
	return _sendheader($str, $self->{_so});
}

sub sendbody {
	my $self = shift;
	my $str = shift;
	return _sendbody($str, $self->{_so});
}

sub getheader {
	my $self = shift;
	return _getheader($self->{_so});
}

sub getbody {
	my $self = shift;
	my $str = shift;
	return _getbody($str, $self->{_so});
}

# проверяем доступность концентратора
sub get_addr {
	my $self = shift;
	my $saddr = shift;
	print "Connection attempt to $saddr\n"	if($self->{_debug});
	my $res = $self->sendheader("FF FF ".saddr($saddr)." 01 ");
	print "sendheader res: $res\n"	if($self->{_debug});
	$res = $self->sendbody("86 ");
	print "sendbody res: $res\n"	if($self->{_debug});
	my (@res) = split(":", $self->getheader());
	print join(" ",@res)."\n"	if($self->{_debug});
	(@res) = split(":", $self->getbody(hex($res[9])));
	print join(" ",@res)."\n"	if($self->{_debug});
	return join("",$res[4],$res[3]);
}

# чтение байта конфигурации концентратора
sub get_config {
	my $self = shift;
	my $saddr = shift;
	print "get_config from $saddr\n"	if($self->{_debug});
	$self->sendheader("FF FF ".saddr($saddr)." 01 ");
	$self->sendbody("80 ");
	my (@res) = split(":", $self->getheader());
	print join(" ",@res)."\n"	if($self->{_debug});
	(@res) = split(":", $self->getbody(hex($res[9])));
	print "get_config: ".join(" ",@res)."\n"	if($self->{_debug});
	return $res[3];
}

# запись байта конфигурации концентратора
sub set_config {
	my $self = shift;
	my $saddr = shift;
	my $sconf = shift;
	print "set_config for $saddr\n"	if($self->{_debug});
	$self->sendheader("FF FF ".saddr($saddr)." 02 ");
	$self->sendbody("00 $sconf ");
	my (@res) = split(":", $self->getheader());
	print join(" ",@res)."\n"	if($self->{_debug});
	(@res) = split(":", $self->getbody(hex($res[9])));
	print "set_config: ".join(" ",@res)."\n"	if($self->{_debug});
	return(($sconf eq $res[3])? 0:-1);
}

## Очистка регистров управления подчиненными узлами
sub set_clr_all_seg {
	my $self = shift;
	my $saddr = shift;
	print "set_clr_all_seg for $saddr\n"	if($self->{_debug});
	$self->sendheader("FF FF ".saddr($saddr)." 01 ");
	$self->sendbody("1D ");
	my (@res) = split(":", $self->getheader());
	print join(" ",@res)."\n"	if($self->{_debug});
	(@res) = split(":", $self->getbody(hex($res[9])));
	print "set_clr_all_seg: ".join(" ",@res)."\n"	if($self->{_debug});
	return(('1D' eq $res[2])? 0:-1);
}

# список почтовых ящиков концентратора (список счетчиков)
sub getlist {
	my $self = shift;
	my $saddr = shift;

	my $maxpages = 256;
	my %list;
	print "getlist: Building address list for $saddr\n"	if($self->{_debug});
	for(my $page = 0; $page<$maxpages; $page++) {
		my $pageno = sprintf("%02X", $page);
		my $res = $self->sendheader("FF FF ".saddr($saddr)." 02 ");
		#print "res: $res\n";
		last	if($res<0);
		$res = $self->sendbody("90 $pageno ");
		#print "res: $res\n";
		last	if($res<0);
		my (@res) = split(":", $self->getheader());
		#print join(" ",@res)."\n";
		last	if($res[0]<0);
		(@res) = split(":", $self->getbody(hex($res[9])));
		#print join(" ",@res)."\n";
		last	if($res[0]<0);
		shift @res;
		shift @res;
		shift @res;
		shift @res;
		my $i = 0;
		while(@res) {
			$i = 0;
			my @r;
			push @r, shift @res;
			push @r, shift @res;
			push @r, shift @res;
			push @r, shift @res;
			last	unless(defined $r[0] && defined $r[1] && defined $r[2] && defined $r[3]);
			$i++;
			my $da = $r[3].$r[2].$r[1].$r[0];
			print "getlist: Found [$da] "	if($self->{_debug});
			# Регистры модема подчиненного устройства 
			my (@rsl) = $self->get_mod_config($saddr, $da);
			if($rsl[0] eq 0) {	#  Выясняем, что за устройство
				my $VER = $rsl[7];	# VER - прошивка модема
				my $HP = $rsl[8];	# HP - номер протокола (2 - hpM230 1 - hpM203)
				my $BCNF = $rsl[9];	# BCNF
				print "Modem VER: $VER HP: $HP BCNF: $BCNF ".($HP eq 2 ? "hpM230":"hpM203")."\n"	if($self->{_debug});
				$list{$da} = $HP;
			} else {
				print "Unknown device\n"	if($self->{_debug});
				$list{$da} = -1;
			}
		}
		last	unless $i;
	}
	return %list;
}

## Чтение регистра модема конфигурации подчиненного узла
sub get_mod_config {
	my $self = shift;
	my $saddr = shift;
	my $addr = shift;

	my $res = $self->sendheader("FF FF ".saddr($saddr)." 05 ");
	#print "res: $res\n";
	$res = $self->sendbody("97 ".saddr($addr)." ");
	#print "res: $res\n";
	my (@res) = split(":", $self->getheader());
	#print join(" ",@res)."\n";
	(@res) = split(":", $self->getbody(hex($res[9])));
	#print join(" ",@res)."\n";
	return @res;
}

# Запись команды в регистр запроса
sub set_seg_req {
	my $self = shift;
	my $saddr = shift;
	my $addr = shift;
	my $segm = shift;
	my $hp = shift;
	my $cmd = shift;

	my $req = cmds($cmd,$hp);
	my $segms = sprintf("%02X",$segm);
	my (@a) = split(" ", $req);
	my $len = (scalar @a) + 6;
	$len = sprintf("%02X", $len);	
	#print "Len: [$len]\n";

	my $res = $self->sendheader("FF FF ".saddr($saddr)." $len ");
	#print "res: $res\n";
	$res = $self->sendbody("1B ".saddr($addr)." $segms $req ");
	#print "res: $res\n";
	my (@res) = split(":", $self->getheader());
	print "set_seg_req: ".join(" ",@res)."\n"	if($self->{_debug});
	(@res) = split(":", $self->getbody(hex($res[9])));
	print "set_seg_req: ".join(" ",@res)."\n"	if($self->{_debug});
	return @res;
}

## Чтение регистров статуса почтового ящика
sub get_seg_status {
	my $self = shift;
	my $saddr = shift;
	my $addr = shift;
	my $segm = shift;

	my $segms = sprintf("%02X",$segm);
	my $res = $self->sendheader("FF FF ".saddr($saddr)." 06 ");
	#print "res: $res\n";
	$res = $self->sendbody("9A ".saddr($addr)." $segms ");
	#print "res: $res\n";
	my (@res) = split(":", $self->getheader());
	#print join(" ",@res)."\n";
	(@res) = split(":", $self->getbody(hex($res[9])));
	print "get_seg_status: ".join(" ", @res)."\n"	if($self->{_debug});
	return @res;
}
# Управление флагом TRANS_TYPE
sub set_seg_status {
	my $self = shift;
	my $saddr = shift;
	my $addr = shift;
	my $segm = shift;
	my $ttype = shift;

	my $segms = sprintf("%02X",$segm);
	my $ttf = $ttype ? "20":"00";
	my $res = $self->sendheader("FF FF ".saddr($saddr)." 07 ");
	#print "res: $res\n";
	$res = $self->sendbody("1A ".saddr($addr)." $segms $ttf ");
	#print "res: $res\n";
	my (@res) = split(":", $self->getheader());
	#print join(" ",@res)."\n";
	(@res) = split(":", $self->getbody(hex($res[9])));
	print "set_seg_status: ".join(" ",@res)."\n"	if($self->{_debug});
	return @res;
}

## Чтение регистра запроса почтового ящика
sub get_seg_req {
	my $self = shift;
	my $saddr = shift;
	my $addr = shift;
	my $segm = shift;

	my $segms = sprintf("%02X",$segm);
	my $res = $self->sendheader("FF FF ".saddr($saddr)." 06 ");
	#print "res: $res\n";
	$res = $self->sendbody("9B ".saddr($addr)." $segms ");
	#print "res: $res\n";
	my (@res) = split(":", $self->getheader());
	#print join(" ",@res)."\n";
	(@res) = split(":", $self->getbody(hex($res[9])));
	print "get_seg_req: ".join(" ", @res)."\n"	if($self->{_debug});
	return @res;
}

## Чтение регистра ответа почтового ящика
sub get_seg_ans {
	my $self = shift;
	my $saddr = shift;
	my $addr = shift;
	my $segm = shift;

	my $segms = sprintf("%02X",$segm);
	my $res = $self->sendheader("FF FF ".saddr($saddr)." 06 ");
	#print "res: $res\n";
	$res = $self->sendbody("9C ".saddr($addr)." $segms ");
	#print "res: $res\n";
	my (@res) = split(":", $self->getheader());
	#print join(" ",@res)."\n";
	(@res) = split(":", $self->getbody(hex($res[9])));
	print "get_seg_ans: ".join(" ", @res)."\n"	if($self->{_debug});
	return @res;
}



################################################# subroutines
sub saddr {
	my ($addr) = @_;
	my @data = map {/(..)/gm} $addr;
	return join(" ", reverse @data);
}
sub cmds {
	my ($cmd,$hp) = @_;
	return $CMD->{$cmd}->{$hp};
}
1;

__DATA__
__C__

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>

#include <unistd.h>  /* UNIX standard function definitions */
#include <fcntl.h>   /* File control definitions */
#include <errno.h>   /* Error number definitions */
#include <termios.h> /* POSIX terminal control definitions */

#define	MAXLENGTH	265	// наибольшая длина пакета
#define	HEADERLENGTH	8	// длина заголовка

/*===================================================================*/
#define CRC24_INIT 0x00b704ceL
#define CRC24_POLY 0x01864cfbL

const unsigned long CRC24tab[256] ={
0x00000000, 0x00864CFB, 0x008AD50D, 0x000C99F6,
0x0093E6E1, 0x0015AA1A, 0x001933EC, 0x009F7F17,
0x00A18139, 0x0027CDC2, 0x002B5434, 0x00AD18CF,
0x003267D8, 0x00B42B23, 0x00B8B2D5, 0x003EFE2E,
0x00C54E89, 0x00430272, 0x004F9B84, 0x00C9D77F,
0x0056A868, 0x00D0E493, 0x00DC7D65, 0x005A319E,
0x0064CFB0, 0x00E2834B, 0x00EE1ABD, 0x00685646,
0x00F72951, 0x007165AA, 0x007DFC5C, 0x00FBB0A7,
0x000CD1E9, 0x008A9D12, 0x008604E4, 0x0000481F,
0x009F3708, 0x00197BF3, 0x0015E205, 0x0093AEFE,
0x00AD50D0, 0x002B1C2B, 0x002785DD, 0x00A1C926,
0x003EB631, 0x00B8FACA, 0x00B4633C, 0x00322FC7,
0x00C99F60, 0x004FD39B, 0x00434A6D, 0x00C50696,
0x005A7981, 0x00DC357A, 0x00D0AC8C, 0x0056E077,
0x00681E59, 0x00EE52A2, 0x00E2CB54, 0x006487AF,
0x00FBF8B8, 0x007DB443, 0x00712DB5, 0x00F7614E,
0x0019A3D2, 0x009FEF29, 0x009376DF, 0x00153A24,
0x008A4533, 0x000C09C8, 0x0000903E, 0x0086DCC5,
0x00B822EB, 0x003E6E10, 0x0032F7E6, 0x00B4BB1D,
0x002BC40A, 0x00AD88F1, 0x00A11107, 0x00275DFC,
0x00DCED5B, 0x005AA1A0, 0x00563856, 0x00D074AD,
0x004F0BBA, 0x00C94741, 0x00C5DEB7, 0x0043924C,
0x007D6C62, 0x00FB2099, 0x00F7B96F, 0x0071F594,
0x00EE8A83, 0x0068C678, 0x00645F8E, 0x00E21375,
0x0015723B, 0x00933EC0, 0x009FA736, 0x0019EBCD,
0x008694DA, 0x0000D821, 0x000C41D7, 0x008A0D2C,
0x00B4F302, 0x0032BFF9, 0x003E260F, 0x00B86AF4,
0x002715E3, 0x00A15918, 0x00ADC0EE, 0x002B8C15,
0x00D03CB2, 0x00567049, 0x005AE9BF, 0x00DCA544,
0x0043DA53, 0x00C596A8, 0x00C90F5E, 0x004F43A5,
0x0071BD8B, 0x00F7F170, 0x00FB6886, 0x007D247D,
0x00E25B6A, 0x00641791, 0x00688E67, 0x00EEC29C,
0x003347A4, 0x00B50B5F, 0x00B992A9, 0x003FDE52,
0x00A0A145, 0x0026EDBE, 0x002A7448, 0x00AC38B3,
0x0092C69D, 0x00148A66, 0x00181390, 0x009E5F6B,
0x0001207C, 0x00876C87, 0x008BF571, 0x000DB98A,
0x00F6092D, 0x007045D6, 0x007CDC20, 0x00FA90DB,
0x0065EFCC, 0x00E3A337, 0x00EF3AC1, 0x0069763A,
0x00578814, 0x00D1C4EF, 0x00DD5D19, 0x005B11E2,
0x00C46EF5, 0x0042220E, 0x004EBBF8, 0x00C8F703,
0x003F964D, 0x00B9DAB6, 0x00B54340, 0x00330FBB,
0x00AC70AC, 0x002A3C57, 0x0026A5A1, 0x00A0E95A,
0x009E1774, 0x00185B8F, 0x0014C279, 0x00928E82,
0x000DF195, 0x008BBD6E, 0x00872498, 0x00016863,
0x00FAD8C4, 0x007C943F, 0x00700DC9, 0x00F64132,
0x00693E25, 0x00EF72DE, 0x00E3EB28, 0x0065A7D3,
0x005B59FD, 0x00DD1506, 0x00D18CF0, 0x0057C00B,
0x00C8BF1C, 0x004EF3E7, 0x00426A11, 0x00C426EA,
0x002AE476, 0x00ACA88D, 0x00A0317B, 0x00267D80,
0x00B90297, 0x003F4E6C, 0x0033D79A, 0x00B59B61,
0x008B654F, 0x000D29B4, 0x0001B042, 0x0087FCB9,
0x001883AE, 0x009ECF55, 0x009256A3, 0x00141A58,
0x00EFAAFF, 0x0069E604, 0x00657FF2, 0x00E33309,
0x007C4C1E, 0x00FA00E5, 0x00F69913, 0x0070D5E8,
0x004E2BC6, 0x00C8673D, 0x00C4FECB, 0x0042B230,
0x00DDCD27, 0x005B81DC, 0x0057182A, 0x00D154D1,
0x0026359F, 0x00A07964, 0x00ACE092, 0x002AAC69,
0x00B5D37E, 0x00339F85, 0x003F0673, 0x00B94A88,
0x0087B4A6, 0x0001F85D, 0x000D61AB, 0x008B2D50,
0x00145247, 0x00921EBC, 0x009E874A, 0x0018CBB1,
0x00E37B16, 0x006537ED, 0x0069AE1B, 0x00EFE2E0,
0x00709DF7, 0x00F6D10C, 0x00FA48FA, 0x007C0401,
0x0042FA2F, 0x00C4B6D4, 0x00C82F22, 0x004E63D9,
0x00D11CCE, 0x00575035, 0x005BC9C3, 0x00DD8538
};
/*===================================================================*/
long crc_octets (char *octets, int len) {
	long crc = CRC24_INIT;
	long temp;
	int arg;

	while (len--){
		temp = crc;
		temp >>= 8;
		temp >>= 8;
		temp ^= *octets++;
		arg = temp & 0x000000FF;
		crc <<= 8;
		crc ^= CRC24tab[arg];
	}
	crc &= 0x00ffffffL;
	return crc;
}

/* Serial I/O ========================================================*/

int init_port(char *sio) {
	int fd; /* File descriptor for the port */
	struct termios options;

	fd = open(sio, O_RDWR | O_NOCTTY | O_NDELAY);
	if (fd == -1) {
		perror("open_port: Unable to open serial port - ");
	}
	if(!isatty(fd)) {
		perror("open_port: This is not be a serial port");
	}
	fcntl(fd,F_SETFL,0);
	tcgetattr(fd,&options);
	cfmakeraw(&options);
	if(cfsetispeed(&options, B38400) < 0 || cfsetospeed(&options, B38400) < 0) {
		perror("open_port: Unable to set speed");
	}
	options.c_cc[VMIN] = 0;
	options.c_cc[VTIME] = 10; // timeout
	if(tcsetattr(fd, TCSANOW, &options) < 0) {
		perror("open_port: Unable to set configuration");
	}
	return (fd);
}

int close_port(int fd) {
	close(fd);
	return (0);
}

int _sendheader(char *string, int SO) {
	char buffer[HEADERLENGTH+1];
	char temp[HEADERLENGTH+1];
	int len, byte;
	int i = 0;
	unsigned int crc;
	temp[0] = '\0';
	while (*string != NULL) {
		char c = *string++;
		if(c == ' ' || c == '\t' || c == '\n') {
			if(sscanf(temp, "%02X", &byte) != 0) {
				buffer[i++] = byte;
			}
			temp[0] = '\0';
		} else {
			len = strlen(temp);
			temp[len] = c;
			temp[len+1] = '\0';
		}
		if(i>HEADERLENGTH) return(-1);
	}
	crc = crc_octets(buffer, i);
	unsigned int b;
	b = crc & 0xFF;
	if(write(SO, &b, 1) < 0) return(31);
	b = (crc & 0xFF00)>>8;
	if(write(SO, &b, 1) < 0) return(32);
	b = (crc & 0xFF0000)>>16;
	if(write(SO, &b, 1) < 0) return(33);
	if(write(SO, buffer, i) < 0) return(2);
	return(0);
}

int _sendbody(char *string, int SO) {
	char buffer[MAXLENGTH+1];
	char temp[MAXLENGTH+1];
	int len, byte;
	int i = 0;
	unsigned int crc = 0;

	temp[0] = '\0';
	while (*string != NULL) {
		char c = *string++;
		if(c == ' ' || c == '\t' || c == '\n') {
			if(sscanf(temp, "%X", &byte) != 0) {
				buffer[i++] = byte;
				crc += byte;
			}
			temp[0] = '\0';
		} else {
			len = strlen(temp);
			temp[len] = c;
			temp[len+1] = '\0';
		}
	}
	if(write(SO, buffer, i) < 0) return(2);
	crc--;
	if(write(SO, &crc, 1) < 0) return(3);
	return(0);
}


unsigned char _getbyte(int fd) {
	unsigned char block_from;
	int block_len=1;
	while (block_len!=0)
	{
		block_len=read(fd, &block_from, block_len);
//		if (block_len>0) printf("Resutlt: %X\n",block_from);
		if (block_len>0) return(block_from);
	}
	return(-1);
}

unsigned char* _getheader(int fd) {
	unsigned char ostring[(MAXLENGTH)*3];
	unsigned char buffer[HEADERLENGTH];
	int res = -1;
	unsigned int crc;
	unsigned int rcrc;

	unsigned char byte0 = _getbyte(fd); rcrc = byte0 & 0xFF;
	unsigned char byte1 = _getbyte(fd); rcrc |= (byte1 << 8) & 0xFF00;
	unsigned char byte2 = _getbyte(fd); rcrc |= (byte2 << 16) & 0xFF0000;
	unsigned char byte3 = _getbyte(fd); buffer[0] = byte3;
	unsigned char byte4 = _getbyte(fd); buffer[1] = byte4;
	unsigned char byte5 = _getbyte(fd); buffer[2] = byte5;
	unsigned char byte6 = _getbyte(fd); buffer[3] = byte6;
	unsigned char byte7 = _getbyte(fd); buffer[4] = byte7;
	crc = crc_octets(buffer, 5);
	if(crc == rcrc) res = 0;
	sprintf(ostring, "%d::%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X", res,byte0,byte1,byte2,byte3,byte4,byte5,byte6,byte7);
	return(ostring);
}

unsigned char* _getbody(int len, int fd) {
	unsigned char ostring[(MAXLENGTH)*3];
	int res = -1;

	unsigned char buffer[MAXLENGTH+1];
	unsigned char tmp[40];
	unsigned int byte;
	int i = 0;
	unsigned int crc = 0;

	do {
		buffer[i] = _getbyte(fd);
		crc += buffer[i];
		i++;
	} while(i < len);
	crc &= 0xFF; crc--;
	buffer[len] = _getbyte(fd);
	if(crc == buffer[len]) res = 0;
	sprintf(ostring, "%d:", res);
	i = 0;
	do {
		sprintf(tmp, ":%02X", buffer[i]);
		strcat(ostring, tmp);
		i++;
	} while(i <= len);
	return(ostring);
}


