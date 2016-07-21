package GHPowerLDAP;

use strict;
use vars qw(@ISA @EXPORT);
use utf8;
use open qw(:std :utf8);
#use Encode qw(encode decode is_utf8);
use Net::LDAP;
#use POSIX;
use Carp;

my $LDAP_HOST = 'localhost';
my $BASE_DN = 'o=zgorka';
my $DOMAINS_DN = 'ou=domains,'.$BASE_DN;

END {
#  my $self = shift;
#  my $mesg = $self->{ldap}->unbind;  # take down session
#  $mesg->code && croak $mesg->error;
}

sub new {
  my $class = shift;
  my $self={};
  bless $self,$class;
  $self->init;
  return $self;
}

sub init {
  my $self = shift;
  my $ldap = Net::LDAP->new($LDAP_HOST, raw => qr/(?i:^jpegPhoto|;binary)/);
  # bind to a directory without dn and password (anonymously)
  my $mesg = $ldap->bind();
  $mesg->code && croak "Host: $LDAP_HOST ".$mesg->error;
  $self->{ldap} = $ldap;
}

# Список улиц
sub Street_List {
  my $self = shift;
  my $mesg = $self->{ldap}->search(
                      base => $DOMAINS_DN,
                      filter => "(objectClass=*)",
                      scope => 'one'
                     );
  $mesg->code && return undef;
  my @a;
  foreach my $entry ($mesg->sorted("destinationIndicator")) {
    my $name = $entry->get_value('ou');
#    Encode::_utf8_on($name);
    # Сокращенное название
    my ($sname) = ($name =~ /^\W*(\w{1})/);
    $sname .= ".";
#    Encode::_utf8_off($name);
#    Encode::_utf8_off($sname);
    my %h;
    $h{$name} = $sname;
    push @a,\%h;
  }
  return \@a;
}

# Список участков на заданной улице
sub Domains_List {
  my $self = shift;
  my $search = shift;

  return undef  unless $search;
  my $dn = "$search,".$DOMAINS_DN;
  my $mesg = $self->{ldap}->search(
                      base => $dn,
                      filter => "(objectClass=*)",
                      scope => 'one'
                     );
  $mesg->code && return undef;
  my $ret;
  foreach my $entry ($mesg->entries()) {
    my $s = $entry->dn();
    my ($key) = ($s =~ /^(.+)\,$DOMAINS_DN$/);
    my ($name) = ($key =~ /^ou\=([^,]+)/);
    $ret->{$key} = $name;
  }
  return $ret;
}

# Вся информация о заданном участке
sub get_Domain {
  my $self = shift;
  my $search = shift;

  return undef  unless $search;
  my $dn = "$search,".$DOMAINS_DN;

  my $mesg = $self->{ldap}->search(
                      base => $dn,
                      filter => "(objectClass=*)",
                      scope => 'subtree'
                     );
  $mesg->code && return undef;
  my $ret = $mesg->as_struct;
  # Добавим данные о всех владельцах
  my $owners = $mesg->entry->get_value('owner',asref=>1);
  my @owners_data;
  foreach my $owner (@$owners) {
    my $mesg = $self->{ldap}->search(
                      base => $owner,
                      filter => "(objectClass=*)",
                      scope => 'subtree'
                     );
    unless($mesg->code) {
      push @owners_data, $mesg->as_struct->{$mesg->entry->dn()};
    }
  }
  $ret->{$mesg->entry->dn()}->{owners} = \@owners_data;

  # Добавим данные о всех управляющих
  my $managers = $mesg->entry->get_value('manager',asref=>1);
  my @managers_data;
  foreach my $manager (@$managers) {
    my $mesg = $self->{ldap}->search(
                      base => $manager,
                      filter => "(objectClass=*)",
                      scope => 'subtree'
                     );
    unless($mesg->code) {
      push @managers_data, $mesg->as_struct->{$mesg->entry->dn()};
    }
  }
  $ret->{$mesg->entry->dn()}->{managers} = \@managers_data;

  return ($ret->{$mesg->entry->dn()});
  return $ret;  # With dn
}

# Вся структура ou=domains с владельцами и пр.
sub Domains_Struct {
  my $self = shift;
  my $mesg = $self->{ldap}->search(
                      base => $DOMAINS_DN,
                      filter => "(objectClass=*)",
                      scope => 'one'
                     );
  $mesg->code && return undef;

  my $Struct;
  foreach my $entry ($mesg->sorted("destinationIndicator")) {
    my $name = $entry->get_value('ou');
    $Struct->{$name}->{name} = $name;
    # Сокращенное название
    my ($sname) = ($name =~ /^\W*(\w{1})/);
    $sname .= ".";
    $Struct->{$name}->{sname} = $sname;
    $Struct->{$name}->{ord} = $entry->get_value('destinationIndicator');

    my $domlist = $self->Domains_List("ou=$name");
    foreach my $dn (keys %{$domlist}) {
      my $dom = $self->get_Domain($dn);
      $Struct->{$name}->{Dom}->{$domlist->{$dn}} = $dom;
      $Struct->{$name}->{Dom}->{$domlist->{$dn}}->{dn} = $dn;
    }
  }
  return $Struct;
}



1;
