local rig = script.Parent
local hum = rig.Humanoid
local animator = hum.Animator
local anim = script.Animation
local animTrack = animator:LoadAnimation(anim)

animTrack.Looped = true

animTrack:Play()