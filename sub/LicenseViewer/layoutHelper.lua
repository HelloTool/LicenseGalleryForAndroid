import "android.graphics.Typeface"
function buildTitleLayout(title)
  return {
    TextView;
    layout_height="wrap";
    layout_width="fill";
    paddingTop="8dp";
    paddingBottom="0dp";
    padding="16dp";
    textSize="14sp";
    text=title;
    typeface=Typeface.DEFAULT_BOLD;
    textColor=android.res.color.attr.colorAccent;
  };
end

function buildTextLayout(text,id)
  return{
    TextView;
    layout_height="wrap";
    layout_width="fill";
    id=id;
    text=text;
    padding="16dp";
    paddingTop="4dp";
    paddingBottom="4dp";
    textSize="14sp";
    textColor=android.res.color.attr.textColorPrimary;
    textIsSelectable=true;
  };
end

function buildTagsLayout(name,key)
  return {
    LinearLayout;
    layout_height="fill";
    layout_width=0;
    layout_weight=1;
    id=key.."Layout";
    orientation="vertical";
    buildTagTitleLayout(name);
    --contentDescription=name;
    padding="8dp";
    focusable=true;
    {
      TextView;
      layout_height="wrap";
      layout_width="fill";
      textSize="14sp";
      --textIsSelectable=true;
      id=key.."TextView";
      --focusable=false;
      lineSpacing={"4dp",1};
      textColor=android.res.color.attr.textColorPrimary;
    };
  };
end

function buildTagTitleLayout(title)
  return{
    TextView;
    layout_height="wrap";
    layout_width="fill";
    text=title;
    textSize="14sp";
    layout_marginBottom="4dp";
    typeface=Typeface.DEFAULT_BOLD;
    textColor=android.res.color.attr.textColorPrimary;
  };
end