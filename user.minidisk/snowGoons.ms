import "stringUtil"
import "listUtil"
import "mathUtil"

clear
display(2).mode = displayMode.pixel
curtain = display(2)
curtain.clear color.clear

loadPics = function	
	outer.pics = {}
	for name in file.children("/usr/pics")
		if not name.endsWith(".png") then continue
		pics[name - ".png"] = file.loadImage("/usr/pics/" + name)
	end for
	pics.heart = file.loadImage("/sys/pics/Heart.png")
end function
loadPics

loadSounds = function	
	outer.sounds = {}
	for name in file.children("/usr/sounds")
		if not name.endsWith(".wav") then continue
		sounds[name - ".wav"] = file.loadSound("/usr/sounds/" + name)
	end for
end function
loadSounds

cellSize = 32
rows = 640 / cellSize
cols = 960 / cellSize

display(5).mode = displayMode.tile
tileDisp = display(5)
tileDisp.tileSet = pics.snowTiles
tileDisp.cellSize = cellSize
tileDisp.extent = [cols, rows]

spriteDisp = display(4)

TileSprite = new Sprite
TileSprite.row = 0
TileSprite.col = 0
TileSprite.scale = cellSize / 128
TileSprite.update = function
	self.x = (self.col + 0.5) * cellSize
	self.y = (self.row + 0.5) * cellSize
end function

TileSprite.setMeltLevel = function(t)
	// Adjust corners so as to melt this sprite top-down,
	// from 0 (not at all) to 1 (completely melted)
	h = self.image.height * self.scale
	top = self.y - h/2 + h * t
	corners = self.corners
	corners[2][1] = top
	corners[3][1] = top
	self.setCorners corners
end function

santa = new TileSprite
santa.image = pics.santa
santa.hit = false
spriteDisp.sprites.push santa

arrow = new TileSprite
arrow.image = pics.arrow
arrow.tint = "#00008888"
arrow.update = function
	self.col = santa.col
	self.row = santa.row
	super.update
end function
spriteDisp.sprites.push arrow
arrow.update

SnowGoon = new TileSprite
SnowGoon.image = pics.snowGoon
SnowGoon.dead = false

SnowGoon.calcMove = function
	self.nextcol = self.col + sign(santa.col - self.col)
	self.nextrow = self.row + sign(santa.row - self.row)
	self.col = null
	self.row = null
end function

SnowGoon.finishMove = function
	newcol = self.nextcol
	newrow = self.nextrow
	safe = isEmpty(newcol, newrow)
	self.col = newcol
	self.row = newrow
	self.update
	if self.col == santa.col and self.row == santa.row then
		santa.hit = true
	end if
	if safe then return
	other = goonAt(newcol, newrow)
	if other then other.dead = true
	self.dead = true
	tileDisp.setCell newcol, newrow, 1
	Particle.MakeMany self.x, self.y, 20
	sounds.impact.play
end function

SnowGoon.remove = function
	spriteDisp.sprites.removeVal self
	goons.removeVal self
end function

goonAt = function(col, row)
	for goon in goons
		if goon.col == col and goon.row == row then return goon
	end for
	return null
end function

Particle = new Sprite
Particle.image = pics.particle
Particle.scale = santa.scale
Particle.vx = 0
Particle.vy = 0
Particle.minY = 0
Particle.Instances = []
Particle.update = function
	self.x += self.vx
	self.y += self.vy
	self.vy -= 0.25
	if self.y < self.minY then
		Particle.Instances.removeVal self
		spriteDisp.sprites.removeVal self
	else if self.y < self.minY + 10 and self.vy < 0 then
		t = (self.y - self.minY) / 10
		self.tint = color.lerp(color.clear, color.white, t)
	end if
end function
Particle.UpdateAll = function
	for i in range(self.Instances.len-1, 0, -1)
		self.Instances[i].update
	end for
end function
Particle.Make = function(x,y)
	p = new Particle
	p.x = x; p.y = y
	p.vx = (rnd - 0.5) * 3
	p.vy = 3 * rnd
	p.minY = y - 5
	self.Instances.push p
	spriteDisp.sprites.push p
end function
Particle.MakeMany = function(x, y, count)
	for i in range(1, count)
		Particle.Make x,y
	end for
end function

setCurtain = function(t)
	radius = 500 * (1-t)
	curtain.clear color.black
	curtain.fillEllipse santa.x-radius, santa.y-radius,
	  radius*2, radius*2, color.clear
end function

closeCurtain = function
	for t in range(0, 1, 1/60)
		setCurtain t
		Particle.UpdateAll
		yield
	end for
end function

openCurtain = function
	for t in range(1, 0, -1/60)
		setCurtain t
		Particle.UpdateAll
		yield
	end for
	curtain.clear color.clear
end function

isEmpty = function(col, row)
	if col < 0 or col >= tileDisp.extent[0] then return false
	if row < 0 or row >= tileDisp.extent[1] then return false
	if tileDisp.cell(col, row) > 0 then return false
	if goonAt(col, row) then return false
	return true
end function

updateTarget = function(dcol, drow)
	outer.target = {}
	target.col = santa.col + dcol
	target.row = santa.row + drow
	if isEmpty(target.col, target.row) then
		target.valid = true
		arrow.tint = "#00008888"
	else
		target.valid = false
		arrow.tint = color.clear
	end if	
end function

trackMouse = function
	if floor(mouse.x/cellSize) == santa.col and
	   floor(mouse.y/cellSize) == santa.row then
		updateTarget 0, 0
		arrow.tint = color.clear
		return
	end if
	angle = atan(mouse.y - santa.y, mouse.x - santa.x) * 180/pi
	angle = round((angle - 22.5) / 45) * 45
	arrow.rotation = angle
	rad = angle * pi/180
	updateTarget round(cos(rad)), round(sin(rad))
end function

endTurn = function
	arrow.tint = color.clear
	for goon in goons; goon.calcMove; end for
	for goon in goons; goon.finishMove; end for
	for i in range(goons.len-1, 0, -1)
		if goons[i].dead then goons[i].remove
	end for
	if not goons then endRound
	if santa.hit then endGame
end function

endRound = function
	closeCurtain
	startRound
end function

endGame = function
	santa.tint = "#AAAAFF"
	closeCurtain
	setCurtain 0.95
	curtain.print "GAME OVER", 480-9*10, 400, color.red, "large"
	key.clear
	for i in range(120)
		Particle.UpdateAll
		yield
		if key.available then break
	end for
	key.clear
	reset; run "startup"
end function

startRound = function
	tileDisp.clear 0
	for i in range(10)
		tileDisp.setCell floor(cols*rnd), floor(rows*rnd), 1
	end for
	santa.col = cols / 2
	santa.row = rows / 2
	santa.update
	arrow.update
	tileDisp.setCell santa.col, santa.row, 0
	outer.goons = []
	for i in range(10)
		goon = new SnowGoon
		while true
			goon.col = floor(cols*rnd)
			goon.row = floor(rows*rnd)
			if isEmpty(goon.col, goon.row) then break
		end while
		goon.update
		goons.push goon
		spriteDisp.sprites.push goon
	end for
	openCurtain
end function

moveToTarget = function
	if not target.valid then return
	santa.col = target.col
	santa.row = target.row
	santa.update
	arrow.update
	endTurn
end function

handleArrowKeys = function
	dcol = 0
	drow = 0
	while true
		kh = key.pressed("right") - key.pressed("left")
		if kh then dcol = kh
		kv = key.pressed("up") - key.pressed("down")
		if kv then drow = kv
		if not kh and not kv then break
		arrow.rotation = atan(drow, dcol) * 180/pi
		updateTarget dcol, drow
		yield
	end while
	moveToTarget
	key.clear
	arrow.tint = color.clear
end function

handleClick = function
	while mouse.button
		trackMouse
		yield
	end while
	moveToTarget
end function

handleKey = function
	k = key.get
	kc = k.code
	if 17 <= kc <= 20 then  // arrow keys
		handleArrowKeys
	else if k == " " then
		endTurn
	else if k == "h" then
		doMeltyHeart
		endTurn
	else if kc == 27 then
		text.row = 0
		exit
	end if	
end function

doMeltyHeart = function
	hs = new Sprite
	hs.image = pics.heart
	hs.x = santa.x
	hs.y = santa.y
	hs.scale = 0
	spriteDisp.sprites.push hs
	victims = []
	for goon in goons
		if abs(goon.col - santa.col) <= 1 and 
		  abs(goon.row - santa.row) <= 1 then victims.push goon  
	end for
	for t in range(0, 1, 1/30)
		hs.scale = mathUtil.lerp(0.1, 1, t)
		yield
	end for
	for t in range(0, 1, 1/30)
		hs.scale = mathUtil.lerp(1, 0.1, t)
		for goon in victims
			goon.setMeltLevel mathUtil.lerp(1, 0, t)
		end for
		yield
	end for
	spriteDisp.sprites.remove -1
	for goon in victims
		goon.remove
	end for
end function

lastMousePos = mouse + {}
mainLoop = function
	startRound
	while true
		yield
		Particle.UpdateAll
		if mouse != lastMousePos then
			lastMousePos = mouse + {}
			trackMouse
		end if
		if mouse.button then handleClick
		if key.available then handleKey
	end while
end function

if locals == globals then
	mainLoop
end if
