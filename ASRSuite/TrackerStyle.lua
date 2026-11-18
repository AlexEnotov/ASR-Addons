-- Shared by the independently installed trackers.
if ASRTrackerStyle then return end
local T = {}
ASRTrackerStyle = T

local white = "Interface\\Buttons\\WHITE8X8"
local thin = {
  bgFile=white,
  edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize=10,
  insets={left=2,right=2,top=2,bottom=2},
}
local borderless = {bgFile=white}
local stoneInsets = {left=1.5,right=1.5,top=10,bottom=11}
local flatInsets = {left=0,right=0,top=0,bottom=0}

function T.Get(options)
  local style = options and options.frameStyle
  if style == "thin" or style == "none" then return style end
  return "stone"
end

function T.Insets(style, stoneSkin)
  if style == "stone" and stoneSkin then return stoneInsets end
  return flatInsets
end

function T.Apply(frame, style, opacity, drawStone)
  if style == "stone" then
    (drawStone or ASRStyle.Panel)(frame, opacity)
    return
  end
  frame:SetBackdrop(style == "thin" and thin or borderless)
  frame:SetBackdropColor(0.04, 0.04, 0.045, opacity)
  if style == "thin" then frame:SetBackdropBorderColor(0.61, 0.55, 0.46, 1) end
end

function T.Command(options, message, refresh)
  local style = (message or ""):lower():match("^%s*frame%s+(%a+)%s*$")
  if style ~= "stone" and style ~= "thin" and style ~= "none" then return false end
  options.frameStyle = style
  refresh()
  return true
end
