 local ie = _G
 if minetest.request_insecure_environment then
	 ie = minetest.request_insecure_environment()
	 if not ie then
		 error("Insecure environment required!")
	 end
 end

 Http  = ie.require("socket.http")
 Ltn12 = ie.require("ltn12")

 Modname = minetest.get_current_modname()
 Modpath = minetest.get_modpath(Modname)


displays = {}
nextDisplayIndex = 0

display_formspec_name = Modname .. ":display_formspec_"

local DisplayEntity = {
    initial_properties = {
        hp_max = 1,
        physical = true,
        collide_with_objects = false,
        collisionbox = {-.5, -.5, -.1, .5, .5, .1},
        visual = "mesh",
        mesh = "test.obj",
        visual_size = {x = 1, y = 1},
        textures = {"img.png"},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
    },

    id = -1,
    texture_name = "img.png",
    proportions = 1.0,
    size = 1.0
}

function DisplayEntity:change_texture_to(texture)
    self.texture_name = texture;
    self.object:set_properties ({textures = {texture}})
end

function DisplayEntity:set_proportions(new_proportions)
    self.proportions = new_proportions
    self:adapt_size()
end

function DisplayEntity:set_size(new_size)
    self.size = new_size
    self:adapt_size()
end

function  DisplayEntity:adapt_size()
    
    local size_x = self.size;
    local size_y = self.size * self.proportions;
    local half_x = size_x * 0.5
    local half_y = size_y * 0.5

    self.object:set_properties({
        visual_size = {x = size_x, y = size_y},
        collisionbox = {-half_x, -half_y, -.1, half_x, half_y, .1}
    })
end

function DisplayEntity:on_activate(staticdata, dtime_s)
    
    if staticdata ~= nil and staticdata ~= "" then
        local data = minetest.parse_json(staticdata)
        self.id = data.id
        self.proportions = data.proportions
        self.size = data.size
        self:change_texture_to(data.texture_name)
        self:adapt_size()
    end
    
    if self.id <0 then
        self.id = nextDisplayIndex
        nextDisplayIndex = nextDisplayIndex + 1
    end
    
    displays[self.id] = self
    
end


function  DisplayEntity:get_staticdata()
    return minetest.write_json({
        id = self.id,
        texture_name = self.texture_name,
        proportions = self.proportions,
        size = self.size
    })
end


function DisplayEntity:on_rightclick(clicker)
    self:show_formspec(clicker)
end

function DisplayEntity:show_formspec(clicker)
    minetest.show_formspec(clicker:get_player_name(), display_formspec_name .. self.id, testSpec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not starts_with(formname, display_formspec_name) then
        return
    end

    local id = tonumber(string.sub(formname, display_formspec_name:len()+1));
    local display = displays[id]
    if not display then
        msg_player(player, "Error: no display found with id " .. id)
        return
    end

    if fields.URL and fields.URL ~= "" then

        if ends_with(fields.URL, ".png") or ends_with(fields.URL, ".jpg") then
            local resName = downloadAndSaveTexture(player, fields.URL)
            if resName then
                msg_player(player, "Saved " .. resName)
                display:change_texture_to(resName)
            end
        else
            msg_player(player, "Only .png and .jpg are supported. Invalid URL: " .. fields.URL )
        end
    end

    if fields.UP then
        msg_player(player, "UP pressed")
        display:set_size(display.size+1)
    end

    if fields.DOWN then
        msg_player(player, "DOWN pressed")
        display:set_size(display.size-1)
    end

    if fields.R16_9 then
        display:set_proportions(0.5625)
    end

    if fields.R4_3 then
        display:set_proportions(0.75)
    end

    if fields.R5_4 then
        display:set_proportions(0.8)
    end

    if fields.R1_1 then
        display:set_proportions(1.0)
    end
end)


 function starts_with(str, start)
    return str:sub(1, #start) == start
 end
 
 function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
 end

 function msg_player(player, msg)
     minetest.chat_send_player(player:get_player_name(), msg)
 end

local string testSpec = 
"formspec_version[4]" ..
"size[10,10]" ..
"label[1,1;Please insert URL Here:]" ..
"field[1,2;8,1;URL;URL;]" ..
"button[1,4; 1,1;UP;UP;]" ..
"button[2,4; 1,1;DOWN;DOWN;]"  ..
"button[1,5; 1,1;R16_9;16:9;]"  ..
"button[2,5; 1,1;R4_3;4:3;]"  ..
"button[3,5; 1,1;R5_4;5:4;]"  ..
"button[4,5; 1,1;R1_1;1:1;]"  

minetest.register_entity(Modname .. ':display', DisplayEntity)

function downloadAndSaveTexture(requester ,url)
        msg_player(requester, "HTTP Request: " .. url)
		local method = "GET"
		local resp   = {}

		local client, code, headers, status = Http.request({url=url, sink=Ltn12.sink.table(resp), method=method })
            
        if code == 200 then
            if resp then
                local data = table.concat(resp);
                if data then
                    local name = url:match( "([^/]+)$" )
                    local path =  Modpath .. DIR_DELIM .. "textures" .. DIR_DELIM .. name
                    local file = io.open(path, "w+")
                    io.output(file)
                    io.write(data)
                    io.close(file)
                    minetest.dynamic_add_media(path)
                    return name
                end
                return nil
            end
        else
            msg_player(requester, "ERROR: " ..code)
            return nil
        end
end