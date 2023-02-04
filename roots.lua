-- title:  TBD
-- author: Torakko, Hattes, sfabian
-- desc:   Game made for Global Game Jam 2023.
-- script: lua

------ CONSTANTS ----------
-- size
HEIGHT = 136
WIDTH = 240
TILE_SIZE = 8
TILE_HEIGHT = 77 -- 136 / 8
TILE_WIDTH = 30 -- 240 / 8
CAMERA_MAX = 1680 -- map_width - screen_width -> 240*8 - 30*8 = 1680

-- buttons
BUTTON_UP = 0
BUTTON_DOWN = 1
BUTTON_LEFT = 2
BUTTON_RIGHT = 3
BUTTON_Z = 4
BUTTON_X = 5
BUTTON_A = 6
BUTTON_S = 7

-- colors (default palette SWEETIE-16)
BLACK = 0
PURPLE = 1
RED = 2
ORANGE = 3
YELLOW = 4
LIGHT_GREEN = 5
GREEN = 6
DARK_GREEN = 7
DARK_BLUE = 8
BLUE = 9
LIGHT_BLUE = 10
CYAN = 11
WHITE = 12
LIGHT_GREY = 13
GREY = 14
DARK_GREY = 15

-- tile flags
TILE_SOLID = 0
TILE_DEADLY = 1
TILE_WINNING = 2

-- directions
DIR_UP = 1
DIR_DOWN = 2
DIR_LEFT = 3
DIR_RIGHT = 4
DIR_DOWN_LEFT = 5
DIR_DOWN_RIGHT = 6
DIR_UP_LEFT = 7
DIR_UP_RIGHT = 8

-- states
STATE_INIT = 1
STATE_MENU = 2
STATE_GAME = 3

-- entity states
ENTITY_STATE_DAMAGED = 1
ENTITY_STATE_DEFAULT = 2
ENTITY_STATE_UPPER_ROW = 3
ENTITY_STATE_LOWER_ROW = 4
ENTITY_STATE_GOING_UP = 5
ENTITY_STATE_GOING_DOWN = 6

-- sprites
SPR_TOOTH = {
    [ENTITY_STATE_DAMAGED] = {sprite=3, width=2, height=2},
    [ENTITY_STATE_DEFAULT] = {sprite=1, width=2, height=2},
}
SPR_LOGO = 33
SPR_CANDY = 272
SPR_ICECREAM = 273
SPR_SODA = 274

SPR_PLAYER = {
    [ENTITY_STATE_UPPER_ROW] = {sprite=256, rotation=2},
    [ENTITY_STATE_LOWER_ROW] = {sprite=256},
    [ENTITY_STATE_GOING_UP] = {sprite=256},
    [ENTITY_STATE_GOING_DOWN] = {sprite=256}
}


-- entities
TEETH = {
    {x=05, y=02, flip=03},
    {x=07, y=02, flip=03},
    {x=09, y=02, flip=03},
    {x=11, y=02, flip=03},
    {x=13, y=02, flip=03},
    {x=15, y=02, flip=02},
    {x=17, y=02, flip=02},
    {x=19, y=02, flip=02},
    {x=21, y=02, flip=02},
    {x=23, y=02, flip=02},
    {x=05, y=13, flip=01},
    {x=07, y=13, flip=01},
    {x=09, y=13, flip=01},
    {x=11, y=13, flip=01},
    {x=13, y=13, flip=01},
    {x=15, y=13, flip=00},
    {x=17, y=13, flip=00},
    {x=19, y=13, flip=00},
    {x=21, y=13, flip=00},
    {x=23, y=13, flip=00},
}

-- timeouts
TIMEOUT_SHOT = 1

-- other
PLAYER_SPEED = 2
BULLET_SPEED = 2

CANDY_DATA = {
        name="Candy",
        sprite=SPR_CANDY,
        health=1,
        speed=0.5,
}
ICECREAM_DATA = {
        name="Icecream",
        sprite=SPR_ICECREAM,
        health=2,
        speed=0.25,
}
SODA_DATA = {
        name="Soda",
        sprite=SPR_SODA,
        health=3,
        speed=0.125,
}

------ GLOBAL VARIABLES ----------
t = 0
x_pos = 96
y_pos = 24
state = STATE_INIT
player = {}
timeouts = {}
bullets = {}

------ UTILITIES ------
function add(list, elem)
    list[#list+1] = elem
end

function del(list, elem)
    local found = false
    for i=1, #list do
        if found then
            list[i-1] = list[i]
        end
        if list[i] == elem then
            found = true
        end
    end
    if found then
        list[#list] = nil
    end
end

function print_centered(string, y, color, fixed, scale, smallfont)
    y = y or 0
    color = color or DARK_GREY
    fixed = fixed or false
    scale = scale or 1
    smallfont = smallfont or false
    local string_width = print(string, -100, -100, color, fixed, scale, smallfont)
    print(string, (WIDTH-string_width)//2, y, color, fixed, scale, smallfont)
end

function inarray(needle, haystack)
  for _, hay in ipairs(haystack) do
    if hay == needle then
      return true
    end
  end
  return false
end

function print_with_border(text, x, y)
    print(text, x-1, y, DARK_GREY, false, 1, false)
    print(text, x, y-1, DARK_GREY, false, 1, false)
    print(text, x+1, y, DARK_GREY, false, 1, false)
    print(text, x, y+1, DARK_GREY, false, 1, false)
    print(text, x, y, WHITE, false, 1, false)
end

------ FUNCTIONS -----------
function TIC()
    if state == STATE_INIT then
        --music(02)
        --state = STATE_MENU
        init()
        state = STATE_GAME
    elseif state == STATE_MENU then
        update_menu()
        draw_menu()
    elseif state == STATE_GAME then
        update_game()
        draw_game()
    end
    t = t + 1
end

------ MENU ---------------
function update_menu()
    if btnp(BUTTON_Z) then
        init()
        state = STATE_GAME
    end
end

function draw_menu()
    cls(BLACK)
    print_centered("Teeth protector", 45, ORANGE, false, 2)
    print_centered("Press Z to start", 80, ORANGE)
end

------ GAME ---------------
function init()
    t = 0
    teeth = {}
    candy = {}
    icecream = {}
    soda = {}
    spawn_teeth()
    init_player()
    timeouts = {[TIMEOUT_SHOT] = 0}
    bullets = {}
end

function spawn_teeth()
    row_x = 32
    upper_row_y = 2
    lower_row_y = HEIGHT - 18
    teeth_in_row = 12
    for i=row_x, teeth_in_row * 16, 16 do
        x = i
        y = upper_row_y
        add(teeth, {name=string.format('tooth on %d,%d', x, y),
                    sprites=SPR_TOOTH,
                    x=x,
                    y=y,
                    flip=2,
                    health=2})
        y = lower_row_y
        add(teeth, {name=string.format('tooth on %d,%d', x, y),
                    sprites=SPR_TOOTH,
                    x=x,
                    y=y,
                    flip=0,
                    health=2})
    end
end

function spawn_tooth(data)
    local new_tooth = {
        name=string.format('tooth on %d,%d', data.x, data.y),
        sprites=SPR_TOOTH,
        x=data.x,
        y=data.y,
        tileX=data.x,
        tileY=data.y,
        flip=data.flip,
        health=2,
    }
    add(teeth,new_tooth)
end

function spawn_enemy(data)
    -- min_x = 5, max_x = 24
    local x = 5 + math.random() * (24-5)
    local dir = ENTITY_STATE_GOING_DOWN
    if math.random() > 0.5 then
        dir = ENTITY_STATE_GOING_UP
    end
    local new_enemy = {
        name=data.name,
        sprite=data.sprite,
        x=x*8,
        y=8*8,
        tileX=x,
        tileY=y,
        flip=0,
        health=data.health,
        direction=dir,
        width=1,
        height=1,
        speed=data.speed,
    }
    return new_enemy
end

function spawn_candy()
    add(candy,spawn_enemy(CANDY_DATA))
end

function spawn_icecream()
    add(icecream,spawn_enemy(ICECREAM_DATA))
end

function spawn_soda()
    add(soda,spawn_enemy(SODA_DATA))
end

function update_game()
    handle_input()
    update_player()
    update_enemies()
    update_bullets()
    update_timeouts()
end

function update_timeouts()
    for i=#timeouts,1,-1 do
        timeouts[i] = timeouts[i] - 1
    end
end

function update_enemies()
    move_enemy_list(candy)
    move_enemy_list(icecream)
    move_enemy_list(soda)
    if t % 50 == 0 then
        spawn_candy()
    elseif t % 90 == 0 then
        spawn_icecream()
    elseif t % 130 == 0 then
        spawn_soda()
    end
end

function move_enemy_list(list)
    for _, enemy in ipairs(list) do
        if enemy.direction == ENTITY_STATE_GOING_DOWN then
            enemy.y = enemy.y+enemy.speed
        elseif enemy.direction == ENTITY_STATE_GOING_UP then
            enemy.y = enemy.y-enemy.speed
        end
    end
end

function init_player()
    player = {
        x = (WIDTH/2) - 4,
        y = HEIGHT - 30,
        state = ENTITY_STATE_LOWER_ROW,
    }
end

function draw_game()
    cls(DARK_GREY)
    map(0, 0, -- map coordinates
    32, 18, -- width, height
    0, 0) -- screen pos
    draw_teeth()
    draw_enemy_list(candy)
    draw_enemy_list(icecream)
    draw_enemy_list(soda)
    draw_player()
    draw_bullets()
end

function draw_teeth()
    for _, tooth in ipairs(teeth) do
        draw_tooth(tooth)
    end
end

function draw_tooth(tooth)
    local sprite_data = tooth.sprites[tooth.health]
    spr(sprite_data.sprite,
        tooth.x,
        tooth.y,
        BLACK,
        1,
        tooth.flip,
        0,
        sprite_data.width,
        sprite_data.height)
end

function draw_enemy_list(list)
    for _, enemy in ipairs(list) do
        draw_enemy(enemy)
    end
end

function draw_enemy(enemy)
    --trace(enemy.name)
    spr(enemy.sprite,
        enemy.x,
        enemy.y,
        BLACK,
        1,
        0,
        0,
        enemy.width,
        enemy.height)
end

-- spr(id x y colorkey=-1 scale=1 flip=0 rotate=0 w=1 h=1)
function draw_player()
    spr(SPR_PLAYER[player.state].sprite,
        player.x,player.y,BLACK,
        1, 0, SPR_PLAYER[player.state].rotation)
end

function draw_bullets()
    for _, bullet in ipairs(bullets) do
        rect(bullet.x,
             bullet.y,
             2,
             2,
             ORANGE)
    end
end

function handle_input()
    if player.state == ENTITY_STATE_LOWER_ROW or player.state == ENTITY_STATE_UPPER_ROW then
        handle_input_on_row()
    elseif player.state == ENTITY_STATE_GOING_UP or player.state == ENTITY_STATE_GOING_DOWN then
    end
    if btn(BUTTON_X) then
        state = STATE_MENU
    end
end

function handle_input_on_row()
    if player.state == ENTITY_STATE_LOWER_ROW and btn(BUTTON_UP) then
        player.state = ENTITY_STATE_GOING_UP
    elseif player.state == ENTITY_STATE_UPPER_ROW and btn(BUTTON_DOWN) then
        player.state = ENTITY_STATE_GOING_DOWN
    end

    x_min = 32
    x_max = 204
    if btn(BUTTON_LEFT) then
        player.x = player.x - PLAYER_SPEED
        player.x = math.max(player.x, x_min)
    end
    if btn(BUTTON_RIGHT) then
        player.x = player.x + PLAYER_SPEED
        player.x = math.min(player.x, x_max)
    end
    if btnp(BUTTON_Z) then
        shoot()
    end
end

function shoot()
    if timeouts[TIMEOUT_SHOT] > 0 then
        return
    end
    timeouts[TIMEOUT_SHOT] = 20
    bullet = {x=player.x+3}
    bullet.dx = 0
    if player.state == ENTITY_STATE_UPPER_ROW then
        bullet.dy = BULLET_SPEED
        bullet.y = player.y + 8
    elseif player.state == ENTITY_STATE_LOWER_ROW then
        bullet.dy = 0 - BULLET_SPEED
        bullet.y = player.y
    end
    add(bullets, bullet)
    -- spawn bullet
    -- start timeout
end

function update_player()
    if player.state == ENTITY_STATE_GOING_UP then
        player.state = ENTITY_STATE_UPPER_ROW
        player.y = 22
    elseif player.state == ENTITY_STATE_GOING_DOWN then
        player.state = ENTITY_STATE_LOWER_ROW
        player.y = HEIGHT - 30
    end
end

function update_bullets()
    for i, bullet in ipairs(bullets) do
        bullet.x = bullet.x + bullet.dx
        bullet.y = bullet.y + bullet.dy
        if bullet.y > HEIGHT or bullet.y < 0 or bullet.x > WIDTH or bullet.x < 0 then
            del(bullets, bullet)
        end
    end
end


-- <TILES>
-- 000:2222222222222222222222222222222222222222222222222222222222222222
-- 001:000ccc0000cccccc0ccccccccccccccccccccccccccccccccccccccccccccccc
-- 002:00ccc000cccccc00ccccccc0cccccccccccccccccccccccccccccccccccccccc
-- 003:000ccc0000cccccc0cccccccffccccccccffccccccccffcccccccffcccccccff
-- 004:0cccc000cccccf00ccccfc00cccfccd0ccfcccd0cffcccdecfccccdefcccccde
-- 005:000aaa0000a000aa0a000000a0000000a0000000a0000000a0000000a0000000
-- 006:00aaa000aa000a00000000a00000000a0000000a0000000a0000000a0000000a
-- 007:000bbb0000baaabb0ba000aaba000000ba000000ba000000ba000000ba000000
-- 008:00bbb000bbaaab00aa000ab0000000ab000000ab000000ab000000ab000000ab
-- 017:cccccccccccccccccccccccccccccccccccccccc0ccccccc2ccccccc2cccc222
-- 018:ccccccccccccccccccccccccccccccccccccccccccccccc0ccccccc2222cccc2
-- 019:cccccccfcccccfffcccfffcccfffccccfccccccccccccccccccccccccc222222
-- 020:fcccccdeffccccdecffcccdeccfffcdeccccffdeccccccdeccccccde2222ccde
-- 021:a0000000a0000000a0000000a0000000a00000000a0000000a000aaa0aaaa000
-- 022:0000000a0000000a0000000a0000000a0000000a000000a0aaa000a0000aaaa0
-- 023:ba000000ba000000ba000000ba000000ba0000000ba00aaa0baaabbb0bbbb000
-- 024:000000ab000000ab000000ab000000ab000000abaaa00ab0bbbaaab0000bbbb0
-- 033:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 034:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 049:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 050:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <SPRITES>
-- 000:000c4000000c40000094490000aaaa0009aaaa900aaaaaa09a0000a9a000000a
-- 001:0c4000000c44000009a4900009aaa90009aaaa9009aaaaa909a0000a09a00000
-- 016:00000000000cc00090ccc90999cc9c9999c9cc99909ccc09000cc00000000000
-- 017:000cc00000cccc0000bbbb0000bbbb0000aaaa00000330000003300000033000
-- 018:00ddddd000222220002ccc20002c2220002c2220002ccc200022222000ddddd0
-- </SPRITES>

-- <MAP>
-- 001:000000000101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:000000000101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:000000010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000001010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000001010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000001010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000001010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000001010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000001010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000001010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:000000000101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:000000000101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

