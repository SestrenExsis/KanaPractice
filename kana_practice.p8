pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- kana practice
-- by sestrenexsis
-- github.com/sestrenexsis/kanapractice

-- code based on shodo
--  by ryosuke mihara
--  github.com/oinariman/shodo
-- pixel art based on art by hiro (hamstone)
--  assetstore.unity.com/packages/2d/fonts/sprite-font-japanese-kana-43862

-- description:
-- * ink drying

-- modes:
-- * guided learning
-- * quiz

-- quiz mode:
-- * choose a random kana
-- * ask the player to draw it
-- * stroke order matters
-->8
-- constants and constructors

-- accl : speedup when moving
-- drag : slowdown over time
-- pull : slowdown on paper
-- pool : ink spread over time
-- maxr : ink max spread
-- maxw : max wetness of ink
-- dryt : time to finish drying

_accl=0.175
_drag=0.100
_pull=0.650
_pool=0.200
_maxr=5.000
_dryt={3.4,0.2,0.2,0.2}
_mous=false
_hint=false

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
	n,   -- name    : str
	r,   -- row pos : number
	c,   -- col pos : number
	f    -- frames  : table
	) -- return type: table
	local res={
		name=n,
		row=r,
		col=c,
		frames=f
	}
	res.strokes=getstrokes(res)
	return res
end

-- kana info
_kanatbl={
a=kana("a",0,0,{0,1,2,3}),
i=kana("i",0,1,{4,5}),
u=kana("u",0,2,{6,7}),
e=kana("e",0,3,{8,9,10,11}),
o=kana("o",0,4,{12,13,14,15}),
ka=kana("ka",1,0,{16,17,18}),
ki=kana("ki",1,1,{19,20,21,22}),
ku=kana("ku",1,2,{23}),
ke=kana("ke",1,3,{24,25,26}),
ko=kana("ko",1,4,{27,28}),
sa=kana("sa",2,0,{29,30,31}),
shi=kana("shi",2,1,{32}),
su=kana("su",2,2,{33,34,35}),
se=kana("se",2,3,{36,37,38}),
so=kana("so",2,4,{39,40,41,42}),
ta=kana("ta",3,0,{43,44,45,46}),
chi=kana("chi",3,1,{47,48,49}),
tsu=kana("tsu",3,2,{50}),
te=kana("te",3,3,{51,52}),
to=kana("to",3,4,{53,54}),
na=kana("na",4,0,{55,56,57,58,59}),
ni=kana("ni",4,1,{60,61,62}),
nu=kana("nu",4,2,{63,64,65,66}),
ne=kana("ne",4,3,{67,68,69,70,71}),
no=kana("no",4,4,{72,73}),
ha=kana("ha",5,0,{74,75,76,77}),
hi=kana("hi",5,1,{78,79,80}),
fu=kana("fu",5,2,{81,82,83,84}),
he=kana("he",5,3,{85}),
ho=kana("ho",5,4,{86,87,88,89,90}),
ma=kana("ma",6,0,{91,92,93,94}),
mi=kana("mi",6,1,{95,96,97,98}),
mu=kana("mu",6,2,{99,100,101,102}),
me=kana("me",6,3,{103,104,105}),
mo=kana("mo",6,4,{106,107,108}),
ya=kana("ya",7,0,{109,110,111}),
yu=kana("yu",7,2,{112,113,114}),
yo=kana("yo",7,4,{115,116,117}),
ra=kana("ra",8,0,{118,119,120}),
ri=kana("ri",8,1,{121,122}),
ru=kana("ru",8,2,{123,124,125,126}),
re=kana("re",8,3,{127,128,129,130,131}),
ro=kana("ro",8,4,{132,133,134}),
wa=kana("wa",9,0,{135,136,137,138}),
wo=kana("wo",9,4,{139,140,141,142}),
n=kana("n",10,0,{143,144})
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

function _init()
	inittitle()
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
				rectfill(lft,top,rgt,btm,c)
			end
		end
		i-=5
		if (i<=0) break
	end
	local res=(i>0)
	return res
end

function testinks(
	x,y, -- upper left corner
	s    -- scale in pixels
	) -- return type: table
	local res={}
	for inks in all(_inks) do
		local stroke={}
		local lx=-1
		local ly=-1
		for ink in all(inks) do
			local cx=flr((ink.pos.x-x)/s)
			local cy=flr((ink.pos.y-y)/s)
			if cx!=lx or cy!=ly then
				add(stroke,point(cx,cy))
			end
			lx=cx
			ly=cy
		end
		add(res,stroke)
	end
	return res
end

function evaluate(src,trg)
	local tot=0
	local pts={}
	for i=1,#trg do
		local pt=trg[i]
		local index=8*pt.y+pt.x
		pts[index]=1
		tot+=1
	end
	local err=tot
	for i=1,#src do
		local pt=src[i]
		local index=8*pt.y+pt.x
		if pts[index]==nil then
			err+=1
		elseif pts[index]==1 then
			err-=1
			pts[index]=0
		end
	end
	local res=err
	return res
end

function evaluateall(src,trg)
	local evals={}
	local minst=min(#src,#trg)
	local maxst=max(#src,#trg)
	if 1<=minst then
		for i=1,minst do
			local tot=max(#src[i],#trg[i])
			local err=evaluate(src[i],trg[i])
			local eval={tot,err}
			add(evals,eval)
		end
	end
	if minst+1<=maxst then
		for i=minst+1,maxst do
			local tot=0
			local err=0
			if #src>=i then
				tot=#src[i]
				err=#src[i]
			end
			if #trg>=i then
				tot=min(tot,#trg[i])
				err=max(err,#trg[i])
			end
			local eval={tot,err}
			add(evals,eval)
		end
	end
	local tot=0
	local err=0
	for i=1,#evals do
		tot+=evals[i][1]
		err+=evals[i][2]
	end
	local res=evals
	return res
end

-->8
-- title screen

function inittitle()
	_debug={
		screen="title"
	}
	initfn=inittitle
	updatefn=updatetitle
	drawfn=drawtitle
	palt(0,false)
	palt(7,true)
end

function updatetitle()
	if btnp(❎) then
		initmenu()
	end
end

function drawtitle()
	cls()
	cursor(0,114,1)
	print("press ❎ to go to menu")
end
-->8
-- menu screen

function initmenu()
	_debug={
		screen="main menu"
	}
	initfn=initmenu
	updatefn=updatemenu
	drawfn=drawmenu
	palt(0,false)
	palt(7,true)
	_menuindex=1
	_menu={
		"   study deck   ",
		"practice reading",
		"practice writing"
	}
end

function updatemenu()
		if (btnp(⬆️)) _menuindex-=1
		if (btnp(⬇️)) _menuindex+=1
		_menuindex=1+(_menuindex-1)%#_menu
	if btnp(❎) then
		if (_menuindex==1) initstudy()
		if (_menuindex==2) initread()
		if (_menuindex==3) initwrite()
	end
end

function drawmenu()
	cls()
	cursor(0,114,1)
	print("press ❎ to select")
	for i,text in ipairs(_menu) do
		local c=5
		if (i==_menuindex) c=7
		print(text,8,8*i+24,c)
	end
end
-->8
-- study screen

function initstudy()
	_debug={
		screen="study"
	}
	initfn=initstudy
	updatefn=updatestudy
	drawfn=drawstudy
	--palt(0,false)
	--palt(7,true)
	_cursor=point(0,0)
	_cols=5
	_rows=11
end

function updatestudy()
	if (btnp(⬆️)) _cursor.y-=1
	if (btnp(⬇️)) _cursor.y+=1
	if (btnp(⬅️)) _cursor.x-=1
	if (btnp(➡️)) _cursor.x+=1
	_cursor.x=_cursor.x%_cols
	_cursor.y=_cursor.y%_rows
	if (btnp(🅾️)) initmenu()
end

function drawstudy()
	cls()
	local cx=_cursor.x
	local cy=_cursor.y
	local s=1
	local sk=nil
	for n,k in pairs(_kanatbl) do
		local x=(1.5*s*8)*k.col
		local y=(1.3*s*8)*k.row
		local c=1
		if k.col==cx and k.row==cy then
			c=7
			sk=k
			rectfill(x,y,x+7,y+7,1)
		end
		drawkana(k,x,y,s,c)
	end
	if sk==nil then
		x=(1.5*s*8)*cx
		y=(1.3*s*8)*cy
		rectfill(x,y,x+7,y+7,1)
	else
		rect(60,1,61+66,2+66,6)
		drawkana(sk,62,3,8,_c_cut)
		local i=(12*t())%64
		i=mid(0,i-16,64)
		drawkana(sk,62,3,8,_c_dry,i)
		print(sk.name,61,70,6)
	end
	cursor(0,114,1)
	print("press 🅾️ to quit studying")
end
-->8
-- read screen

function initread()
	_debug={
		screen="read"
	}
	initfn=initread
	updatefn=updateread
	drawfn=drawread
	local i=flr(rnd(#_kanakey))+1
	_kana=_kanatbl[_kanakey[i]]
end

function updateread()
 -- get input
	if btnp(🅾️) then
		initmenu()
		return
	elseif btnp(➡️,1) then
		initscreen()
		return
	end
end

function drawread()
	local k=_kana
	cls(_c_cnv)
	drawkana(k,62,3,8,_c_cut)
	cursor(0,114,1)
	print("press 🅾️ to quit reading")
end
-->8
-- write screen

-- px : x position
-- py : y position
-- vx : x velocity
-- vy : y velocity
-- lx : last x pos
-- ly : last y pos
-- sz : brush radius
-- on : using brush

function initwrite()
	_debug={
		screen="write"
	}
	initfn=initwrite
	updatefn=updatewrite
	drawfn=drawwrite
	palt(0,false)
	palt(7,true)
	_nib_px=64
	_nib_py=6
	_nib_vx=0
	_nib_vy=0
	_nib_lx=64
	_nib_ly=64
	_nib_sz=0
	_nib_on=false
	_nib_pr=false
	_lines=0
	local i=flr(rnd(#_kanakey))+1
	_kana=_kanatbl[_kanakey[i]]
	_inks={{}}
end

function updatewrite()
	_nib_lx=_nib_px
	_nib_ly=_nib_py
 -- get input
	if btnp(🅾️) then
		initmenu()
		return
	elseif btnp(➡️,1) then
		initscreen()
		return
	end
 if btnp(🅾️,1) then
 	_mous=not _mous
 	sfx(0)
 end
 if btnp(❎,1) then
 	_hint=not _hint
 	sfx(0)
 end
	if _mous then
		poke(0x5f2d,1)
		_nib_pr=_nib_on
		_nib_on=btn(❎) or stat(34)==1
		_nib_px=stat(32)
		_nib_py=stat(33)
		_nib_vx=_nib_px-_nib_lx
		_nib_vy=_nib_py-_nib_ly
	else
		_nib_pr=_nib_on
		_nib_on=btn(❎)
		if (btn(⬆️)) _nib_vy-=_accl
		if (btn(⬇️)) _nib_vy+=_accl
		if (btn(⬅️)) _nib_vx-=_accl
		if (btn(➡️)) _nib_vx+=_accl
	end
	if _nib_pr and _nib_on then
		_nib_pr=false
	end
	-- update pen physics
	if _nib_vx>0 then
		_nib_vx-=_drag
		_nib_vx=max(0,_nib_vx)
	else
		_nib_vx+=_drag
		_nib_vx=min(0,_nib_vx)
	end
	if _nib_vy>0 then
		_nib_vy-=_drag
		_nib_vy=max(0,_nib_vy)
	else
		_nib_vy+=_drag
		_nib_vy=min(0,_nib_vy)
	end
	if (not _mous) then
		local multi=1.000
		if (_nib_on) multi=_pull
		if (_nib_vx~=0) then
			_nib_px+=multi*_nib_vx
		end
		if (_nib_vy~=0) then
			_nib_py+=multi*_nib_vy
		end
	end
	-- keep pen in bounds
	_nib_px=mid(0,_nib_px,127)
	_nib_py=mid(0,_nib_py,127)
	-- update ink effects
	if (_nib_pr) add(_inks,{})
	if _nib_on then
		_nib_sz+=_pool
	else
		_nib_sz-=_pool
	end
	_nib_sz=mid(0,_nib_sz,_maxr)
	local l=point(_nib_lx,_nib_ly)
	local p=point(_nib_px,_nib_py)
	local pts=betweens(l,p)
	if _nib_sz>0 then
		for pt in all(pts) do
			local ink=inkdrop(pt,_nib_sz)
			add(_inks[#_inks],ink)
		end
	end
end

function drawwrite()
	local k=_kana
	cls(_c_cnv)
	rect(23,23,120,120,6)
	-- draw hint
	if _hint then
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
			_nib_px,_nib_py,
	 	max(1,_nib_sz),_c_nib
		)
	print(k.name,3,3,1)
	print(#_inks-1,112,0,1)
	--local test=testinks(24,24,12)
	--drawkana(test,64,23,9,2,3)
	--local evals=evaluateall(test,p)
	--for i=1,#evals do
	--	local ev=evals[i]
	--	local msg=ev[1].." "..ev[2]
	--	print(msg,104,8*i,1)
	--end
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
00070000000100000000000007eeeeee011111170700001001000070000100000007000000010000000100000001000000000000000000000000000007000100
011e11000111110000eeee000000011000000ee000e0010000100e0007eee010011e1010011110700111101001111010070011100100eee0010011100e000100
000e0000000100007e0000e0000010000000e000000e10000001e0000010000100e000010010000e00100001001000010e01000001070000010100000e111110
000e1110000eeee00000000e00010000000e000000010000000e00000010010000e001000010010000100700001001000e00000001000000010000000e101001
00e000010070000e0000000e00010000000e00000010000000e00000010001000e0001000100010001000e00010001000e000000010000000100000010e01001
000000010000000e000000e000010000000e00000010000000e0000000011110000111100001111000011e10000eeee00e000000010000000100000010e11011
000000010000000e00000e00000010000000e0000010000000e0000000100100001001000010010000e00e00007001000e0100000101000001070000010e0101
00011110000eeee000eee0000000011000000ee000011111000eeeee000111000001110000011100000ee1000001110000e01111001011110010eeee00100011
010007000100010001000100070000000100000001000000010000000100000000000000000000000000010000000100000007000000010000e0000000700000
01000e0001000100010001001e1100007eee00001117000011110000111100000011110000eeee00070111110107eeee01011e11010111117e10010011e00e00
01111e1001eeeee0011111100e1111000111110001e11100011eee00011111000e070010070100e00e0001000100010001000e00010001000010011000e00e10
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
01e00000011000000110000000ee010000e1010000110100001107000e00010001000e0001000100011e110007eeee000111110000e0011000100ee000100110
10e0010010100100101007007e10001011e0001011100010111000e00e11110001e11e00017eee00000e0000000100000001000000e11001001ee00e00111001
00e001000010010000100e000010000000e0000000100000001000000e0010100e00e010010010e0011e11000111110007eeee0001e000010ee0000e01100001
01e111100eeeeee001111e100110000001e000000e1000000110000010e01001e010e0011010100e000e0000000100000001000010e00010701000e010100010
e0e001017010010e10100e0110100010e0e0001070e000e01010001010e10001e01e00011011000e000e000e0001000100010001000e010000010e0000010100
e0e001001010010010100e00011000100e10001001e000e00110001010e00010e0e00010101000e0000e000e0001000100010001000e00000001000000010000
0e001000010010000100e0000001110000011100000eee0000111100010e01000e01010001010e000000eee00000111000001110000e00000001000000010000
0000100000001000000070000000100000007000000010000007000000010000000100000070001000100070007eeee000111170001111100011111000700000
00011100000eee000001e100000010000000e000000010000000e000000010000000100000e00010001000e00000010000000e00000001000000010000e00000
7010101010e010e01010e010000017ee0000e1110000111100100000007000000010000000e00010001000e000011000000ee000000110000001100011e10100
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
00011110000211100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02110400011304000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001111000028c800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0051010100ca04080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01011001040240080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010001040600080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110010004200800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000700000001000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001eee0000e11100001111000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07ee0100011e01000111070001110100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011110000e111000011e100001eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110101001e010100e10e01007e010e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01011001010e10010e01e0010101100e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010001010e00010e0e00010101000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110010001e001000e10010001100e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002705027050270502705027050270502705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
