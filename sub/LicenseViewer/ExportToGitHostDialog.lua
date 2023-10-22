import "android.net.Uri"
local ExportToGitHostDialog={}
setmetatable(ExportToGitHostDialog,ExportToGitHostDialog)

local layout={
  LinearLayout;
  layout_height="fill";
  layout_width="fill";
  orientation="vertical";
  paddingTop="8dp";
  {
    TextView;
    layout_height="wrap";
    layout_width="fill";
    paddingTop="8dp";
    paddingBottom="0dp";
    padding="24dp";
    textSize="14sp";
    text="仓库链接";
    typeface=Typeface.DEFAULT_BOLD;
    textColor=android.res.color.attr.colorAccent;
  };
  {
    EditText;
    layout_width="fill";
    layout_marginStart="22dp";
    layout_marginEnd="22dp";
    lines=1;
    inputType="text";
    hint="输入 GitHub 仓库链接...";
    id="urlEdit";
  };
}

function ExportToGitHostDialog.__call(self)
  self=table.clone(self)
  return self
end

function ExportToGitHostDialog:create()
  local ids={}
  local builder=AlertDialog.Builder(this)
  .setTitle("导出到 Git 仓库")
  .setView(loadlayout(layout,ids))
  .setPositiveButton(android.R.string.ok,nil)
  .setNegativeButton(android.R.string.no,nil)
  local dialog=builder.create()
  dialog.create()
  local positiveButton=dialog.getButton(Dialog.BUTTON_POSITIVE)
  positiveButton.onClick=function()
    local url=ids.urlEdit.text
    if url:match("^https?://github.com/[^/]+/[^/]+$") then
      openInBrowser(url.."/community/license/new?template=AGPL-3.0")
     else
      ids.urlEdit.setError("请输入正确的仓库地址")
    end
  end
  return dialog
end

function ExportToGitHostDialog:show()
  return self:create().show()
end

return ExportToGitHostDialog
