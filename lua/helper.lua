---加载应用级别的外置dex，用于子页面
function loadAppDex()
  if luajava.luadir:match("([^/]*)/[^/]*/?$")=="sub" then
    local libsDir=luajava.luadir:match("(.+)/[^/]*/[^/]*/?$").."/libs"
    local files=io.ls(libsDir)
    for i=1,#files do
      local file=files[i]
      if file~="." and file~=".." and not io.isdir(libsDir.."/"..file) then
        if not file:match("%.so") then
          activity.loadDex(libsDir.."/"..file)
        end
      end
    end
  end
end
loadAppDex()

require "import"

import "android.content.Intent"
import "android.net.Uri"
import "android.content.Context"
import "java.io.File"

---弹出吐司
---@param text string
function toast(text)
  Toast.makeText(activity, text, Toast.LENGTH_SHORT).show()
end

---启动浏览器
---@param url string 链接
function openInBrowser(url)
  local intent = Intent(Intent.ACTION_VIEW,Uri.parse(url))
  if intent.resolveActivity(activity.getPackageManager()) then
    activity.startActivity(intent)
   else
    toast("未找到浏览器")
  end
end

---@param url string
function getInternetCacheContentPath(url)
  local uri=Uri.parse(url)
  local path=activity.getExternalCacheDir().getPath().."/internet/"..uri.getAuthority().."/"..uri.getPath()..".json"
  return path
end

---@param url string
---@param content string
function saveInternetCacheContent(url,content)
  local path=getInternetCacheContentPath(url)
  File(path).getParentFile().mkdirs()
  io.open(path,"w"):write(content):close()
end

---@param url string
function readInternetCacheContent(url)
  local path=getInternetCacheContentPath(url)
  File(path).getParentFile().mkdirs()
  local file=io.open(path,"r")
  local content=file:read("*a")
  file:close()
  return content
end

---@param url string
function isInternetCacheContent(url)
  local path=getInternetCacheContentPath(url)
  return File(path).isFile()
end

---复制内容并弹出提示
---@param content string 内容
function copyAndToast(content)
  activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(content)
  toast("已复制到剪贴板")
end

---使用第三方软件打开文件，并授予读取和编辑权限
---@param uri Uri 文件 Uri
function openInOtherApp(uri)
  local intent = Intent(Intent.ACTION_VIEW)
  intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
  intent.setDataAndType(uri, "text/json")
  xpcall(activity.startActivity,function(err)
    toast("未找到文件编辑器："..err:match("(.-)\n"))
  end,intent)
end

---获取悬浮的背景色<br>
---@return color number 在Android7.0以上，返回colorBackgroundFloating颜色，否则返回白色
function getFloatingBgColor()
  return Build.VERSION.SDK_INT>=23 and android.res.color.attr.colorBackgroundFloating or 0xFFFFFFFF
end

---对象的id记录工具
ObjIds={_id=0}

setmetatable(ObjIds,{__index=function(self,key)
    self._id=self._id+1
    self[key]=self._id
    return self._id
end})

function setLayoutParams(view,paramMap)
  local params=view.getLayoutParams()
  for key,value in pairs(paramMap) do
    params[key]=value
  end
  view.setLayoutParams(params)
end