-- PULSAR
-- Mansour Quddus

function _config()
  return {
    name = "PULSAR",
    game_id = "com.usagi.pulsar",
    game_width = 320,
    game_height = 180,
    pause_menu = true,
  }
end

--  Constants 

local W = usagi.GAME_W   -- 320
local H = usagi.GAME_H   -- 180
local CX = W / 2
local CY = H / 2

local ARENA_MARGIN = 12
local BALL_R = 4
local ORB_R  = 3

local GRAVITY_STRENGTH = 280
local BOUNCE_DAMPEN    = 0.82
local SPEED_CAP        = 220

local WALL_PULSE_SPEED_BASE = 6
local WALL_PULSE_SPEED_RAMP = 0.5
local WALL_MIN_SIZE         = 40

local RED_STAR_R             = 5
local RED_STAR_LIFE_BASE     = 4.0
local RED_STAR_INTERVAL_BASE = 12.5
local RED_STAR_SPAWN_SCORE   = 20

local WHITE_DWARF_R             = 3
local WHITE_DWARF_LIFE          = 7.0
local WHITE_DWARF_INTERVAL_BASE = 14.0
local WHITE_DWARF_SPAWN_SCORE   = 35
local WHITE_DWARF_SPEED_BASE    = 200
local WHITE_DWARF_FREEZE_BASE   = 5.0

local GRAV_WELL_LIFE_BASE     = 5.0
local GRAV_WELL_INTERVAL_BASE = 16.0
local GRAV_WELL_SPAWN_SCORE   = 55
local GRAV_WELL_EFFECT_BASE   = 5.0
local GRAV_WELL_RADIUS_BASE   = 40
local GRAV_WELL_PULL          = 90
local GRAV_WELL_RED_PUSH      = 110
local GRAV_WELL_RED_KILL_SPD  = 160

local PLASMA_DISK_LIFE           = 5.0
local PLASMA_DISK_INTERVAL_BASE  = 13.0
local PLASMA_DISK_INTERVAL_FAST  = 8.0
local PLASMA_DISK_SPAWN_SCORE    = 25
local PLASMA_DISK_LONG_HOLD      = 13.0
local PLASMA_DISK_DETONATE_RANGE = 45

local SHOP_EVERY = 20

local COMBO_WINDOW = 1.2
local COMBO_MAX    = 6

local NEAR_MISS_MIN = 0
local NEAR_MISS_MAX = 12
local NEAR_MISS_CD  = 0.8

local FREEZE_GRAV_MULT = 2.0

local PICKUP_LABEL_DURATION = 2.0   -- seconds the pickup name stays on screen

-- Colors (Pico-8 palette)
local C_BG        = gfx.COLOR_BLACK
local C_WALL      = gfx.COLOR_DARK_PURPLE
local C_WALL2     = gfx.COLOR_INDIGO
local C_BALL      = gfx.COLOR_WHITE
local C_BALL_TR   = gfx.COLOR_LIGHT_GRAY
local C_ORB       = gfx.COLOR_YELLOW
local C_ORB2      = gfx.COLOR_ORANGE
local C_GRAV      = gfx.COLOR_PEACH
local C_SCORE     = gfx.COLOR_WHITE
local C_HI        = gfx.COLOR_YELLOW
local C_DEAD      = gfx.COLOR_RED
local C_STARS     = gfx.COLOR_DARK_BLUE
local C_TITLE     = gfx.COLOR_PINK
local C_SUB       = gfx.COLOR_LIGHT_GRAY
local C_DWARF     = gfx.COLOR_WHITE
local C_DWARF_GLOW = gfx.COLOR_BLUE
local C_WELL      = gfx.COLOR_DARK_PURPLE
local C_WELL2     = gfx.COLOR_INDIGO
local C_WELL_CTR  = gfx.COLOR_WHITE
local C_WELL_AUR  = gfx.COLOR_INDIGO
local C_DISK      = gfx.COLOR_RED
local C_DISK2     = gfx.COLOR_ORANGE
local C_SHOP_BG   = gfx.COLOR_DARK_BLUE
local C_SHOP_BRD  = gfx.COLOR_INDIGO
local C_SHOP_HL   = gfx.COLOR_YELLOW
local C_SHOP_TXT  = gfx.COLOR_WHITE
local C_SHOP_SUB  = gfx.COLOR_LIGHT_GRAY
local C_SHOP_KEY  = gfx.COLOR_PEACH
local C_COMBO     = gfx.COLOR_YELLOW
local C_COMBO_HI  = gfx.COLOR_ORANGE
local C_NEAR_MISS = gfx.COLOR_PEACH

-- Upgrade system 

local U = {}

local function reset_upgrades()
  U.red_star_interval    = RED_STAR_INTERVAL_BASE
  U.red_star_life        = RED_STAR_LIFE_BASE
  U.white_dwarf_interval = WHITE_DWARF_INTERVAL_BASE
  U.white_dwarf_freeze   = WHITE_DWARF_FREEZE_BASE
  U.white_dwarf_speed    = WHITE_DWARF_SPEED_BASE
  U.grav_well_interval   = GRAV_WELL_INTERVAL_BASE
  U.grav_well_effect     = GRAV_WELL_EFFECT_BASE
  U.grav_well_radius     = GRAV_WELL_RADIUS_BASE
  U.plasma_disk_interval = PLASMA_DISK_INTERVAL_BASE
  U.orb_push             = 10
  U.bounce_dampen        = BOUNCE_DAMPEN
  U.speed_cap            = SPEED_CAP
  U.wall_speed_base      = WALL_PULSE_SPEED_BASE
end

local PERK_POOL = {
  {
    label = "Red Star Timer +2s",
    desc  = "Red stars spawn less frequently",
    apply = function(u) u.red_star_interval = u.red_star_interval + 2.0 end,
  },
  {
    label = "Red Star Life +1s",
    desc  = "Red stars vanish sooner",
    apply = function(u) u.red_star_life = u.red_star_life + 1.0 end,
  },
  {
    label = "Freeze Duration +1s",
    desc  = "White Dwarf freezes last longer",
    apply = function(u) u.white_dwarf_freeze = u.white_dwarf_freeze + 1.0 end,
  },
  {
    label = "Dwarf Speed -20",
    desc  = "White Dwarf moves slower, easier to catch",
    apply = function(u) u.white_dwarf_speed = math.max(60, u.white_dwarf_speed - 20) end,
  },
  {
    label = "Dwarf Timer -2s",
    desc  = "White Dwarfs appear more often",
    apply = function(u) u.white_dwarf_interval = math.max(4.0, u.white_dwarf_interval - 2.0) end,
  },
  {
    label = "Gravity Well +1.5s",
    desc  = "Gravity Well effect lasts longer",
    apply = function(u) u.grav_well_effect = u.grav_well_effect + 1.5 end,
  },
  {
    label = "Gravity Well Radius +8",
    desc  = "Orb magnet pull reaches farther",
    apply = function(u) u.grav_well_radius = u.grav_well_radius + 8 end,
  },
  {
    label = "Gravity Well Timer -2s",
    desc  = "Gravity Wells appear more often",
    apply = function(u) u.grav_well_interval = math.max(6.0, u.grav_well_interval - 2.0) end,
  },
  {
    label = "Plasma Disk Timer -2s",
    desc  = "Plasma Disks appear more often",
    apply = function(u) u.plasma_disk_interval = math.max(4.0, u.plasma_disk_interval - 2.0) end,
  },
  {
    label = "Orb Push +5px",
    desc  = "Collecting orbs pushes walls back farther",
    apply = function(u) u.orb_push = u.orb_push + 5 end,
  },
  {
    label = "Wall Speed -0.5",
    desc  = "Arena collapses slightly slower",
    apply = function(u) u.wall_speed_base = math.max(1.0, u.wall_speed_base - 0.5) end,
  },
  {
    label = "Speed Cap +20",
    desc  = "Your star can move faster",
    apply = function(u) u.speed_cap = u.speed_cap + 20 end,
  },
  {
    label = "Bouncier Walls",
    desc  = "Walls retain more of your momentum",
    apply = function(u) u.bounce_dampen = math.min(0.99, u.bounce_dampen + 0.04) end,
  },
}

local function pick_offers()
  local offers = {}
  for _ = 1, 3 do
    local idx = math.random(1, #PERK_POOL)
    table.insert(offers, PERK_POOL[idx])
  end
  return offers
end

-- Helpers 

local function predict_trajectory(ball, arena, gx, gy, steps, dt)
  local x, y = ball.x, ball.y
  local vx, vy = ball.vx, ball.vy
  local pts = {}

  local left   = arena.x + BALL_R
  local right  = arena.x + arena.w - BALL_R
  local top    = arena.y + BALL_R
  local bottom = arena.y + arena.h - BALL_R

  for i = 1, steps do
    vx = vx + gx * GRAVITY_STRENGTH * dt
    vy = vy + gy * GRAVITY_STRENGTH * dt

    local spd = math.sqrt(vx * vx + vy * vy)
    if spd > U.speed_cap then
      vx = vx / spd * U.speed_cap
      vy = vy / spd * U.speed_cap
    end

    x = x + vx * dt
    y = y + vy * dt

    if x < left   then x = left;   vx = math.abs(vx) * U.bounce_dampen  end
    if x > right  then x = right;  vx = -math.abs(vx) * U.bounce_dampen end
    if y < top    then y = top;    vy = math.abs(vy) * U.bounce_dampen  end
    if y > bottom then y = bottom; vy = -math.abs(vy) * U.bounce_dampen end

    table.insert(pts, { x = x, y = y })
  end

  return pts
end

local function rnd(lo, hi)
  return lo + math.random() * (hi - lo)
end

local function spawn_orb(arena)
  local margin = 14
  local ax = arena.x + margin
  local ay = arena.y + margin
  local aw = arena.w - margin * 2
  local ah = arena.h - margin * 2
  if aw < 10 or ah < 10 then return nil end
  return {
    x = rnd(ax, ax + aw),
    y = rnd(ay, ay + ah),
    t = 0,
    pull_trail = false,
  }
end

local function spawn_red_star(arena, ball, safe_radius)
  local margin = 16
  local ax = arena.x + margin
  local ay = arena.y + margin
  local aw = arena.w - margin * 2
  local ah = arena.h - margin * 2
  if aw < 10 or ah < 10 then return nil end
  local ang = rnd(0, math.pi * 2)
  local spd = rnd(60, 110)
  local x, y
  for _ = 1, 20 do
    local cx = rnd(ax, ax + aw)
    local cy = rnd(ay, ay + ah)
    local dx = cx - ball.x
    local dy = cy - ball.y
    if safe_radius == nil or dx * dx + dy * dy >= safe_radius * safe_radius then
      x, y = cx, cy
      break
    end
  end
  if not x then return nil end
  return {
    x = x, y = y,
    vx = math.cos(ang) * spd,
    vy = math.sin(ang) * spd,
    t = 0,
    life = U.red_star_life,
  }
end

local function spawn_white_dwarf(arena)
  local margin = 16
  local ax = arena.x + margin
  local ay = arena.y + margin
  local aw = arena.w - margin * 2
  local ah = arena.h - margin * 2
  if aw < 10 or ah < 10 then return nil end
  local ang = rnd(0, math.pi * 2)
  return {
    x = rnd(ax, ax + aw),
    y = rnd(ay, ay + ah),
    vx = math.cos(ang) * U.white_dwarf_speed,
    vy = math.sin(ang) * U.white_dwarf_speed,
    t = 0,
    life = WHITE_DWARF_LIFE,
    trail = {},
  }
end

local function spawn_grav_well(arena)
  local margin = 20
  local ax = arena.x + margin
  local ay = arena.y + margin
  local aw = arena.w - margin * 2
  local ah = arena.h - margin * 2
  if aw < 10 or ah < 10 then return nil end
  return {
    x = rnd(ax, ax + aw),
    y = rnd(ay, ay + ah),
    t = 0,
    life = GRAV_WELL_LIFE_BASE,
  }
end

local function spawn_plasma_disk(arena)
  local margin = 18
  local ax = arena.x + margin
  local ay = arena.y + margin
  local aw = arena.w - margin * 2
  local ah = arena.h - margin * 2
  if aw < 10 or ah < 10 then return nil end
  return {
    x = rnd(ax, ax + aw),
    y = rnd(ay, ay + ah),
    t = 0,
    life = PLASMA_DISK_LIFE,
  }
end

local function make_bg_stars()
  local stars = {}
  for _ = 1, 60 do
    table.insert(stars, {
      x = math.random(0, W),
      y = math.random(0, H),
      b = math.random(1, 3),
    })
  end
  return stars
end

local function award_score(pts, arena_push, arena)
  State.score = State.score + pts
  if arena_push > 0 then
    arena.x = arena.x - arena_push
    arena.y = arena.y - arena_push
    arena.w = arena.w + arena_push * 2
    arena.h = arena.h + arena_push * 2
    arena.x = math.max(ARENA_MARGIN / 2, arena.x)
    arena.y = math.max(ARENA_MARGIN / 2, arena.y)
    arena.w = math.min(W - arena.x - ARENA_MARGIN / 2, arena.w)
    arena.h = math.min(H - arena.y - ARENA_MARGIN / 2, arena.h)
  end
end

-- Show a pickup name banner at the top of the screen
local function show_pickup(label)
  State.pickup_label   = label
  State.pickup_label_t = PICKUP_LABEL_DURATION
end

-- State machine 

function _init()
  State = {
    phase    = "title",
    hi       = 0,
    stars_bg = make_bg_stars(),
  }
  local saved = usagi.load()
  if saved and saved.hi then
    State.hi = saved.hi
  end
end

local function start_game()
  reset_upgrades()
  local arena = { x = ARENA_MARGIN, y = ARENA_MARGIN,
                  w = W - ARENA_MARGIN * 2, h = H - ARENA_MARGIN * 2 }
  State.phase   = "play"
  State.score   = 0
  State.arena   = arena
  State.grav_x  = 0
  State.grav_y  = 1
  State.ball = {
    x  = CX,
    y  = CY - 20,
    vx = rnd(-60, 60),
    vy = rnd(40, 80),
  }
  State.trail  = {}
  State.orbs   = {}
  for _ = 1, 3 do
    local o = spawn_orb(State.arena)
    if o then table.insert(State.orbs, o) end
  end
  State.orb_timer             = 0
  State.dead_timer            = 0
  State.flash_t               = 0
  State.grav_flash            = 0
  State.shake_t               = 0
  State.shake_i               = 0
  State.danger_t              = 0
  State.red_star              = nil
  State.red_star_timer        = 0
  State.white_dwarf           = nil
  State.white_dwarf_timer     = 0
  State.freeze_t              = 0
  State.grav_well             = nil
  State.grav_well_timer       = 0
  State.grav_well_effect      = 0
  State.well_aura_r           = 0
  State.plasma_disk           = nil
  State.plasma_disk_timer     = 0
  State.plasma_disk_equipped  = false
  State.plasma_disk_hold_t    = 0
  State.plasma_disk_fast_next = false
  State.last_shop_score       = 0
  State.shop_offers           = nil
  State.shop_select_t         = 0
  State.combo                 = 1
  State.combo_timer           = 0
  State.combo_flash_t         = 0
  State.near_miss_cd          = 0
  State.near_miss_flash_t     = 0
  State.pickup_label          = nil
  State.pickup_label_t        = 0
end

-- Update 

function _update(dt)
  for _, s in ipairs(State.stars_bg) do
    s.b = s.b + dt * 1.2
  end

  if State.phase == "title" then
    update_title(dt)
  elseif State.phase == "play" then
    update_play(dt)
  elseif State.phase == "shop" then
    update_shop(dt)
  elseif State.phase == "dead" then
    update_dead(dt)
  end
end

function update_title(dt)
  if input.pressed(input.BTN1) or input.pressed(input.DOWN)
     or input.pressed(input.UP) or input.pressed(input.LEFT)
     or input.pressed(input.RIGHT) then
    start_game()
  end
end

function update_shop(dt)
  State.shop_select_t = State.shop_select_t + dt

  local chosen = nil
  if input.key_pressed(input.KEY_1) or input.pressed(input.BTN1) then
    chosen = 1
  elseif input.key_pressed(input.KEY_2) or input.pressed(input.BTN2) then
    chosen = 2
  elseif input.key_pressed(input.KEY_3) or input.pressed(input.BTN3) then
    chosen = 3
  end

  if chosen and State.shop_offers and State.shop_offers[chosen] then
    State.shop_offers[chosen].apply(U)
    State.shop_offers = nil
    State.phase = "play"
    effect.flash(0.1, gfx.COLOR_YELLOW)
  end
end

function update_play(dt)
  local ball  = State.ball
  local arena = State.arena

  -- Tick pickup label timer
  if State.pickup_label_t > 0 then
    State.pickup_label_t = State.pickup_label_t - dt
    if State.pickup_label_t <= 0 then
      State.pickup_label   = nil
      State.pickup_label_t = 0
    end
  end

  -- Gravity input 
  local gx, gy = 0, 0
  if input.held(input.UP)    then gy = gy - 1 end
  if input.held(input.DOWN)  then gy = gy + 1 end
  if input.held(input.LEFT)  then gx = gx - 1 end
  if input.held(input.RIGHT) then gx = gx + 1 end

  if gx ~= 0 or gy ~= 0 then
    local mag = math.sqrt(gx * gx + gy * gy)
    gx = gx / mag
    gy = gy / mag
  else
    gx, gy = State.grav_x or 0, State.grav_y or 1
  end

  if gx ~= (State.grav_x or 0) or gy ~= (State.grav_y or 0) then
    State.grav_flash = 0.12
  end
  State.grav_x, State.grav_y = gx, gy
  if State.grav_flash > 0 then State.grav_flash = State.grav_flash - dt end

  -- Physics 
  local grav_mult = 1.0
  if State.freeze_t > 0 then grav_mult = FREEZE_GRAV_MULT end

  ball.vx = ball.vx + State.grav_x * GRAVITY_STRENGTH * grav_mult * dt
  ball.vy = ball.vy + State.grav_y * GRAVITY_STRENGTH * grav_mult * dt

  local spd = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
  if spd > U.speed_cap then
    ball.vx = ball.vx / spd * U.speed_cap
    ball.vy = ball.vy / spd * U.speed_cap
  end

  ball.x = ball.x + ball.vx * dt
  ball.y = ball.y + ball.vy * dt

  -- Trail 
  table.insert(State.trail, { x = ball.x, y = ball.y })
  if #State.trail > 10 then table.remove(State.trail, 1) end

  -- Wall bouncing 
  local left   = arena.x + BALL_R
  local right  = arena.x + arena.w - BALL_R
  local top    = arena.y + BALL_R
  local bottom = arena.y + arena.h - BALL_R
  local bounced = false

  if ball.x < left   then ball.x = left;   ball.vx = math.abs(ball.vx) * U.bounce_dampen;  bounced = true end
  if ball.x > right  then ball.x = right;  ball.vx = -math.abs(ball.vx) * U.bounce_dampen; bounced = true end
  if ball.y < top    then ball.y = top;    ball.vy = math.abs(ball.vy) * U.bounce_dampen;   bounced = true end
  if ball.y > bottom then ball.y = bottom; ball.vy = -math.abs(ball.vy) * U.bounce_dampen;  bounced = true end

  if bounced then
    State.combo = 1
    State.combo_timer = 0
    sfx.play("WallHit.wav")
  end

  -- Combo timer decay 
  if State.combo > 1 then
    State.combo_timer = State.combo_timer - dt
    if State.combo_timer <= 0 then
      State.combo = 1
      State.combo_timer = 0
    end
  end
  if State.combo_flash_t > 0 then State.combo_flash_t = State.combo_flash_t - dt end
  if State.near_miss_flash_t > 0 then State.near_miss_flash_t = State.near_miss_flash_t - dt end
  if State.near_miss_cd > 0 then State.near_miss_cd = State.near_miss_cd - dt end

  -- Arena collapse 
  if State.freeze_t > 0 then
    State.freeze_t = State.freeze_t - dt
  else
    local wall_spd = U.wall_speed_base + (State.score / 10) * WALL_PULSE_SPEED_RAMP
    local shrink = wall_spd * dt
    arena.x = arena.x + shrink
    arena.y = arena.y + shrink
    arena.w = arena.w - shrink * 2
    arena.h = arena.h - shrink * 2
  end

  -- Grav well effect tick 
  local well_active = State.grav_well_effect > 0
  if well_active then
    State.grav_well_effect = State.grav_well_effect - dt
    if State.grav_well_effect < 0 then State.grav_well_effect = 0 end
    State.well_aura_r = U.grav_well_radius + math.sin(usagi.elapsed * 6) * 4
  end

  -- Orb pickup + magnet pull 
  State.orb_timer = State.orb_timer + dt
  local new_orbs = {}
  for _, o in ipairs(State.orbs) do
    o.t = o.t + dt

    o.pull_trail = false
    if well_active then
      local dx = ball.x - o.x
      local dy = ball.y - o.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist < U.grav_well_radius and dist > 0.5 then
        o.pull_trail = true
        local nx = dx / dist
        local ny = dy / dist
        o.x = o.x + nx * GRAV_WELL_PULL * dt
        o.y = o.y + ny * GRAV_WELL_PULL * dt
      end
    end

    local dx = ball.x - o.x
    local dy = ball.y - o.y
    if dx * dx + dy * dy < (BALL_R + ORB_R) ^ 2 then
      State.combo = math.min(State.combo + 1, COMBO_MAX)
      State.combo_timer = COMBO_WINDOW
      if State.combo > 1 then
        State.combo_flash_t = 0.25
      end

      local pts  = State.combo
      local push = U.orb_push + (State.combo > 2 and (State.combo - 2) * 2 or 0)
      effect.flash(0.06, gfx.COLOR_YELLOW)
      sfx.play("OrbPickup")
      award_score(pts, push, arena)

      local threshold = math.floor(State.score / SHOP_EVERY) * SHOP_EVERY
      if State.score > 0 and threshold > State.last_shop_score and State.score >= threshold then
        State.last_shop_score = threshold
        State.shop_offers = pick_offers()
        State.shop_select_t = 0
        State.phase = "shop"
        sfx.play("Shop")
      end
    else
      table.insert(new_orbs, o)
    end
  end
  State.orbs = new_orbs

  if State.phase == "shop" then return end

  local orb_interval = math.max(0.8, 2.0 - State.score * 0.03)
  if State.orb_timer > orb_interval then
    State.orb_timer = 0
    if #State.orbs < 5 then
      local o = spawn_orb(arena)
      if o then table.insert(State.orbs, o) end
    end
  end

  -- Plasma Disk: manual detonation 
  if State.plasma_disk_equipped and input.pressed(input.BTN2) then
    local held_long = State.plasma_disk_hold_t >= PLASMA_DISK_LONG_HOLD
    State.plasma_disk_equipped = false
    State.plasma_disk_fast_next = held_long
    State.plasma_disk_timer = 0
    State.plasma_disk_hold_t = 0
    effect.screen_shake(0.25, 4)
    effect.flash(0.18, gfx.COLOR_ORANGE)
    show_pickup("Plasma Disk detonated!")
    sfx.play("PlasmaDisk")

    if State.red_star then
      local rs = State.red_star
      local dx = rs.x - ball.x
      local dy = rs.y - ball.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist < PLASMA_DISK_DETONATE_RANGE and dist > 0.5 then
        local nx = dx / dist
        local ny = dy / dist
        rs.vx = nx * 260
        rs.vy = ny * 260
      end
    end
  end

  -- Red star spawn/update 
  local danger_now = (arena.w < 80 or arena.h < 80)
  State.red_star_timer = State.red_star_timer + dt
  if not State.red_star and State.score > RED_STAR_SPAWN_SCORE and not danger_now
     and State.red_star_timer > U.red_star_interval then
    local rs = spawn_red_star(arena, ball, danger_now and nil or 60)
    if rs then
      State.red_star = rs
      State.red_star_timer = 0
      sfx.play("RedStar")
    end
  end

  if State.red_star then
    local rs = State.red_star
    rs.t = rs.t + dt

    if well_active then
      local dx = rs.x - ball.x
      local dy = rs.y - ball.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist > 0.5 then
        local nx = dx / dist
        local ny = dy / dist
        rs.vx = rs.vx + nx * GRAV_WELL_RED_PUSH * dt
        rs.vy = rs.vy + ny * GRAV_WELL_RED_PUSH * dt
        local rs_spd = math.sqrt(rs.vx * rs.vx + rs.vy * rs.vy)
        local rs_cap = 180
        if rs_spd > rs_cap then
          rs.vx = rs.vx / rs_spd * rs_cap
          rs.vy = rs.vy / rs_spd * rs_cap
        end
      end
    end

    rs.x = rs.x + rs.vx * dt
    rs.y = rs.y + rs.vy * dt
    local rleft   = arena.x + RED_STAR_R
    local rright  = arena.x + arena.w - RED_STAR_R
    local rtop    = arena.y + RED_STAR_R
    local rbottom = arena.y + arena.h - RED_STAR_R
    local rs_bounced = false
    if rs.x < rleft   then rs.x = rleft;   rs.vx = math.abs(rs.vx); rs_bounced = true  end
    if rs.x > rright  then rs.x = rright;  rs.vx = -math.abs(rs.vx); rs_bounced = true end
    if rs.y < rtop    then rs.y = rtop;    rs.vy = math.abs(rs.vy); rs_bounced = true  end
    if rs.y > rbottom then rs.y = rbottom; rs.vy = -math.abs(rs.vy); rs_bounced = true end
    if rs_bounced then sfx.play("WallHit") end

    local dx_nm = ball.x - rs.x
    local dy_nm = ball.y - rs.y
    local centre_dist = math.sqrt(dx_nm * dx_nm + dy_nm * dy_nm)
    local gap = centre_dist - BALL_R - RED_STAR_R
    if gap >= NEAR_MISS_MIN and gap <= NEAR_MISS_MAX and State.near_miss_cd <= 0 then
      State.near_miss_cd = NEAR_MISS_CD
      State.near_miss_flash_t = 0.4
      award_score(1, 3, arena)
      effect.flash(0.07, gfx.COLOR_PEACH)
    end

    local dx = ball.x - rs.x
    local dy = ball.y - rs.y
    if dx * dx + dy * dy < (BALL_R + RED_STAR_R) ^ 2 then
      if State.plasma_disk_equipped then
        local held_long = State.plasma_disk_hold_t >= PLASMA_DISK_LONG_HOLD
        State.plasma_disk_equipped = false
        State.plasma_disk_fast_next = held_long
        State.plasma_disk_timer = 0
        State.plasma_disk_hold_t = 0
        rs.vx = -rs.vx * 1.4
        rs.vy = -rs.vy * 1.4
        effect.flash(0.2, gfx.COLOR_RED)
        effect.screen_shake(0.3, 4)
        show_pickup("Plasma Disk shattered!")
        sfx.play("PlasmaDisk")
        State.red_star = nil
      else
        local kill = true
        if well_active then
          local rel_vx = ball.vx - rs.vx
          local rel_vy = ball.vy - rs.vy
          local rel_spd = math.sqrt(rel_vx * rel_vx + rel_vy * rel_vy)
          kill = rel_spd > GRAV_WELL_RED_KILL_SPD
        end

        if kill then
          if State.score > State.hi then
            State.hi = State.score
            usagi.save({ hi = State.hi })
          end
          State.phase = "dead"
          State.dead_timer = 0
          effect.screen_shake(0.5, 6)
          effect.flash(0.35, gfx.COLOR_RED)
          sfx.play("GameOver")
          State.red_star = nil
          return
        else
          rs.vx = -rs.vx * 1.2
          rs.vy = -rs.vy * 1.2
          effect.flash(0.08, gfx.COLOR_ORANGE)
        end
      end
    end

    if State.red_star and rs.t > U.red_star_life then
      effect.flash(0.1, gfx.COLOR_ORANGE)
      effect.screen_shake(0.15, 3)
      for _ = 1, 3 do
        local ang = rnd(0, math.pi * 2)
        local dist = rnd(4, 12)
        local ox = rs.x + math.cos(ang) * dist
        local oy = rs.y + math.sin(ang) * dist
        ox = math.max(arena.x + 4, math.min(arena.x + arena.w - 4, ox))
        oy = math.max(arena.y + 4, math.min(arena.y + arena.h - 4, oy))
        table.insert(State.orbs, { x = ox, y = oy, t = 0, pull_trail = false })
      end
      State.red_star = nil
    end
  end

  -- White Dwarf spawn/update
  State.white_dwarf_timer = State.white_dwarf_timer + dt
  if not State.white_dwarf and State.score > WHITE_DWARF_SPAWN_SCORE
     and State.white_dwarf_timer > U.white_dwarf_interval then
    local wd = spawn_white_dwarf(arena)
    if wd then
      State.white_dwarf = wd
      State.white_dwarf_timer = 0
      sfx.play("WhiteDwarf")
    end
  end

  if State.white_dwarf then
    local wd = State.white_dwarf
    wd.t = wd.t + dt

    table.insert(wd.trail, { x = wd.x, y = wd.y })
    if #wd.trail > 8 then table.remove(wd.trail, 1) end

    wd.x = wd.x + wd.vx * dt
    wd.y = wd.y + wd.vy * dt
    local wleft   = arena.x + WHITE_DWARF_R
    local wright  = arena.x + arena.w - WHITE_DWARF_R
    local wtop    = arena.y + WHITE_DWARF_R
    local wbottom = arena.y + arena.h - WHITE_DWARF_R
    local wd_bounced = false
    if wd.x < wleft   then wd.x = wleft;   wd.vx = math.abs(wd.vx); wd_bounced = true  end
    if wd.x > wright  then wd.x = wright;  wd.vx = -math.abs(wd.vx); wd_bounced = true end
    if wd.y < wtop    then wd.y = wtop;    wd.vy = math.abs(wd.vy); wd_bounced = true  end
    if wd.y > wbottom then wd.y = wbottom; wd.vy = -math.abs(wd.vy); wd_bounced = true end
    if wd_bounced then sfx.play("WallHit") end

    local dx = ball.x - wd.x
    local dy = ball.y - wd.y
    if dx * dx + dy * dy < (BALL_R + WHITE_DWARF_R) ^ 2 then
      State.freeze_t = U.white_dwarf_freeze
      if State.plasma_disk_equipped then
        local held_long = State.plasma_disk_hold_t >= PLASMA_DISK_LONG_HOLD
        State.plasma_disk_equipped = false
        State.plasma_disk_fast_next = held_long
        State.plasma_disk_timer = 0
        State.plasma_disk_hold_t = 0
      end
      effect.flash(0.15, gfx.COLOR_WHITE)
      effect.screen_shake(0.2, 2)
      show_pickup("White Dwarf  -  Arena Frozen!")
      sfx.play("PowerUpPickup")
      State.white_dwarf = nil
    elseif wd.t > WHITE_DWARF_LIFE then
      State.white_dwarf = nil
    end
  end

  -- Gravity Well pickup spawn/update 
  State.grav_well_timer = State.grav_well_timer + dt
  if not State.grav_well and State.score > GRAV_WELL_SPAWN_SCORE
     and State.grav_well_timer > U.grav_well_interval
     and not well_active then
    local gw = spawn_grav_well(arena)
    if gw then
      State.grav_well = gw
      State.grav_well_timer = 0
      sfx.play("GravWell")
    end
  end

  if State.grav_well then
    local gw = State.grav_well
    gw.t = gw.t + dt

    local dx = ball.x - gw.x
    local dy = ball.y - gw.y
    if dx * dx + dy * dy < (BALL_R + 8) ^ 2 then
      State.grav_well_effect = U.grav_well_effect
      State.well_aura_r = U.grav_well_radius
      if State.plasma_disk_equipped then
        local held_long = State.plasma_disk_hold_t >= PLASMA_DISK_LONG_HOLD
        State.plasma_disk_equipped = false
        State.plasma_disk_fast_next = held_long
        State.plasma_disk_timer = 0
        State.plasma_disk_hold_t = 0
      end
      effect.flash(0.18, gfx.COLOR_INDIGO)
      effect.screen_shake(0.15, 2)
      show_pickup("Gravity Well  -  Orbs Magnetized!")
      sfx.play("PowerUpPickup")
      State.grav_well = nil
    elseif gw.t > GRAV_WELL_LIFE_BASE then
      State.grav_well = nil
    end
  end

  -- Plasma Disk pickup spawn/update 
  State.plasma_disk_timer = State.plasma_disk_timer + dt

  if State.plasma_disk_equipped then
    State.plasma_disk_hold_t = State.plasma_disk_hold_t + dt
  end

  local disk_interval = State.plasma_disk_fast_next and PLASMA_DISK_INTERVAL_FAST or U.plasma_disk_interval
  if not State.plasma_disk and not State.plasma_disk_equipped
     and State.score > PLASMA_DISK_SPAWN_SCORE
     and State.plasma_disk_timer > disk_interval then
    local pd = spawn_plasma_disk(arena)
    if pd then
      State.plasma_disk = pd
      State.plasma_disk_timer = 0
      State.plasma_disk_fast_next = false
      sfx.play("PlasmaDisk")
    end
  end

  if State.plasma_disk then
    local pd = State.plasma_disk
    pd.t = pd.t + dt

    local dx = ball.x - pd.x
    local dy = ball.y - pd.y
    if dx * dx + dy * dy < (BALL_R + 10) ^ 2 then
      State.plasma_disk_equipped = true
      State.plasma_disk_hold_t   = 0
      State.plasma_disk_fast_next = false
      effect.flash(0.12, gfx.COLOR_RED)
      effect.screen_shake(0.1, 2)
      show_pickup("Plasma Disk  -  Shield Active!")
      sfx.play("PlasmaDisk")
      State.plasma_disk = nil
    elseif pd.t > PLASMA_DISK_LIFE then
      State.plasma_disk = nil
      State.plasma_disk_timer = 0
    end
  end

  -- Danger flash / shake 
  State.danger_t = State.danger_t + dt
  if arena.w < 80 or arena.h < 80 then
    if arena.w < 50 or arena.h < 50 then
      State.shake_t = 0.1
      State.shake_i = 2
    end
  end
  if State.shake_t > 0 then
    State.shake_t = State.shake_t - dt
    effect.screen_shake(0.05, State.shake_i)
  end

  -- Death check 
  local min_dim = math.min(arena.w, arena.h)
  if min_dim < WALL_MIN_SIZE then
    if State.score > State.hi then
      State.hi = State.score
      usagi.save({ hi = State.hi })
    end
    State.phase = "dead"
    State.dead_timer = 0
    effect.screen_shake(0.4, 5)
    effect.flash(0.3, gfx.COLOR_RED)
    sfx.play("GameOver")
  end
end

function update_dead(dt)
  State.dead_timer = State.dead_timer + dt
  if State.dead_timer > 1.0 then
    if input.pressed(input.BTN1) or input.pressed(input.DOWN)
       or input.pressed(input.UP) or input.pressed(input.LEFT)
       or input.pressed(input.RIGHT) then
      start_game()
    end
  end
end

-- Draw 

function _draw(dt)
  gfx.clear(C_BG)
  draw_bg_stars()

  if State.phase == "title" then
    draw_title()
  elseif State.phase == "play" then
    draw_play()
  elseif State.phase == "shop" then
    draw_play()
    draw_shop()
  elseif State.phase == "dead" then
    draw_play()
    draw_dead()
  end
end

function draw_bg_stars()
  for _, s in ipairs(State.stars_bg) do
    local b = (math.sin(s.b) + 1) / 2
    if b > 0.5 then
      gfx.px(s.x, s.y, C_STARS)
    end
  end
end

function draw_title()
  local t = usagi.elapsed
  local pulse = math.sin(t * 3) * 4
  local bx = 30 - pulse
  local by = 50 - pulse
  local bw = W - 60 + pulse * 2
  local bh = H - 80 + pulse * 2

  gfx.rect_fill(bx, by, bw, bh, gfx.COLOR_DARK_BLUE)
  gfx.rect(bx, by, bw, bh, gfx.COLOR_INDIGO)
  gfx.rect(bx + 2, by + 2, bw - 4, bh - 4, gfx.COLOR_DARK_PURPLE)

  local title = "P U L S A R"
  local tw, _ = usagi.measure_text(title)
  local tx = (W - tw) / 2
  gfx.text(title, tx - 1, 62, gfx.COLOR_DARK_PURPLE)
  gfx.text(title, tx + 1, 62, gfx.COLOR_DARK_PURPLE)
  gfx.text(title, tx, 63, gfx.COLOR_INDIGO)
  gfx.text(title, tx, 61, gfx.COLOR_PINK)
  gfx.text(title, tx, 62, C_TITLE)

  local sub = "a simple 2d arcade game about a collapsing star"
  local sw, _ = usagi.measure_text(sub)
  gfx.text(sub, (W - sw) / 2, 78, C_SUB)

  local ins = { "WASD/Arrow Keys = flip gravity", "Collect orbs to prevent collapse", "-- Mansour --" }
  for i, line in ipairs(ins) do
    local lw, _ = usagi.measure_text(line)
    gfx.text(line, (W - lw) / 2, 95 + (i - 1) * 10, gfx.COLOR_LIGHT_GRAY)
  end

  if util.flash(usagi.elapsed, 1.5) then
    local prompt = "press any direction to begin"
    local pw, _ = usagi.measure_text(prompt)
    gfx.text(prompt, (W - pw) / 2, 135, gfx.COLOR_PEACH)
  end

  if State.hi > 0 then
    local hi_str = "best: " .. State.hi
    local hw, _ = usagi.measure_text(hi_str)
    gfx.text(hi_str, (W - hw) / 2, 148, C_HI)
  end
end

function draw_shop()
  local offers = State.shop_offers
  if not offers then return end

  gfx.rect_fill(0, 0, W, H, gfx.COLOR_BLACK)

  local pw = 280
  local ph = 140
  local px = math.floor((W - pw) / 2)
  local py = math.floor((H - ph) / 2)

  gfx.rect_fill(px, py, pw, ph, C_SHOP_BG)
  gfx.rect(px, py, pw, ph, C_SHOP_BRD)
  gfx.rect(px + 1, py + 1, pw - 2, ph - 2, gfx.COLOR_DARK_PURPLE)

  local hdr = "UPGRADE"
  local hw, _ = usagi.measure_text(hdr)
  gfx.text_ex(hdr, math.floor((W - hw * 2) / 2), py + 7, 2, 0, C_SHOP_HL, 1)

  local sub = "choose one"
  local sw, _ = usagi.measure_text(sub)
  gfx.text(sub, math.floor((W - sw) / 2), py + 22, C_SHOP_SUB)

  local row_h  = 30
  local row_y0 = py + 34
  local key_labels = { "1/X", "2/O", "3/[]" }
  local row_colors = { gfx.COLOR_PEACH, gfx.COLOR_GREEN, gfx.COLOR_BLUE }

  for i = 1, 3 do
    local ry   = row_y0 + (i - 1) * row_h
    local perk = offers[i]
    local row_brd = row_colors[i]

    gfx.rect_fill(px + 8, ry, 12, 12, gfx.COLOR_DARK_PURPLE)
    gfx.rect(px + 8, ry, 12, 12, row_brd)
    local kw, _ = usagi.measure_text(key_labels[i])
    gfx.text(key_labels[i], px + 8 + math.floor((12 - kw) / 2), ry + 3, row_brd)

    gfx.text(perk.label, px + 25, ry + 1, C_SHOP_TXT)
    gfx.text(perk.desc,  px + 25, ry + 11, C_SHOP_SUB)
  end

  local footer = "keys  1 / 2 / 3  to pick"
  local fw, _ = usagi.measure_text(footer)
  gfx.text(footer, math.floor((W - fw) / 2), py + ph - 10, C_SHOP_KEY)
end

function draw_play()
  local ball  = State.ball
  local arena = State.arena
  local t     = usagi.elapsed

  -- Arena walls 
  local danger = math.min(arena.w, arena.h) < 90
  local wall_c  = danger and C_DEAD or C_WALL
  local wall_c2 = danger and gfx.COLOR_ORANGE or C_WALL2

  gfx.rect_fill(arena.x - 4, arena.y - 4, arena.w + 8, arena.h + 8, C_STARS)
  gfx.rect(arena.x - 4, arena.y - 4, arena.w + 8, arena.h + 8, wall_c2)
  gfx.rect(arena.x - 2, arena.y - 2, arena.w + 4, arena.h + 4, wall_c2)
  gfx.rect_fill(arena.x, arena.y, arena.w, arena.h, gfx.COLOR_BLACK)
  gfx.rect(arena.x, arena.y, arena.w, arena.h, wall_c)

  if State.freeze_t > 0 then
    if util.flash(t, 6) then
      gfx.rect(arena.x + 1, arena.y + 1, arena.w - 2, arena.h - 2, gfx.COLOR_LIGHT_GRAY)
    end
  end

  if danger then
    local d = math.floor(t * 8) % 2 == 0
    if d then
      local ax, ay, aw, ah = arena.x, arena.y, arena.w, arena.h
      gfx.line(ax, ay, ax + 6, ay + 6, gfx.COLOR_RED)
      gfx.line(ax + aw, ay, ax + aw - 6, ay + 6, gfx.COLOR_RED)
      gfx.line(ax, ay + ah, ax + 6, ay + ah - 6, gfx.COLOR_RED)
      gfx.line(ax + aw, ay + ah, ax + aw - 6, ay + ah - 6, gfx.COLOR_RED)
    end
  end

  -- Gravity Well pickup 
  if State.grav_well then
    local gw = State.grav_well
    local cx = math.floor(gw.x)
    local cy = math.floor(gw.y)
    local near_end = gw.life - gw.t < 1.2
    local blink    = near_end and util.flash(gw.t, 10)

    if not blink then
      local spin = t * 3.5
      for ring = 1, 3 do
        local rr  = 4 + ring * 3
        local off = spin + ring * (math.pi * 2 / 3)
        local ox = math.floor(cx + math.cos(off) * 1.5)
        local oy = math.floor(cy + math.sin(off) * 1.5)
        local rc = (ring == 1) and C_WELL2 or C_WELL
        gfx.circ(ox, oy, rr, rc)
      end
      gfx.circ(cx, cy, 14, C_WELL)
      gfx.circ_fill(cx, cy, 2, C_WELL_CTR)
      gfx.px(cx, cy, gfx.COLOR_WHITE)
    else
      gfx.circ(cx, cy, 10, C_WELL2)
    end
  end

  -- Orbs 
  for _, o in ipairs(State.orbs) do
    local pulse = math.sin(o.t * 5) * 1.5
    local r = ORB_R + pulse

    if o.pull_trail then
      for tr_r = math.floor(r) + 3, math.floor(r) + 1, -1 do
        gfx.circ(math.floor(o.x), math.floor(o.y), tr_r, C_WELL2)
      end
    end

    gfx.circ(math.floor(o.x), math.floor(o.y), math.floor(r + 2), C_ORB2)
    gfx.circ_fill(math.floor(o.x), math.floor(o.y), math.floor(r), C_ORB)
    if util.flash(o.t, 4) then
      gfx.px(math.floor(o.x), math.floor(o.y) - math.floor(r) - 1, gfx.COLOR_WHITE)
    end
  end

  -- Red star 
  if State.red_star then
    local rs    = State.red_star
    local pulse = math.sin(rs.t * 10) * 1.5
    local r     = RED_STAR_R + pulse
    local near_end = U.red_star_life - rs.t < 1.0
    local blink    = near_end and util.flash(rs.t, 10)

    if State.near_miss_flash_t > 0 then
      gfx.circ(math.floor(rs.x), math.floor(rs.y), math.floor(r + 6), C_NEAR_MISS)
    end

    if not blink then
      gfx.circ(math.floor(rs.x), math.floor(rs.y), math.floor(r + 2), gfx.COLOR_RED)
      gfx.circ_fill(math.floor(rs.x), math.floor(rs.y), math.floor(r), gfx.COLOR_ORANGE)
      gfx.circ_fill(math.floor(rs.x), math.floor(rs.y), math.floor(r * 0.4), gfx.COLOR_YELLOW)
    else
      gfx.circ(math.floor(rs.x), math.floor(rs.y), math.floor(r + 3), gfx.COLOR_RED)
    end
  end

  -- White Dwarf
  if State.white_dwarf then
    local wd = State.white_dwarf

    for i, pos in ipairs(wd.trail) do
      local a = i / #wd.trail
      if a > 0.2 then
        local tr = math.max(1, math.floor(WHITE_DWARF_R * a))
        gfx.circ_fill(math.floor(pos.x), math.floor(pos.y), tr, C_DWARF_GLOW)
      end
    end

    local near_end = WHITE_DWARF_LIFE - wd.t < 1.0
    local blink    = near_end and util.flash(wd.t, 14)

    if not blink then
      gfx.circ(math.floor(wd.x), math.floor(wd.y), WHITE_DWARF_R + 2, C_DWARF_GLOW)
      gfx.circ_fill(math.floor(wd.x), math.floor(wd.y), WHITE_DWARF_R, C_DWARF)
      gfx.px(math.floor(wd.x), math.floor(wd.y), gfx.COLOR_WHITE)
    end
  end

  -- Gravity Well active effect 
  if State.grav_well_effect > 0 then
    local aura_r = math.floor(State.well_aura_r)
    local bx     = math.floor(ball.x)
    local by_    = math.floor(ball.y)

    local aura_col = util.flash(usagi.elapsed, 6) and C_WELL2 or C_WELL
    gfx.circ(bx, by_, aura_r,     aura_col)
    gfx.circ(bx, by_, aura_r - 2, C_WELL)

    local spin = usagi.elapsed * 4
    for i = 0, 3 do
      local ang = spin + i * (math.pi / 2)
      local sx  = bx + math.floor(math.cos(ang) * aura_r)
      local sy  = by_ + math.floor(math.sin(ang) * aura_r)
      gfx.px(sx, sy, C_WELL_CTR)
    end

    local total_pips = 10
    local pips_left  = math.ceil((State.grav_well_effect / U.grav_well_effect) * total_pips)
    for p = 0, total_pips - 1 do
      local px_ = arena.x + 4 + p * 5
      local py_ = arena.y + arena.h - 6
      local pc  = p < pips_left and C_WELL2 or gfx.COLOR_DARK_GRAY
      gfx.rect_fill(px_, py_, 4, 3, pc)
    end
  end

  -- Plasma Disk pickup
  if State.plasma_disk then
    local pd   = State.plasma_disk
    local cx   = math.floor(pd.x)
    local cy   = math.floor(pd.y)
    local near_end = pd.life - pd.t < 1.0
    local blink    = near_end and util.flash(pd.t, 12)

    if not blink then
      gfx.circ(cx, cy, 9, gfx.COLOR_RED)
      gfx.circ(cx, cy, 6, gfx.COLOR_RED)
    else
      gfx.circ(cx, cy, 9, gfx.COLOR_RED)
    end
  end

  -- Plasma Disk equipped 
  if State.plasma_disk_equipped then
    local bx  = math.floor(ball.x)
    local by_ = math.floor(ball.y)
    gfx.circ(bx, by_, BALL_R + 6, gfx.COLOR_RED)
    gfx.circ(bx, by_, BALL_R + 3, gfx.COLOR_RED)
  end

  -- Trajectory prediction 
  local traj = predict_trajectory(ball, arena, State.grav_x, State.grav_y, 18, 1/30)
  for i, pt in ipairs(traj) do
    if i % 2 == 0 then
      gfx.px(math.floor(pt.x), math.floor(pt.y), gfx.COLOR_ORANGE)
    end
  end

  --  Ball trail 
  for i, pos in ipairs(State.trail) do
    local a = i / #State.trail
    if a > 0.4 then
      local tr = math.floor(BALL_R * a * 0.8)
      if tr > 0 then
        local col = i > #State.trail - 3 and C_BALL_TR or gfx.COLOR_DARK_GRAY
        gfx.circ_fill(math.floor(pos.x), math.floor(pos.y), tr, col)
      end
    end
  end

  --  Ball 
  local gc = State.grav_flash > 0 and C_GRAV or C_BALL
  if State.grav_well_effect > 0 and State.grav_flash == 0 then
    gc = util.flash(usagi.elapsed, 5) and C_WELL2 or C_BALL
  end
  gfx.circ_fill(math.floor(ball.x), math.floor(ball.y), BALL_R, gc)
  gfx.circ(math.floor(ball.x), math.floor(ball.y), BALL_R + 1, gfx.COLOR_LIGHT_GRAY)

  -- Gravity indicator 
  local gx, gy  = State.grav_x, State.grav_y
  local ix  = arena.x + arena.w / 2
  local iy  = arena.y + arena.h / 2
  local arr_len = 12
  local ex  = ix + gx * arr_len
  local ey  = iy + gy * arr_len
  gfx.line(math.floor(ix) - 3, math.floor(iy), math.floor(ix) + 3, math.floor(iy), gfx.COLOR_DARK_GRAY)
  gfx.line(math.floor(ix), math.floor(iy) - 3, math.floor(ix), math.floor(iy) + 3, gfx.COLOR_DARK_GRAY)
  local ac = State.grav_flash > 0 and gfx.COLOR_YELLOW or gfx.COLOR_DARK_PURPLE
  gfx.line(math.floor(ix), math.floor(iy), math.floor(ex), math.floor(ey), ac)
  gfx.circ_fill(math.floor(ex), math.floor(ey), 2, ac)

  -- Combo display 
  if State.combo > 1 then
    local combo_str = "x" .. State.combo
    local cw, _ = usagi.measure_text(combo_str)
    local cbx = math.floor(ball.x) - math.floor(cw / 2)
    local cby = math.floor(ball.y) - BALL_R - 14
    local cc  = State.combo_flash_t > 0 and C_COMBO_HI or C_COMBO
    gfx.text(combo_str, cbx + 1, cby + 1, gfx.COLOR_BLACK)
    gfx.text(combo_str, cbx, cby, cc)

    if State.combo_timer > 0 then
      local bar_w = 24
      local bar_x = arena.x + arena.w - bar_w - 4
      local bar_y = arena.y + 12
      local fill  = math.floor((State.combo_timer / COMBO_WINDOW) * bar_w)
      gfx.rect_fill(bar_x, bar_y, bar_w, 3, gfx.COLOR_DARK_GRAY)
      gfx.rect_fill(bar_x, bar_y, fill, 3, cc)
    end
  end

  -- Near-miss popup
  if State.near_miss_flash_t > 0 then
    local nm = "SKIM! +1"
    local nw, _ = usagi.measure_text(nm)
    local rise = math.floor((0.4 - State.near_miss_flash_t) * 20)
    gfx.text(nm, math.floor(ball.x) - math.floor(nw / 2), math.floor(ball.y) - 20 - rise, C_NEAR_MISS)
  end

  -- Score & next shop 
  local sc_str = tostring(State.score)
  local sw, _  = usagi.measure_text(sc_str)
  local sx = arena.x + arena.w - sw - 4
  local sy = arena.y + 3
  gfx.text(sc_str, sx + 1, sy + 1, gfx.COLOR_BLACK)
  gfx.text(sc_str, sx, sy, C_SCORE)

  local next_shop = (math.floor(State.score / SHOP_EVERY) + 1) * SHOP_EVERY
  local ns_str = "Next shop at: " .. next_shop
  local nw2, _ = usagi.measure_text(ns_str)
  gfx.text(ns_str, arena.x + 3, arena.y + 3, gfx.COLOR_DARK_GRAY)

  if State.hi > 0 then
    local hi_str = "best:" .. State.hi
    local hw, _ = usagi.measure_text(hi_str)
    gfx.text(hi_str, arena.x + 3, arena.y + 11, gfx.COLOR_DARK_GRAY)
  end

  -- Plasma Disk detonation hint 
  if State.plasma_disk_equipped then
    local hint = "O/X/BTN2 = detonate"
    local htw, _ = usagi.measure_text(hint)
    gfx.text(hint, math.floor((W - htw) / 2), arena.y + arena.h + 2, gfx.COLOR_DARK_GRAY)
  end

  -- HUD: freeze + 2x gravity indicator
  -- Drawn last so it sits on top of everything (shares the top strip with
  -- the pickup label; freeze wins if both are somehow active simultaneously)
  if State.freeze_t > 0 then
    if util.flash(usagi.elapsed, 8) then
      local fz = "FROZEN  2x GRAV"
      local fw, _ = usagi.measure_text(fz)
      gfx.text(fz, (W - fw) / 2, 3, C_DWARF)
    end
  elseif State.pickup_label and State.pickup_label_t > 0 then
    -- Fade: full brightness for first half, then blink off in last 0.5s
    local show = true
    if State.pickup_label_t < 0.5 then
      show = util.flash(usagi.elapsed, 8)
    end
    if show then
      local lw, _ = usagi.measure_text(State.pickup_label)
      gfx.text(State.pickup_label, math.floor((W - lw) / 2), 3, C_SHOP_HL)
    end
  end
end

function draw_dead()
  gfx.rect_fill(CX - 60, CY - 30, 120, 60, gfx.COLOR_BLACK)
  gfx.rect(CX - 60, CY - 30, 120, 60, C_DEAD)
  gfx.rect(CX - 58, CY - 28, 116, 56, gfx.COLOR_DARK_PURPLE)

  local over = "COLLAPSED"
  local ow, _ = usagi.measure_text(over)
  gfx.text(over, CX - ow / 2, CY - 20, C_DEAD)

  local sc_str = "score: " .. State.score
  local sw, _ = usagi.measure_text(sc_str)
  gfx.text(sc_str, CX - sw / 2, CY - 8, C_SCORE)

  if State.score >= State.hi and State.score > 0 then
    local nb = "NEW BEST!"
    local nw, _ = usagi.measure_text(nb)
    local flash_c = util.flash(usagi.elapsed, 4) and C_HI or gfx.COLOR_ORANGE
    gfx.text(nb, CX - nw / 2, CY + 2, flash_c)
  end

  if State.dead_timer > 1.0 then
    if util.flash(usagi.elapsed, 2) then
      local pr = "any key to retry"
      local pw, _ = usagi.measure_text(pr)
      gfx.text(pr, CX - pw / 2, CY + 16, gfx.COLOR_LIGHT_GRAY)
    end
  end
end