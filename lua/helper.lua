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

function copyAndToast(text)
  activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(text)
  toast("已复制到剪贴板")
end