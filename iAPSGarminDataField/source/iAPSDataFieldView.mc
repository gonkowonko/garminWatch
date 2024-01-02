//**********************************************************************
// DESCRIPTION : DataField for iAPS 
// AUTHORS : 
//          Created by ivalkou - https://github.com/ivalkou 
//          Modify by Pierre Lagarde - https://github.com/avouspierre
// COPYRIGHT : (c) 2023 ivalkou / Lagarde 
//

import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


class iAPSDataFieldView extends WatchUi.DataField {

    function initialize() {
        DataField.initialize();   
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));

        // Use the generic, centered layout
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));

            // LEFT START
            var labelView = View.findDrawableById("label");
            labelView.locX = labelView.locX - 110;
            labelView.locY = labelView.locY - 20;

            var valueView = View.findDrawableById("value");
            valueView.locX = labelView.locX;
            valueView.locY = labelView.locY + 5;

            var valueViewArrow = View.findDrawableById("arrow"); 
            valueViewArrow.locX = valueView.locX + 60 ;  //default is moved during processing
            valueViewArrow.locY = valueView.locY + 15; 

            // LEFT END

            // RIGHT START

            var valueViewDelta = View.findDrawableById("valueDelta"); 
            valueViewDelta.locX = valueViewDelta.locX + 30;   
            valueViewDelta.locY = labelView.locY; 

            //var valueViewTime = View.findDrawableById("valueTime");
            //valueViewTime.locX = valueViewDelta.locX;
           // valueViewTime.locY = valueViewDelta.locY + 20; 

            var valueIob = View.findDrawableById("iob");
            valueIob.locX = valueViewDelta.locX;
            valueIob.locY = valueViewDelta.locY + 20; 

            var valueCob = View.findDrawableById("cob");
            valueCob.locX = valueIob.locX;
            valueCob.locY = valueIob.locY + 20; 

            // RIGHT END

            //hide stuff we dont have room for

            var isHalfView = getIsHalfView(dc);

            valueIob.isVisible = !isHalfView;
            valueCob.isVisible = !isHalfView;

            if(isHalfView){
                (valueView as Text).setFont(Graphics.FONT_SYSTEM_NUMBER_MEDIUM);
                valueView.locX = valueView.locX + 70;
                valueViewArrow.locX = valueViewArrow.locX + 70;
                valueViewArrow.locY = valueViewArrow.locY - 5;

                (valueViewDelta as Text).setJustification(Graphics.TEXT_JUSTIFY_CENTER);

                valueViewDelta.locX = 61;
                //(valueViewDelta as Text).setBackgroundColor(Graphics.COLOR_BLUE);
                valueViewDelta.locY = valueView.locY + 35;
            }
        }

       // (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
        
    }

    function getIsHalfView(dc as Dc) as Boolean {
        return dc.getWidth() == 122;   //122 = half, 246 full on a 830
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        var bgString = "--";
        var timeAgoString = null;
        var deltaString = "--";
        var isNightMode = false;
        var cobString = "";
        var iobString = "";
        var bgTenOrOver = false;
        
        if(getBackgroundColor() == Graphics.COLOR_BLACK){
            isNightMode = true;
        }

        //Grab the application settings
        var settingUrgentLow = Application.Properties.getValue("UrgentLowValue");
        var settingUrgentHigh = Application.Properties.getValue("UrgentHighValue");
        var settingLow = Application.Properties.getValue("LowValue");
        var settingHigh = Application.Properties.getValue("HighValue");

        //Some fallback defaults
        if(settingUrgentLow == null){
            settingUrgentLow = 3.8;
        }

        if(settingUrgentHigh == null){
            settingUrgentHigh = 11;
        }

        if(settingLow == null){
            settingLow = 4.4;
        }

        if(settingHigh == null){
            settingHigh = 9;
        }

        var isHalfView = getIsHalfView(dc);

        var status = Application.Storage.getValue("status") as Dictionary;
        var fontColour = Graphics.COLOR_DK_GREEN;

        if (status != null) {

            var bg = status["glucose"] as String;
            var bgNumber = (bg == null) ? null : bg.toFloat();
            bgString = (bg == null) ? "--" : bg as String;
            bgTenOrOver = bgNumber >= 10;

            if (bgNumber <= settingUrgentLow || bgNumber >= settingUrgentHigh) {
                    fontColour = Graphics.COLOR_DK_RED;
            } else if (bgNumber <= settingLow || bgNumber >= settingHigh) {
                fontColour = isNightMode ? Graphics.COLOR_YELLOW : Graphics.COLOR_ORANGE;
            } else if (bgNumber == null) {
            fontColour =  Graphics.COLOR_BLUE;
            }
        
            var min = getMinutes(status); //-1 means no data

            if (min >= 30){
                timeAgoString = "stale";
            } else if (min >= 0) {
                timeAgoString = min.format("%d") + " min";
            } else {
                timeAgoString = "??";
            }
        
            deltaString = getDeltaText(status) as String; 
           
            cobString = status["cob"] as String;
            var iobValue = status["iob"] as Double;
            
            if(iobValue != null) {              
                iobString = iobValue.format("%.2f");
            }

        }

        if(bgString.equals("--")) {
            fontColour = isNightMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        }

        cobString = "COB: " + cobString;
        iobString = "IOB:  " + iobString;

        if(timeAgoString != null){
            deltaString = deltaString + " (" + timeAgoString + ")";
        }

        //Set the background shape
        (View.findDrawableById("Background") as Text).setColor(isNightMode ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE); 

        // Set the foreground color and value
        var label = View.findDrawableById("label") as Text;
        var value = View.findDrawableById("value") as Text;
        //var valueTime = View.findDrawableById("valueTime") as Text;
        var valueDelta = View.findDrawableById("valueDelta") as Text;
        var valueIob = View.findDrawableById("iob") as Text;
        var valueCob = View.findDrawableById("cob") as Text;

        value.setColor(fontColour);
        label.setColor(isNightMode ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY);
        //valueTime.setColor(isNightMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);
        valueDelta.setColor(isNightMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);
        valueIob.setColor(isNightMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);
        valueCob.setColor(isNightMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);

        value.setText(bgString);
        valueDelta.setText(deltaString);
        //valueTime.setText(loopString);
        valueIob.setText(iobString);
        valueCob.setText(cobString);

        var arrowView = View.findDrawableById("arrow") as Bitmap;   
        if (isNightMode) {
             arrowView.setBitmap(getDirection(status));   
        }  
        else {
            arrowView.setBitmap(getDirectionBlack(status));
        }

        var valueView =  View.findDrawableById("value");
        var valueViewArrow =  View.findDrawableById("arrow");
        valueView.locX = bgTenOrOver ? 13 : 25;

        if(isHalfView){
            valueViewArrow.locX = valueView.locX + (bgTenOrOver ? 78 : 60); 
        }else{
            valueViewArrow.locX = valueView.locX + (bgTenOrOver ? 105 : 80);  
        }
        
        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

    function getMinutes(status as Dictionary) as Number {
        if (status == null) {
            return -1;
        }

        var lastGlucoseDate = status["glucoseDateInterval"] as Number;

        if (lastGlucoseDate == null) {
            return -1;
        }

        if (lastGlucoseDate instanceof Number) {
            
            var now = Time.now().value() as Number;
            var min = (now - lastGlucoseDate) / 60;
            return min;

        } else {
            return -1;
        }
    }

    function getLoopColor(min as Number) as Number {
        if (min < 0) {
            return getBackgroundColor() as Number;
        } else if (min <= 5) {
            return getBackgroundColor() as Number;
        } else if (min <= 10) {
            return Graphics.COLOR_YELLOW as Number;
        } else {
            return Graphics.COLOR_RED as Number;
        }
    } 

    function getDeltaText(status as Dictionary) as String {
        if (status == null) {
            return "--";
        }
        var delta = status["delta"] as String;
        
        var deltaString = (delta == null) ? "--" : delta;

        return deltaString;
    }

    function getDirectionBlack(status) as BitmapType {
        var bitmap = WatchUi.loadResource(Rez.Drawables.UnknownB);
        if (status instanceof Dictionary)  {
            var trend = status["trendRaw"] as String;
            if (trend == null) {
                return bitmap;
            }

            switch (trend) {
                case "Flat":
                case "→":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FlatB);
                    break;
                case "SingleUp":
                case "↑":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleUpB);
                    break;
                case "SingleDown":
                case "↓":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleDownB);
                    break;
                case "FortyFiveUp":
                case "↗︎":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveUpB);
                    break;
                case "FortyFiveDown":
                case "↘︎":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveDownB);
                    break;
                case "DoubleUp":
                case "TripleUp":
                case "⇈":
                case "↑↑":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleUpB);
                    break;
                case "DoubleDown":
                case "TripleDown":
                case "⇊":
                case "↓↓":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleDownB);
                    break;
                default: break;
            }

            return bitmap;
        } else {
            return bitmap;
        }
        
    }

    function getDirection(status) as BitmapType {
        var bitmap = WatchUi.loadResource(Rez.Drawables.Unknown);
        if (status instanceof Dictionary)  {
            var trend = status["trendRaw"] as String;
            if (trend == null) {
                return bitmap;
            }

            switch (trend) {
                case "Flat":
                case "→":
                    bitmap = WatchUi.loadResource(Rez.Drawables.Flat);
                    break;
                case "SingleUp":
                case "↑":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleUp);
                    break;
                case "SingleDown":
                case "↓":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleDown);
                    break;
                case "FortyFiveUp":
                case "↗︎":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveUp);
                    break;
                case "FortyFiveDown":
                case "↘︎":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveDown);
                    break;
                case "DoubleUp":
                case "TripleUp":
                case "⇈":
                case "↑↑":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleUp);
                    break;
                case "DoubleDown":
                case "TripleDown":
                case "⇊":
                case "↓↓":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleDown);
                    break;
                default: break;
            }

            return bitmap;
        } else {
            return bitmap;
        }
        
    }  


}
