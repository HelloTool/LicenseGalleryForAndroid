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

function buildTagLayout(text,color)
  return{
    LinearLayout;
    layout_height="wrap";
    layout_width="fill";
    gravity="start|center";
    layout_marginTop="2dp";
    layout_marginBottom="2dp";
    {
      CardView;
      layout_height="12dp";
      layout_width="12dp";
      layout_marginEnd="4dp";
      cardBackgroundColor=color;
      radius="6dp";
      elevation=0;
    };
    {
      TextView;
      layout_height="wrap";
      layout_width="fill";
      text=text;
      textSize="14sp";
      textIsSelectable=true;
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