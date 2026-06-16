-- PULSAR - 320x180 Logo Scene

function _config()
  return {
    name = "PULSAR Logo",
    game_id = "com.usagi.pulsar",
    game_width = 320,
    game_height = 180,
    pause_menu = false,
  }
end

local W = usagi.GAME_W
local H = usagi.GAME_H
local CX = W / 2
local CY = H / 2

local stars = {}

function _init()
  math.randomseed(os.time())

  for i = 1, 128 do
    table.insert(stars, {
      x = math.random(0, W),
      y = math.random(0, H),
      phase = math.random() * math.pi * 2,
      size = math.random(1, 3),
      color = ({
        gfx.COLOR_WHITE,
        gfx.COLOR_LIGHT_GRAY,
        gfx.COLOR_PEACH,
        gfx.COLOR_YELLOW
      })[math.random(1, 4)]
    })
  end
end

function _update(dt)
end

local function draw_star(s)
  local b = math.sin(usagi.elapsed * 2 + s.phase)

  if b < -0.2 then
    return
  end

  gfx.px(s.x, s.y, s.color)

  if s.size >= 2 then
    gfx.px(s.x - 1, s.y, s.color)
    gfx.px(s.x + 1, s.y, s.color)
    gfx.px(s.x, s.y - 1, s.color)
    gfx.px(s.x, s.y + 1, s.color)
  end

  if s.size == 3 and b > 0.7 then
    gfx.px(s.x - 1, s.y - 1, gfx.COLOR_WHITE)
    gfx.px(s.x + 1, s.y - 1, gfx.COLOR_WHITE)
    gfx.px(s.x - 1, s.y + 1, gfx.COLOR_WHITE)
    gfx.px(s.x + 1, s.y + 1, gfx.COLOR_WHITE)
  end
end

local function draw_planet()
  local px = 85
  local py = 55
  local r = 18

  gfx.circ_fill(px, py, r, gfx.COLOR_DARK_PURPLE)
  gfx.circ(px, py, r, gfx.COLOR_INDIGO)

  gfx.circ_fill(px - 5, py - 3, 6, gfx.COLOR_PINK)
  gfx.circ_fill(px + 4, py + 6, 4, gfx.COLOR_INDIGO)

  gfx.line_ex(px - 28, py + 4, px + 28, py - 4, 3, gfx.COLOR_LIGHT_GRAY)
  gfx.line_ex(px - 28, py + 4, px + 28, py - 4, 1, gfx.COLOR_WHITE)
end

local function draw_galaxy()
  local gx = 235
  local gy = 55

  for i = 1, 18 do
    local a = i * 0.6 + usagi.elapsed * 0.15
    local r = i * 1.3

    local x = gx + math.cos(a) * r
    local y = gy + math.sin(a) * r * 0.6

    gfx.px(math.floor(x), math.floor(y), gfx.COLOR_INDIGO)
  end

  gfx.circ_fill(gx, gy, 3, gfx.COLOR_WHITE)
  gfx.circ(gx, gy, 6, gfx.COLOR_PINK)
end

local function draw_nebula()
  gfx.circ_fill(250, 130, 28, gfx.COLOR_DARK_BLUE)
  gfx.circ_fill(235, 120, 18, gfx.COLOR_INDIGO)
  gfx.circ_fill(265, 138, 16, gfx.COLOR_DARK_PURPLE)
end

local function draw_bg()
  gfx.clear(gfx.COLOR_BLACK)

  draw_nebula()
  draw_planet()
  draw_galaxy()

  for _, s in ipairs(stars) do
    draw_star(s)
  end
end

local function draw_pulsar()
  local pulse = math.sin(usagi.elapsed * 4) * 2
  local r = 16 + pulse

  -- Outer energy rings
  gfx.circ(CX, CY, r + 10, gfx.COLOR_DARK_PURPLE)
  gfx.circ(CX, CY, r + 6, gfx.COLOR_INDIGO)

  -- Rotated gravity beams (45 degrees)

  local beam = 30

  gfx.line_ex(
    CX - beam, CY - beam,
    CX + beam, CY + beam,
    3,
    gfx.COLOR_PINK
  )

  gfx.line_ex(
    CX - beam, CY + beam,
    CX + beam, CY - beam,
    3,
    gfx.COLOR_PINK
  )

  gfx.line_ex(
    CX - beam, CY - beam,
    CX + beam, CY + beam,
    1,
    gfx.COLOR_ORANGE
  )

  gfx.line_ex(
    CX - beam, CY + beam,
    CX + beam, CY - beam,
    1,
    gfx.COLOR_ORANGE
  )

  -- Core
  gfx.circ_fill(CX, CY, r, gfx.COLOR_ORANGE)
  gfx.circ_fill(CX, CY, r * 0.65, gfx.COLOR_YELLOW)
  gfx.circ_fill(CX, CY, r * 0.25, gfx.COLOR_WHITE)
end

local function draw_title()
  local title = "P U L S A R"

  local tw = usagi.measure_text(title)
  local scale = 2

  local tx = (W - tw * scale) / 2
  local ty = CY + 42

  gfx.text_ex(
    title,
    tx + 2,
    ty + 2,
    scale,
    0,
    gfx.COLOR_DARK_PURPLE,
    1
  )

  gfx.text_ex(
    title,
    tx,
    ty - 1,
    scale,
    0,
    gfx.COLOR_INDIGO,
    1
  )

  gfx.text_ex(
    title,
    tx,
    ty,
    scale,
    0,
    gfx.COLOR_WHITE,
    1
  )
end

function _draw(dt)
  draw_bg()
  draw_pulsar()
  draw_title()
end