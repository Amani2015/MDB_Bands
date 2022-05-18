//+------------------------------------------------------------------+
//|                                                    MDB_Bands.mq5 |
//|                                       Copyright 2022, Tz_Fx_Lab. |
//|                                  https://www.patreon.com/TzFxLab |
//+------------------------------------------------------------------+

/*
         *Why this indicator?*
         ===================
         1. There is no holy grail?? is that true?
         2. I continue to find out using this project as means of study to achieve the expected result
         3. Join us in the move!

         This is just the basic build of the indicator with the following features
            => Indicators (macd, bollinger bands on macd and bollinger bands on main chart)
            => The indicator has alerts, push_notifications to mobile terminals and also plots arrows on chart!)
            => Availbility of study mode and trading mode for enhanced userbility.
*/



datetime expiryDate =  D'2022.05.30 00:00'; //short period release of the indicator

#property copyright "Willing to support? Please click HERE!"
#property link      "https://www.patreon.com/TzFxLab"
#property version   "22.00" //we use last 2 numbers of Year, and incremented build number of the product after the dot
#property indicator_chart_window
#property indicator_buffers 12
#property indicator_plots 5

#property description "Build date 20220517" //actual date when the improvement have been committed (yyyymmdd)
#property description "Search search and God will make it found TzFxLab"



//-- Indicator inputs
input bool StudyMode = false;  //Activate study mode


//-- Theme Settings
enum ThemList {GreenOnBlack = 1,    //Green on Black
               BlackOnWhite = 2,    //Black on White
               ColorOnBlack = 3,    //Color on Black
               ColorsOnWhite = 4    //Color on white
              };
input ThemList SelectedTheme = GreenOnBlack;   //Default Theme



//--List of tested Strategies
enum StrategyList
  {
   ExtremeEntry=1 //ExtremeEntry
  };
input StrategyList SelectedStrategy = 1;     //Applied Strategy:


//-- Notification settings
input bool WindowsAlert = true;              //Windows Alert
input bool PushNotification = true;          //Push Notification
input bool SoundNotification = true;         //Sound Notification


//--Indicator external inputs parameters
//main chart indicator settings
input string MainWindoSettings; //MAIN WINDOW SETTINGS
input int mbolingerPeriod = 20; //mBands Period:
input double mDeviation = 2; //mBands Deviation:
input ENUM_APPLIED_PRICE mBolingerAppliedPrice = PRICE_CLOSE; //mBands Applied To:


//Window 1 indicator inputs
input string window1Settings; //WINDOW 1 SETTINGS
input int FastEMA = 12; //macd Fast EMA
input int SlowEMA = 26; //macd Slow EMA
input int MacdSignal = 9; //Signal
input ENUM_APPLIED_PRICE MacdAppliedPrice = PRICE_CLOSE; //Applied To:
input int obolingerPeriod = 20; //oBands Period:
input double oDeviation = 1.6; //oBands Deviation:


//--Indicator Buffers
//Arrow Buffers
double ArrowBuy[];
double ArrowSell[];

//MACD Buffers
double main[];
double Signal[];

//mBands Buffers
double mMiddleBB[];
double mUpperBB[];
double mLowerBB[];

//oBands Buffers
double oMiddleBB[];
double oUpperBB[];
double oLowerBB[];


//--Indicator Handles
//Main chart
int mBandsHandle;

//Window 1
int macdHandle;
int oBandsHandle;



//--Other important variables
int ExtBarsMinimum;
int MaxPeriod = 20;
bool checked;
#define  UpArrow   233
#define  DownArrow 234
#define  ArrowShift 30




//+------------------------------------------------------------------+
//| MDB_Bands Initialization Function                                |
//+------------------------------------------------------------------+
void OnInit()
  {
//Check product usage authentication
datetime currentTime = TimeCurrent();
if(expiryDate < currentTime)
  {
   Alert("The use period for non patreons is up" +
         "\n Dear Patreons: Please contact me to get your FREE pass to continue the use:" +
         "\n Through: Whatapp/telegram/call/sms on : +255766988200 ");
   return;
  }
  
//---- indicator buffer settings
//BUY  ARROW
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_ARROW);        //Sets indicator draw type
   PlotIndexSetString(0,PLOT_LABEL,"Buy_Arrow");            //sets the lable for the indicator
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_SOLID) ;     //set apparance type
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,1);                //sets the width of the plot
   SetIndexBuffer(0, ArrowBuy, INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0, PLOT_ARROW, UpArrow);
   PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, ArrowShift);

//SELL  ARROW
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_ARROW);        //Sets indicator draw type
   PlotIndexSetString(1,PLOT_LABEL,"Sell_Arrow");           //sets the lable for the indicator
   PlotIndexSetInteger(1,PLOT_LINE_STYLE,STYLE_SOLID) ;     //set apparance type
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,1);                //sets the width of the plot
   SetIndexBuffer(1, ArrowSell, INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(1, PLOT_ARROW, DownArrow);
   PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, -ArrowShift);

//mBands
   SetIndexBuffer(2,mMiddleBB, INDICATOR_CALCULATIONS);        //Buffer maping for  mMiddleBB values
   SetIndexBuffer(3,mUpperBB, INDICATOR_CALCULATIONS);        //Buffer maping for  mUpperBB values
   SetIndexBuffer(4,mLowerBB, INDICATOR_CALCULATIONS);        //Buffer maping for  mLowerBB values

//MACD
   SetIndexBuffer(5,main, INDICATOR_CALCULATIONS);        //Buffer maping for  _main values
   SetIndexBuffer(6,Signal, INDICATOR_CALCULATIONS);      //Buffer maping for  _signal values

//oBands
   SetIndexBuffer(7,oMiddleBB, INDICATOR_CALCULATIONS);        //Buffer maping for  oMiddleBB values
   SetIndexBuffer(8,oUpperBB, INDICATOR_CALCULATIONS);        //Buffer maping for  oUpperBB values
   SetIndexBuffer(9,oLowerBB, INDICATOR_CALCULATIONS);        //Buffer maping for  oLowerBB values



//-- Indicator data handles defined
//On chart handles
   mBandsHandle = iBands(_Symbol,0,mbolingerPeriod,0,mDeviation,mBolingerAppliedPrice);   //main Bollinger handle defined

//Macd handle
   macdHandle = iMACD(_Symbol,0,FastEMA,SlowEMA,MacdSignal,MacdAppliedPrice);   //macd handle defined

//BBA Handle
   oBandsHandle = iBands(_Symbol,0,obolingerPeriod,0,oDeviation,macdHandle);   //oscilator Bollinger handle defined



//--Drawables on second window chart
   if(StudyMode)
     {
      ChartIndicatorAdd(0,0,mBandsHandle);      //Plot bollinger bands on main chart window
      ChartIndicatorAdd(0,1,macdHandle);        //Plot fast macd
      ChartIndicatorAdd(0,1,oBandsHandle);      //Plot bollinger bands on macd
     }

//---Display theme selection procedure
//GreenOnBlack Them
   if(SelectedTheme == 1)
     {
      //Arrow colors
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrDodgerBlue);       //Buy arrow color
      PlotIndexSetInteger(1,PLOT_LINE_COLOR,clrRed);              //Sell arrow color

      //Chart colors settings
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);       //Background color
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);       //Foreground color
      ChartSetInteger(0, CHART_COLOR_GRID, clrLightSlateGray);    //Choose back color for grid lines
      ChartSetInteger(0, CHART_COLOR_CHART_UP, clrLime);          //Bar up  color
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrLime);        //Bar down  color
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrBlack);      //Bull candle color
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrWhite);      //Bear candle color
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrLime);        //ChartLine color
      ChartSetInteger(0, CHART_COLOR_VOLUME,clrLimeGreen);        //Volumes color
      ChartSetInteger(0, CHART_COLOR_BID, clrLightSlateGray);     //Color of the bid line
      ChartSetInteger(0, CHART_COLOR_ASK, clrRed);                //Ask line color
      ChartSetInteger(0, CHART_COLOR_LAST, C'0,192,0');           //Last line color
      ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrRed);         //Stop Level color

      //chart show
      ChartSetInteger(0, CHART_SHOW_TICKER, true);                //Show ticker
      ChartSetInteger(0, CHART_SHOW_OHLC, true);                  //Show OHLC
      ChartSetInteger(0, CHART_SHOW_ONE_CLICK, true);             //Show Quick trading buttons
      ChartSetInteger(0, CHART_SHOW_BID_LINE, true);              //Show Bid line
      ChartSetInteger(0, CHART_SHOW_ASK_LINE,true);               //Show Ask Line
      ChartSetInteger(0, CHART_SHOW_LAST_LINE, true);             //Show Last Line
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);           //Hide period separator
      ChartSetInteger(0, CHART_SHOW_GRID, false);                 //Do not show the grid
      ChartSetInteger(0,CHART_SHOW_TRADE_LEVELS,true);            //Show Trade Levels
      ChartSetInteger(0, CHART_FOREGROUND, false);                //Enabled candles to be under indicactors

      //Others
      ChartSetInteger(0, CHART_SCALE, 3);                         //Candle width
     }



//BlackOnWhite Theme if selected
   if(SelectedTheme == 2)
     {
      //Arrow colors
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrBlue);             //Buy arrow color
      PlotIndexSetInteger(1,PLOT_LINE_COLOR,clrOrangeRed);        //Sell arrow color

      //Chart colors settings
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);       //Background color
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrBlack);       //Foreground color
      ChartSetInteger(0, CHART_COLOR_GRID, clrSilver);            //Choose back color for grid lines
      ChartSetInteger(0, CHART_COLOR_CHART_UP, clrBlack);         //Bar up  color
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrBlack);       //Bar down  color
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrWhite);      //Bull candle color
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrBlack);      //Bear candle color
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrBlack);       //ChartLine color
      ChartSetInteger(0, CHART_COLOR_VOLUME,clrGreen);            //Volumes color
      ChartSetInteger(0, CHART_COLOR_BID, clrSilver);             //Color of the bid line
      ChartSetInteger(0, CHART_COLOR_ASK, clrSilver);             //Ask line color
      ChartSetInteger(0, CHART_COLOR_LAST,clrSilver);             //Last line color
      ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrOrangeRed);   //Stop Level color

      //chart show
      ChartSetInteger(0, CHART_SHOW_TICKER, true);                //Show ticker
      ChartSetInteger(0, CHART_SHOW_OHLC, true);                  //Show OHLC
      ChartSetInteger(0, CHART_SHOW_ONE_CLICK, true);             //Show Quick trading buttons
      ChartSetInteger(0, CHART_SHOW_BID_LINE, true);              //Show Bid line
      ChartSetInteger(0, CHART_SHOW_ASK_LINE,true);               //Show Ask Line
      ChartSetInteger(0, CHART_SHOW_LAST_LINE, true);             //Show Last Line
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);           //Hide period separator
      ChartSetInteger(0, CHART_SHOW_GRID, false);                 //Do not show the grid
      ChartSetInteger(0,CHART_SHOW_TRADE_LEVELS,true);            //Show Trade Levels
      ChartSetInteger(0, CHART_FOREGROUND, false);                //Enabled candles to be under indicactors

      //Others
      ChartSetInteger(0, CHART_SCALE, 3);                         //Candle width
     }


//Color on Black
   if(SelectedTheme==3)
     {
      //Arrow colors
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrLightBlue);        //Buy arrow color
      PlotIndexSetInteger(1,PLOT_LINE_COLOR,clrRed);              //Sell arrow color

      //Chart colors settings
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);       //Background color
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);       //Foreground color
      ChartSetInteger(0, CHART_COLOR_GRID, clrLightSlateGray);    //Choose back color for grid lines
      ChartSetInteger(0, CHART_COLOR_CHART_UP, clrLimeGreen);     //Bar up  color
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrRed);         //Bar down  color
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrLimeGreen);  //Bull candle color
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrRed);        //Bear candle color
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrLime);        //ChartLine color
      ChartSetInteger(0, CHART_COLOR_VOLUME,clrLimeGreen);        //Volumes color
      ChartSetInteger(0, CHART_COLOR_BID, clrLightSlateGray);     //Color of the bid line
      ChartSetInteger(0, CHART_COLOR_ASK, clrRed);                //Ask line color
      ChartSetInteger(0, CHART_COLOR_LAST, C'0,192,0');           //Last line color
      ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrRed);         //Stop Level color

      //chart show
      ChartSetInteger(0, CHART_SHOW_TICKER, true);                //Show ticker
      ChartSetInteger(0, CHART_SHOW_OHLC, true);                  //Show OHLC
      ChartSetInteger(0, CHART_SHOW_ONE_CLICK, true);             //Show Quick trading buttons
      ChartSetInteger(0, CHART_SHOW_BID_LINE, true);              //Show Bid line
      ChartSetInteger(0, CHART_SHOW_ASK_LINE,true);               //Show Ask Line
      ChartSetInteger(0, CHART_SHOW_LAST_LINE, true);             //Show Last Line
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);           //Hide period separator
      ChartSetInteger(0, CHART_SHOW_GRID, false);                 //Do not show the grid
      ChartSetInteger(0,CHART_SHOW_TRADE_LEVELS,true);            //Show Trade Levels
      ChartSetInteger(0, CHART_FOREGROUND, false);                //Enabled candles to be under indicactors

      //Others
      ChartSetInteger(0, CHART_SCALE, 3);                         //Candle width
     }




//ColorOnWhite Them is selected
   if(SelectedTheme == 4)
     {
      //Arrow colors
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrBlue);        //Buy arrow color
      PlotIndexSetInteger(1,PLOT_LINE_COLOR,clrBlack);              //Sell arrow color

      //Chart colors settings
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);       //Background color
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrBlack);       //Foreground color
      ChartSetInteger(0, CHART_COLOR_GRID, C'241,236,242');       //Choose back color for grid lines
      ChartSetInteger(0, CHART_COLOR_CHART_UP, C'38,166,154');    //Bar up  color
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, C'239,83,80');   //Bar down  color
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, C'38,166,154'); //Bull candle color
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, C'239,83,80');  //Bear candle color
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, C'86,186,132');  //ChartLine color
      ChartSetInteger(0, CHART_COLOR_VOLUME,C'38,166,154');       //Volumes color
      ChartSetInteger(0, CHART_COLOR_BID, C'38,166,154');         //Color of the bid line
      ChartSetInteger(0, CHART_COLOR_ASK, C'239,83,80');          //Ask line color
      ChartSetInteger(0, CHART_COLOR_LAST, C'156,186,240');       //Last line color
      ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, C'239,83,80');   //Stop Level color

      //chart show
      ChartSetInteger(0, CHART_SHOW_TICKER, true);                //Show ticker
      ChartSetInteger(0, CHART_SHOW_OHLC, true);                  //Show OHLC
      ChartSetInteger(0, CHART_SHOW_ONE_CLICK, true);             //Show Quick trading buttons
      ChartSetInteger(0, CHART_SHOW_BID_LINE, true);              //Show Bid line
      ChartSetInteger(0, CHART_SHOW_ASK_LINE,true);               //Show Ask Line
      ChartSetInteger(0, CHART_SHOW_LAST_LINE, true);             //Show Last Line
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);           //Hide period separator
      ChartSetInteger(0, CHART_SHOW_GRID, false);                 //Do not show the grid
      ChartSetInteger(0,CHART_SHOW_TRADE_LEVELS,true);            //Show Trade Levels
      ChartSetInteger(0, CHART_FOREGROUND, false);                //Enabled candles to be under indicactors

      //Others
      ChartSetInteger(0, CHART_SCALE, 3);                         //Candle width
     }

  }





//+------------------------------------------------------------------+
//|MDB_Bands onDeinit function                                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(reason == REASON_PARAMETERS ||
// reason == REASON_RECOMPILE ||
      reason == REASON_ACCOUNT)
     {
      checked = false;
     }


//--- delete the indicator
   int total = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
   for(int subwin = total - 1; subwin >= 0; subwin--)
     {
      int amount = ChartIndicatorsTotal(0, subwin);
      for(int i = amount - 1; i >= 0; i--)
        {
         string name = ChartIndicatorName(0, subwin, i);

         //--find and delete MACD from the charts upon exit
         if(StringFind(name, "MACD", 0) == 0)
           {
            ChartIndicatorDelete(0, subwin, name);
           }

         //--find and delete Bollinger Bands from the charts upon exit
         if(StringFind(name, "Bands", 0) == 0)
           {
            ChartIndicatorDelete(0, subwin, name);
           }
        }
     }
   Comment(""); //Dellete all comments on chart, on removing the indicator
  }




//+------------------------------------------------------------------+
//| MDB_Bands OnCalculate function                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

//*******************************************************************************
//Tanzania trade logic Signal sending section
//*******************************************************************************
//--- Alert frequency control system
   MqlRates priceData[];                           // create price array
   ArraySetAsSeries(priceData, true);              //sort the array from current candle downwards
   CopyRates(_Symbol, _Period, 0, 5, priceData);   //copy candle prices for 5 candles into array
   static datetime timeStampLastCheck;             //Create Date time variable for the last time Stamp
   datetime timeStampCurrentCandle;                //Create datetime variable for current candle
   timeStampCurrentCandle = priceData[0].time;     //read time stamp for current candle in array

//--- STAMPS
//signal time
   datetime SignalTime = TimeTradeServer();

//Code to determine trade targets automatically
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);



//--- IS STOPPED FLAG
   if(IsStopped())
      return(0);                 //Must respect the stop flag
   if(rates_total < MaxPeriod)
      return(0);                 //check that we have enough bars to calculate


//--- CHECK IF HANDLES ARE LOADED CORRECTLY
//on main chart
   if(BarsCalculated(mBandsHandle) < rates_total)
      return(0);  //not calculated

//on window 1
   if(BarsCalculated(macdHandle) < rates_total)
      return(0);  //not calculated

   if(BarsCalculated(oBandsHandle) < rates_total)
      return(0);  //not calculated




//--- COPYING INDICATOR DATA
   int copyBars = 0;             //copying new bars
   int startBar = 0;             //this line copy data for gap creation purpose.
   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      copyBars = rates_total;
      startBar = MaxPeriod; //this line for handling gaps
     }
   else
     {
      copyBars = rates_total - prev_calculated;
      if(prev_calculated > 0)
         copyBars++;
      startBar = prev_calculated - 1; //This line for handling gaps
     }
//error checking.
   if(IsStopped())
      return(0);   //respect the stop flag


//-- Copying Handles to the buffers
//on main
   if(CopyBuffer(mBandsHandle, 0, 0, copyBars, mMiddleBB) <= 0)
      return(0);
   if(CopyBuffer(mBandsHandle,1, 0, copyBars, mUpperBB) <= 0)
      return(0);
   if(CopyBuffer(mBandsHandle, 2, 0, copyBars, mLowerBB) <= 0)
      return(0);


//on window 1
//MACD data copy
   if(CopyBuffer(macdHandle, 0, 0, copyBars, main) <= 0)
      return(0);
   if(CopyBuffer(macdHandle, 1, 0, copyBars, Signal) <= 0)
      return(0);

//Oscilator Bands Data copy
   if(CopyBuffer(oBandsHandle, 0, 0, copyBars, oMiddleBB) <= 0)
      return(0);
   if(CopyBuffer(oBandsHandle,1, 0, copyBars, oUpperBB) <= 0)
      return(0);
   if(CopyBuffer(oBandsHandle, 2, 0, copyBars, oLowerBB) <= 0)
      return(0);



//--- CODE TO GET ARROW PRINTED
//Error checking.
   if(IsStopped())
      return(0);   //respect the stop flag

//--- Loop for determining where to place the predetermined arrow
   for(int i = startBar; i < rates_total && !IsStopped(); i++)
     {
      //--- Arrow findinng and strategies codes
      ArrowBuy[i] = EMPTY_VALUE; //lines added to control the arrows
      ArrowSell[i] = EMPTY_VALUE;
      if(i > 0)
        {

         // here we can populate all strategies we fill can work with this set of indicators
         //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
         //ExtremeEntry
         //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
         if(SelectedStrategy==1)
           {
            //+++++++++++++
            //Buy section
            //+++++++++++++
            if(
               low[i-1]<mLowerBB[i-1]
               && close[i-1]-open[i-1]<0
               && main[i-1]>oLowerBB[i-1]
               
               && main[i-1]<0
               && oMiddleBB[i-1]>0
               && Signal[i-1]>0
            )
              {
               ArrowBuy[i-1] = low[i-1];
               if(timeStampCurrentCandle != timeStampLastCheck)
                 {
                  timeStampLastCheck = timeStampCurrentCandle;
                  if(
                     PushNotification
                  )
                    {
                     SendNotification(
                        "BUY : " + _Symbol + ":ExtremeEntry" +
                        "\nTime Frame :" + StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7) +
                        "\nEntry Price :" + DoubleToString(Ask, _Digits) +
                        "\nTime :" + TimeToString(SignalTime) +
                        "\nJoin our Telegram Channel: " + "https://t.me/Tz_Fx_Lab "
                     );
                    }
                  if(
                     WindowsAlert)
                    {
                     Alert(
                        "BUY : " + _Symbol + ":ExtremeEntry " +
                        "\nTime Frame :" + StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7) +
                        "\nEntry Price :" + DoubleToString(Ask, _Digits) +
                        "\nTime :" + TimeToString(SignalTime) +
                        "\nJoin our Telegram Channel: " + "https://t.me/Tz_Fx_Lab "
                     );
                    }
                  if(SoundNotification)
                    {
                     PlaySound("wait.wav");
                    }
                 }
              }




            //+++++++++++++
            //Sell section
            //+++++++++++++
            if(
               high[i-1]>mUpperBB[i-1]
               && close[i-1]-open[i-1]>0
               && main[i-1]<oUpperBB[i-1]
               
               && main[i-1]>0
               && oMiddleBB[i-1]<0
               && Signal[i-1]<0
            )
              {
               ArrowSell[i-1] = high[i-1];
               if(timeStampCurrentCandle != timeStampLastCheck)
                 {
                  timeStampLastCheck = timeStampCurrentCandle;
                  if(
                     PushNotification
                  )
                    {
                     SendNotification(
                        "SELL : " + _Symbol + ":ExtremeEntry" +
                        "\nTime Frame :" + StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7) +
                        "\nEntry Price :" + DoubleToString(Bid, _Digits) +
                        "\nTime :" + TimeToString(SignalTime) +
                        "\nPlease support Us: " + "https://www.patreon.com/TzFxLab "
                     );
                    }
                  if(
                     WindowsAlert)
                    {
                     Alert(
                        "SELL : " + _Symbol + ":ExtremeEntry " +
                        "\nTime Frame :" + StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7) +
                        "\nEntry Price :" + DoubleToString(Bid, _Digits) +
                        "\nTime :" + TimeToString(SignalTime) +
                        "\nPlease Support Us: " + "https://www.patreon.com/TzFxLab "
                     );
                    }
                  if(SoundNotification)
                    {
                     PlaySound("wait.wav");
                    }
                 }
              }
           } //---- End of ExtremeEntry strategy


        }//---- End of arrow checking code
     }//---- End of loop which determines where to place the arrow


//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
