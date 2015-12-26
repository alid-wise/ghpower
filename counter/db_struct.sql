--
--       Copyright (C) 2008-2012 Александр Девяткин, "Зелёная горка"
--
--       Разрешается повторное распространение и использование как в виде исходного
--       кода, так и в двоичной форме, с изменениями или без, при соблюдении следующих
--       условий:
--
--       * При повторном распространении исходного кода должно оставаться указанное
--         выше уведомление об авторском праве, этот список условий и последующий
--         отказ от гарантий.
--       * При повторном распространении двоичного кода должна сохраняться указанная
--         выше информация об авторском праве, этот список условий и последующий отказ
--         от гарантий в документации и/или в других материалах, поставляемых при
--         распространении.
--       * Ни название "Зелёная горка", ни имена ее сотрудников не могут быть
--         использованы в качестве поддержки или продвижения продуктов, основанных
--         на этом ПО без предварительного письменного разрешения.
--
--       ЭТА ПРОГРАММА ПРЕДОСТАВЛЕНА ВЛАДЕЛЬЦАМИ АВТОРСКИХ ПРАВ И/ИЛИ ДРУГИМИ СТОРОНАМИ
--	"КАК ОНА ЕСТЬ" БЕЗ КАКОГО-ЛИБО ВИДА ГАРАНТИЙ, ВЫРАЖЕННЫХ ЯВНО ИЛИ ПОДРАЗУМЕВАЕМЫХ,
--	ВКЛЮЧАЯ, НО НЕ ОГРАНИЧИВАЯСЬ ИМИ, ПОДРАЗУМЕВАЕМЫЕ ГАРАНТИИ КОММЕРЧЕСКОЙ ЦЕННОСТИ
--	И ПРИГОДНОСТИ ДЛЯ КОНКРЕТНОЙ ЦЕЛИ. НИ В КОЕМ СЛУЧАЕ, ЕСЛИ НЕ ТРЕБУЕТСЯ
--	СООТВЕТСТВУЮЩИМ ЗАКОНОМ, ИЛИ НЕ УСТАНОВЛЕНО В УСТНОЙ ФОРМЕ, НИ ОДИН ВЛАДЕЛЕЦ
--	АВТОРСКИХ ПРАВ И НИ ОДНО ДРУГОЕ ЛИЦО, КОТОРОЕ МОЖЕТ ИЗМЕНЯТЬ И/ИЛИ ПОВТОРНО
--	РАСПРОСТРАНЯТЬ ПРОГРАММУ, КАК БЫЛО СКАЗАНО ВЫШЕ, НЕ НЕСЁТ ОТВЕТСТВЕННОСТИ,
--	ВКЛЮЧАЯ ЛЮБЫЕ ОБЩИЕ, СЛУЧАЙНЫЕ, СПЕЦИАЛЬНЫЕ ИЛИ ПОСЛЕДОВАВШИЕ УБЫТКИ,
--	ВСЛЕДСТВИЕ ИСПОЛЬЗОВАНИЯ ИЛИ НЕВОЗМОЖНОСТИ ИСПОЛЬЗОВАНИЯ ПРОГРАММЫ (ВКЛЮЧАЯ,
--	НО НЕ ОГРАНИЧИВАЯСЬ ПОТЕРЕЙ ДАННЫХ, ИЛИ ДАННЫМИ, СТАВШИМИ НЕПРАВИЛЬНЫМИ, ИЛИ
--	ПОТЕРЯМИ ПРИНЕСЕННЫМИ ИЗ-ЗА ВАС ИЛИ ТРЕТЬИХ ЛИЦ, ИЛИ ОТКАЗОМ ПРОГРАММЫ РАБОТАТЬ
--	СОВМЕСТНО С ДРУГИМИ ПРОГРАММАМИ), ДАЖЕ ЕСЛИ ТАКОЙ ВЛАДЕЛЕЦ ИЛИ ДРУГОЕ ЛИЦО БЫЛИ
--	ИЗВЕЩЕНЫ О ВОЗМОЖНОСТИ ТАКИХ УБЫТКОВ.
--

--       Copyright (C) 2008-2012 Aleksandr Deviatkin, "Green Hill"
--
--       Redistribution and use in source and binary forms, with or without
--       modification, are permitted provided that the following conditions are
--       met:
--       
--       * Redistributions of source code must retain the above copyright
--         notice, this list of conditions and the following disclaimer.
--       * Redistributions in binary form must reproduce the above
--         copyright notice, this list of conditions and the following disclaimer
--         in the documentation and/or other materials provided with the
--         distribution.
--       * Neither the name of the Green Hill nor the names of its
--         contributors may be used to endorse or promote products derived from
--         this software without specific prior written permission.
--       
--       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--       "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--       LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--       A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
--       OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--       SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--       LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--       DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--       THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--       OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--

-- users
create table auth (
	id serial not null,
	name varchar,
	login varchar,
	password varchar,
	email varchar,
	active integer default 0,
	gid integer default 0,
	memo varchar,
	modtime timestamp without time zone DEFAULT now()
);
create table groups (
	id integer not null,
	name varchar
);
INSERT INTO groups (id,name) VALUES (1,'admin');
INSERT INTO groups (id,name) VALUES (2,'manager');
INSERT INTO groups (id,name) VALUES (3,'user');
INSERT INTO groups (id,name) VALUES (4,'guest');
-- admin/admin
INSERT INTO auth (name,login,password,email,active,gid,memo) VALUES ('- embedded admin -','admin','$1$YqBppwE5$9GaW92wOLUP0v4Au/Lfab.','admin@email',1,1,'Эту запись не стоит удалять');

-- группы мониторинга (лучи)
create table mgroup (
	id integer not null,
	active integer,
	name varchar,
	if_id integer,
	memo varchar,
	rank integer,
	bid integer,
	modtime timestamp without time zone DEFAULT now()
);

-- счетчики
create table counters (
	id integer not null,
	name varchar,
	addr integer,
	mgroup integer,
	passwd varchar,
	passwd2 varchar,
	sn integer,
	model integer,
	ktrans integer default 1,	-- коэффициент пересчета
	setdate date,	-- дата установки
	memo varchar,
	active integer,
	modtime timestamp default now(),
	tower_id integer,
	year integer,
	street integer,
	house varchar,
	owner integer,	-- users.id
	plimit decimal DEFAULT 3.6,	-- допустимая потребляемая мощность
	subscr integer default 0,	-- подписка владельца на алерты
	primary key (id)
);

-- модели счетчиков
create table counter_type (
	id integer not null,
	name varchar,
	type varchar
);

-- интерфейсы
create table iface (
	id integer not null,
--	name varchar,
	dev varchar
);

-- текущее состояние
create table status (
	id serial not null,
	cid integer,
	state integer, -- текущее состояние
	pstate integer, -- предыдущее состояние
	se1 decimal DEFAULT 0, -- текущие показания Т1
	se2 decimal DEFAULT 0, -- текущие показания Т2
	lpower decimal,
	modtime timestamp without time zone DEFAULT now(),
	maintenance integer DEFAULT 0,
	primary key (id)
);
-- лог алертов
create table alerts (
 id serial not null,
 atime timestamp without time zone DEFAULT now(),
 cid integer,
 state integer,
 pstate integer,
 se1 decimal DEFAULT 0,
 se2 decimal DEFAULT 0,
 primary key (id)
);

-- данные
create table monitor (
	dt timestamp without time zone,
	date integer not null,
	counter integer not null,
	mv1 decimal,	-- текущее напряжение ф1
	mv2 decimal,	-- текущее напряжение ф2
	mv3 decimal,	-- текущее напряжение ф3
	mc1 decimal,	-- текущий ток ф1
	mc2 decimal,	-- текущий ток ф2
	mc3 decimal,	-- текущий ток ф3
	mf decimal,		-- частота
	ma1 decimal,	-- углы между фазами 1-2
	ma2 decimal,	-- углы между фазами 1-3
	ma3 decimal,	-- углы между фазами 2-3
	mps decimal,	-- мощность P сумма
	mp1 decimal,	-- мощность P ф1
	mp2 decimal,	-- мощность P ф2
	mp3 decimal,	-- мощность P ф3
	mqs decimal,	-- мощность Q сумма
	mq1 decimal,	-- мощность Q ф1
	mq2 decimal,	-- мощность Q ф2
	mq3 decimal,	-- мощность Q ф3
	mss decimal,	-- мощность S сумма
	ms1 decimal,	-- мощность S ф1
	ms2 decimal,	-- мощность S ф2
	ms3 decimal,	-- мощность S ф3
	mks decimal,	-- коэфф.мощности сумма
	mk1 decimal,	-- коэфф.мощности ф1
	mk2 decimal,	-- коэфф.мощности ф2
	mk3 decimal,	-- коэфф.мощности ф3
	se1ai decimal, -- накопленная энергия Т1 A-import
	se1ae decimal, -- накопленная энергия Т1 A-export
	se1ri decimal, -- накопленная энергия Т1 R-import
	se1re decimal, -- накопленная энергия Т1 R-export
	se2ai decimal, -- накопленная энергия Т2 A-import
	se2ae decimal, -- накопленная энергия Т2 A-export
	se2ri decimal, -- накопленная энергия Т2 R-import
	se2re decimal, -- накопленная энергия Т2 R-export
	ise decimal		-- интегральная мощность
);
CREATE INDEX monitor_date_i ON monitor (date);
CREATE INDEX monitor_dt_i ON monitor (dt);
CREATE INDEX monitor_counter_i ON monitor (counter);
create index monitor_rdt_i on monitor (counter) where extract(hour from dt)=0 and extract(minute from dt)=0;
create VIEW m_monitor as SELECT to_timestamp(monitor."date"::double precision) as tm,* from monitor;
CREATE VIEW m_power AS select to_char(to_timestamp(monitor.date::double precision),'DD.MM.YYYY HH24:MI:SS') AS date,to_char(to_timestamp(monitor.date::double precision),'DD.MM.YYYY') AS dt,to_char(to_timestamp(monitor.date::double precision),'HH24:MI:SS') AS tm,monitor.counter AS counter,to_char(monitor.mp1,'999999') AS p1,to_char(monitor.mp2,'999999') AS p2,to_char(monitor.mp3,'999999') AS p3,to_char(monitor.mps,'999999') AS p,to_char(monitor.ise*1000,'999999') AS pi from monitor;

create view m_stored_energy as select to_char(to_timestamp(monitor.date::double precision), 'DD.MM.YYYY HH24:MI:SS'::text) AS datime, to_char(to_timestamp(monitor.date::double precision), 'DD.MM.YYYY'::text) AS dt, to_char(to_timestamp(monitor.date::double precision), 'HH24:MI:SS'::text) AS tm,date,counter,counters.addr,counters.name,counters.memo,se1ai,se2ai from monitor inner join counters on counter=counters.id order by date desc;

CREATE FUNCTION ise_stamp() RETURNS trigger AS '
DECLARE
   prev record;
BEGIN
   SELECT INTO prev counters.ktrans,date,se1ai,se2ai from ONLY monitor inner join counters on counter=counters.id where date<NEW.date and counter=NEW.counter order by date desc limit 1;
   IF NOT FOUND THEN
       NEW.ise := 0;
   ELSE
       NEW.ise := ((NEW.se1ai + NEW.se2ai) - (prev.se1ai + prev.se2ai)) * 3600 * prev.ktrans /(NEW.date - prev.date);
   END IF;
   RETURN NEW;
END;
' LANGUAGE plpgsql;

CREATE TRIGGER ise_stamp BEFORE INSERT ON monitor FOR EACH ROW EXECUTE PROCEDURE ise_stamp();


-- описания полей
create table monitor_descr (
	id integer,
	name varchar,
	descr varchar
);

insert into monitor_descr (id,name,descr) values (1,'mv1','текущее напряжение ф1');
insert into monitor_descr (id,name,descr) values (2,'mv2','текущее напряжение ф2');
insert into monitor_descr (id,name,descr) values (3,'mv3','текущее напряжение ф3');
insert into monitor_descr (id,name,descr) values (4,'mc1','текущий ток ф1');
insert into monitor_descr (id,name,descr) values (5,'mc2','текущий ток ф2');
insert into monitor_descr (id,name,descr) values (6,'mc3','текущий ток ф3');
insert into monitor_descr (id,name,descr) values (7,'mf','частота');
insert into monitor_descr (id,name,descr) values (8,'ma1','углы между фазами 1-2');
insert into monitor_descr (id,name,descr) values (9,'ma2','углы между фазами 1-3');
insert into monitor_descr (id,name,descr) values (10,'ma3','углы между фазами 2-3');
insert into monitor_descr (id,name,descr) values (11,'mps','мощность P сумма');
insert into monitor_descr (id,name,descr) values (12,'mp1','мощность P ф1');
insert into monitor_descr (id,name,descr) values (13,'mp2','мощность P ф2');
insert into monitor_descr (id,name,descr) values (14,'mp3','мощность P ф3');
insert into monitor_descr (id,name,descr) values (15,'mqs','мощность Q сумма');
insert into monitor_descr (id,name,descr) values (16,'mq1','мощность Q ф1');
insert into monitor_descr (id,name,descr) values (17,'mq2','мощность Q ф2');
insert into monitor_descr (id,name,descr) values (18,'mq3','мощность Q ф3');
insert into monitor_descr (id,name,descr) values (19,'mss','мощность S сумма');
insert into monitor_descr (id,name,descr) values (20,'ms1','мощность S ф1');
insert into monitor_descr (id,name,descr) values (21,'ms2','мощность S ф2');
insert into monitor_descr (id,name,descr) values (22,'ms3','мощность S ф3');
insert into monitor_descr (id,name,descr) values (23,'mks','коэфф.мощности сумма');
insert into monitor_descr (id,name,descr) values (24,'mk1','коэфф.мощности ф1');
insert into monitor_descr (id,name,descr) values (25,'mk2','коэфф.мощности ф2');
insert into monitor_descr (id,name,descr) values (26,'mk3','коэфф.мощности ф3');
insert into monitor_descr (id,name,descr) values (27,'se1ai','накопленная энергия Т1 A-import');
insert into monitor_descr (id,name,descr) values (28,'se1ae','накопленная энергия Т1 A-export');
insert into monitor_descr (id,name,descr) values (29,'se1ri','накопленная энергия Т1 R-import');
insert into monitor_descr (id,name,descr) values (30,'se1re','накопленная энергия Т1 R-export');
insert into monitor_descr (id,name,descr) values (31,'se2ai','накопленная энергия Т2 A-import');
insert into monitor_descr (id,name,descr) values (32,'se2ae','накопленная энергия Т2 A-export');
insert into monitor_descr (id,name,descr) values (33,'se2ri','накопленная энергия Т2 R-import');
insert into monitor_descr (id,name,descr) values (34,'se2re','накопленная энергия Т2 R-export');
insert into monitor_descr (id,name,descr) values (35,'ise','интегральная мощность');




-- Месячные расходы по счетчикам
-- (заполняется раз в месяц counter/mexpenses)
create table mexpenses (
	id serial not null,
	cid integer,	-- counter id
	year integer,
	month integer,
	exp1 decimal DEFAULT 0,
	exp2 decimal DEFAULT 0,
	modtime timestamp without time zone DEFAULT now(),
	primary key (id)
);
CREATE INDEX mexpenses_year_i ON mexpenses (year);
CREATE INDEX mexpenses_month_i ON mexpenses (month);
CREATE INDEX mexpenses_counter_i ON mexpenses (cid);


--
-- Проезды
--
CREATE TABLE street (
    id integer NOT NULL,
    name character varying(100) NOT NULL
);

--
-- столбы
--
CREATE TABLE towers (
    id serial NOT NULL,
    name character varying,
    memo character varying,
    modtime timestamp without time zone DEFAULT now() NOT NULL,
    primary key (id)
);


--
-- Платежи
--
CREATE TABLE payments (
    id serial NOT NULL,
    auth integer,
    cid integer,
    date date,
	init integer,	-- 1-первая запись; 2-первая запись, но показаний КС на эту дату нет
	mode integer DEFAULT 2,
    prev1 decimal,
    prev2 decimal,
    current1 decimal,
    current2 decimal,
    mdate date,
    cost decimal,
    amount decimal,
    balance decimal,
	memo text,
    modtime timestamp without time zone DEFAULT now() NOT NULL,
    primary key (id)
);
CREATE INDEX payments_date_i ON payments (date ASC);
CREATE INDEX payments_cid_i ON payments (cid);

CREATE TABLE tariff (
    id serial NOT NULL,
    auth integer,
    t0 decimal,
    t1 decimal,
    t2 decimal,
    k decimal,
    sdate date,           -- начало действия тарифа
    modtime timestamp without time zone DEFAULT now() NOT NULL,
    primary key (id)
);
INSERT INTO tariff (t1,t2,sdate) VALUES (4.11,1.39,'2012-07-01');


CREATE TABLE users (
	id serial NOT NULL,
	auth integer,
	fname character varying(255),
	mname character varying(255),
	lname character varying(255),
	status character varying,
	birthday date,
	passport character varying,
	address character varying,	-- адрес прописки
	active integer,
	memo character varying,
	modtime timestamp without time zone DEFAULT now(),
	primary key (id)
);

CREATE TABLE phones (
	id serial NOT NULL,
	auth integer,
	userid integer NOT NULL,
	phone character varying(255),
	typeid integer NOT NULL default 0,
--	active integer NOT NULL default 1,
--	memo character varying,
	modtime timestamp without time zone DEFAULT now(),
	primary key (id)
);

CREATE TABLE sms_log (
	id serial NOT NULL,
	auth integer,
	dt timestamp without time zone DEFAULT now(),
	cid integer NOT NULL,
	userid integer NOT NULL,
	phone character varying(255),
	msg character varying,
	msg_id bigint,
	active smallint NOT NULL default 0,
	status smallint,
	descr character varying,
	posted timestamp without time zone,
	updates timestamp without time zone,
	parts smallint,
	cost numeric,
	modtime timestamp without time zone DEFAULT now(),
	primary key (id)
);
CREATE INDEX sms_log_dt_i ON sms_log (dt);
CREATE INDEX sms_log_userid_i ON sms_log (userid);
CREATE INDEX sms_log_cid_i ON sms_log (cid);

-- Альтернативный вариант списка персон (vCard)
CREATE TABLE contacts (
        id serial NOT NULL,
        uid varchar,
        active integer default 1,
        fullname varchar,
        carddata varchar,
        uri varchar,
        etag varchar,
        modtime timestamp without time zone DEFAULT now(),
        primary key (uid)
);
-- example:
INSERT INTO contacts (uid,fullname,carddata) VALUES ('489b1350-46e4-69e4-49bd-3fd47b26e237','Admin','FN:Admin');

update contacts set id=cast(substring(carddata,'\WID:(\d+)') as int);



