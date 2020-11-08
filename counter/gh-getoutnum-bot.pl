#!/usr/bin/perl -w
use strict;
use utf8;
use Data::Dumper;
use WWW::Telegram::BotAPI;
use Config::YAML;
use lib "$ENV{MY}/lib/";
use GHPower;
use DBI;
use POSIX;
use Fcntl qw(:DEFAULT);
use Lock;


my (@args, %opts);
foreach(@ARGV){
   if(/^\-(\S)(\S*)/){  $opts{$1} = $2; }else{  push @args, $_; }
}
my $daemon = exists $opts{d};

my $stop;
$SIG{TERM} = sub { $stop++; };  # kill by default signal
my $lock = "$ENV{MY}/data/gh-getoutnum-bot.pid";
my $dlock;

if($daemon) {
    my $pid = fork();
    exit(0)     if($pid);
    die "Couldn't fork: $!" unless defined($pid);
    POSIX::setsid() or die "Can't start a new session: $!";
    # ставим собственную блокировку
    $dlock = Lock->new($lock);
    exit(1) if($dlock->set);
}

# Конфирурация, пользователи
my $cfg = "$ENV{MY}/counter/gh-getoutnum-bot.conf";
my $CFG = Config::YAML->new( config => $cfg);

my %UserAllowed;
foreach(keys %{$CFG->{tg_user_allowed}}) {
    $UserAllowed{$_} = $CFG->{tg_user_allowed}->{$_};
}

my $dbh = DBI->connect("dbi:Pg:dbname=$CFG->{database};host=$CFG->{dbhost};port=$CFG->{dbport}","","", { RaiseError => 1, AutoCommit => 0});
my $ghpower = GHPower->new($dbh);

my $api = WWW::Telegram::BotAPI->new(token => $CFG->{'token'});


# получаем очередь сообщений. По умолчанию, отдается массив не более 100
$api->getUpdates();

# включаем бесконечный цикл и погнали обрабатывать
while (!$stop) {
    # если в очереди ничего нет, делаем задержку на 1 секунду и начинаем все сначала.
    if ( scalar @{ ( $api->getUpdates->{result} ) } == 0 ) { sleep 1; next; }

    # ----
    my $updateid;
    #если в очереди что-то есть начинаем обрабатывать этот массив
    for ( my $i = 0 ; $i < scalar @{ ( $api->getUpdates->{result} ) } ; $i++ ) {
        my $data = $api->getUpdates;
#print Dumper $data;
        my $chat_id = $data->{result}[$i]->{message}->{from}->{id};
        my $reply_to_message_id = $data->{result}[$i]->{message}->{message_id};
        my $Text;

#        my $Me = $api->getMe;
#print Dumper $Me;

        my $allowed = exists $UserAllowed{$chat_id};

        # Начало диалога
        if($data->{result}[$i]->{message}->{entities}) {
            foreach my $entity (@{$data->{result}[$i]->{message}->{entities}}) {
                if($entity->{type} eq 'bot_command' && $data->{result}[$i]->{message}->{text} eq '/start') {
                    if($allowed) {
                        $Text = 'Введите две строки: Адресат и Тема';
                    } else {
                        $Text = 'User ID: '.$chat_id;
                    }
                    last;
                }
            }
        } else {
            unless($allowed) {
                $Text = 'Доступ запрещён';
            } else {
                my ($addr, $subj) = split(/\n/, $data->{result}[$i]->{message}->{text}, 2);
                my $outnum = $ghpower->get_next_outnum($chat_id, '', $addr, $subj);
                if($outnum) {
                    $Text = "Номер: $outnum\nАдрес: $addr\nТема: $subj";
                    $dbh->commit;
                } else {
                    $Text = 'Произошла ошибка';
                    $dbh->rollback;
                }
            }
        }

        $api->sendMessage ({
            chat_id => $chat_id,
            reply_to_message_id => $reply_to_message_id,
            text => $Text});

        $updateid = ( $api->getUpdates->{result}[$i]->{update_id} );
        sleep 1;
    }

    # делаем апдейт очереди, пометив обработанные сообщения путем задания offset
    $api->getUpdates( { offset => $updateid + 1 } );
    next;
}

$dbh->disconnect;
$dlock->clear   if($dlock && $daemon);
exit(0);
