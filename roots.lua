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

-- sprites
SPR_TOOTH = {
    [ENTITY_STATE_DAMAGED] = {sprite=3, width=2, height=2},
    [ENTITY_STATE_DEFAULT] = {sprite=1, width=2, height=2},
}
SPR_LOGO = 33
SPR_PLAYER_STRAIGHT = 256
SPR_PLAYER_TILTED = 257

-- player constants
ROW_UPPER = 0
ROW_LOWER = 1
ENTITY_STATE_ON_ROW = 0
ENTITY_STATE_GOING_UP = 1
ENTITY_STATE_GOING_DOWN = 2


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

------ GLOBAL VARIABLES ----------
t = 0
x_pos = 96
y_pos = 24
state = STATE_INIT
player = {}

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
        init_player()
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
    spawn_teeth()
end

function spawn_teeth()
    for _, tooth_data in ipairs(TEETH) do
        spawn_tooth(tooth_data)
    end
end

function spawn_tooth(data)
    local new_tooth = {
        name=string.format('tooth on %d,%d', data.x, data.y),
        sprites=SPR_TOOTH,
        x=data.x*8,
        y=data.y*8,
        tileX=data.x,
        tileY=data.y,
        flip=data.flip,
        health=2,
    }
    teeth[#teeth+1]=new_tooth
end

function update_game()
    handle_input()
    update_player()
end

function init_player()
    player = {
        x = 0,
        row = ROW_LOWER,
        state = ENTITY_STATE_ON_ROW,
    }
end

function draw_game()
    cls(DARK_GREY)
    map(0, 0, -- map coordinates
    32, 18, -- width, height
    0, 0) -- screen pos
    draw_teeth()
    draw_player()
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

-- spr(id x y colorkey=-1 scale=1 flip=0 rotate=0 w=1 h=1)
function draw_player()
    PLAYER_X_MIN = 16
    PLAYER_X_MAX = WIDTH - 24

    x_pos = PLAYER_X_MIN + player.x
    if player.row == ROW_UPPER then
        y_pos = 6
        rotation = 2
    else
        y_pos = HEIGHT - 14
        rotation = 0
    end

    spr(SPR_PLAYER_STRAIGHT,x_pos,y_pos,BLACK, 1, 0, rotation)
end

function handle_input()
    if player.state == ENTITY_STATE_ON_ROW then
        handle_input_on_row()
    elseif player.state == ENTITY_STATE_GOING_UP or player.state == ENTITY_STATE_GOING_DOWN then
    end
    if btn(BUTTON_X) then
        state = STATE_MENU
    end
end

function handle_input_on_row()
    if player.row == ROW_LOWER and btn(BUTTON_UP) then
        player.state = ENTITY_STATE_GOING_UP
    elseif player.row == ROW_UPPER and btn(BUTTON_DOWN) then
        player.state = ENTITY_STATE_GOING_DOWN
    end

    min_pos = 0
    max_pos = 200
    if btn(BUTTON_LEFT) then
        player.x = player.x - 1
        player.x = math.max(player.x, min_pos)
    end
    if btn(BUTTON_RIGHT) then
        player.x = player.x + 1
        player.x = math.min(player.x, max_pos)
    end
end

function update_player()
    if player.state == ENTITY_STATE_GOING_UP then
        player.row = ROW_UPPER
        player.state = ENTITY_STATE_ON_ROW
    elseif player.state == ENTITY_STATE_GOING_DOWN then
        player.row = ROW_LOWER
        player.state = ENTITY_STATE_ON_ROW
    end
end


-- <TILES>
-- 000:2222222222222222222222222222222222222222222222222222222222222222
-- 001:000ccc0000cccccc0ccccccccccccccccccccccccccccccccccccccccccccccc
-- 002:0cccc000cccccc00cccccc00ccccccd0ccccccd0ccccccdeccccccdeccccccde
-- 003:000ccc0000cccccc0cccccccffccccccccffccccccccffcccccccffcccccccff
-- 004:0cccc000cccccf00ccccfc00cccfccd0ccfcccd0cffcccdecfccccdefcccccde
-- 017:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc222222
-- 018:ccccccdeccccccdeccccccdeccccccdeccccccdeccccccdeccccccde2222ccde
-- 019:cccccccfcccccfffcccfffcccfffccccfccccccccccccccccccccccccc222222
-- 020:fcccccdeffccccdecffcccdeccfffcdeccccffdeccccccdeccccccde2222ccde
-- 033:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 034:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 049:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 050:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <SPRITES>
-- 000:000c4000000c40000094490000aaaa0009aaaa900aaaaaa09a0000a9a000000a
-- 001:0c4000000c44000009a4900009aaa90009aaaa9009aaaaa909a0000a09a00000
-- </SPRITES>

-- <MAP>
-- 002:000000000001010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:000000000001010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000000101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000000010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000000101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000000001010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:000000000001010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

