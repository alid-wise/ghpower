/* Javascript Calendar
(c) kdg http://HTMLWEB.RU/java/example/calendar_kdg.php */

var _Calendar=function(){
var _Calendar={
now:null,
sccd:null,
sccm:null,
sccy:null,
ccm:null,
ccy:null,
updobj:null,
mn:new Array('Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентрябрь','Октябрь','Ноябрь','Декабрь'),
mnn:new Array('31','28','31','30','31','30','31','31','30','31','30','31'),
mnl:new Array('31','29','31','30','31','30','31','31','30','31','30','31'),
calvalarr:new Array(42),

$:function(objID)
{
    if(document.getElementById){return document.getElementById(objID);}
    else if(document.all){return document.all[objID];}
    else if(document.layers){return document.layers[objID];}
},

checkClick:function(e){
	e?evt=e:evt=event;
	CSE=evt.target?evt.target:evt.srcElement;
	if (_Calendar.$('fc'))
		if (!_Calendar.isChild(CSE,_Calendar.$('fc')))
			_Calendar.$('fc').style.display='none';
},

isChild:function(s,d){
	while(s){
		if (s==d)
			return true;
		s=s.parentNode;
	}
	return false;
},

Left:function(obj){
	var curleft = 0;
	if (obj.offsetParent)
	{
		while (obj.offsetParent)
		{
			curleft += obj.offsetLeft
			obj = obj.offsetParent;
		}
	}
	else if (obj.x)
		curleft += obj.x;
	return curleft;
},

Top:function(obj){
	var curtop = 0;
	if (obj.offsetParent)
	{
		while (obj.offsetParent)
		{
			curtop += obj.offsetTop
			obj = obj.offsetParent;
		}
	}
	else if (obj.y)
		curtop += obj.y;
	return curtop;
},


lcs:function(ielem){
	_Calendar.updobj=ielem;
	_Calendar.$('fc').style.left=_Calendar.Left(ielem);
	_Calendar.$('fc').style.top=_Calendar.Top(ielem)+ielem.offsetHeight;
	_Calendar.$('fc').style.display='';

	// First check date is valid
	curdt=ielem.value;
	curdtarr=curdt.split('-');
	isdt=true;
	for(var k=0;k<curdtarr.length;k++){
		if (isNaN(curdtarr[k]))
			isdt=false;
	}
	if (isdt&(curdtarr.length==3)){
		_Calendar.ccm=curdtarr[1]-1;
		_Calendar.ccy=curdtarr[2];
		_Calendar.prepcalendar(curdtarr[0],curdtarr[1]-1,curdtarr[2]);
	}

},

evtTgt:function(e)
{
	var el;
	if(e.target)el=e.target;
	else if(e.srcElement)el=e.srcElement;
	if(el.nodeType==3)el=el.parentNode; // defeat Safari bug
	return el;
},
EvtObj:function(e){if(!e)e=window.event;return e;},

cs_over:function(e){
	_Calendar.evtTgt(_Calendar.EvtObj(e)).style.background='#FFEBCC';
},

cs_out:function(e){
	_Calendar.evtTgt(_Calendar.EvtObj(e)).style.background='#FFFFFF';
},

cs_click:function(e){
	_Calendar.updobj.value=_Calendar.calvalarr[_Calendar.evtTgt(_Calendar.EvtObj(e)).id.substring(2,_Calendar.evtTgt(_Calendar.EvtObj(e)).id.length)];
	_Calendar.$('fc').style.display='none';
},

f_cps:function(obj){
	obj.style.background='#FFFFFF';
	obj.style.font='10px Arial';
	obj.style.color='#333333';
	obj.style.textAlign='center';
	obj.style.textDecoration='none';
	obj.style.border='1px solid #606060';
	obj.style.cursor='pointer';
},

prepcalendar:function( hd, cm, cy ){
	_Calendar.now=new Date();
	sd=_Calendar.now.getDate();
	md=Math.max(cy,_Calendar.now.getFullYear());
	td=new Date();
	td.setDate(1);
	td.setFullYear(cy);
	td.setMonth(cm);
	cd=td.getDay(); // день недели
	if(cd==0)cd=6; else cd--;

	vd='';
	for(var m=0;m<12;m++) vd=vd+'<option value="'+m+'"'+(m==cm?' selected':'')+'>'+_Calendar.mn[m]+'</option>'; // цикл по месяцам

	d='';
	for(var y=cy-40;y<=md;y++)   d=d+'<option value="'+y+'"'+(y==cy?' selected':'')+'>'+y+'</option>'; // цикл по годам
	_Calendar.$('mns').innerHTML=' <select onChange="_Calendar.cmonth(this);">' + vd + '</select><select onChange="_Calendar.cyear(this);">' + d + '</select>'; // текущий месяц и год

	marr=((cy%4)==0)?_Calendar.mnl:_Calendar.mnn;

	for(var d=1;d<=42;d++)// цикл по всем ячейкам таблицы
	{	d=parseInt(d);
		vd=_Calendar.$ ( 'cv' + d );
		_Calendar.f_cps ( vd );
		if ((d >= (cd -(-1)))&&(d<=cd-(-marr[cm]))) {
			dd = new Date(d-cd,cm,cy);
			if(d==36)_Calendar.$("last_table_tr").style.display="";
			vd.onmouseover=_Calendar.cs_over;
			vd.onmouseout=_Calendar.cs_out;
			vd.onclick=_Calendar.cs_click;

			if (_Calendar.sccm == cm && _Calendar.sccd == (d-cd) && _Calendar.sccy == cy)
				vd.style.color='#FF9900'; // сегодня
			/*else if(dd.getDay()==6||dd.getDay()==0)
				vd.style.color='#FF0000'; // выходной*/

			vd.innerHTML=d-cd;

			_Calendar.calvalarr[d]=_Calendar.addnull(d-cd,cm-(-1),cy);
		}
		else
		{
			if(d==36){_Calendar.$("last_table_tr").style.display="none"; break;}
			vd.innerHTML='&nbsp;';
			vd.onmouseover=null;
			vd.onmouseout=null;
			vd.onclick=null;
			vd.style.cursor='default';
		}
	}
},

caddm:function(){
	marr=((_Calendar.ccy%4)==0)?_Calendar.mnl:_Calendar.mnn;

	_Calendar.ccm+=1;
	if (_Calendar.ccm>=12){
		_Calendar.ccm=0;
		_Calendar.ccy++;
	}
	_Calendar.prepcalendar('',_Calendar.ccm,_Calendar.ccy);
},

csubm:function(){
	marr=((_Calendar.ccy%4)==0)?_Calendar.mnl:_Calendar.mnn;

	_Calendar.ccm-=1;
	if (_Calendar.ccm<0){
		_Calendar.ccm=11;
		_Calendar.ccy--;
	}
	_Calendar.prepcalendar('',_Calendar.ccm,_Calendar.ccy);
},

cmonth:function(t){
    _Calendar.ccm=t.options[t.selectedIndex].value;
    _Calendar.prepcalendar('',_Calendar.ccm,_Calendar.ccy);
},

cyear:function(t){
	_Calendar.ccy=t.options[t.selectedIndex].value;
	_Calendar.prepcalendar('',_Calendar.ccm,_Calendar.ccy);
},

today:function(){
	_Calendar.updobj.value=_Calendar.addnull(_Calendar.now.getDate(),_Calendar.now.getMonth()+1,_Calendar.now.getFullYear());
	_Calendar.$('fc').style.display='none';
	_Calendar.prepcalendar('',_Calendar.sccm,_Calendar.sccy);
},

addnull:function(d,m,y){
	var d0='',m0='';
	if (d<10)d0='0';
	if (m<10)m0='0';

	return ''+d0+d+'-'+m0+m+'-'+y;
}
}

_Calendar.now=n=new Date;
_Calendar.sccd=n.getDate();
_Calendar.sccm=n.getMonth();
_Calendar.sccy=n.getFullYear();
_Calendar.ccm=n.getMonth();
_Calendar.ccy=n.getFullYear();

document.write('<table id="fc" style="position:absolute;border-collapse:collapse;background:#FFFFFF;border:1px solid #303030;display:none;-moz-user-select:none;-khtml-user-select:none;user-select:none;" cellpadding=2>');
document.write('<tr style="font:bold 13px Arial"><td style="cursor:pointer;font-size:15px" onclick="_Calendar.csubm()">&laquo;</td><td colspan="5" id="mns" align="center"></td><td align="right" style="cursor:pointer;font-size:15px" onclick="_Calendar.caddm()">&raquo;</td></tr>');
document.write('<tr style="background:#FF9900;font:12px Arial;color:#FFFFFF"><td align=center>П</td><td align=center>В</td><td align=center>С</td><td align=center>Ч</td><td align=center>П</td><td align=center>С</td><td align=center>В</td></tr>');
for(var kk=1;kk<=6;kk++){
	//document.write('<tr>');
	if(kk==6)
		document.write('<tr id="last_table_tr">')
	else
		document.write('<tr>');
	for(var tt=1;tt<=7;tt++){
		num=7 * (kk-1) - (-tt);
		document.write('<td id="cv' + num + '" style="width:18px;height:18px">&nbsp;</td>');
	}
	document.write('</tr>');
}
document.write('<tr><td colspan="7" align="center" style="cursor:pointer;font:13px Arial;background:#FFC266" onclick="_Calendar.today()">Сегодня: '+_Calendar.addnull(_Calendar.sccd,_Calendar.sccm+1,_Calendar.sccy)+'</td></tr>');
document.write('</table>');

document.all?document.attachEvent('onclick',_Calendar.checkClick):document.addEventListener('click',_Calendar.checkClick,false);

_Calendar.prepcalendar('',_Calendar.ccm,_Calendar.ccy);

return _Calendar;
}();