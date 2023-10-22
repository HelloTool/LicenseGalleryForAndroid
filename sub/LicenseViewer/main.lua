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
import "android.text.SpannableString"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.drawable.LayerDrawable"
import "android.text.Spannable"
import "android.text.style.BulletSpan"
import "android.text.style.DynamicDrawableSpan"
import "android.text.util.Linkify"
import "com.onegravity.rteditor.RTEditorMovementMethod"

import "ScaleUtil"
import "cjson"
import "res"
import "layoutHelper"
import "i18n.tags"
import "i18n.helper.translate"
import "ExportToGitHostDialog"

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
  local exportMenu=menu.addSubMenu(0,ObjIds.export,0,"导出..")
  exportMenu.add(0,ObjIds.exportLicense,0,"导出许可证")
  exportMenu.add(0,ObjIds.exportToGitHost,0,"导出到 Git 仓库")
  exportMenuItem=menu.findItem(ObjIds.export)

  local copyMenu=menu.addSubMenu(0,ObjIds.copy,0,"复制..")
  copyMenu.add(0,ObjIds.copyName,0,"复制名称")
  copyMenu.add(0,ObjIds.copySdxId,0,"复制 SDX ID")
  copyMenu.add(0,ObjIds.copyLicense,0,"复制许可证内容")
  copyMenuItem=menu.findItem(ObjIds.copy)

  local shareMenu=menu.addSubMenu(0,ObjIds.share,0,"分享..")
  shareMenuItem=menu.findItem(ObjIds.share)
  shareMenu.add(0,ObjIds.shareLicenseContent,0,"分享许可证内容")
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
   elseif id==ObjIds.copySdxId then
    copyAndToast(licenseData.spdx_id)
   elseif id==ObjIds.copyName then
    copyAndToast(licenseData.name)
   elseif id==ObjIds.exportToGitHost then
    ExportToGitHostDialog()
    :show()
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

---@param key string
function getI18nText(key)
  return tags.zh[key] or tags[key] or key
end

---@param text string
---@param color number
function addBulletForLines(text,color)
  if #text==0 then
    return nil
  end
  local spannable=SpannableString(text)
  local textJ=String(text)
  local index=0
  while index>=0 do
    local bulletSpan=BulletSpan(ScaleUtil.dp2px(4), color, ScaleUtil.dp2px(6))
    spannable.setSpan(bulletSpan, index, index+1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
    index=textJ.indexOf("\n",index)+1
    if index==0 then
      break
    end
  end
  return spannable
end

---@param text string
function fixRelativeUrl(text)
  return text:gsub([[<a(.-)href="/(.-)"(.-)>]],function(start,url,_end)
    return ([[<a%shref="%s%s"%s>]]):format(start,URL_CHOOSEALICENSE,url,_end)
  end)
end

---设置数据
---@param data LicenseDetails
function setData(data)
  licenseData=data
  data.description=fixRelativeUrl(data.description)
  data.implementation=fixRelativeUrl(data.implementation)
  activity.setTitle(data.spdx_id)
  descriptionView.text=Html.fromHtml((data.description))
  implementationView.text=Html.fromHtml(translate(data.implementation))

  bodyView.text=data.body:gsub("\n*$",""):gsub("^\n*","")

  local tags={
    {data.permissions,0xff4caf50,permissionsTextView},
    {data.conditions,0xff2196f3,conditionsTextView},
    {data.limitations,0xfff44336,limitationsTextView}
  }
  for index,content in ipairs(tags) do
    if #content[1]==0 then
      content[3].setText("无")
     else
      local newContents={}
      for index,content in ipairs(content[1])
        newContents[index]=getI18nText(content)
      end
      local text=table.concat(newContents,"\n")
      content[3].setText(addBulletForLines(text,content[2]))
    end
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
