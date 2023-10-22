local translate

---@class TranslationItem

---从上到下危险性逐渐增加
---@type TranslationItem[]
local translations={
  {
    "%(typically named (.-)%)",
    function(names)
      return ("（%s）"):format(translate(("通常命名为 %s"):format(names)))
    end
  },
  {
    "Create a text file (.-) in the root of your source code and copy the text of the license ?([^ ]-) into the file%.",
    function(hint,disclaimer)
      return ("在源代码的根目录中创建一个文本文件%s，并将许可证%s的文本复制到该文件中。"):format(hint,disclaimer=="disclaimer" and "免责声明" or disclaimer)
    end
  },
  {
    "Replace (.-) with the current year and (.-) with the name %(or names%) of the copyright holders%.",
    function(year,fullname)
      return ("将 %s 替换为当前年份，将 %s 替换为版权持有人的姓名。"):format(year,fullname)
    end
  },
  {
    "([^%.]-), as per GNU conventions",
    function(sentence)
      return "按照 GNU 的约定，"..sentence
    end
  },
  {
    " or ",
    " 或 "
  },
}

---本地使用替换的方法快速翻译文字
---@param originText 原始文字
function translate(originText)
  local translatedText=originText
  for index,item in ipairs(translations) do
    translatedText=translatedText:gsub(item[1],item[2])
  end
  return translatedText
end

return translate