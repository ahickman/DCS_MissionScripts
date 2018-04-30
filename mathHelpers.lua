-- Standard Functions to help with Math & table management

function shuffleTable( t )
    local rand = math.random
    assert( t, "shuffleTable() expected a table, got nil" )
    local iterations = #t
    local j
    
    for i = iterations, 2, -1 do
        j = rand(i)
        t[i], t[j] = t[j], t[i]
    end
	return t
end

-- EXTRA POINT FUNCTIONS FOR CONVENIENCE
function POINT_VEC3:Dot( inVec3 )
  local SX = self:GetX()
  local SY = self:GetY()
  local SZ = self:GetZ()
  local IX = inVec3:GetX()
  local IY = inVec3:GetY()
  local IZ = inVec3:GetZ()  
  return SX*IX + SY*IY + SZ*IZ
end
function POINT_VEC2:Dot( inVec2 )
  local SX = self:GetX()
  local SZ = self:GetZ()
  local IX = inVec2:GetX()
  local IZ = inVec2:GetZ()  
  return SX*IX + SZ*IZ
end
function POINT_VEC3:GetUnitVector()
  local SX = self:GetX()
  local SY = self:GetY()  
  local SZ = self:GetZ()  
  local mag = self:Mag()
  return POINT_VEC3:New(SX/mag, SY/mag, SZ/mag)
end
function POINT_VEC2:GetUnitVector()
  local SX = self:GetX()
  local SZ = self:GetZ()    
  local mag = self:Mag()
  return POINT_VEC2:New(SX/mag, SZ/mag)
end
function POINT_VEC3:GetDirectionVector(P)
  local SX = self:GetX()
  local SY = self:GetY()  
  local SZ = self:GetZ()  
  local PX = P:GetX()
  local PY = P:GetY()
  local PZ = P:GetZ()  
  return POINT_VEC3:New(PX-SX, PY-SY, PZ-SZ )
end
function POINT_VEC2:GetDirectionVector(P)
  local SX = self:GetX()
  local SZ = self:GetZ()    
  local PX = P:GetX()
  local PZ = P:GetZ()  
  return POINT_VEC2:New(PX-SX, PZ-SZ)
end
function POINT_VEC3:Distance(P)
  local SX = self:GetX()
  local SY = self:GetY()  
  local SZ = self:GetZ()
  local PX = P:GetX()
  local PY = P:GetY()
  local PZ = P:GetZ()      
  return ((SX-PX)^2 + (SY-PY)^2 + (SZ-PZ)^2) ^ 0.5
end
function POINT_VEC2:Distance(P)
  local SX = self:GetX() 
  local SZ = self:GetZ()
  local PX = P:GetX()  
  local PZ = P:GetZ()      
  return ((SX-PX)^2 + (SZ-PZ)^2) ^ 0.5
end
function POINT_VEC3:Mag()
  local SX = self:GetX()
  local SY = self:GetY()  
  local SZ = self:GetZ()  
  return (SX*SX + SY*SY + SZ*SZ) ^ 0.5
end
function POINT_VEC2:Mag()
  local SX = self:GetX()
  local SZ = self:GetZ()  
  return (SX*SX + SZ*SZ) ^ 0.5
end
function POINT_VEC2:Rotate(ang)
  local SX = self:GetX()
  local SZ = self:GetZ()  
  return POINT_VEC2:New(SX*math.cos(ang) - SZ*math.sin(ang), SX*math.sin(ang) + SZ*math.cos(ang))
end
function POINT_VEC3:RotateY(ang)
  local SX = self:GetX()
  local SY = self:GetY()
  local SZ = self:GetZ()  
  return POINT_VEC3:New(SX*math.cos(ang) - SZ*math.sin(ang), SY, SX*math.sin(ang) + SZ*math.cos(ang))
end
function POINT_VEC2:Add(P)
  local SX = self:GetX()
  local SZ = self:GetZ()    
  local PX = P:GetX()
  local PZ = P:GetZ()  
  return POINT_VEC2:New(PX+SX, PZ+SZ)
end
function POINT_VEC3:Add(P)
  local SX = self:GetX()
  local SY = self:GetY()
  local SZ = self:GetZ()    
  local PX = P:GetX()
  local PY = P:GetY()
  local PZ = P:GetZ()  
  return POINT_VEC3:New(PX+SX, PY+SY, PZ+SZ)
end
function POINT_VEC2:Sub(P)
  local SX = self:GetX()
  local SZ = self:GetZ()    
  local PX = P:GetX()
  local PZ = P:GetZ()  
  return POINT_VEC2:New(PX-SX, PZ-SZ)
end
function POINT_VEC2:Mul(S)
  local SX = self:GetX()
  local SZ = self:GetZ()      
  return POINT_VEC2:New(SX*S, SZ*S)
end
function POINT_VEC3:MulY(S)
  local SX = self:GetX()
  local SY = self:GetY()
  local SZ = self:GetZ()      
  return POINT_VEC3:New(SX*S, SY, SZ*S)
end
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function print_r ( t ) 
    local print_r_cache={}
        local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            env.info(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                local tLen = #t
                for i = 1, tLen do
                    local val = t[i]
                    if (type(val)=="table") then
                        env.info(indent.."#["..i.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(i)+8))
                        env.info(indent..string.rep(" ",string.len(i)+6).."}")
                    elseif (type(val)=="string") then
                        env.info(indent.."#["..i..'] => "'..val..'"')
                    else
                        env.info(indent.."#["..i.."] => "..tostring(val))
                    end
                end
                for pos,val in pairs(t) do
                    if type(pos) ~= "number" or math.floor(pos) ~= pos or (pos < 1 or pos > tLen) then
                        if (type(val)=="table") then
                            env.info(indent.."["..pos.."] => "..tostring(t).." {")
                            sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                            env.info(indent..string.rep(" ",string.len(pos)+6).."}")
                        elseif (type(val)=="string") then
                            env.info(indent.."["..pos..'] => "'..val..'"')
                        else
                            env.info(indent.."["..pos.."] => "..tostring(val))
                        end
                    end
                end
            else
                env.info(indent..tostring(t))
            end
        end
    end
    
   if (type(t)=="table") then
        env.info(tostring(t).." {")
        sub_print_r(t,"  ")
        env.info("}")
    else
        sub_print_r(t,"  ")
    end

   env.info()
end
