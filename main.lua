require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.text.util.Linkify"
import "android.graphics.Point"
import "com.onegravity.rteditor.RTEditorMovementMethod"

import "res"
import "cjson"
require "helper"
require "init"
import "ScaleUtil"

---https://docs.github.com/zh/rest/licenses/licenses?apiVersion=2022-11-28#get-all-commonly-used-licenses--status-codes
URL_API_GITHUB_LICENSES="https://api.github.com/licenses"
URL_CHOOSEALICENSE="https://choosealicense.com/"
NAX_AUTO_SEARCH_LIMIT=100

activity.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN|WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
activity.setContentView(loadlayout("layout"))

local filteringText=""

function onCreateOptionsMenu(menu)
  menu.add(0,1,0,"选择开源许可证网站")
  local helpMenu=menu.addSubMenu("帮助")
  helpMenu.add(0,3,0,"认识开源许可证")
  menu.add(0,2,0,"关于")
end

function onOptionsItemSelected(item)
  local id=item.getItemId()
  if id==1 then
    openChooseALicenseWebsite()
   elseif id==2 then
    showAboutDialog()
   elseif id==3 then
    openInBrowser("https://oschina.gitee.io/opensource-guide/guide/第二部分：学习和使用开源项目/第 3 小节：认识开源许可证/")
  end
end

function onConfigurationChanged(newConfig)
  local screenWidthDp=newConfig.screenWidthDp
  if screenWidthDp>960 then
    setLayoutParams(mainLayout,{width=ScaleUtil.dp2px(960)})
   else
    setLayoutParams(mainLayout,{width=-1})
  end
end

function openChooseALicenseWebsite()
  openInBrowser(URL_CHOOSEALICENSE)
end

function showAboutDialog()
  local dialog=AlertDialog.Builder(this)
  .setTitle(appname)
  .setIcon(R.drawable.icon)
  .setMessage("")
  .setPositiveButton(android.R.string.ok,nil)
  --.setNeutralButton("法律信息...",nil)
  .setNegativeButton("开源仓库",nil)
  .show()

  local messageView=dialog.findViewById(android.R.id.message)
  local neutralButton=dialog.getButton(Dialog.BUTTON_NEUTRAL)
  local negativeButton=dialog.getButton(Dialog.BUTTON_NEGATIVE)
  messageView.setAutoLinkMask(Linkify.WEB_URLS|Linkify.EMAIL_ADDRESSES)
  messageView.setTextIsSelectable(true)
  messageView.setMovementMethod(RTEditorMovementMethod.getInstance())
  messageView.setText([[
软件版本: v]]..("%s (%s)"):format(appver,appcode)..[[ 
开源许可: MIT
反馈邮箱: jesse205@qq.com

使用 GitHub License API 获取许可证数据的，并有序地暂时出来，供用户快速选择的 Android 客户端。

免责声明：

1. 本软件中的网站、内容与本软件无关。本软件仅作为许可证提供方（GitHub、Choose an open source license）的浏览器使用。
2. 我们大多数人不是律师。本软件以及网站不提供法律咨询。如果您对代码的最佳许可证或与代码相关的任何其他法律问题有任何疑问，您可以进一步研究或咨询专业人员。

用户协议：

1. 禁止违反当地法律与法规

隐私政策：

1. 本程序只会申请联网权限，其余权限均为默认权限
2. 本程序不会上传为提供网络服务的信息（如：IP）以外的任何信息。]])
  --设置为文本后需要取消自动连接，否则会点击重复
  messageView.setAutoLinkMask(0)

  messageView.requestFocus()
  negativeButton.onClick=function(view)
    openInBrowser("https://gitee.com/AideLua/LicenseGallery")
  end
end

---@class LicenseItem
---@field key string
---@field name string
---@field spdx_id string|nil
---@field node_id string
---@field url string|nil


---所有许可数据
---@type LicenseItem[]
local data={}

---已过滤数据
---@type LicenseItem[]
local filteredData={}
local adapter=luajava.override(BaseAdapter,{
  getCount=function(super)
    return int(#filteredData)
  end,
  getItem=function(super,position)
    return filteredData[position+1]
  end,
  getItemId=function(super,position)
    return long(position)
  end,
  getView=function(super,position, convertView, parent)
    local _,view=xpcall(function()
      local ids
      local view=convertView
      local itemData=filteredData[position+1]
      if not view then
        ids={}
        view=loadlayout("itemLayout",ids)
        view.tag=ids
       else
        ids=view.tag
      end
      ids.title.text=itemData.name
      ids.summary.text=itemData.spdx_id or "未知"
      view.alpha=itemData.spdx_id and 1 or 0.6
      return view
    end,
    function(errMsg)
      print(errMsg)
      return View(activity)
    end)
    return view
  end,
  isEnabled=function(super,position)
    return not not filteredData[position+1].spdx_id
  end
})
listView.setAdapter(adapter)

listView.onItemClick=function(parent,view,position,id)
  local itemData=filteredData[position+1]
  activity.newActivity("sub/LicenseViewer/main.lua",{itemData.spdx_id,itemData.key})
end

listView.onCreateContextMenu=function(menu,v,menuInfo)
  local itemData=filteredData[menuInfo.position+1]
  menu.setHeaderTitle(itemData.spdx_id)
  local exportMenu=menu.addSubMenu("复制")
  exportMenu.add(0,0,0,"复制名称")
  .setOnMenuItemClickListener(function()
    copyAndToast(itemData.name)
  end)
  exportMenu.add(0,3,0,"复制 SPDX ID")
  .setEnabled(not not itemData.spdx_id)
  .setOnMenuItemClickListener(function()
    copyAndToast(itemData.spdx_id)
  end)
  --[[
  menu.add(0,2,0,"许可证网址")
  .setEnabled(not not itemData.url)
  .setOnMenuItemClickListener(function()
    openInBrowser(itemData.url)
  end)]]
end

searchButton.onClick=function()
  searchItems(searchEdit.text)
end

searchEdit.onEditorAction=function(view,actionId,event)
  if event then
    searchItems(tostring(view.text))
  end
end

searchEdit.addTextChangedListener({
  onTextChanged=function(text)
    if #data<NAX_AUTO_SEARCH_LIMIT then
      searchItems(tostring(text))
    end
  end
})


---@param text string
function searchItems(text)
  filteringText=text
  local loweredText=string.lower(text)
  table.clear(filteredData)
  for i=1,#data do
    local item=data[i]
    if string.lower(item.name):find(loweredText)
      or string.lower(item.spdx_id):find(loweredText) then
      table.insert(filteredData,item)
    end
  end
  adapter.notifyDataSetChanged()
end

---设置正加载状态
function setLoading(state)
  if state then
    progressBar.visibility=View.VISIBLE
   else
    progressBar.visibility=View.GONE
  end
end

---拉取许可证
function fetchAllLicenses()
  local url=URL_API_GITHUB_LICENSES
  if isInternetCacheContent(url) then
    handleAllLicense(readInternetCacheContent(url))
   else
    setLoading(true)
    Http.get(url,function(code,content,cookie,header)
      if code==200 then
        saveInternetCacheContent(url,content)
        handleAllLicense(content)
       else
        toast("网络错误："..code)
      end
      setLoading(false)
    end)
  end
end

function handleAllLicense(content)
  data=cjson.decode(content)
  searchItems(filteringText)
  setLoading(false)
end

fetchAllLicenses()

rootLayout.setOnTouchListener(newTouchChildOnTouchListener(listView))

onConfigurationChanged(activity.getResources().getConfiguration())
