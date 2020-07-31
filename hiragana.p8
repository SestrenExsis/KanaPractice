pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- hiragana
-- by sestrenexsis
-- github.com/sestrenexsis/kanapractice

-- code based on shodo
--  by ryosuke mihara
--  github.com/oinariman/shodo
-- pixel art based on art by hiro (hamstone)
--  assetstore.unity.com/packages/2d/fonts/sprite-font-japanese-kana-43862

-- description:
-- * ink drying

-- quiz mode:
-- * choose a random kana
-- * ask the player to draw it

_version=1
cartdata("sestrenexsis_hiragana_".._version)

-- the demem() and enmem() 
-- functions are for compactly
-- storing data about the 10
-- most recent read and write
-- attempts for each kana
-- in local storage
-- the portion before the 
-- decimal stores data about 
-- reads
-- the portion after the 
-- decimal stores data about 
-- writes

-- 0000 0000 0000 0000 . 0000 0000 0000 0000
-- -a-- -bbb bbbb bbbb . -c-- -ddd dddd dddd
-- ==== ==== ==== ==== . ==== ==== ==== ====
-- a: included in read deck         1 bit(s)
-- b: last ten read attempts       11 bit(s)
-- c: included in write deck        1 bit(s)
-- d: last ten write attempts      11 bit(s)

function demem(
	v  -- value       : number
	)  -- return type : table
	-- create read history
	local rtbl={}
	local ract=false
	local rval=flr(v)%0x8000
	if (rval&0x4000>0) ract=true
	rval=rval&0x07ff
	while rval>0 do
		add(rtbl,rval%2)
		rval=flr(rval>>1)
	end
	deli(rtbl,#rtbl)
	-- create write history
	local wtbl={}
	local wact=false
	local wval=flr((v<<16)%0x8000)
	if (wval&0x4000>0) wact=true
	wval=wval&0x07ff
	while wval>0 do
		add(wtbl,wval%2)
		wval=flr(wval>>1)
	end
	deli(wtbl,#wtbl)
	local res={
		r=ract,  -- in read deck
		rh=rtbl, -- read attempts
		w=wact,  -- in write deck
		wh=wtbl  -- write attempts
	}
	return res
end

function enmem(
	k   -- kana : table
	)  -- return type : number
	local res=0
	for i=1,min(10,#k.reads) do
		local v=k.reads[i]<<(i-1)
		res+=v
	end
	res+=1<<#k.reads
	if (k.read) res+=0x4000
	for i=1,min(10,#k.writes) do
		local v=k.writes[i]>>(17-i)
		res+=v
	end
	res+=1>>(16-#k.writes)
	if (k.write) res+=0x0.4000
	return res
end

function testmem(v,r,rh,w,wh)
	local k={
		read=r,
		reads=rh,
		write=w,
		writes=wh
	}
	print(tostr(enmem(k),true))
	print(tostr(v,true))
	assert(enmem(k)==v)
	local tbl=demem(v)
	--print(#tbl.rh.." "..#rh)
	assert(#tbl.rh==#rh)
	for i=1,#tbl.rh do
		--print(tbl.rh[i].." "..rh[i])
		assert(tbl.rh[i]==rh[i])
	end
	--print(#tbl.wh.." "..#wh)
	assert(#tbl.wh==#wh)
	for i=1,#tbl.wh do
		--print(tbl.wh[i].." "..wh[i])
		assert(tbl.wh[i]==wh[i])
	end
end

--[[
testmem(0x00cd.00cd,
	false,{1,0,1,1,0,0,1},
	false,{1,0,1,1,0,0,1}
	)
testmem(0x07ff.0002,
	false,{1,1,1,1,1,1,1,1,1,1},
	false,{0}
	)
]]--
-->8
-- constants and constructors

-- accl : speedup when moving
-- drag : slowdown over time
-- pull : slowdown on paper
-- pool : ink spread over time
-- maxr : ink max spread
-- dryt : time to finish drying

_accl=0.175
_drag=0.100
_pull=0.650
_pool=0.400
_maxr=5.000
_dryt={3.4,0.2,0.2,0.2}
_mous=false

function point(xpos,ypos)
	local res={
		x=xpos,
		y=ypos
	}
	return res
end

function getstrokes(k)
	local res={}
	local n={
		-- orthogonal
		-1, 0, 1, 0, 0,-1, 0, 1,
		-- diagonal
		-1,-1, 1,-1,-1, 1, 1, 1
	}
	local px=-1
	local py=-1
	-- scan through all frames
	local points={}
	for id in all(k.frames) do
		-- find start of stroke
		local found=false
		local sx=8*(id%16)
		local sy=8*flr(id/16)
		for x=0,7 do
			for y=0,7 do
				if sget(sx+x,sy+y)==7 then
					-- start of new stroke
					if x!=px or y!=py then
						if #points>0 then
							add(res,points)
						end
						points={}
					end
					px=x
					py=y
					found=true
					break
				end
				if (found) break
			end
		 if (found) break
		end
		-- follow stroke path
		local found=true
		local lx=0
		local ly=0
		local lx2=0
		local ly2=0
		while found do
			local pt=point(px,py)
			add(points,pt)
			found=false
			-- find neighbors
			for i=1,#n,2 do
				local nx=px+n[i]
				local ny=py+n[i+1]
				if nx>=0 and nx<=7 and
				   ny>=0 and ny<=7 and
				   (nx!=lx or ny!=ly) and
				   (nx!=lx2 or ny!=ly2) then
					if sget(sx+nx,sy+ny)==14 then
						lx2=lx
						ly2=ly
						lx=px
						ly=py
						px=nx
						py=ny
						found=true
						break
					end
				end
			end -- for each neighbor
		end -- while neighbor found
	end -- for each stroke frame
	if #points>0 then
		add(res,points)
	end
	return res
end

function kana(
	n, -- name    : str
	i, -- index   : number
	r, -- row pos : number
	c, -- col pos : number
	f  -- frames  : table
	) -- return type: table
	local rw=demem(dget(i))
	local res={
		name=n,
		index=i,
		row=r,
		col=c,
		frames=f,
		read=rw.r,
		reads=rw.rh,
		write=rw.w,
		writes=rw.wh
	}
	res.strokes=getstrokes(res)
	return res
end

-- kana info
_kanatbl={
a=kana("a",0,0,0,{0,1,2,3}),
i=kana("i",1,0,1,{4,5}),
u=kana("u",2,0,2,{6,7}),
e=kana("e",3,0,3,{8,9,10,11}),
o=kana("o",4,0,4,{12,13,14,15}),
ka=kana("ka",5,1,0,{16,17,18}),
ki=kana("ki",6,1,1,{19,20,21,22}),
ku=kana("ku",7,1,2,{23}),
ke=kana("ke",8,1,3,{24,25,26}),
ko=kana("ko",9,1,4,{27,28}),
sa=kana("sa",10,2,0,{29,30,31}),
shi=kana("shi",11,2,1,{32}),
su=kana("su",12,2,2,{33,34,35}),
se=kana("se",13,2,3,{36,37,38}),
so=kana("so",14,2,4,{39,40,41,42}),
ta=kana("ta",15,3,0,{43,44,45,46}),
chi=kana("chi",16,3,1,{47,48,49}),
tsu=kana("tsu",17,3,2,{50}),
te=kana("te",18,3,3,{51,52}),
to=kana("to",19,3,4,{53,54}),
na=kana("na",20,4,0,{55,56,57,58,59}),
ni=kana("ni",21,4,1,{60,61,62}),
nu=kana("nu",22,4,2,{63,64,65,66}),
ne=kana("ne",23,4,3,{67,68,69,70,71}),
no=kana("no",24,4,4,{72,73}),
ha=kana("ha",25,5,0,{74,75,76,77}),
hi=kana("hi",26,5,1,{78,79,80}),
fu=kana("fu",27,5,2,{81,82,83,84}),
he=kana("he",28,5,3,{85}),
ho=kana("ho",29,5,4,{86,87,88,89,90}),
ma=kana("ma",30,6,0,{91,92,93,94}),
mi=kana("mi",31,6,1,{95,96,97,98}),
mu=kana("mu",32,6,2,{99,100,101,102}),
me=kana("me",33,6,3,{103,104,105}),
mo=kana("mo",34,6,4,{106,107,108}),
ya=kana("ya",35,7,0,{109,110,111}),
yu=kana("yu",36,7,2,{112,113,114}),
yo=kana("yo",37,7,4,{115,116,117}),
ra=kana("ra",38,8,0,{118,119,120}),
ri=kana("ri",39,8,1,{121,122}),
ru=kana("ru",40,8,2,{123,124,125,126}),
re=kana("re",41,8,3,{127,128,129,130,131}),
ro=kana("ro",42,8,4,{132,133,134}),
wa=kana("wa",43,9,0,{135,136,137,138}),
wo=kana("wo",44,9,4,{139,140,141,142}),
n=kana("n",45,10,0,{143,144})
}
_kanakey={
	"a","i","u","e","o",
	"ka","ki","ku","ke","ko",
	"sa","shi","su","se","so",
	"ta","chi","tsu","te","to",
	"na","ni","nu","ne","no",
	"ha","hi","fu","he","ho",
	"ma","mi","mu","me","mo",
	"ya","yu","yo",
	"ra","ri","ru","re","ro",
	"wa","wo",
	"n"
}

_c_cnv=7 -- canvas color
_c_cut=7*16+6 -- watermark color
_c_nib=1 -- nib color
_c_wet=0 -- wet ink color
_c_dry=5 -- dry ink color
_c_ink=_c_wet*16+_c_dry
_fills={
	0b1111111111111111,
	0b0101111101011111,
	0b0101101001011010,
	0b0000101000001010,
	0b0000000000000000
}

function brush(
	x, -- x pos   : number
	y  -- y pos   : number
	) -- return type: table
	local position=point(x,y)
	local velocity=point(0,0)
	local lastpos=point(x,y)
	local res={
		pos=position,
		vel=velocity,
		lpos=lastpos,
		r=0,
		on=false,
		lon=false,
		press=function(self)
			local res=self.on and not self.lon
			return res
		end
	}
	-- r     : brush radius
	-- on    : using brush
	-- lon   : last using brush
	-- press : brush was just pressed
	return res
end

function brushphysics(
	b,   -- brush : brush
	drag -- should move be slowed
	) -- return type: nil
	if b.vel.x>0 then
		b.vel.x-=_drag
		b.vel.x=max(0,b.vel.x)
	else
		b.vel.x+=_drag
		b.vel.x=min(0,b.vel.x)
	end
	if b.vel.y>0 then
		b.vel.y-=_drag
		b.vel.y=max(0,b.vel.y)
	else
		b.vel.y+=_drag
		b.vel.y=min(0,b.vel.y)
	end
	if drag then
		local multi=1.000
		if (b.on) multi=_pull
		if (b.vel.x~=0) then
			b.pos.x+=multi*b.vel.x
		end
		if (_brush.vel.y~=0) then
			b.pos.y+=multi*b.vel.y
		end
	end
	-- keep pen in bounds
	b.pos.x=mid(0,b.pos.x,127)
	b.pos.y=mid(0,b.pos.y,127)
	-- update ink effects
	if b.on then
		b.r+=_pool
	else
		b.r-=_pool
	end
	b.r=mid(0,b.r,_maxr)
	b.lon=b.on
end

function inkdrop(
	position,
	amount
	)
	local res={
		pos=position,
		amt=amount,
		age=t()
	}
	return res
end
-->8
-- main functions

-- memory locations:
-- 0-45 : stats for each kana
-- 62   : previous study time
-- 63   : memory version

function entime()
	local res=0
	res+=ceil(365.25*(stat(80)%100))
	local leap=stat(80)%4==0
	local julian={
		 0,  31, 59,
		 90,120,151,
		181,212,243,
		273,304,334
		}
	res+=julian[stat(81)]
	if (leap and stat(81)>2) res+=1
	res+=stat(82)-1
	res+=stat(83)/24
	res+=stat(84)/24/60
	res+=stat(85)/24/60/60
	return res
end

function detime(tm)
	local dy=flr(tm)
	local hr=flr(tm*24)%24
	local mi=flr(tm*24*60)%60
	local sc=flr(tm*24*60*60)%60
	local res=dy.."d "
	res=res..hr.."h "
	res=res..mi.."m "
	res=res..sc.."s"
	return res
end

function _init()
	if dget(63)==0 then
		-- if this is first load
		-- add a,e,i,o,u to decks
		dset(0,0x4000.4000)
		dset(1,0x4000.4000)
		dset(2,0x4000.4000)
		dset(3,0x4000.4000)
		dset(4,0x4000.4000)
	end
	-- store previous study time
	_logtm=dget(62)
	dset(63,_version)
	inittitle()
end

function studytime()
	dset(62,entime())
end

function initscreen()
	initfn()
end

function _update()
	updatefn()
end

function _draw()
	drawfn()
end

-- helper functions

function drawmsgs()
	if _lmsg!=nil and #_lmsg>0 then
		print(_lmsg,3,122,1)
	end
	if _rmsg!=nil and #_rmsg>0 then
		local x=128-4*#_rmsg-4
		print(_rmsg,x,122,1)
	end
end

function hamming(num)
	local res=0
	while num>0 do
		if (num%2==1) res+=1
		num=flr(num/2)
	end
	return res
end

function sum(tbl)
	local res=0
	for num in all(tbl) do
		res+=num
	end
	return res
end

function betweens(pt0,pt1)
	local x0=flr(pt0.x)
	local y0=flr(pt0.y)
	local x1=flr(pt1.x)
	local y1=flr(pt1.y)
	local w=abs(x1-x0)
	local h=abs(y1-y0)
	local dx=0
	if w>0 then
		dx=(x1-x0)/w
	end
	local dy=0
	if h>0 then
		dy=(y1-y0)/h
	end
	local e=max(w,h)
	local dw=2*w
	local dh=2*h
	local x=x0
	local y=y0
	local res={}
	if w>=h then
		while x!=x1 do
			x+=dx
			e+=dh
			if e>=dw then
				e-=dw
				y+=dy
			end
			add(res,point(x,y))
		end
	else
		while y!=y1 do
			y+=dy
			e+=dw
			if e>=dh then
				e-=dh
				x+=dx
			end
			add(res,point(x,y))
		end
	end
	return res
end

function drawkana(
	k,   -- kana
	x,y, -- upper left corner
	s,   -- scale in pixels
	c,   -- color
	i    -- progression counter
	) -- return type: bool
	if (c==nil) c=_c_cut
	if (i==nil) i=64
	for pts in all(k.strokes) do
		local pt0=nil
		local pt1=nil
		for pt in all(pts) do
			i-=1
			if (i<=0) break
			if s==1 then
				pset(x+pt.x,y+pt.y,c)
			else
				local top=y+s*pt.y
				local lft=x+s*pt.x
				local btm=top+s-1
				local rgt=lft+s-1
				pt1=point(lft,top)
				if pt0~=nil then
					local ps=betweens(pt0,pt1)
					for p in all(ps) do
						top=p.y+0.25*s
						lft=p.x+0.25*s
						btm=top+0.5*s
						rgt=lft+0.5*s
						rectfill(lft,top,rgt,btm,c)
					end
				end
			end
			pt0=pt1
		end
		i-=5
		if (i<=0) break
	end
	local res=(i>0)
	return res
end
-->8
-- title/menu screens

-- title screen

function inittitle()
	palt()
	_lmsg=""
	_rmsg="main menu ❎"
	initfn=inittitle
	updatefn=updatetitle
	drawfn=drawtitle
end

function updatetitle()
	if btnp(❎) then
		initmenu()
	end
end

function drawtitle()
	cls()
	pal()
	if _logtm==0 then
		print("welcome!")
	else
		local curtm=entime()
		local tm=detime(curtm-_logtm)
		print("last studied "..tm.." ago")
	end
	drawmsgs()
	pal(1,3)
	pal(2,7)
	spr(196,32,38,8,3)
	print("v".._version,1,122)
end

-- menu screen

function initmenu()
	palt()
	initfn=initmenu
	updatefn=updatemenu
	drawfn=drawmenu
	_menuindex=1
	_menu={
		"study read deck ",
		"study write deck",
		"practice reading",
		"practice writing",
		"sandbox"
	}
	_lmsg="⬆️⬇️ choose"
	_rmsg="open ❎"
end

function updatemenu()
	local lastidx=_menuindex
	if (btnp(⬆️)) _menuindex-=1
	if (btnp(⬇️)) _menuindex+=1
	if (lastidx!=_menuindex) sfx(63)
	_menuindex=1+(_menuindex-1)%#_menu
	if btnp(❎) then
		sfx(61)
		if (_menuindex==1) initreaddeck()
		if (_menuindex==2) initwritedeck()
		if (_menuindex==3) initread()
		if (_menuindex==4) initwrite()
		if (_menuindex==5) initsandbox()
	end
end

function drawmenu()
	cls()
	for i,text in ipairs(_menu) do
		local bc=7
		local fc=3
		if i==_menuindex then
			bc=3
			fc=7
		end
		local x=28
		local y=34+13*i
		rectfill(x+1,y,x+70,y+11,bc)
		rectfill(x,y+1,x+71,y+10,bc)
		print(text,33,y+3,fc)
	end
	drawmsgs()
end
-->8
-- study deck screens

-- study read deck screen

function initreaddeck()
	initfn=initreaddeck
	updatefn=updatereaddeck
	drawfn=drawreaddeck
	_cursor=point(0,0)
	_cols=5
	_rows=11
	_sk=nil -- selected kana
	_decksz=0
	_lmsg="🅾️ exit"
	_rmsg=""
	_msg_add="add card ❎"
	_msg_del="remove card ❎"
	_msg_lst="need 2+ cards"
end

function updatereaddeck()
	_decksz=0
	for n,k in pairs(_kanatbl) do
		if (k.read) _decksz+=1
	end
	local lx=_cursor.x
	local ly=_cursor.y
	if (btnp(⬆️)) _cursor.y-=1
	if (btnp(⬇️)) _cursor.y+=1
	if (btnp(⬅️)) _cursor.x-=1
	if (btnp(➡️)) _cursor.x+=1
	_cursor.x=_cursor.x%_cols
	_cursor.y=_cursor.y%_rows
	local cx=_cursor.x
	local cy=_cursor.y
	if lx!=cx or ly!=cy then
		sfx(58)
	end
	if btnp(❎) and _sk!=nil then
		if _decksz>2 or not _sk.read then
			_sk.read=not _sk.read
			dset(_sk.index,enmem(_sk))
			if _sk.read then
				sfx(57)
			else
				sfx(59)
			end
		end
	end
	if (btnp(🅾️)) initmenu()
	if _sk==nil then
		_rmsg=""
	elseif _sk.read then
		if _decksz<3 then
			_rmsg=_msg_lst
		else
			_rmsg=_msg_del
		end
	else
		_rmsg=_msg_add
	end
end

function drawreaddeck()
	cls()
	local cx=_cursor.x
	local cy=_cursor.y
	local s=1
	_sk=nil
	for n,k in pairs(_kanatbl) do
		local x=1+(1.5*s*8)*k.col
		local y=1+(1.3*s*8)*k.row
		local wt=sum(k.reads)
		local bc=0
		local fc=5
		if (#k.reads>0) fc=8
		if (wt>= 1) fc=9
		if (wt>= 3) fc=10
		if (wt>= 6) fc=11
		if (wt>=10) fc=3
		if k.read then
			bc=fc
			fc=7
			rectfill(x,y,x+7,y+7,bc)
		end
		drawkana(k,x,y,s,fc)
		if k.col==cx and k.row==cy then
			_sk=k
			rect(x-1,y-1,x+8,y+8,7)
		end
	end
	if _sk==nil then
		x=1+(1.5*s*8)*cx
		y=1+(1.3*s*8)*cy
		rectfill(x,y,x+7,y+7,1)
	else
		rect(60,1,61+66,2+66,6)
		drawkana(_sk,62,3,8,_c_cut)
		local i=(12*t())%64
		i=mid(0,i-16,64)
		drawkana(_sk,62,3,8,_c_dry,i)
		print(_sk.name,61,70,6)
		local m=dget(_sk.index)
		print(tostr(m,true),61,78,6)
		local mt=demem(m)
		local act="-"
		if (mt.r) act="+"
		print(act.."r",61,86,12)
		for i=1,#mt.rh do
			print(mt.rh[i],65+4*i,86,6)
		end
	end
	drawmsgs()
end

-- study write deck screen

function initwritedeck()
	initfn=initwritedeck
	updatefn=updatewritedeck
	drawfn=drawwritedeck
	_cursor=point(0,0)
	_cols=5
	_rows=11
	_sk=nil -- selected kana
	_decksz=0
	_lmsg="🅾️ exit"
	_rmsg=""
	_msg_add="add card ❎"
	_msg_del="remove card ❎"
	_msg_lst="need 2+ cards"
end

function updatewritedeck()
	_decksz=0
	for n,k in pairs(_kanatbl) do
		if (k.write) _decksz+=1
	end
	local lx=_cursor.x
	local ly=_cursor.y
	if (btnp(⬆️)) _cursor.y-=1
	if (btnp(⬇️)) _cursor.y+=1
	if (btnp(⬅️)) _cursor.x-=1
	if (btnp(➡️)) _cursor.x+=1
	_cursor.x=_cursor.x%_cols
	_cursor.y=_cursor.y%_rows
	local cx=_cursor.x
	local cy=_cursor.y
	if lx!=cx or ly!=cy then
		sfx(58)
	end
	if btnp(❎) and _sk!=nil then
		if _decksz>2 or not _sk.write then
			_sk.write=not _sk.write
			dset(_sk.index,enmem(_sk))
			if _sk.write then
				sfx(57)
			else
				sfx(59)
			end
		end
	end
	if (btnp(🅾️)) initmenu()
	if _sk==nil then
		_rmsg=""
	elseif _sk.write then
		if _decksz<3 then
			_rmsg=_msg_lst
		else
			_rmsg=_msg_del
		end
	else
		_rmsg=_msg_add
	end
end

function drawwritedeck()
	cls()
	local cx=_cursor.x
	local cy=_cursor.y
	local s=1
	_sk=nil
	for n,k in pairs(_kanatbl) do
		local x=1+(1.5*s*8)*k.col
		local y=1+(1.3*s*8)*k.row
		local wt=sum(k.writes)
		local bc=0
		local fc=5
		if (#k.writes>0) fc=8
		if (wt>= 1) fc=9
		if (wt>= 3) fc=10
		if (wt>= 6) fc=11
		if (wt>=10) fc=3
		if k.write then
			bc=fc
			fc=7
			rectfill(x,y,x+7,y+7,bc)
		end
		drawkana(k,x,y,s,fc)
		if k.col==cx and k.row==cy then
			_sk=k
			rect(x-1,y-1,x+8,y+8,7)
		end
	end
	if _sk==nil then
		x=(1.5*s*8)*cx
		y=(1.3*s*8)*cy
		rectfill(x,y,x+7,y+7,1)
	else
		rect(60,1,61+66,2+66,6)
		drawkana(_sk,62,3,8,_c_cut)
		local i=(12*t())%64
		i=mid(0,i-16,64)
		drawkana(_sk,62,3,8,_c_dry,i)
		print(_sk.name,61,70,6)
		local m=dget(_sk.index)
		print(tostr(m,true),61,78,6)
		local mt=demem(m)
		local act="-"
		if (mt.w) act="+"
		print(act.."w",61,86,12)
		for i=1,#mt.wh do
			print(mt.wh[i],65+4*i,86,6)
		end
	end
	drawmsgs()
end
-->8
-- read screen

-- states
-- * guess : show symbol
-- * check : show name
-- * stats : show stats

function initread()
	initfn=nextread
	updatefn=updateread
	drawfn=drawread
	_errors=0
	_guesses=0
	_lidx=0
	_deck={}
	for i=1,#_kanakey do
		local key=_kanakey[i]
		local kana=_kanatbl[key]
		if kana.read then
			add(_deck,kana.name)
		end
	end
	nextread()
end

function nextread()
	local idx=0
	repeat
		idx=flr(rnd(#_deck))+1
	until idx!=_lidx
	_lidx=idx
	_kana=_kanatbl[_deck[idx]]
	_state="guess"
end

function updateread()
	-- get input
	if _state=="guess" then
		_lmsg=""
		_rmsg="check ❎"
		if btnp(❎) or btnp(🅾️) then
			_state="check"
		end
	elseif _state=="check" then
		_lmsg="🅾️ no"
		_rmsg="yes ❎"
		local guess=-1
		if btnp(❎) then
			-- you got it right
			guess=1
			_state="stats"
			_guesses+=1
			studytime()
			sfx(57)
		elseif btnp(🅾️) then
			-- you got it wrong
			guess=0
			_state="stats"
			_errors+=1
			_guesses+=1
			studytime()
			sfx(59)
		end
		if guess>=0 then
			local m=dget(_kana.index)
			local rw=demem(m)
			add(rw.rh,guess,1)
			while (#rw.rh>10) do
				rw.rh[#rw.rh]=nil
			end
			_kana.reads=rw.rh
			m=enmem(_kana)
			dset(_kana.index,m)
		end
	elseif _state=="stats" then
		_lmsg="🅾️ exit"
		_rmsg="read another ❎"
		if btnp(❎) then
			initscreen()
			return
		elseif btnp(🅾️) then
			initmenu()
			return
		end
	end
end

function drawread()
	cls(_c_cnv)
	local k=_kana
	drawkana(k,62,3,8,_c_cut)
	if _state=="guess" then
		cursor(1,96,1)
		print("say the kana out loud")
	elseif _state=="check" then
		cursor(1,84,1)
		print("the answer was "..k.name)
		print("did you get it right?")
	elseif _state=="stats" then
		cursor(1,90,1)
		local correct=_guesses-_errors
		print(correct.." / ".._guesses)
	end
	drawmsgs()
end
-->8
-- write screen

-- states
-- * guess : show name
-- * check : show stroke order
-- * stats : show stats

function initwrite()
	initfn=nextwrite
	updatefn=updatewrite
	drawfn=drawwrite
	palt(0,false)
	palt(7,true)
	_errors=0
	_guesses=0
	_lidx=0
	_deck={}
	for i=1,#_kanakey do
		local key=_kanakey[i]
		local kana=_kanatbl[key]
		if kana.write then
			add(_deck,kana.name)
		end
	end
	_brush=brush(64,64)
	nextwrite()
end

function nextwrite()
	local idx=0
	repeat
		idx=flr(rnd(#_deck))+1
	until idx!=_lidx
	_lidx=idx
	_kana=_kanatbl[_deck[idx]]
	_brush.lon=false
	_brush.on=false
	_lines=0
	_inks={{}}
	_state="guess"
	_cheat=false
end

function updatewriteguess()
	_brush.lpos.x=_brush.pos.x
	_brush.lpos.y=_brush.pos.y
	-- get input
	if btnp(🅾️,1) then
		_mous=not _mous
		sfx(0)
	end
	if btnp(❎,1) then
		_cheat=true
		sfx(0)
	end
	if _mous then
		poke(0x5f2d,1)
		_brush.on=btn(❎) or stat(34)==1
		_brush.pos.x=stat(32)
		_brush.pos.y=stat(33)
		_brush.vel.x=_brush.pos.x-_brush.lpos.x
		_brush.vel.y=_brush.pos.y-_brush.lpos.y
	else
		_brush.on=btn(❎)
		if (btn(⬆️)) _brush.vel.y-=_accl
		if (btn(⬇️)) _brush.vel.y+=_accl
		if (btn(⬅️)) _brush.vel.x-=_accl
		if (btn(➡️)) _brush.vel.x+=_accl
	end
	if _brush:press() then
		add(_inks,{})
		if (#_inks>2) sfx(62)
	end
	local drag=not _mous
	brushphysics(_brush,drag)
	local pts=betweens(
		_brush.lpos,
		_brush.pos
	)
	if _brush.r>0 then
		for pt in all(pts) do
			local ink=inkdrop(pt,_brush.r)
			add(_inks[#_inks],ink)
		end
	end
end

function updatewrite()
	if _state=="guess" then
		_lmsg="🅾️ finish"
		_rmsg="draw ❎"
		if btnp(🅾️) then
			_state="check"
			return
		else
			updatewriteguess()
		end
	elseif _state=="check" then
		_lmsg="🅾️ no"
		_rmsg="yes ❎"
		local guess=-1
		if btnp(❎) then
			-- you got it right
			guess=1
			_state="stats"
			_guesses+=1
			studytime()
			sfx(57)
		elseif btnp(🅾️) then
			-- you got it wrong
			guess=0
			_state="stats"
			_errors+=1
			_guesses+=1
			studytime()
			sfx(59)
		end
		if guess>=0 then
			local m=dget(_kana.index)
			local rw=demem(m)
			add(rw.wh,guess,1)
			while (#rw.wh>10) do
				rw.wh[#rw.wh]=nil
			end
			_kana.writes=rw.wh
			m=enmem(_kana)
			dset(_kana.index,m)
		end
	elseif _state=="stats" then
		_lmsg="🅾️ exit"
		_rmsg="draw another ❎"
		if btnp(❎) then
			initscreen()
			return
		elseif btnp(🅾️) then
			initmenu()
			return
		end
	end
end

function drawwrite()
	cls(_c_cnv)
	local k=_kana
	rect(23,23,120,120,6)
	-- draw cheat
	if _state=="check" then
		_cheat=true
	end
	if _cheat then
		drawkana(k,7,9,2,_c_cut)
		local i=(12*t())%64
		i=mid(0,i-16,64)
		drawkana(k,7,9,2,_c_dry,i)
		fillp(0b0101111101011111)
		drawkana(k,24,24,12)
	end
	fillp()
	-- draw ink
	for inks in all (_inks) do
		for ink in all(inks) do
			local age=t()-ink.age
			local fill=_fills[#_fills]
			for i=1,#_dryt do
				age-=_dryt[i]
				if age<0 then
					fill=_fills[i]
					break
				end
			end
			fillp(fill)
			local pos=ink.pos
			circfill(
				pos.x,pos.y,
				ink.amt,_c_ink
			)
		end
	end
	fillp()
	circfill(
		_brush.pos.x,_brush.pos.y,
		max(1,_brush.r),_c_nib
	)
	print(k.name,3,3,1)
	print(#_inks-1,112,0,1)
	if _state=="guess" then
		cursor(1,102,1)
		print("write the kana")
	elseif _state=="check" then
		cursor(1,102,1)
		print("did you get it right?")
	elseif _state=="stats" then
		cursor(1,102,1)
		local correct=_guesses-_errors
		print(correct.." / ".._guesses)
	end
	drawmsgs()
end
-->8
-- sandbox screen

-- states
-- * guess : show name
-- * check : show stroke order
-- * stats : show stats

function initsandbox()
	_maxr=2.000
	initfn=nextsandbox
	updatefn=updatesandbox
	drawfn=drawsandbox
	palt(0,false)
	palt(7,true)
	nextsandbox()
end

function nextsandbox()
	_brush=brush(64,64)
	_inks={{}}
end

function updatesandbox()
	_brush.lpos.x=_brush.pos.x
	_brush.lpos.y=_brush.pos.y
	-- get input
	if btnp(🅾️,1) then
		_mous=not _mous
		sfx(0)
	end
	if btnp(🅾️) then
		_inks[#_inks]=nil
	end
	if _mous then
		poke(0x5f2d,1)
		_brush.on=btn(❎) or stat(34)==1
		_brush.pos.x=stat(32)
		_brush.pos.y=stat(33)
		_brush.vel.x=_brush.pos.x-_brush.lpos.x
		_brush.vel.y=_brush.pos.y-_brush.lpos.y
	else
		_brush.on=btn(❎)
		if (btn(⬆️)) _brush.vel.y-=_accl
		if (btn(⬇️)) _brush.vel.y+=_accl
		if (btn(⬅️)) _brush.vel.x-=_accl
		if (btn(➡️)) _brush.vel.x+=_accl
	end
	if _brush:press() then
		add(_inks,{})
		if (#_inks>2) sfx(62)
	end
	local drag=not _mous
	brushphysics(_brush,drag)
	local pts=betweens(
		_brush.lpos,
		_brush.pos
	)
	if _brush.r>0 then
		for pt in all(pts) do
			local ink=inkdrop(pt,_brush.r)
			add(_inks[#_inks],ink)
		end
	end
end

function drawsandbox()
	pal()
	cls(_c_cnv)
	fillp()
	-- draw ink
	for inks in all (_inks) do
		for ink in all(inks) do
			local age=t()-ink.age
			local fill=_fills[#_fills]
			for i=1,#_dryt do
				age-=_dryt[i]
				if age<0 then
					fill=_fills[i]
					break
				end
			end
			fillp(fill)
			local pos=ink.pos
			circfill(
				pos.x,pos.y,
				ink.amt,_c_ink
			)
		end
	end
	fillp()
	circfill(
		_brush.pos.x,_brush.pos.y,
		max(1,_brush.r),_c_nib
	)
	pal(1,3)
	pal(2,11)
	spr(196,32,16,8,3)
end
__gfx__
000100000007000000010000000100000000000000000000007eee0000111100007e000000110000001100000011000000010010000700100001001000010070
0001eee0000e11100001111000011110070000100100007000000000000000000000000000000000000000000000000007eeee01011e1101011111010111110e
07ee0100011e010001110700011101000e0000010100000e0011110000eeee000111110007eeee00011117000111110000010000000e00000001000000010000
00011110000e111000011e100001eee00e0000010100000e01000010070000e000001000000010000000e0000000100000011110000e1110000eeee000011110
00110101001e010100e10e01007e010e0e0000010100000e00000010000000e00001110000011100000e11000001ee0000110001001e000100e1000e00110001
01011001010e10010e01e0010101100e0e0000000100000000000010000000e0001101000011010000e10100001e0e0001010001010e00010e01000e01010001
01010001010e00010e0e00010101000e00e00000001000000000010000000e0001100100011001000e10010001e00e0001010001010e00010e01000e01010001
00110010001e001000e10010001100e0000000000000000000011000000ee00001000011010000110e000011070000ee0010011000e0011000700ee000100110
000101000007010000010700000010000000100000007000000010000000070000000010000000100000007007eeee0001111100000100000007000000010000
00010010000e0010000100e0007eeee0001111100011e110001111100000e0000700001001000010010000e0000000e00000001007eeeee0011e111001111110
07eee00001e110000111100000001000000010000000e00000001000000e00000e0111110107eeee010111e10000000000000000000010000000e00000001000
00100e0000e001000010010000111110007eeee00011e1100011111000e000000e00001001000010010000e000000000000000000000010000000e0000000100
00100e0000e0010000100100000001000000010000000e000000010000e000000e00001001000010010000e00000000000000000000011000000ee0000001100
01000e000e0001000100010000100000001000000010000000700000000e00000e00001001000010010000e00000000000000000010000000100000007000000
01000e000e00010001000100000100000001000000010000000e00000000e00000e0001000100010001000e00100000007000000001000000010000000e00000
0000e00000001000000010000000110000001100000011000000ee0000000e0000e001000010010000100e000011111000eeeee00001110000011100000eee00
07000000000010000000700000001000001000100010007000700010007eee000011170000111100001111000001000000070000000100000001000000010000
0e00000007eeeee00111e1100111111000100010001000e000e0001000001000000ee000000110000001100007eeee00011e1100011111000111110007eeee00
0e000000000010000000e0000000100007eeeeee011111e101e11111011111100ee1111007eeeee00111117000010000000e0000000100000001000000010000
0e0000000011100000e1e000007e100000100010001000e000e000100000110000001100000011000000ee000010111000e0111000107ee00010111000011110
0e0000000010100000e0e0000010e0000010010000100e0000e00100000100000001000000010000000e00000010000000e00000001000000010000000100001
0e0000e000011000000e10000001e000001000000010000000e0000000100000001000000010000000e00000010000000e000000010000000100000000000001
00e00e0000001000000010000000e000001000000010000000e0000000100000001000000010000000e00000010100000e010000010100000107000000000001
000ee0000001000000010000000e00000001111000011110000eeee0000111000001110000011100000eee00010011100e001110010011100100eee000011110
00070000000100000000000007eeeeee011111170700010001000700000100000007000000010000000100000001000000000000000000000000000007000100
011e11000111110000eeee000000011000000ee000e010000010e00007eee010011e1010011110700111101001111010070011100100eee0010011100e000100
000e0000000100007e0000e0000010000000e000000e0000000e00000010000100e000010010000e00100001001000010e01000001070000010100000e111110
000e1110000eeee00000000e00010000000e00000010000000e000000010010000e001000010010000100700001001000e00000001000000010000000e101001
00e000010070000e0000000e00010000000e00000010000000e00000010001000e0001000100010001000e00010001000e000000010000000100000010e01001
000000010000000e000000e000010000000e00000010000000e0000000011110000111100001111000011e10000eeee00e000000010000000100000010e11011
000000010000000e00000e00000010000000e0000010000000e0000000100100001001000010010000e00e00007001000e0100000101000001070000010e0101
00011110000eeee000eee0000000011000000ee000011111000eeeee000111000001110000011100000ee1000001110000e01111001011110010eeee00100011
010007000100010001000100070000000100000001000000010000000100000000000000000000000000010000000100000007000000010000e0000000700000
01000e0001000100010001001e1100007eee00001117000011110000111100000017110000eeee00070111110107eeee01011e11010111117e10010011e00e00
01111e1001eeeee0011111100e1111000111110001e11100011eee00011111000e0e0010070100e00e0001000100010001000e00010001000010011000e00e10
0110e0010e10100e011010010e100010011000100e1000100ee000e001100010e00e00011001000e0e0001000100010001000e0001000100010001010e000e01
1010e001e010100e101010011e00001011000010e1000010710000e011000010e00e00011001000e0e0001000100010001000e0001000100010001000e000e00
1011e011e011101e101110e10e0001100100011001000110010001e001000ee0e0e000011010000e0e0011100100111001001e100100eee0010001000e000e00
010e01010e010e0e0101070e0e00101101001011010010110100e0e10100701ee0e00010101000e00e01010101010101010e0e010107010e010001000e000e00
00e00011007000e10010001e0e000100010001000100010001000e00010001000e00010001000e0000e01100001011000010e100001011000011100000eee000
00100000007e000000110000001100000011000000000000000111110007eeee0001111100011711000111110000100000001000000070000000100000e00000
111007000000e0000000100000001000000010000000000007000100010001000100010001000e000100010007eeeee0011111100111e110011111100e100000
001001e00000000000000000000000000000000000ee00000e011111010111110107eeee01011e110101111100001000000010000000e0000000100070100100
0100010e000100000007000000010000000100000e00e0000e000100010001000100010001000e00010001000111111007eeeee00111e1100111111000100100
01000100010010100100e010070010100100107070000e000e000100010001000100010001000e000100010000001000000010000000e0000000100001111110
01000100100010011000e001e00010011000100e000000e00e001110010111100100111001001e100100eee000111100001111000011e10000eeee0010100101
01000100100010011000e001e00010011000100e0000000e0e0101010101010101010101010e0e010107010e01001010010010100e00e010070010e010100100
001110000011000000ee000000110000001100000000000000e0100000101000001010000010e00000101000001100000011000000ee00000011000001001000
00700000001000000010000000100000007000000010000000100000070001000100070001000100000700000001000000010000007010000010100000107000
01e00000011000000110000000ee010000e1010000110100001107000e00010001000e0001000100011e110007eeee000111110000e0011000100ee000100e10
10e0010010100100101007007e10001011e0001011100010111000e00e11110001e11e00017eee00000e0000000100000001000000e11001001ee00e00111001
00e001000010010000100e000010000000e0000000100000001000000e0010100e00e010010010e0011e11000111110007eeee0001e000010ee0000e01100001
01e111100eeeeee001111e100110000001e000000e1000000110000010e01001e010e0011010100e000e0000000100000001000010e00010701000e010100010
e0e001017010010e10100e0110100010e0e0001070e000e01010001010e10001e01e00011011000e000e000e0001000100010001000e010000010e0000010100
e0e001001010010010100e00011000100e10001001e000e00110001010e00010e0e00010101000e0000e000e0001000100010001000e00000001000000010000
0e001000010010000100e0000001110000011100000eee0000111100010e01000e01010001010e000000eee00000111000001110000e00000001000000010000
0000100000001000000070000000100000007000000010000007000000010000000100000070001000100070007eeee000111170001111100011111000700000
00011100000eee000001e100000010000000e000000010000000e000000010000000100000e00010001000e00000010000000e00000001000000010000e00000
7010101010e010e01010e01000007eee0000e1110000111100100000007000000010000000e00010001000e000011000000ee000000110000001100011e10100
e10010011e00100e1100e001000010000000e000000010000010000000e000000010000000e00010001000e00011111000e1111000eeeee00011111000e01100
e10010011e00100e1100e001000010000000e00000001000011111000e11110001eeee00000e0010000100e0010000010e0000010700000e0100000101e10100
0e001010070010e00100e010001111000011e10000eeee00010000100e000010070000e000000010000000e000011001000110010001100e000ee00101e00100
00011100000eee000001e100010010100e00e010070010e00000001000000010000000e00000010000000e00001001010010010100e0010e00700e0110e00100
00001000000010000000e0000011000100ee00010011000e0001110000011100000eee00000010000000e0000001111000011110000eeee000011e1000e00011
00100000001000000010000000100000007eeee00011117000111110007000000010000000100000001000000000100000007000000010000000100000007000
001000000010000000100000001000000000010000000e000000010001e1100007eee000011170000111100007eeeee0011e111001111110011111100000e000
7eee01001117010011110e001111070000011000000ee0000001100000e1111000111110001e11100011eee000010000000e00000001000000010000000e0000
0010110000e011000010e10000101e000011111000e1111000eeeee000e100010011000100e1000100ee000e00011011000e1011000ee011000110e7000e0000
011101000e11010001ee010001110e00010000010e0000010700000e01e00001011000010e1000010710000e0010010000e0010000700e0000100e0000e11000
011001000e1001000e10010001100e0000000001000000010000000e00e0000100100001001000010010000e0000101000001010000010e00000e01000e00100
10100100e01001007010010010100e0000000001000000010000000e00e0000100100001001000010010000e0000100000001000000010000000e0000e100101
001000110010001100100011001000ee0001111000011110000eeee000e000100010001000100010001000e000000111000001110000011100000eee0e000010
000010000000001000000070000007ee00000e110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000000070010000100e0000010e00000e010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000e0000000100000001ee00000e710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e00e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01e00e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011110000211100000000000000000000000000000000000000022222222222222222220000000000000000000000000000000000000000000000000000000
02110400011304000000000000000000000000000000000000000222111222211222111222000000000000000000000000000000000000000000000000000000
0001111000028c800000000000000000000000000000000000000222121222122222122222000000000000000000000000000000000000000000000000000000
0051010100ca04080000000000000000001111111111111111111212111212122212112212111111111111111111100000000000000000000000000000000000
01011001040240080000000000000000011111111111111111111222121222122222122222111111111111111111110000000000000000000000000000000000
01010001040600080000000000000000111111111111111111111222121222211222111222111111111111111111111000000000000000000000000000000000
00110010004200800000000000000000111111111111111111111122222222222222222221111111111111111111111000000000000000000000000000000000
00010000000700000001000000010000111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000
0001eee0000e11100001111000011110111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000
07ee0100011e01000111070001110100112221222122212222221112222211122222111222221112222211122222111000000000000000000000000000000000
00011110000e111000011e100001eee0112221222122212222222122222221222222112222222122222221222222211000000000000000000000000000000000
00110101001e010100e10e01007e010e112221222122212222222122222221222222112222222122222221222222211000000000000000000000000000000000
01011001010e10010e01e0010101100e112221222122212221222122212221222111112221222122212221222122211000000000000000000000000000000000
01010001010e00010e0e00010101000e112222222122212221222122212221222122212221222122212221222122211000000000000000000000000000000000
00110010001e001000e10010001100e0112222222122212222222122222221222122212222222122212221222222211000000000000000000000000000000000
00000000000000000000000000000000112222222122212222221122222221222122212222222122212221222222211000000000000000000000000000000000
00000000000000000000000000000000112221222122212222222122222221222122212222222122212221222222211000000000000000000000000000000000
00000000000000000000000000000000112221222122212221222122212221222122212221222122212221222122211000000000000000000000000000000000
00000000000000000000000000000000112221222122212221222122212221222222212221222122212221222122211000000000000000000000000000000000
00000000000000000000000000000000112221222122212221222122212221222222212221222122212221222122211000000000000000000000000000000000
00000000000000000000000000000000112221222122212221222122212221122222112221222122212221222122211000000000000000000000000000000000
00000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000
__label__
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777775557777777777777777777777777777777777577777755577777777777777777777777777777775557777777777777777777777777777777777777
77777777555555777777777777777777777777777777775557775555557777777777777777777777777777777555577777777777777777777777777777777777
77777775555555777777775557777777777777777777777555755555557777777777777777777777777777777555557777777777777777777777777777777777
77775555555555777777755555577777777777777777777555755555557777777777777777777777777777775555557777777777777777777777777777777555
77755555555555777777755555557777777777777777777755555555577777777777777777777777777777775555557777777777777777777777777777755555
77775557555555777777555555555777777777777777777755555555777777777777777777777777777777775555557777777777777777777777777755555555
77777777555555777777555555555577777777777777775555555777777777777777777777777777777777777555577777777777777777777777755555555555
77777777555555777777555555555557777777777777755557755577777777777777777777777777777777777777777777777777777777777775555555555555
77777777555557777777555555555557777777777777555577775557777777777777777777777777777777777777777777777777777777777755555555555557
77777775555557777775555557555557777777777777777777777555777777777777777777777777777777777777777777777777777777777555555555555777
77777775555557777755555557755577777777777777777777777555557777777777777777777777777777777777777777777777777777777555555555777777
77777755555577777755555577777777777777777777777777777755555777777777777777777777777777777757777777777777777777775555555555777777
77777755555577777555555777777777777777777777777777777755555777777777777777777777777777777555777777777777777777775555557755577777
77777755555777775555555777777777777777777777777777777755555577777777777777777777777777777755577777777777777777755555577755577777
777777555557777555555577777777777777777777777777777777bbbbbbbbbbbbbbbbbbb7777777777777777755577777777777777777755555577755577777
77777555555777555555577777777777777777777777777777777bbb333bbbb33bbb333bbb777777777777777775557777777777777777755555777775557777
77777555555775555555777777777777777777777777777777777bbb3b3bbb3bbbbb3bbbbb777777777777777775557777777777777777755555577775557777
77777555557755555557777777777777773333333333333333333b3b333b3b3bbb3b33bb3b333333333333333333357777777777777777755555577775557777
77777555555555555577777777777777733333333333333333333bbb3b3bbb3bbbbb3bbbbb333333333333333333335777777777777777755555577775557777
77775555555555555777777777777777333333333333333333333bbb3b3bbbb33bbb333bbb333333333333333333333777777777777777775555557755555777
777755555555555577777777777777773333333333333333333333bbbbbbbbbbbbbbbbbbb3333333333333333333333577777777777777775555555755555777
77775555555555577777777777777777333333333333333333333333333333333333333333333333333333333333333557777777777777777555555555555777
77775555555555777777777777777777333333333333333333333333333333333333333333333333333333333333333557777755777777777755555555555777
7777555555557777777777777777777733bbb3bbb3bbb3bbbbbb333bbbbb333bbbbb333bbbbb333bbbbb333bbbbb333557777755577777777775555555555777
7777555555577777777777777777777733bbb3bbb3bbb3bbbbbbb3bbbbbbb3bbbbbb33bbbbbbb3bbbbbbb3bbbbbbb33557777775557777777777555555555777
7777755557777777777777777777777733bbb3bbb3bbb3bbbbbbb3bbbbbbb3bbbbbb33bbbbbbb3bbbbbbb3bbbbbbb33557777777555777777777755555555777
7777777777777777777755777777777733bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb33333bbb3bbb3bbb3bbb3bbb3bbb33577777777755577777777775555557777
7777777777777777777555777777777733bbbbbbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb33777777777775777777777777777777777
7777777777777777775557777777777733bbbbbbb3bbb3bbbbbbb3bbbbbbb3bbb3bbb3bbbbbbb3bbb3bbb3bbbbbbb33777777777777777777777777777777777
7777777777777777775557777777777733bbbbbbb3bbb3bbbbbb33bbbbbbb3bbb3bbb3bbbbbbb3bbb3bbb3bbbbbbb33777777777777777777777777777777777
7777777777777777755577777777777733bbb3bbb3bbb3bbbbbbb3bbbbbbb3bbb3bbb3bbbbbbb3bbb3bbb3bbbbbbb33777777777777777777777777777777777
7777777777777777755577777777777733bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb33777777777777777777777777777777777
7777777777777775555777777777777733bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbbbbbb3bbb3bbb3bbb3bbb3bbb3bbb33777777777777777777777777777777777
7777777777755555555777777777777733bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbbbbbb3bbb3bbb3bbb3bbb3bbb3bbb33777777777777777777777777777777777
7777777777775555555777777777777733bbb3bbb3bbb3bbb3bbb3bbb3bbb33bbbbb33bbb3bbb3bbb3bbb3bbb3bbb33777777777777777777777777777777777
77777777777775555557777777777777733333333333333333333333333333333333333333333333333333333333337777777777777777777777777777777777
77777777777755555557777777777777777777777777777777777777775557777777777777777777777777777777777755577777777777777777777777777777
77777777777755555555777777777777777777777777777777777777777555777755555777777777777777777775555555555777777777777777777777777777
77777777777555555555577777777777777777777777777777777777777555775555555577777777777777777755555555555577777777777777777777777777
77777777557555555755777777777777777777777777777777777777777755555555555577777777777777777575555555555557777777777777777777777777
77777775555555557777777777777777777777777777777777777777755555555555555577777777777777775777777755555557777777777777777777777777
77777777555555557777777777777777777777777777777777777775555555557755555777777777777777777777777775555557777777777777777755577777
77777777775555555577777777777777777777777777777777777555555577555577777777777777777777777777777777555557777777777777777555557777
77777777775555555557777777777777777777777777777777775555577777755555777777777777777777777777777777755577777777777777775555555577
77777777775555555557777777777777777777777777777777777557777777775555577777777777777777777777777777777777777777777777775555555557
77777777755555555557777757777777777777777777777777777777777777775555577777777777777777777777777777777777777777777777775555555555
77777777755555555577777557777777777777777777777777777777777775555555577777777777777777777777777777777777777777777777775555555555
77777777755555777777775557777777777777777777777777777777777777775555577777777777777777777777777777777777777777777777755555555555
77777777755555777777775557777777777777777777777777777777777777777555777777777777777777777777777777777777777777777777755577775555
77777777755555777777755577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777555777777555
77777777755555777777755577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777775557777777755
77777777755555777777555777777777777777777777777777777777577777777777777777777777777777777777777777777777777777777755577777777775
77777777755555557755555777777777777777777777777777777775557777777777777777777777777777777777777777777777777777777775777777777777
77777777755555555555557777777777777777777777777777777775557777777777777777777777777777777777777777777777777777777777777777777777
77777777755555555555557777777777777777777777777777777777555555577777777777777777777777777757777777777777777777777777777777777777
77777777775555555555557777777777777777777777777777777777755555557777777777777777777777777755577777777777777777777777777777777777
77777777777555555555577777777777777777777777777777777777775555557777777777777777777777777755557777777757777777777777777777777777
77777777777777555555777777777777777777777777777777777777775555555777777777777777777777777775555577755555777777777777777777777777
77777777777777777777777777777777777777777777777777777777777555557777777777777777777777777777755555555557777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777775555555557777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777755555557777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777755577777777777777777777777777
77777777777777777777777757777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777555777777777777777777777777777777777777557777777777777777777777777777777777777777777777777777777777777777
77777757777777777777777555777777777777777777777777777777777777775555555557777777777777777777777777777777777777777777777777777777
77777757777777777777777555777777777777777777777777777777777777555555555555777777777777777777777777777777777777777777777777777777
77777555777777777777775557777777777777777777777777777777777755555555555555577777777777777777777577777777777777777777777777777777
77777555777777777755555555555557777777777777777777577777775555555555555555557777777777777777775557777777777777777777777777775777
77777555777777755555555555555555777777777777777777577777555555555555555555555777777777777777775557777777777777777777777777755577
77777555777777555555555555555555577777777777777777757755555555555555577555555577777777777777777555777777777777777777777777755577
77777755577555555555555555555555777777777777777777755555555555557755577755555577777777777777777555777777777777777777777777755577
77777755555555555555555555555557777777777777777777555555555555777775557775555557777777777777777757777777777777777777777777755577
77755555555555755555555557777777777777777777777777555555555577777775557775555557777777777777777777777777755577777777777777755577
77555555555777777775555577777777777777777777777777555555557777777775557777555557777777777777777775555555555557777777777777555557
77555555557777777775555577777777777777777777777777555555777777777777555777555557777777777777775555555555555557777777777777555557
77777777555777777777555777777777777777777777777777755577777777777777555777555557777777777775557775555555555557777777777777555557
77777777555777777777777777777777777777777777777777777777777777777777555777555557777777777777777777755555555577777777777777555557
77777777555777777777777777777777777777777777777777777777777777777777555755555557777777777777777775555555555777777777777777555557
77777777755557777777777777777777777777777777777777777777777777777777555555555557777777777777777555555555557777777777777777555557
77777777755555777777777777777777777777777777777777777777777777777777555555555577777777777777755555555555577777777777777777555557
77777777755555577777777777777777777777777777777777777777777777775555555555555777777777777777555555555557777777777777777777555557
77777777755555557777777777777777777777777777777777777777777777755555555555557777777777777777555555555557777777777777777777555557
77777777775555555777777777777777777777777777777777777777777777775555555555777777777777777777555555555557777777777777777777555557
77777777777555555577777777777777777777777777777777777777777777777775555557777777777777777777755555555557777777777777777777555555
77777777777755555555777777777777777777777777777777777777777777777775555557777777777777777777777555555557777777777777777777555555
77777777777775555555577777777777777777777777777777777777777777777775555577777777777777777777775555555555555777777777777777555555
77777777777775555555557777777777777777777777777777777777777777777775555577777777777777777777755555555555555555577777777777555557
77777777777777555555555777777777777777777777777777777777777777777755555577777777777777777777755555555555555555555777777777555557
77777777777777755555557777777777777777777777777777777777777777777755555577777777777777777777755555555555555555555557777777555557
77777777777777777777777777777777777777777777777777777777777777777755555777777777777777777777775555555555555555555555777777755577
77777777777777777777777777777777777777777777777777777777777777777755555777777777777777777777777777777777755555555555777777777777
77777777777777777777777777777777777777777777777777777777777777777775557777777777777777777777777777777777777775555555577777777777
77777777777777777775777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777755555777777777777
77777777777777777755577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777775557777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777775557777775555577777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777755555555555555557777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777755555555555555555555557777777777777777777777777777777775777777777777777777777777777777777777777777777777777777777777
77777777555555555555555555555555557777777777777777777777777777777755577777777777777777777777777777777777777777777777777777777777
77777775555555555555555555555555577777777777777777755777777777777555777777777777777777777777777777777777777777777777777777777777
77777755555577777755555555555577777777777777777777755577777777777555555555577777777777777777777777777777777775555577777777777777
77777575777777777775557777777777777777777777777777755577777555555555555555555577777777777777777777777755555555555557777777777777
77777777777777777775557777777777777777777777777777775557555555555555555555555557777777777777777777755555555555555557777777777777
77777777777777777755555777777777777777777777777777775555555555555555555555555555777777777777777775555555555555555557777777775777
77777777777777777755555777777777777777777777777777777555555555555555555555555555777777777777777557755577755555555577777777755577
77777777777777777755555777777777777777777777777777775555555555555557777775555555777777777777775777777777555555555777777777755577
77777777777777555755555777777777777777777777777777755555555557755577777777755555777777777777777777777775555555577777777777755577
77777777777775555555555777777777777777777777777777555555557775555777777777755555777777777777777777777755555557777777777777755577
77777777777555555555555777777777777777777777777777555555557755555777777777755555777777777777777777777555555577777777777777755577
77777777775555555555555777777777777777777777777775555557555755555777777777755555777777777777777777775555555777777777777775555555
77777777755555555555555777777777777777777777777775555557755555555777777777755555777777777777777777775555557777777777777755555555
77777777755555555555555777777777777777777777777775555577775555555777777777755555777777777777777777755555577777777777777775555555
77777777755555577555555777777777777777777777777775555577775555557777777777755555777777777777777777755555577777777777777775555555
77777777755555557555555777777777777777777777777775555577775555557777777777555555777777777777777777755555777777777777777775555555
77777777775555555555555777777777777777777777777775555577755555555577777777555555777777777777777777755555777777777777777755555555
77777777777555555555555777777777777777777777777775555557755555555557777775555557777777777777777777755555777777777777777755555555
77777777777755555555555777777777777777777777777775555555555555555555777775555557777777777777777777755555777777777777777755555755
77777777777775555555555777777777777777777777777777555555555555555555577755555577777777777777777777755555577777777777777755555775
77777777777777555555555777777777777777777777777777555555555557555555577755555577777777777777777777755555557777777777777555555777
73737337777777775555557777777777777777777777777777755555555577775555577755555777777777777777777777775555557777777777777555555777
73737737777777755555557777777777777777777777777777775555555777777555777755557777777777777777777777777555555777777777777555557777
73737737777777555555577777777777777777777777777777777777777777777777775555777777777777777777777777777555555777777777777555557777
73337737777755555555777777777777777777777777777777777777777777777777755557777777777777777777777777777755555557777777777555557777
77377333777555555557777777777777777777777777777777777777777777777777775577777777777777777777777777777775555555777777777555557777
77777777777555555557777777777777777777777777777777777777777777777777777777777777777777777777777777777777777557777777777755577777

__sfx__
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000100200d0200b02007010040100a0000a0000b0000c0000d0000a2000a2000a2000c2000f2001720019200081000810000000000000000000000000000000000000000000000000000000000000000000
000300000c050000100f05000010120500001017050000101a0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001a010240101d010250001d000290001800020000210002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000127400f7400c7400f7300c730097300c72009720067200871005710027100770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000017430114300c43014420104200b420104100b410074100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001d03021030260301d02021020260201c01021010260100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000c6101762023620316103661037610336102e610286102561023610206101e6101c6101c6101d610206102361023610206101d6101c61000000000000000000000000000000000000000000000000000
000100002a01036010270002700027000270002700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
