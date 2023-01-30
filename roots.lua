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



------ GLOBAL VARIABLES ----------
t = 0
state = STATE_INIT

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
        state = STATE_MENU
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
        state = STATE_GAME
    end
end

function draw_menu()
    cls(BLACK)
    --spr(SPRITE_MENU_BOHR,0,40,BLACK,6,0,0,1,2)
    --spr(SPRITE_MENU_BOHR,192,40,BLACK,6,1,0,1,2)
    --spr(SPRITE_MENU_CAT_OPEN,64,88,BLACK,3,0,0,2,2)
    --spr(SPRITE_MENU_CAT_CLOSED,128,88,BLACK,3,1,0,2,2)
    print_centered("GAME NAME!!", 10, ORANGE, false, 2)
    print_centered("Press Z to start", 75, ORANGE)
end

------ GAME ---------------
function update_game()
    handle_input()
end

function draw_game()
    cls(BLACK)
    print_centered("We are playing!!", 10, ORANGE, false, 2)
end

function handle_input()
    if btn(BUTTON_X) then
        state = STATE_MENU
    end
end

function handle_move_input(player)
    player.move_state = ENTITY_STATE_MOVE
    if btn(BUTTON_UP) and btn(BUTTON_LEFT) then
        moveEntity(player, -PLAYER_SPEED, -PLAYER_SPEED, DIR_UP_LEFT)
    elseif btn(BUTTON_UP) and btn(BUTTON_RIGHT) then
        moveEntity(player,  PLAYER_SPEED, -PLAYER_SPEED, DIR_UP_RIGHT)
    elseif btn(BUTTON_DOWN) and btn(BUTTON_LEFT) then
        moveEntity(player, -PLAYER_SPEED,  PLAYER_SPEED, DIR_DOWN_LEFT)
    elseif btn(BUTTON_DOWN) and btn(BUTTON_RIGHT) then
        moveEntity(player,  PLAYER_SPEED,  PLAYER_SPEED, DIR_DOWN_RIGHT)
    elseif btn(BUTTON_UP) then
        moveEntity(player,             0, -PLAYER_SPEED, DIR_UP)
    elseif btn(BUTTON_DOWN) then
        moveEntity(player,             0,  PLAYER_SPEED, DIR_DOWN)
    elseif btn(BUTTON_LEFT) then
        moveEntity(player, -PLAYER_SPEED,             0, DIR_LEFT)
    elseif btn(BUTTON_RIGHT) then
        moveEntity(player,  PLAYER_SPEED,             0, DIR_RIGHT)
    else
        player.move_state = ENTITY_STATE_STILL
    end
    player.tileX = math.floor(player.x/8)
    player.tileY = math.floor(player.y/8)
end

