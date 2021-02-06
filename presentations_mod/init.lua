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
 path_to_textures = Modpath .. DIR_DELIM .. "textures" .. DIR_DELIM


displays = {}
nextDisplayIndex = 0

display_formspec_name = Modname .. ":display_formspec_"
display_entity_name = Modname .. ':display'
display_item_name  = Modname .. ":display_item"

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
    proportions = 1.0,
    size = 1.0,
    
    texture_names ={"img.png"},
    textures_index = 1,
    textures_count = 1
}

function DisplayEntity:change_textures_to(textures)
    self.texture_names = textures;
    self.current_index = 1
    self:update_texture()
end

function DisplayEntity:set_proportions(new_proportions)
    self.proportions = new_proportions
    self:update_size()
end

function DisplayEntity:set_size(new_size)
    self.size = new_size
    self:update_size()
end

function  DisplayEntity:update_texture()
    local name = self.texture_names[self.textures_index]
    self.object:set_properties({textures = {name}})
end

function  DisplayEntity:update_size()
    
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
        self.texture_names = data.texture_names
        self.textures_index = data.textures_index
        self.textures_count = data.textures_count

        self:update_size()
        self:update_texture()
    end
    
    if self.id <0 then
        while displays[nextDisplayIndex] ~= nil do
            nextDisplayIndex = nextDisplayIndex +1
        end
        self.id = nextDisplayIndex
        nextDisplayIndex = nextDisplayIndex + 1
    end
    
    displays[self.id] = self
    
end

function DisplayEntity:destroy_correctly()
    minetest.add_item(self.object:get_pos(), display_item_name)
    displays[self.id] = nil
    self.object:remove()
end

function  DisplayEntity:get_staticdata()
    return minetest.write_json({
        id = self.id,
        proportions = self.proportions,
        size = self.size,
        texture_names = self.texture_names,
        textures_index = self.textures_index,
        textures_count = self.textures_count
    })
end

function DisplayEntity:on_punch(puncher, time_from_last_punch, tool_capabilities, dir, damage)

    -- allow breaking while using strong tool
    if damage >= 5 then
        msg_player(puncher, "Display destroyed from excessive damage of " .. damage)
        self:destroy_correctly()
        return true
    end
    
    local index = self.textures_index + 1
    if index > self.textures_count then
        index = 1
    end
    self.textures_index = index
    self:update_texture()
    return true
end

function DisplayEntity:on_rightclick(clicker)
    self:show_formspec(clicker)
end

function DisplayEntity:show_formspec(clicker)

    local height = 5.5 + self.textures_count*0.5

    local testSpec = 
    "formspec_version[4]" ..
    "size[10,".. height .."]" ..
    "achor[0,0]"..
    "button[1,0.25; 2,.5;Destroy;Destroy;]"  ..
    "label[6,0.5; ID: ".. self.id ..";]" ..
    "button[1,1; 2,.5;MoveUp;Up;]" ..
    "button[3,1; 2,.5;MoveDown;Down;]" ..
    "button[5,1; 2,.5;MoveRight;Right;]" ..
    "button[7,1; 2,.5;MoveLeft;Left;]" ..
    "button[1,2; 2,.5;MoveForward;Forward;]" ..
    "button[3,2; 2,.5;MoveBackward;Backward;]" ..
    "button[5,2; 2,.5;RotateClock;Rotate Clockwise;]" ..
    "button[7,2; 2.5,.5;RotateAnticlock;Rotate Anticlockwise;]" ..
    
    "button[1,3; 1,.5;ScalePlus;+;]" ..
    "button[2,3; 1,.5;ScaleMinus;-;]"  ..
    "button[4,3; 1,.5;R16_9;16:9;]"  ..
    "button[5,3; 1,.5;R4_3;4:3;]"  ..
    "button[6,3; 1,.5;R5_4;5:4;]"  ..
    "button[7,3; 1,.5;R1_1;1:1;]"  ..
    
    "label[1,4.5;URLs:]" ..
    "field[2,4.25;1,.5;Count;Count:;".. self.textures_count .. ";]" ..
    "button[4,4.25;2,.5;UpdateImages; Save URLs]"

    local y = 5
    for i = 1, self.textures_count, 1 do
        local default = self.texture_names[i]
        if default == nil then
            default = ""
        end
        testSpec = testSpec .."field[1,".. y ..";8,.5;URL".. i ..";;".. default ..";]" 
        y = y + 0.5
    end

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

    if fields.Count then
        display.textures_count = math.min(30, tonumber(fields.Count))
    end

    if fields.ScalePlus then
        display:set_size(display.size+1)
    end

    if fields.ScaleMinus then
        display:set_size(math.max(display.size-1, 1))
    end

    if fields.MoveUp then
        move_offset(display,0,1,0)
    end

    if fields.MoveDown then
        move_offset(display, 0,-1,0)
    end

    if fields.MoveRight then
        move_offset(display,1,0,0)
    end

    if fields.MoveLeft then
        move_offset(display,-1,0,0)
    end

    if fields.MoveForward then
        move_offset(display,0,0,1)
    end

    if fields.MoveBackward then
        move_offset(display,0,0,-1)
    end

    if fields.RotateClock then
        display.object:set_yaw(display.object:get_yaw() + math.pi/4)
    end

    if fields.RotateAnticlock then
        display.object:set_yaw(display.object:get_yaw() - math.pi/4)
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

    if fields.Destroy then
        display:destroy_correctly()
    end
    
    if fields.UpdateImages then
        local newTextures = {}
        for i = 1, display.textures_count, 1 do
            local current = "URL"..i;
            local url = fields[current]
            newTextures[i] = "img.png"

            if url and url ~= "" then
                local valid = ends_with_one_of(url, {".jpg", ".JPG", ".png", ".PNG"})
                local fixSpelling = ends_with_one_of(url, {".JPG", ".PNG"})

                if valid then
                    local name = url:match( "([^/]+)$")
                    if fixSpelling then
                        name = name:gsub(".JPG", ".jpg")
                        name = name:gsub(".PNG", ".png")
                    end

                    if file_exists(path_to_textures .. name) then
                        newTextures[i] = name
                        msg_player(player, "Image " .. i .. " already downloaded.")
                    else
                        local ok = download_and_save_texture(player, url, name)
                        if ok then
                            newTextures[i] = name
                        else
                            --error
                        end
                    end
                else
                    msg_player(player, "Only .png and .jpg are supported. Invalid URL: " .. i .. " -> " .. url)
                end
            end
        end

        display:change_textures_to(newTextures)
    end

    
end)


function move_offset (display, x, y, z)  
    local pos = display.object:get_pos()
    pos.x = pos.x + x
    pos.y = pos.y + y
    pos.z = pos.z + z
    display.object:move_to(pos);
end


 function starts_with(str, start)
    return str:sub(1, #start) == start
 end
 
 function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
 end

 function ends_with_one_of(str, endings)
    if str == "" then
        return true
    end

    for index, value in ipairs(endings) do
        if str:sub(-#value) == value then
            return true
        end
    end
    return false
 end

 function msg_player(player, msg)
     minetest.chat_send_player(player:get_player_name(), msg)
 end

 function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
 end

minetest.register_entity(display_entity_name, DisplayEntity)

function download_and_save_texture(requester ,url, name)
        msg_player(requester, "HTTP Request: " .. url)
		local method = "GET"
		local resp   = {}

		local client, code, headers, status = Http.request({url=url, sink=Ltn12.sink.table(resp), method=method })
            
        if code == 200 then
            if resp then
                local data = table.concat(resp);
                if data then
                    
                    local path =  path_to_textures .. name
                    local file = io.open(path, "w+")
                    io.output(file)
                    io.write(data)
                    io.close(file)
                    minetest.dynamic_add_media(path)
                    msg_player(requester, "Saved " .. name)
                    return true
                end
            end
        else
            msg_player(requester, "ERROR: " ..code)
        end

        return false
end


minetest.register_craftitem(display_item_name,{
    description = "Display",
    inventory_image = "img.png",
    on_use = function(itemstack, user, pointed_thing)
        local pos = user:get_pos()
        pos.y = pos.y + 1
        minetest.add_entity(pos,  display_entity_name)
        itemstack:take_item()
        return itemstack
    end

})

minetest.register_chatcommand("delete_all_displays", {
    privs = {},
    func = function(name, param)
    
        for _, entity in ipairs(minetest.luaentities) do
            if entity.proportions then
                entity.object:remove()
            end
        end

    end,
})