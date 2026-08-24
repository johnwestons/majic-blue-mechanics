local app = require("src.app")

function love.load() app.load() end
function love.update(dt) app.update(dt) end
function love.draw() app.draw() end
function love.keypressed(key) app.keypressed(key) end
function love.mousepressed(x, y, button) app.mousepressed(x, y, button) end
function love.quit() app.quit() end
