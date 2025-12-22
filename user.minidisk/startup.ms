import "textUtil"

clear
gfx.clear "#88FF88"
text.color = "#AA0000"
title = "SANTA vs. the SNOW GOONS"
gfx.print title, 480 - len(title)*10, 500, text.color, "large"

textUtil.printCenteredAt 34, 16, "How to Play"
print
print "  1. Move to any neighboring square with mouse or arrow keys."
print "  2. Snow goons will all take one step directly towards you."
print "  3. Snow goons that hit a snow pile, or each other, are destroyed."
print "  4. Press H to melt nearby goons with your warm heart!"

goon = file.loadImage("pics/snowGoon.png")
gfx.drawImage goon, 50, 50

santa = file.loadImage("pics/santa.png")
gfx.drawImage santa, 960-50-santa.width, 50

textUtil.printCenteredAt 34, 5, "Click anywhere to begin!"

while true
	yield
	if mouse.button then
		while mouse.button; yield; end while
		run "snowGoons"
	end if
end while
