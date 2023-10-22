local scale=activity.getResources().getDisplayMetrics().scaledDensity
--屏幕缩放工具类
local ScaleUtil={}


function ScaleUtil.dp2px(dpValue)
  return tointeger(dpValue*scale)
end

function ScaleUtil.px2sp(pxValue)
  return tointeger(pxValue/scale)
end


function ScaleUtil.sp2px(spValue)
  return tointeger(spValue*scale)
end

return ScaleUtil