-- output.lua by HerrVincling, 13.03.2022
function getColorIndicatorText(data)
    return "#" .. string.sub(data.color1:getHexStr(), 0, 6) .. " █" .. "#" .. string.sub(data.color2:getHexStr(), 0, 6) .. "█"
end

function server_message(self, data)
    if ChatLog then
        if ChatLog.exists then
            if data.tool then
                sm.gui.chatMessage(data.tool .. " " .. data.text)
            else
                sm.gui.chatMessage(data.text)
            end
            return
        end
    end
    if data.character then
        self.network:sendToClient(data.character:getPlayer(), "client_displayAlert", data.text)
        return
    end
    self.network:sendToClients("client_displayAlert", data.text)
end

