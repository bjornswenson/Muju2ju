Menu = class()

function Menu:init()
	self.bg = love.graphics.newImage('media/graphics/main-menu.png')
	self.font = love.graphics.newFont('media/fonts/pixel.ttf', 8)
end

function Menu:update()

end

function Menu:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(self.bg)
	love.graphics.setFont(self.font)
	love.graphics.print('Dedicated to President Harry S. Truman', 2, love.graphics.getHeight() - love.graphics.getFont():getHeight())
end

function Menu:keypressed(key)

end

function Menu:keyreleased(key)

end

function Menu:mousepressed(x, y, b)
	if math.inside(x, y, 435, 220, 190, 90) then
		Context:remove(ctx)
		Context:add(Game)
	elseif math.inside(x, y, 425, 335, 210, 90) then
		print('Harry Truman bitch!')
	elseif math.inside(x, y, 455, 445, 160, 90) then
		love.event.quit()
	end
end

function Menu:mousereleased(x, y, b)

end
