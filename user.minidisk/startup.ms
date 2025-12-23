import "textUtil"
import "textUI"

clear
gfx.clear "#88FF88"
text.color = "#AA0000"
title = "SANTA vs. the SNOW GOONS"
gfx.print title, 480 - len(title)*10, 500, text.color, "large"

textUtil.printCenteredAt 34, 16, "How to Play"
print
print "  1. Move to any neighboring square with mouse or arrow keys."
print "     (Press spacebar or click Santa to wait in place.)"
print "  2. Snow goons will all take one step directly towards you."
print "  3. Snow goons that hit a snow pile, or each other, are destroyed."
print "  4. Press H to melt nearby goons with your warm heart!"

goon = file.loadImage("pics/snowGoon.png")
gfx.drawImage goon, 50, 50

santa = file.loadImage("pics/santa.png")
gfx.drawImage santa, 960-50-santa.width, 50

textUtil.printCenteredAt 34, 5, "Click anywhere to begin!"

if env.hasIndex("lastScore") then
	s = "Last Score: " + env.lastScore
	textUtil.printAt 66 - s.len, 0, s
end if

Sound.stopAll
if not env.hasIndex("bgmOn") then env.bgmOn = true

textUtil.printAt 2, 0, "Music:"
bgmSwitch = textUI.Switch.make(9, 0)
bgmSwitch.isOn = env.bgmOn
bgmSwitch.action = function(x)
	env.bgmOn = x
	if x then bgm.play 0.5 else bgm.stop
end function
bgmSwitch.start

bgm = file.loadSound("music/titleScreenMusic.ogg")
bgm.loop = true
if env.bgmOn then bgm.play 0.5

while true
	yield
	textUI.update
	if mouse.button and not bgmSwitch.containsMouse then
		while mouse.button; yield; end while
		for i in range(0.5, 0, -0.05)
			bgm.adjust i
			yield
		end for
		Sound.stopAll
		run "snowGoons"
	end if
end while
