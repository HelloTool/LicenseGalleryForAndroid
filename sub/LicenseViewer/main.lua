package.path=package.path
..activity.getLuaPath("../../?.lua;")
..activity.getLuaPath("../../lua/?.lua;")
..activity.getLuaPath("../../?/init.lua;")
..activity.getLuaPath("../../lua/?/init.lua;")

require "helper"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.text.Html"
import "android.content.Intent"
import "android.net.Uri"
import "java.io.FileWriter"
import "com.onegravity.rteditor.RTEditorMovementMethod"

import "cjson"
import "res"
import "layoutHelper"
import "i18n.tags"
import "i18n.helper.translate"

licenseName,licenseKey=...

URL_API_GITHUB_LICENSE_FORMATTER="https://api.github.com/licenses/%s"
URL_CHOOSEALICENSE="https://choosealicense.com/"
CODE_EXPORT=1

activity.setContentView(loadlayout("layout"))
actionBar=activity.getActionBar()
actionBar.setDisplayHomeAsUpEnabled(true)
activity.setTitle(licenseName)
actionBar.setSubtitle("查看许可证")

descriptionView.setMovementMethod(RTEditorMovementMethod.getInstance())

if Build.VERSION.SDK_INT>=25 then
  descriptionView.setRevealOnFocusHint(false)
  bodyView.setRevealOnFocusHint(false)
end

local licenseData={}
local loading=false
local loadedMenus=false

function onCreateOptionsMenu(menu)
  local copyMenu=menu.addSubMenu(0,ObjIds.copy,0,"复制..")
  copyMenu.add(0,ObjIds.copyLicense,0,"复制许可证")
  copyMenuItem=menu.findItem(ObjIds.copy)

  local shareMenu=menu.addSubMenu(0,ObjIds.share,0,"分享..")
  shareMenuItem=menu.findItem(ObjIds.share)
  shareMenu.add(0,ObjIds.shareLicenseContent,0,"分享许可证内容")
  exportMenuItem=menu.add(0,ObjIds.exportLicense,0,"导出许可证")
  websiteMenuItem=menu.add(0,ObjIds.licenseWebsite,0,"许可证网址")
  loadedMenus=true
  refreshMenus()
end

function onOptionsItemSelected(item)
  local id=item.getItemId()
  if id==android.R.id.home then
    activity.finish()
   elseif id==ObjIds.shareLicenseContent then--分享许可证内容
    shareLicense()
   elseif id==ObjIds.exportLicense then--导出许可证
    exportLicense()
   elseif id==ObjIds.licenseWebsite then
    openInBrowser(licenseData.html_url)
   elseif id==ObjIds.copyLicense then
    copyAndToast(licenseData.body)
  end
end

function onActivityResult(requestCode,resultCode,data)
  if requestCode==CODE_EXPORT then
    onExportLicenseResult(requestCode,resultCode,data)
  end
end

function onExportLicenseResult(requestCode,resultCode,data)
  if resultCode == Activity.RESULT_OK then
    local uri = data.getData()
    local fileWriter
    local success=false
    pcall(function()
      local pfd=activity.getContentResolver().openFileDescriptor(uri, "rwt")
      fileWriter=FileWriter(pfd.getFileDescriptor())
      fileWriter.write(licenseData.body)
      success=true
    end)
    if fileWriter then
      fileWriter.close()
    end
    if success then
      AlertDialog.Builder(this)
      .setTitle("编辑文件")
      .setMessage("文件保存成功，您可能需要编辑一些内容（比如版权）。是否调用外部应用以编辑文件？")
      .setPositiveButton(android.R.string.ok,function()
        openInOtherApp(uri)
      end)
      .setNegativeButton(android.R.string.no,nil)
      .show()
    end
  end
end

function refreshMenus()
  if not loadedMenus return end
  local licenseUsable=not loading
  exportMenuItem.setEnabled(licenseUsable)
  shareMenuItem.setEnabled(licenseUsable)
  copyMenuItem.setEnabled(licenseUsable)
  websiteMenuItem.setEnabled(not not (licenseUsable and licenseData.html_url))
end

function exportLicense()
  local intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
  intent.addCategory(Intent.CATEGORY_OPENABLE)
  intent.setType("text/plain")
  intent.putExtra(Intent.EXTRA_TITLE, "LICENSE.txt")
  activity.startActivityForResult(intent,CODE_EXPORT)
end

function shareLicense()
  local intent = Intent()
  intent.setAction(Intent.ACTION_SEND)
  intent.putExtra(Intent.EXTRA_TEXT, licenseData.body)
  intent.putExtra(Intent.EXTRA_TITLE,licenseData.name)
  intent.setData(activity.getUriForPath(File(luajava.luadir).getParentFile().getParent().."/images/license.png"))
  intent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
  activity.startActivity(Intent.createChooser(intent, nil))
end

---@class LicenseDetails
---@field key string 许可证标识
---@field name string 名称
---@field url string api链接
---@field node_id string
---@field html_url string 网页链接
---@firld spdx_id string SDPX 名称
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
  refreshMenus()
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
  activity.setTitle(data.spdx_id)
  descriptionView.text=Html.fromHtml((data.description))
  implementationView.text=Html.fromHtml(translate(data.implementation))

  bodyView.text=data.body:gsub("\n*$",""):gsub("^\n*","")

  for index,content in ipairs(data.permissions)
    permissionsLayout.addView(loadlayout(buildTagLayout(tags.zh[content] or tags[content] or content,0xff4caf50),nil,LinearLayout))
  end
  for index,content in ipairs(data.conditions)
    conditionsLayout.addView(loadlayout(buildTagLayout(tags.zh[content] or tags[content] or content,0xff2196f3),nil,LinearLayout))
  end
  for index,content in ipairs(data.limitations)
    limitationsLayout.addView(loadlayout(buildTagLayout(tags.zh[content] or tags[content] or content,0xfff44336),nil,LinearLayout))
  end
end

---拉取许可证
function fetchLicenseDetails()
  local url=URL_API_GITHUB_LICENSE_FORMATTER:format(licenseKey)
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
