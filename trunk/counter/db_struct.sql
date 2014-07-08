--
--       Copyright (C) 2008-2012 ��������� ��������, "��̣��� �����"
--
--       ����������� ��������� ��������������� � ������������� ��� � ���� ���������
--       ����, ��� � � �������� �����, � ����������� ��� ���, ��� ���������� ���������
--       �������:
--
--       * ��� ��������� ��������������� ��������� ���� ������ ���������� ���������
--         ���� ����������� �� ��������� �����, ���� ������ ������� � �����������
--         ����� �� ��������.
--       * ��� ��������� ��������������� ��������� ���� ������ ����������� ���������
--         ���� ���������� �� ��������� �����, ���� ������ ������� � ����������� �����
--         �� �������� � ������������ �/��� � ������ ����������, ������������ ���
--         ���������������.
--       * �� �������� "��̣��� �����", �� ����� �� ����������� �� ����� ����
--         ������������ � �������� ��������� ��� ����������� ���������, ����������
--         �� ���� �� ��� ���������������� ����������� ����������.
--
--       ��� ��������� ������������� ����������� ��������� ���� �/��� ������� ���������
--	"��� ��� ����" ��� ������-���� ���� ��������, ���������� ���� ��� ���������������,
--	�������, �� �� ������������� ���, ��������������� �������� ������������ ��������
--	� ����������� ��� ���������� ����. �� � ���� ������, ���� �� ���������
--	��������������� �������, ��� �� ����������� � ������ �����, �� ���� ��������
--	��������� ���� � �� ���� ������ ����, ������� ����� �������� �/��� ��������
--	�������������� ���������, ��� ���� ������� ����, �� ���� ���������������,
--	������� ����� �����, ���������, ����������� ��� ������������� ������,
--	���������� ������������� ��� ������������� ������������� ��������� (�������,
--	�� �� ������������� ������� ������, ��� �������, �������� �������������, ���
--	�������� ������������ ��-�� ��� ��� ������� ���, ��� ������� ��������� ��������
--	��������� � ������� �����������), ���� ���� ����� �������� ��� ������ ���� ����
--	�������� � ����������� ����� �������.
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
INSERT INTO auth (name,login,password,email,active,gid,memo) VALUES ('- embedded admin -','admin','$1$YqBppwE5$9GaW92wOLUP0v4Au/Lfab.','admin@email',1,1,'��� ������ �� ����� �������');



# "����" ���� ������


-- ������ ����������� (����)
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

-- ��������
create table counters (
	id integer not null,
	name varchar,
	addr integer,
	mgroup integer,
	passwd varchar,
	passwd2 varchar,
	sn integer,
	model integer,
	ktrans integer default 1,	-- ����������� ���������
	setdate date,	-- ���� ���������
	memo varchar,
	active integer,
	modtime timestamp default now(),
	tower_id integer,
	year integer,
	street integer,
	house varchar,
	owner integer,	-- users.id
	plimit decimal DEFAULT 3.6,	-- ���������� ������������ ��������
	primary key (id)
);

-- ������ ���������
create table counter_type (
	id integer not null,
	name varchar,
	type varchar
);

-- ����������
create table iface (
	id integer not null,
--	name varchar,
	dev varchar
);

-- ������� ���������
create table status (
	id serial not null,
	cid integer,
	state integer, -- ������� ���������
	pstate integer, -- ���������� ���������
	se1 decimal DEFAULT 0, -- ������� ��������� �1
	se2 decimal DEFAULT 0, -- ������� ��������� �2
	lpower decimal,
	modtime timestamp without time zone DEFAULT now(),
	primary key (id)
);
-- ��� �������
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

-- ������
create table monitor (
	dt timestamp without time zone,
	date integer not null,
	counter integer not null,
	mv1 decimal,	-- ������� ���������� �1
	mv2 decimal,	-- ������� ���������� �2
	mv3 decimal,	-- ������� ���������� �3
	mc1 decimal,	-- ������� ��� �1
	mc2 decimal,	-- ������� ��� �2
	mc3 decimal,	-- ������� ��� �3
	mf decimal,		-- �������
	ma1 decimal,	-- ���� ����� ������ 1-2
	ma2 decimal,	-- ���� ����� ������ 1-3
	ma3 decimal,	-- ���� ����� ������ 2-3
	mps decimal,	-- �������� P �����
	mp1 decimal,	-- �������� P �1
	mp2 decimal,	-- �������� P �2
	mp3 decimal,	-- �������� P �3
	mqs decimal,	-- �������� Q �����
	mq1 decimal,	-- �������� Q �1
	mq2 decimal,	-- �������� Q �2
	mq3 decimal,	-- �������� Q �3
	mss decimal,	-- �������� S �����
	ms1 decimal,	-- �������� S �1
	ms2 decimal,	-- �������� S �2
	ms3 decimal,	-- �������� S �3
	mks decimal,	-- �����.�������� �����
	mk1 decimal,	-- �����.�������� �1
	mk2 decimal,	-- �����.�������� �2
	mk3 decimal,	-- �����.�������� �3
	se1ai decimal, -- ����������� ������� �1 A-import
	se1ae decimal, -- ����������� ������� �1 A-export
	se1ri decimal, -- ����������� ������� �1 R-import
	se1re decimal, -- ����������� ������� �1 R-export
	se2ai decimal, -- ����������� ������� �2 A-import
	se2ae decimal, -- ����������� ������� �2 A-export
	se2ri decimal, -- ����������� ������� �2 R-import
	se2re decimal, -- ����������� ������� �2 R-export
	ise decimal		-- ������������ ��������
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


-- �������� �����
create table monitor_descr (
	id integer,
	name varchar,
	descr varchar
);

insert into monitor_descr (id,name,descr) values (1,'mv1','������� ���������� �1');
insert into monitor_descr (id,name,descr) values (2,'mv2','������� ���������� �2');
insert into monitor_descr (id,name,descr) values (3,'mv3','������� ���������� �3');
insert into monitor_descr (id,name,descr) values (4,'mc1','������� ��� �1');
insert into monitor_descr (id,name,descr) values (5,'mc2','������� ��� �2');
insert into monitor_descr (id,name,descr) values (6,'mc3','������� ��� �3');
insert into monitor_descr (id,name,descr) values (7,'mf','�������');
insert into monitor_descr (id,name,descr) values (8,'ma1','���� ����� ������ 1-2');
insert into monitor_descr (id,name,descr) values (9,'ma2','���� ����� ������ 1-3');
insert into monitor_descr (id,name,descr) values (10,'ma3','���� ����� ������ 2-3');
insert into monitor_descr (id,name,descr) values (11,'mps','�������� P �����');
insert into monitor_descr (id,name,descr) values (12,'mp1','�������� P �1');
insert into monitor_descr (id,name,descr) values (13,'mp2','�������� P �2');
insert into monitor_descr (id,name,descr) values (14,'mp3','�������� P �3');
insert into monitor_descr (id,name,descr) values (15,'mqs','�������� Q �����');
insert into monitor_descr (id,name,descr) values (16,'mq1','�������� Q �1');
insert into monitor_descr (id,name,descr) values (17,'mq2','�������� Q �2');
insert into monitor_descr (id,name,descr) values (18,'mq3','�������� Q �3');
insert into monitor_descr (id,name,descr) values (19,'mss','�������� S �����');
insert into monitor_descr (id,name,descr) values (20,'ms1','�������� S �1');
insert into monitor_descr (id,name,descr) values (21,'ms2','�������� S �2');
insert into monitor_descr (id,name,descr) values (22,'ms3','�������� S �3');
insert into monitor_descr (id,name,descr) values (23,'mks','�����.�������� �����');
insert into monitor_descr (id,name,descr) values (24,'mk1','�����.�������� �1');
insert into monitor_descr (id,name,descr) values (25,'mk2','�����.�������� �2');
insert into monitor_descr (id,name,descr) values (26,'mk3','�����.�������� �3');
insert into monitor_descr (id,name,descr) values (27,'se1ai','����������� ������� �1 A-import');
insert into monitor_descr (id,name,descr) values (28,'se1ae','����������� ������� �1 A-export');
insert into monitor_descr (id,name,descr) values (29,'se1ri','����������� ������� �1 R-import');
insert into monitor_descr (id,name,descr) values (30,'se1re','����������� ������� �1 R-export');
insert into monitor_descr (id,name,descr) values (31,'se2ai','����������� ������� �2 A-import');
insert into monitor_descr (id,name,descr) values (32,'se2ae','����������� ������� �2 A-export');
insert into monitor_descr (id,name,descr) values (33,'se2ri','����������� ������� �2 R-import');
insert into monitor_descr (id,name,descr) values (34,'se2re','����������� ������� �2 R-export');
insert into monitor_descr (id,name,descr) values (35,'ise','������������ ��������');




-- �������� ������� �� ���������
-- (����������� ��� � ����� counter/mexpenses)
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
-- �������
--
CREATE TABLE street (
    id integer NOT NULL,
    name character varying(100) NOT NULL
);

--
-- ������
--
CREATE TABLE towers (
    id serial NOT NULL,
    name character varying,
    memo character varying,
    modtime timestamp without time zone DEFAULT now() NOT NULL,
    primary key (id)
);


--
-- �������
--
CREATE TABLE payments (
    id serial NOT NULL,
    cid integer,
    date date,
    prev1 decimal,
    prev2 decimal,
    current1 decimal,
    current2 decimal,
    amount decimal,
    balance decimal,
    modtime timestamp without time zone DEFAULT now() NOT NULL,
    primary key (id)
);
CREATE INDEX payments_date_i ON payments (date ASC);
CREATE INDEX payments_cid_i ON payments (cid);

CREATE TABLE tariff (
    id serial NOT NULL,
    t1 decimal,
    t2 decimal,
    sdate date,           -- ������ �������� ������
    primary key (id)
);
INSERT INTO tariff (t1,t2,sdate) VALUES (4.11,1.39,'2012-07-01');


CREATE TABLE users (
	id integer NOT NULL,
	fname character varying(255),
	mname character varying(255),
	lname character varying(255),
	status character varying,
	birthday date,
	passport character varying,
	address character varying,	-- ����� ��������
	active integer,
	memo character varying,
	usr character varying,
	modtime timestamp without time zone DEFAULT now(),
	primary key (id)
);









