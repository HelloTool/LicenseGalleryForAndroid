require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "res"
import "cjson"
import "helper"

---https://docs.github.com/zh/rest/licenses/licenses?apiVersion=2022-11-28#get-all-commonly-used-licenses--status-codes
URL_API_GITHUB_LICENSES="https://api.github.com/licenses"
NAX_AUTO_SEARCH_LIMIT=100

activity.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN|WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
activity.setContentView(loadlayout("layout"))

local filteringText=""

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
  exportMenu.add(0,3,0,"复制 SPDX 名称")
  .setEnabled(not not itemData.spdx_id)
  .setOnMenuItemClickListener(function()
    copyAndToast(itemData.spdx_id)
  end)
  menu.add(0,2,0,"许可证网址")
  .setEnabled(not not itemData.url)
  .setOnMenuItemClickListener(function()
    openInBrowser(itemData.url)
  end)
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

