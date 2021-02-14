--#region GLOBAL VARIABLES

modname = minetest.get_current_modname()
modpath = minetest.get_modpath(modname)
modstorage = minetest.get_mod_storage()


path_to_textures = modpath .. DIR_DELIM .. "textures" .. DIR_DELIM

display_formspec_name = modname .. ":display_formspec_"
display_entity_name = modname .. ':display'
display_item_name  = modname .. ":display_item"
display_remote_item_name = modname .. ":display_remote_item"
display_remote_item_formspec_name = modname .. "display_remote_formspec_"

display_max_size = 50
display_min_size = 1
display_max_textures = 30

displays = {}
nextDisplayIndex = 0
insecure_environment = nil

max_download_length = 2097152 --2MB Increase this to allow bigger images

--#endregion GLOBAL VARIABLES


function  print_warn(msg)
    print('\27[93m'..msg ..'\27[0m')
end

if minetest.request_insecure_environment then
	 insecure_environment = minetest.request_insecure_environment()
	 if not insecure_environment then
        print_warn("[WARNING] Presentation requires an insecure environment to download textures. Add 'secure.trusted_mods = " .. modname .. "' to the minetest.conf to enable this feature.")
     else
        --override package path to recoginze external folder
        local old_path = insecure_environment.package.path
        local old_cpath = insecure_environment.package.cpath
        insecure_environment.package.path = insecure_environment.package.path.. ";" .. modpath .. "/external/?.lua"
        insecure_environment.package.cpath = insecure_environment.package.cpath.. ";" .. modpath .. "/external/?.so"
        --overriding require to insecure require to allow modules to load dependencies
        local old_require = require
        require = insecure_environment.require	

        --load modules
        Http  = require("socket.http")
        Ltn12 = require("ltn12")

        --reset changes
        require = old_require
        insecure_environment.package.path = old_path
        insecure_environment.package.cpath = old_cpath
     end
end

minetest.register_privilege("presentations", {
    description = "Can use and edit presentation displays"
})

local DisplayEntity = {
    initial_properties = {
        hp_max = 1,
        physical = true,
        collide_with_objects = false,
        collisionbox = {-.5, -.5, -.1, .5, .5, .1},
        visual = "mesh",
        mesh = "display.obj",
        visual_size = {x = 1, y = 1},
        textures = {"default.jpg"},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
    },

    id = -1,
    proportions_x = 1.0,
    proportions_y = 1.0,
    size = 1.0,
    allow_changing = false,
    
    texture_names ={"default.jpg"},
    textures_index = 1,
    textures_count = 1,
    downloaded_textures = {}

}

function DisplayEntity:change_textures_to(textures)
    self.texture_names = textures;
    self.current_index = 1
    self:update_texture()
end

function DisplayEntity:set_proportions(x,y)
    self.proportions_x = x;
    self.proportions_y = y;
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
    
    local size_x = self.size * (self.proportions_x / self.proportions_y);
    local size_y = self.size;
    local half_x = size_x * 0.5
    local half_y = size_y * 0.5

    local yaw = self.object:get_yaw()

    if yaw == 0 then
        self.object:set_properties({
            visual_size = {x = size_x, y = size_y},
            collisionbox = {-half_x, -half_y, -.1, half_x, half_y, .1}
        })
    else 
        self.object:set_properties({
            visual_size = {x = size_x, y = size_y},
            collisionbox = {-.1, -half_y, -half_x, .1, half_y, half_x}
        })
    end
end

function DisplayEntity:on_activate(staticdata, dtime_s)
    
    if staticdata ~= nil and staticdata ~= "" then
        local data = minetest.parse_json(staticdata)

        self.id = data.id
        self.proportions_x = data.proportions_x
        self.proportions_y = data.proportions_y
        self.size = data.size
        self.texture_names = data.texture_names
        self.textures_index = data.textures_index
        self.textures_count = data.textures_count
        self.allow_changing = data.allow_changing
        self.downloaded_textures = data.downloaded_textures

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
    --Removed drop as it is bothersome in creative mode
    --minetest.add_item(self.object:get_pos(), display_item_name)
    displays[self.id] = nil
    self.object:remove()
end

function DisplayEntity:destroy_correctly_and_cleanup(calling_player)
    
    if insecure_environment then
        for key, value in pairs(self.downloaded_textures) do
            if file_exists(path_to_textures .. value) then
                insecure_environment.os.remove(path_to_textures .. value)
                msg_player(calling_player, "Removing: " .. value)
            end
        end
    end

    --add cleanup
    self:destroy_correctly()
end

function  DisplayEntity:get_staticdata()
    return minetest.write_json({
        id = self.id,
        proportions_x = self.proportions_x,
        proportions_y = self.proportions_y,
        size = self.size,
        texture_names = self.texture_names,
        textures_index = self.textures_index,
        textures_count = self.textures_count,
        allow_changing = self.allow_changing,
        downloaded_textures = self.downloaded_textures,
    })
end

function  DisplayEntity:goto_next()
    local index = self.textures_index + 1
    self:goto_number(index)
end

function DisplayEntity:goto_previous()
    local index = self.textures_index - 1
    self:goto_number(index)
end

function DisplayEntity:goto_number(index)
    if index > self.textures_count or index < 0 then
        index = 1
    end
    self.textures_index = index
    self:update_texture()
end

function player_lacks_privilage(player)
     return not minetest.check_player_privs(player, { presentations=true }) 
end

function DisplayEntity:on_punch(puncher, time_from_last_punch, tool_capabilities, dir, damage)

    if not self.allow_changing then
            if player_lacks_privilage(puncher) then
            msg_player(puncher, "Can only change this display with the 'presentations' privilage.")
            return true
        end
    end
    
    self:goto_next()
    return true
end

function DisplayEntity:on_rightclick(clicker)
    if player_lacks_privilage(clicker) then
        msg_player(clicker, "You need the 'presentations' privilage to edit displays.")
        return 
    end

    self:show_formspec(clicker)
end

function DisplayEntity:show_formspec(clicker)

    local height = 5.5 + self.textures_count*0.5

    local testSpec = 
    "formspec_version[4]" ..
    "size[10,".. height .."]" ..
    "achor[0,0]"..
    "label[1,0.5; ID: ".. self.id ..";]" ..
    "button_exit[5,0.25; 1.5,.5;Destroy;Destroy;]"  ..
    "button_exit[6.5,0.25; 2.5,.5;DestroyAndCleanup;Destroy And Cleanup;]"  ..
    "tooltip[DestroyAndCleanup; Destroys the display and deletes all the images downloaded through it;#000000;#ffffff]"..
    "label[1,1.25; Move;]" ..
    "button[1,1.5; 1,0.5;MoveRight;X+;]" ..
    "button[2,1.5; 1,0.5;MoveUp;Y+;]" ..
    "button[3,1.5; 1,0.5;MoveForward;Z+;]" ..
    "button[1,2; 1,0.5;MoveLeft;X-;]" ..
    "button[2,2; 1,0.5;MoveDown;Y-;]" ..
    "button[3,2; 1,0.5;MoveBackward;Z-;]" ..
    "button[1,2.5; 1,0.5;ScalePlus;Size+;]" ..
    "button[2,2.5; 1,0.5;ScaleMinus;Size-;]"  ..
    "button[3,2.5; 1,0.5;Rotate;Rotate;]" ..

    "label[5,1.25; Proportions;]"..
    "button[5,1.5; 1,.5;R1_1;1:1;]"  ..
    "button[6,1.5; 1,.5;R16_9;16:9;]"  ..
    "button[7,1.5; 1,.5;R4_3;4:3;]"  ..
    "button[8,1.5; 1,.5;R5_4;5:4;]"  ..
    "field[5,2.5;1,.5;R_CustomX;;".. self.proportions_x .. ";]"..
    "field[6,2.5;1,.5;R_CustomY;;".. self.proportions_y .. ";]"..
    "button[7,2.5; 2,0.5;R_SetToCustom;Apply Custom;]" ..

    "checkbox[1,3.5;AllowChanging;Allow slide changes;".. tostring(self.allow_changing) .."]"..

    "label[1,4.5;URLs:]" ..
    "field[2,4.25;1,.5;Count;Count:;".. self.textures_count .. ";]" ..
    "button[5,4.25;2,.5;UpdateImages; Save URLs]"

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


function handle_display_form(player, formname, fields)
    local id = tonumber(string.sub(formname, display_formspec_name:len()+1));
    local display = displays[id]
    if not display then
        msg_player(player, "Error: no display found with id " .. id)
        return
    end

    if fields.AllowChanging then
    display.allow_changing = tostring(fields.AllowChanging) == "true"
    end

    if fields.Count then
        local number = tonumber(fields.Count)
        if number then
        display.textures_count = math.min(display_max_textures, number)
        end
    end

    if fields.ScalePlus then
        display:set_size(math.min(display.size+1, display_max_size))
    end

    if fields.ScaleMinus then
        display:set_size(math.max(display.size-1, display_min_size))
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

    if fields.Rotate then
        local yaw = display.object:get_yaw()
        if yaw == 0 then
            display.object:set_yaw(math.pi/2)
        else
            display.object:set_yaw(0)
        end

        display:update_size()
    end

    if fields.R16_9 then
        display:set_proportions(16,9)
    end

    if fields.R4_3 then
        display:set_proportions(4,3)
    end

    if fields.R5_4 then
        display:set_proportions(5,4)
    end

    if fields.R1_1 then
        display:set_proportions(1,1)
    end

    if fields.R_SetToCustom then
        local X = tonumber(fields.R_CustomX)
        local Y = tonumber(fields.R_CustomY)
        if X and Y and Y ~= 0 and X ~= 0 then
            display:set_proportions(X,Y)
        end
    end

    if fields.Destroy then
        display:destroy_correctly()
    end

    if fields.DestroyAndCleanup then
        display:destroy_correctly_and_cleanup(player)
    end
    
    if fields.UpdateImages then
        local newTextures = {}
        for i = 1, display.textures_count, 1 do
            local current = "URL"..i;
            local url = fields[current]
            newTextures[i] = "default.jpg"

            if url and url ~= "" then
                local valid = ends_with_one_of(url, {".jpg", ".jpeg", ".JPG", ".png", ".PNG"})
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
                            table.insert(display.downloaded_textures,name)
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
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if starts_with(formname, display_formspec_name) then
        handle_display_form(player, formname, fields)
    elseif starts_with(formname, display_remote_item_formspec_name) then
        handle_display_remote_form(player, formname, fields)
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

        if not Http or not Ltn12 or not insecure_environment then
            msg_player(requester, "[ERROR] Unable to make http request. (" .. modname .. " requires insecure environment permissions to download textures." )
            return false
        end
        
        if starts_with(url, "https") then

            msg_player(requester, "[ERROR] Https is not supported at the moment.")
            return false
        end

        msg_player(requester, "HTTP Request: " .. url)

        --do a HEAD request first to check for and content-length
        local client, code, headers = Http.request({url=url, method ="HEAD"})

        if code ~= 200 then

            --handle permanent redirect
            if code == 301 then
                local location = headers["location"]
                if location then
                    msg_player(requester, "301 - Redirected to " .. location)
                    return download_and_save_texture(requester, location, name)
                else
                    msg_player(requester, "[ERROR] 301 - Redirection failed ")
                    return false
                end
            end

            msg_player(requester, "[ERROR] HTTP code " ..code)
            return false
        end

        local size = tonumber(headers["content-length"]);

        if not size then
            msg_player(requester, "[ERROR] unable to get content-length")
            return false
        end

        if size > max_download_length then
            msg_player(requester, "[ERROR] filesize of " .. tostring(size) .." bytes exceeds max size of " .. tostring(max_download_length) .. " bytes")
            return false
        end

        --actual HTTP GET to download the content
		local resp   = {}
		local client, code, headers, status = Http.request({url=url, sink=Ltn12.sink.table(resp), method="GET" })
            
        if code ~= 200 then
            msg_player(requester, "[ERROR] HTTP code " ..code)
            return false
        end
            if resp then
                local data = table.concat(resp);
                if data then
                    
                    local path =  path_to_textures .. name
                    local file = insecure_environment.io.open(path, "w+")
                    insecure_environment.io.output(file)
                    insecure_environment.io.write(data)
                    insecure_environment.io.close(file)
                    if minetest.dynamic_add_media then
                        minetest.dynamic_add_media(path)
                        msg_player(requester, "Downloaded and dynamically added " .. name)
                    else 
                        msg_player(requester, "Downloaded " .. name .. ". [WARNING] Failed to add dynamically (dynamic_add_media). This feature requires 5.3.0 or newer." ..
                        "The image should be available on server restart.") 
                    end
                    
                    return true
                end
            end

    msg_player(requester, "[ERROR] Unknown download error")
    return false
end


minetest.register_craftitem(display_item_name,{
    description = "Display",
    inventory_image = "display_item.png",
    on_place = function(itemstack, user, pointed_thing)

        if pointed_thing.type == "node" then
        minetest.add_entity(pointed_thing.above,  display_entity_name)
        
        --Displays are not consumed as this is meant as a creative mode only tool
        --itemstack:take_item()
        end
        return itemstack
    end
})


minetest.register_craftitem(display_remote_item_name, {
    description = "Display Remote",
    inventory_image = "display_remote_item.png",
    on_use = function (itemstack, user, pointed_thing)
        local meta = itemstack:get_meta()

    if pointed_thing then
        if pointed_thing.type == "object" then
        
            if pointed_thing.ref then
            if pointed_thing.ref.get_luaentity then
                local entity = pointed_thing.ref:get_luaentity()
                if entity then
                    meta:set_int("display_id", entity.id)
                    msg_player(user, "[Display Remote] Bound to display with ID " .. entity.id)
                    return itemstack
                end
        end
        end
        end
        
        local id = meta:get_int("display_id")
        if id >= 0 and displays[id] ~= nil then
            minetest.show_formspec(user:get_player_name(), display_remote_item_formspec_name .. id, get_remote_formspec(id))
        end
    end

        return itemstack
    end
    
})

function get_remote_formspec(id)
    
    local formspec = ""
    
    if id < 0 or displays[id] == nil then 
       formspec = "formspec_version[4]" ..
       "size[5,5]" ..
       "achor[0,0]" ..
    "label[1,1; Bound to no display, leftclick on a display to connect;]" 
    else
        local display = displays[id]
        local sizeY = 5.5 + math.floor(display.textures_count/5) * 0.5

        formspec = "formspec_version[4]" ..
        "size[5,".. sizeY .."]" ..
        "achor[0,0]" ..
        "label[1,1; Bound to display #".. id.." ] " ..
        "label[1,2; Currently: " .. display.textures_index .. "/" .. display.textures_count .."]" ..
        "button[1,3;1,1;Left;<-;]" ..
        "button[3,3;1,1;Right;->;]"

        for i = 1, display.textures_count, 1 do
            local igrid = i-1
            local x = (igrid % 5)
            local y = 4.5 + math.floor(igrid/5) * 0.5
            formspec = formspec ..
            "button["..x .. "," .. y .. ";1,.5;goto_" .. i .. ";" .. i .. ";]"
        end

        --current slide, next / previous buttons
        -- buttons for each slide
    end
    return formspec
end

function handle_display_remote_form(player, formname, fields)
    local id = tonumber(string.sub(formname, display_remote_item_formspec_name:len()+1))
    --msg_player(player, "Received form ID:" .. id)
    local display = displays[id]

    if display then
        if fields.Right then
            msg_player(player, "Pressed right")
            display:goto_next()


        elseif fields.Left then
            display:goto_previous()
            msg_player(player, "Pressed left")

        else

            for i = 1, display.textures_count, 1 do
                if fields["goto_"..i] then
                    display:goto_number(i)
                    msg_player(player,"pressed " ..i)
                    return
                end
            end

        end
    else
        msg_player(player, "no display with ID:" .. id)
    end
end

minetest.register_chatcommand("log_presentation_textures", {
    privs = {
        presentations = true,
    },
    func = function(name, param)
        if not insecure_environment then
        return false
        end

        local msg = "DOWNLOADED TEXTURES:"
        msg = msg.. "NOT IMPLEMENTED YET"
        return true, msg
    end
})



print("[OK] Presentations")