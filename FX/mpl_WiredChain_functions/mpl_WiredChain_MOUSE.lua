-- @description WiredChain_MOUSE
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  ---------------------------------------------------
  function ShortCuts(char)
    if char == 32 then Main_OnCommandEx(40044, 0,0) end -- space: play/pause
  end
  ---------------------------------------------------
  function MOUSE_Match(mouse, b)
    if not b then return end
    if not b.mouse_offs_x then b.mouse_offs_x = 0 end 
    if not b.mouse_offs_y then b.mouse_offs_y = 0 end
    if b.x and b.y and b.w and b.h then 
      local state= mouse.x > b.x  + b.mouse_offs_x
               and mouse.x < b.x+b.w + b.mouse_offs_x
               and mouse.y > b.y - b.mouse_offs_y
               and mouse.y < b.y+b.h - b.mouse_offs_y
      if state and not b.ignore_mouse then 
        mouse.context = b.context 
        return true, (mouse.x - b.x- b.mouse_offs_x) / b.w
      end
    end  
  end
   ------------------------------------------------------------------------------------------------------  
  function MOUSE_Mod_ToolTips(conf, obj, data, refresh, mouse)
    if not mouse.context:match('mod_') then  obj.tooltip = '' end
    if not mouse.is_moving and obj.tooltip then 
      
      -- format tip
      local strTT = obj.tooltip
      local str = ''
      for line in strTT:gmatch('[^\r\n]+') do
        local t, t2 = Data_ParseRouteStr({dest = line})
        if t2 then
          if t2.isFX then str = str..'to FX' else str = str..'to track IO' end
          if t2.isFX then str = str..' '..t2.FXid..' pin'..t2.chan end
          if not t2.isFX and t2.chan then str = str..' chan'..t2.chan end
        end
        str = str..'\n'
      end
      
            
      local x, y = GetMousePosition()
      TrackCtl_SetToolTip( str, x+20, y+20, false ) 
    end
  end
   ------------------------------------------------------------------------------------------------------
  function MOUSE(conf, obj, data, refresh, mouse)
    local d_click = 0.4
    mouse.cap = gfx.mouse_cap
    mouse.x = gfx.mouse_x
    mouse.y = gfx.mouse_y
    mouse.LMB_state = gfx.mouse_cap&1 == 1 
    mouse.RMB_state = gfx.mouse_cap&2 == 2 
    mouse.MMB_state = gfx.mouse_cap&64 == 64
    mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5 
    mouse.Ctrl_state = gfx.mouse_cap&4 == 4 
    mouse.Shift_state = gfx.mouse_cap&8 == 8 
    mouse.Alt_state = gfx.mouse_cap&16 == 16 -- alt
    mouse.wheel = gfx.mouse_wheel
    mouse.context = '_window'
    mouse.is_moving = mouse.last_x and mouse.last_y and (mouse.last_x ~= mouse.x or mouse.last_y ~= mouse.y)
    mouse.wheel_trig = mouse.last_wheel and (mouse.wheel - mouse.last_wheel) 
    mouse.wheel_on_move = mouse.wheel_trig and mouse.wheel_trig ~= 0
    if mouse.LMB_state and not mouse.last_LMB_state then  
       mouse.last_x_onclick = mouse.x     
       mouse.last_y_onclick = mouse.y 
       mouse.LMB_state_TS = os.clock()
    end  
    
     mouse.DLMB_state = mouse.LMB_state 
                        and not mouse.last_LMB_state
                        and mouse.last_LMB_state_TS
                        and mouse.LMB_state_TS- mouse.last_LMB_state_TS > 0
                        and mouse.LMB_state_TS -mouse.last_LMB_state_TS < d_click 

  
     if mouse.last_x_onclick and mouse.last_y_onclick then mouse.dx = mouse.x - mouse.last_x_onclick  mouse.dy = mouse.y - mouse.last_y_onclick else mouse.dx, mouse.dy = 0,0 end
   

     -- buttons
       for key in spairs(obj,function(t,a,b) return b < a end) do
         if type(obj[key]) == 'table' and not obj[key].ignore_mouse then
           ------------------------
           
           if MOUSE_Match(mouse, obj[key]) and key:match('mod_')  then
              obj[key].highlighted_pin = true
              if obj[key].func_mouseover then obj[key].func_mouseover() end
              refresh.GUI_minor = true
            end
            ------------------------
           if MOUSE_Match(mouse, obj[key]) and mouse.LMB_state and not mouse.last_LMB_state then mouse.context_latch = key end
           ------------------------
           mouse.onclick_L = not mouse.last_LMB_state 
                               and mouse.cap == 1
                               and MOUSE_Match(mouse, obj[key]) 
          if mouse.onclick_L and obj[key].func then obj[key].func() goto skip_mouse_obj end
           ------------------------
           mouse.onrelease_L = not mouse.LMB_state 
                               and mouse.last_LMB_state 
                               --and not mouse.Ctrl_state  
                               and MOUSE_Match(mouse, obj[key]) 
          if mouse.onrelease_L and obj[key].onrelease_L then obj[key].onrelease_L() goto skip_mouse_obj end          
           ------------------------
           mouse.ondrag_L = -- left drag (persistent even if not moving)
                               mouse.LMB_state 
                               and not mouse.Ctrl_state 
                               and (mouse.context == key or mouse.context_latch == key) 
           if mouse.ondrag_L and obj[key].func_LD then obj[key].func_LD() end 
                 ------------------------
           mouse.ondrag_L_onmove = -- left drag (only when moving after latch)
                               mouse.LMB_state 
                               --and not mouse.Ctrl_state 
                               and mouse.is_moving
                               and mouse.context_latch == key
           if mouse.ondrag_L_onmove and obj[key].func_LD2 then obj[key].func_LD2() end 
                 ------------------------              
           mouse.onclick_LCtrl = mouse.LMB_state 
                               and not mouse.last_LMB_state 
                               and mouse.Ctrl_state  
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onclick_LCtrl and obj[key].func_trigCtrl then obj[key].func_trigCtrl() end
                 ------------------------              
           mouse.onclick_LAlt = not mouse.last_LMB_state 
                               and mouse.cap == 17   -- alt + lclick
                               and MOUSE_Match(mouse, obj[key]) 
          if mouse.onclick_LAlt  then 
              if obj[key].func_L_Alt then obj[key].func_L_Alt() end
              goto skip_mouse_obj  
          end           
                 ------------------------            
           mouse.ondrag_LCtrl = -- left drag (persistent even if not moving)
                               mouse.LMB_state 
                               and mouse.Ctrl_state 
                               and mouse.context_latch == key
           if mouse.ondrag_LCtrl and obj[key].func_ctrlLD then obj[key].func_ctrlLD() end 
                 ------------------------
           mouse.onclick_R = mouse.RMB_state 
                               and not mouse.last_RMB_state 
                               and not mouse.Ctrl_state  
                               and MOUSE_Match(mouse, obj[key]) 
           if mouse.onclick_R and obj[key].func_R then obj[key].func_R() end
                 ------------------------                
           mouse.ondrag_R = -- left drag (persistent even if not moving)
                               mouse.RMB_state 
                               and not mouse.Ctrl_state 
                               and (mouse.context == key or mouse.context_latch == key) 
           if mouse.ondrag_R and obj[key].func_RD then obj[key].func_RD() end 
                 ------------------------  
           mouse.onwheel = mouse.wheel_trig 
                           and mouse.wheel_trig ~= 0 
                           and not mouse.Ctrl_state 
                           and mouse.context == key
           if mouse.onwheel and obj[key].func_wheel then obj[key].func_wheel(mouse.wheel_trig) end
         end
       end
       
       ::skip_mouse_obj::
    
    MOUSE_Mod_ToolTips(conf, obj, data, refresh, mouse)
    
    if not MOUSE_Match(mouse, {x=0,y=0,w=gfx.w, h=gfx.h}) then obj.tooltip = '' end
     -- mouse release    
      if mouse.last_LMB_state and not mouse.LMB_state   then   
        mouse.drag_obj = nil
        -- clear context
        mouse.context_latch = ''
        mouse.context_latch_val = -1
        mouse.context_latch_t = nil
        --Main_OnCommand(NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)
        refresh.GUI = true
      end
      --if mouse.context == '_window' and mouse.last_context ~= '_window' then refresh.GUI = true end
      mouse.last_context = mouse.context
       mouse.last_x = mouse.x
       mouse.last_y = mouse.y
       mouse.last_LMB_state = mouse.LMB_state  
       mouse.last_RMB_state = mouse.RMB_state
       mouse.last_MMB_state = mouse.MMB_state 
       mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
       mouse.last_Ctrl_state = mouse.Ctrl_state
       mouse.last_Alt_state = mouse.Alt_state
       mouse.last_wheel = mouse.wheel   
       mouse.last_context_latch = mouse.context_latch
       mouse.last_LMB_state_TS = mouse.LMB_state_TS
       --mouse.DLMB_state = nil  
       
        
   end
