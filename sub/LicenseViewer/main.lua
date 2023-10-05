package.path=package.path..activity.getLuaPath("../../lua/?.lua;")

require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.text.Html"
import "android.content.Intent"
import "android.net.Uri"
import "java.io.FileWriter"

import "com.onegravity.rteditor.RTEditorMovementMethod"

import "helper"
import "cjson"
import "res"
import "layoutHelper"

licenseName,licenseKey=...

URL_API_GITHUB_LICENSE="https://api.github.com/licenses/%s"
URL_CHOOSEALICENSE="https://choosealicense.com/"
CODE_EXPORT=1

--TODO: i18n
activity.setTitle(licenseName)
activity.setContentView(loadlayout("layout"))
actionBar=activity.getActionBar()
actionBar.setDisplayHomeAsUpEnabled(true)
--actionBar.setSubtitle("查看许可证")

descriptionView.setMovementMethod(RTEditorMovementMethod.getInstance())

if Build.VERSION.SDK_INT>=25 then
  descriptionView.setRevealOnFocusHint(false)
  bodyView.setRevealOnFocusHint(false)
end

tags={
  ["commercial-use"]="商业用途",
  modifications="修改",
  distribution="分配",
  sublicense="分许可",
  ["private-use"]="私人使用",
  ["no-liability"]="无责任",
  ["include-copyright"]="包含版权",
  ["patent-use"]="专利使用",
  ["trademark-use"]="商标使用",
  warranty="担保",
  liability="责任",
  ["include-copyright--source"]="包含版权--来源",
  ["disclose-source"]="披露来源",
  ["document-changes"]="文档更改",
  ["same-license"]="相同许可证",
  ["same-license--file"]="相同许可证--文件",
  ["same-license--library"]="相同许可证--库",
  ["network-use-disclose"]="网络使用公开",
}

local licenseData={}
local loading=false
local loadedMenus=false

function onCreateOptionsMenu(menu)
  local exportMenu=menu.addSubMenu("导出")
  exportMenu.add(0,0,0,"导出许可证")
  exportMenu.add(0,3,0,"复制许可证")
  local shareMenu=menu.addSubMenu("分享")
  shareMenu.add(0,1,0,"分享许可证内容")
  websiteMenu=menu.add(0,2,0,"许可证网址")
  loadedMenus=true
  refreshMenu()
end

function onOptionsItemSelected(item)
  local id=item.getItemId()
  if id==android.R.id.home then
    activity.finish()
   elseif id==0 then--分享许可证内容
    local intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
    intent.addCategory(Intent.CATEGORY_OPENABLE)
    intent.setType("text/plain")
    intent.putExtra(Intent.EXTRA_TITLE, "LICENSE.txt")
    activity.startActivityForResult(intent,CODE_EXPORT)
   elseif id==1 then--导出许可证
    local intent = Intent()
    intent.setAction(Intent.ACTION_SEND)
    intent.putExtra(Intent.EXTRA_TEXT, licenseData.body)
    intent.putExtra(Intent.EXTRA_TITLE,licenseData.name)
    intent.setData(activity.getUriForPath(File(luajava.luadir).getParentFile().getParent().."/images/license.png"))
    intent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    activity.startActivity(Intent.createChooser(intent, nil))
   elseif id==2 then
    openInBrowser(licenseData.html_url)
   elseif id==3 then
    copyAndToast(licenseData.body)
  end
end

function onActivityResult(requestCode,resultCode,data)
  if resultCode == Activity.RESULT_OK then
    if requestCode==CODE_EXPORT then
      local uri = data.getData()
      local pfd=activity.getContentResolver().openFileDescriptor(uri, "rwt")
      local fileWriter=FileWriter(pfd.getFileDescriptor())
      fileWriter.write(licenseData.body)
      fileWriter.close()
    end
  end
end

function refreshMenu()
  if not loadedMenus return end
  websiteMenu.setEnabled(not not (not loading and licenseData.html_url))
end

---@class LicenseDetails
---@field key string 许可证标识
---@field name string 名称
---@field url string api链接
---@field node_id string
---@field html_url string 网页链接
---@field description string 描述
---@field implementation string 使用方法
---@field permissions string[] 权限
---@field conditions string[] 条件
---@field limitations string[] 局限
---@field body string 内容
---@field featured boolean

---设置正加载状态
function setLoading(state)
  loading=state
  if state then
    progressBar.visibility=View.VISIBLE
    scrollView.visibility=View.GONE
   else
    progressBar.visibility=View.GONE
    scrollView.visibility=View.VISIBLE
  end
  refreshMenu()
end

---设置数据
---@param data LicenseDetails
function setData(data)
  licenseData=data
  data.description=data.description:gsub([[<a(.-)href="/(.-)"(.-)>]],function(start,url,_end)
    return ([[<a%shref="%s%s"%s>]]):format(start,URL_CHOOSEALICENSE,url,_end)
  end)
  data.implementation=data.implementation:gsub([[<a(.-)href="/(.-)"(.-)>]],function(start,url,_end)
    return ([[<a%shref="%s%s"%s>]]):format(start,URL_CHOOSEALICENSE,url,_end)
  end)
  descriptionView.text=Html.fromHtml(data.description)
  implementationView.text=Html.fromHtml(data.implementation)
  
  bodyView.text=data.body

  for index,content in ipairs(data.permissions)
    permissionsLayout.addView(loadlayout(buildTagLayout(tags[content] or content,0xff4caf50),nil,LinearLayout))
  end
  for index,content in ipairs(data.conditions)
    conditionsLayout.addView(loadlayout(buildTagLayout(tags[content] or content,0xff2196f3),nil,LinearLayout))
  end
  for index,content in ipairs(data.limitations)
    limitationsLayout.addView(loadlayout(buildTagLayout(tags[content] or content,0xfff44336),nil,LinearLayout))
  end
end

---拉取许可证
function fetchLicenseDetails()
  local url=URL_API_GITHUB_LICENSE:format(licenseKey)
  if isInternetCacheContent(url) then
    handleLicenseDetails(readInternetCacheContent(url))
   else
    setLoading(true)
    Http.get(url,function(code,content,cookie,header)
      if code==200 then
        saveInternetCacheContent(url,content)
        handleLicenseDetails(content)
       else
        toast("网络错误："..code)
      end
      setLoading(false)
    end)
  end
end

function handleLicenseDetails(content)
  setData(cjson.decode(content))
  setLoading(false)
end

fetchLicenseDetails()
