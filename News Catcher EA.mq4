//+------------------------------------------------------------------+
//|   		this is my forex robot									 |
//|					 By Oleg Petrov 								 |
//|							oleg518@mail.ru 						 |
//+------------------------------------------------------------------+
#property strict
//--------------------------------------------------------------------
extern string o1="  ---------- Trailing --------------     ";
extern int     Dist=200;   //Distance of pending order from the price
extern int     TrailingStop         = 40;     //Trailing distance (0 - without trailing)
extern int     TSz                  = 10;     //Trailing step
extern int     tttimer=100;     //Trailing by timer (ms), 0 - trailing without timer

extern string o2="  ---------- Pending orders ----------     ";
extern int     Stoploss=50;     //Stoploss, 0 - without stoploss
extern int     TimeModify=1;     // Interval of shifting pending orders, s
extern int     Kor=50;     //"Calm corridor", 0 - without

extern string o3="  ---------- Time ----------     ";
extern datetime timeStart=D'15:29:50'; // Start (place pendings)
extern datetime timeFinish=0; // Finish (delete pendings) (not necessary, 2 min)

extern string o4="  ---------- Other ---------------------     ";
extern bool  tester=false;  // Pendings now and permanent
extern double Lot=0.01;  // Lot
extern bool show_spread=true;  // Show spread


int tryings_place=5; // кол-во попыток подряд
int tryings_mod=5;
int tryings_del=10;
int tryings_tral=10;

int tryings_place_i_b=1,tryings_mod_i_b=1,tryings_place_i_s=1,tryings_mod_i_s=1,tryings_del_i=1,tryings_tral_i=1;

uint timenew_place=2; // время новой серии попыток, сек
uint timenew_mod=10;
uint timenew_del=10;
uint timenew_tral=10;

uint timenew_place_t_b,timenew_mod_t_b,timenew_place_t_s,timenew_mod_t_s,timenew_del_t,timenew_tral_t;

int series_place=3; // кол-во серий попыток подряд
int series_mod=3;
int series_del=3;
int series_tral=3;

int series_place_i_b=1,series_mod_i_b=1,series_place_i_s=1,series_mod_i_s=1,series_del_i=1,series_tral_i=1;


bool deal_opened=false;
bool error;
bool local_time_corrected=false;
bool need_move_B=false,need_move_S=false,need_move_R=false;
bool old_start_time=false;
bool pending_closed=false;
bool pending_b_placed=false,pending_s_placed=false;
bool print_stats=false;
bool stats_empty=true,stats_empty_written=false;
bool stats_printed=false;
color color_profit,color_rivok;
color TLclr=Lime;
datetime time5sec=TimeLocal();
datetime TTouched;
double currentspread,maxspread=0;
double K1,K2;
double lastOOP,lastOOP_S,lastOOP_B;
double Minute_cur=round(TimeCurrent()/60)*60;
double order_close_slippage_int;
double order_open_slippage_int;
double order_profit_dbl;
double order_profit_p_int;
double OSL,OOP,SL;
double rivok0,rivok;
double SL0=0;
double Spread=MarketInfo(Symbol(),MODE_SPREAD)*Point;
double STOPLEVEL;
double TSsum=0;
int sign_order=0;
int slippage=250;
int oi=2,oi1=2;
int ototal=0;
int otstup_level,otstup_level1;
int otstup_level_error=300;
int otstup_right=5;
int otstup_up=30,otstup_up1=16;;
int otstup_up0=24,otstup_up01=30;
int font_size=14,font_size1=10,font_size_text_=16;
int i=0;
int OT;
int otst=1;
int sign_slip;
int str_pos=0;
int tick_count=0;
int ticketN=0;
int ttimer;
long chart_ID=ChartID();
long time_otst;
long time_left,secs_left,mins_left,hours_left,days_left,mnths_left,yrs_left;
string currentspread_text="currentspread_text";
string hor_line_1="hor_line_1";
string hor_line_2="hor_line_2";
string order_close_slippage="order_close_slippage";
string order_open_slippage="order_open_slippage";
string order_profit_p="order_profit_p";
string order_profit="order_profit";
string Rect1="Rect1";
string server_time="server_time";
string symb=Symbol();
string time_curr="time_curr";
string time_left_str,time_gone_str;
string time_left_hms;
string time_left_str_text="time_left_str_text";
string TimeFinishEv="TimeFinishEv";
string TimeStartEv="TimeStartEv";
string vert_line_curr="vert_line_curr";
string vert_line_finish="vert_line_finish";
string vert_line_start="vert_line_start";
uint tral_start,otladka_start;
////////////////////////////+------------------------------------------------------------------+
////////////////////////////|                   НАЧАЛО ИНИЦИАЛИЗАЦИИ                           |
////////////////////////////+------------------------------------------------------------------+
int OnInit()
  {
   Print("============= Initializing EA ================");
   Print("PC time (TimeLocal) = ",TimeLocal());
   Print("Server time (TimeCurrent) = ",TimeCurrent());
   Print("Symbol ",symb);
   Print("Spread = ",(int)round(Spread/Point));
   if(tester)
     {
      timeStart=TimeCurrent()+5;         // для тестинга
      timeFinish=TimeCurrent()+24*60*60;
     }

   if(tttimer==0) ttimer=1000; else ttimer=tttimer;
   EventSetMillisecondTimer(ttimer);

   if(timeFinish<timeStart) timeFinish=timeStart+2*60;
   Print("Leverage = 1:",AccountLeverage());
   int stoplevel=(int)round(MarketInfo(symb,MODE_STOPLEVEL));
   Print("STOPLEVEL = ",stoplevel);
   Print("The amount of free funds required to open 1 lot order (MODE_MARGINREQUIRED) = ",MarketInfo(symb,MODE_MARGINREQUIRED));
   double need_money=MarketInfo(symb,MODE_MARGINREQUIRED)*Lot;
   Print("The amount of free funds required for order opening ",Lot," of lot (MODE_MARGINREQUIRED) = ",need_money);
   Print("Lot for trade in full balance = ",NormalizeDouble(AccountBalance()/MarketInfo(symb,MODE_MARGINREQUIRED),2));
//   Print("Торговля разрешена? MODE_TRADEALLOWED = ",(int)round(MarketInfo(symb,MODE_TRADEALLOWED)));

   Minute_cur=round(TimeCurrent()/60)*60;

   create_event(TimeStartEv,timeStart,Black);
   create_event(TimeFinishEv,timeFinish,Black);
   create_event(time_curr,TimeCurrent(),MidnightBlue);
   create_v_line(vert_line_start,timeStart,Blue,STYLE_DOT);
   create_v_line(vert_line_finish,timeFinish,Blue,STYLE_DOT);
   create_h_line(hor_line_1,Ask+Dist*Point,DarkSlateGray,STYLE_DASH);
   create_h_line(hor_line_2,Bid-Dist*Point,DarkSlateGray,STYLE_DASH);

   K1=Ask+Kor*Point;
   K2=Bid-Kor*Point;
   create_rect(Rect1,TimeCurrent()+60*5,K1,TimeCurrent()-60*5,K2,MidnightBlue);

   oi=oi-2;
   oi1=oi1-2;
   create_text(server_time,"",White);
   create_text(time_left_str_text,TimeLeftCount(),Lime);
   if(show_spread) create_text(currentspread_text,StringConcatenate(NormalizeDouble(round((Ask-Bid)/Point),0)),White);

   if(Spread>=Stoploss*Point && !Spread==0)
     {
      int oldSLch=Stoploss;
      Stoploss=(int)round(Spread*1.25/Point);
      Print("  !  Старый СЛ = ",oldSLch,"  изменен на ",Stoploss);
     }

/*   if(stoplevel>TrailingStop)
     {
      int oldTrailingStop=TrailingStop;
      TrailingStop=stoplevel+1;
      Print("  !  Старый ТС = ",oldTrailingStop,"  изменен на ",TrailingStop);
     }

   if(stoplevel>Dist)
     {
      int oldDist=Dist;
      Dist=stoplevel+1;
      Print("  !  Старая Dist = ",oldDist,"  изменен на ",Dist);
     }*/

   create_text1("sov_pars1",StringConcatenate("Dist=",Dist,", TS=",TrailingStop,"+",TSz,", SL=",Stoploss,", TM=",TimeModify,"s, Kor=",Kor,", Lot=",Lot),DarkGray);
   create_text1("sov_pars2",StringConcatenate("Begin ",timeStart,", Finish ",timeFinish,""),DarkGray);

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) create_text_error("trade_not_allowed","Autotrading is OFF",White);
   if(MarketInfo(symb,MODE_MARGINREQUIRED)*Lot>AccountBalance())
     {
      create_text_error("not_enough_money1",StringConcatenate("Not enough money (need ",need_money-AccountBalance(), " more funds)"),White);
      //otstup_level_error=otstup_level_error+10;
      //create_text_error("not_enough_money2",StringConcatenate("Нужно ",need_money, " руб., а баланс ",AccountBalance()," руб."),White);
     }

   Print("timeStart = ",timeStart);
   Print("timeFinish = ",timeFinish);


   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   Print("if(tester) CloseSel(-1);");
   if(tester) CloseSel(-1);
  }
////////////////////////////+------------------------------------------------------------------+
////////////////////////////|                    КОНЕЦ ИНИЦИАЛИЗАЦИИ                           |
////////////////////////////+------------------------------------------------------------------+




////////////////////////////+------------------------------------------------------------------+
////////////////////////////|                    НАЧАЛО ТИКА                                   |
////////////////////////////+------------------------------------------------------------------+

void OnTick()
  {
   if((TimeCurrent()>timeStart && TimeCurrent()<timeFinish))
     {
      STOPLEVEL=MarketInfo(symb,MODE_STOPLEVEL);
      OSL=0;

      OOP=0;
      SL=0;

      if(need_move_R)
        {
         need_move_B=true;
         need_move_S=true;
        }
      if(OrdersTotal()>0) ototal=OrdersTotal();

      //+------------------------------------------------------------------+
      //|                     ТРАЛ                                         |
      //+------------------------------------------------------------------+

      for(i=0; i<OrdersTotal(); i++)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderSymbol()==symb)
              {
               TRAILING("TICK");

               //+------------------------------------------------------------------+
               //|                     ПЕРЕДВИЖКА ОТЛОЖЕК                           |
               //+------------------------------------------------------------------+


               if(!deal_opened)

                 {

                  if((TimeCurrent()>TTouched+TimeModify) && (need_move_B || need_move_S))

                    {
                     if(OT==OP_BUYSTOP)
                       {
                        if(Stoploss>=STOPLEVEL && Stoploss!=0) SL=NormalizeDouble(Ask+(Dist-Stoploss)*Point,Digits); else SL=0;
                        if(need_move_B)
                          {
                           otladka_start=GetTickCount();

                           if(GetTickCount()>timenew_mod_t_b+timenew_mod*1000 && series_mod_i_b<=series_mod)
                             {

                              if(OrderModify(OrderTicket(),NormalizeDouble(Ask+Dist*Point,Digits),SL,0,0,CLR_NONE))
                                {
                                 tryings_mod_i_b=1;
                                 series_mod_i_b=1;
                                 timenew_mod_t_b=0;
                                 Print("Buy stop moved on ",Ask+Dist*Point," in ",GetTickCount()-otladka_start," ms");
                                 lastOOP_B=NormalizeDouble(Ask+Dist*Point,Digits);
                                 need_move_B=false;
                                 MoveRect();
                                }
                              else
                                {
                                 Print("Fail moving Buy stop. Error=",GetLastError(),". Attemp number = ",tryings_mod_i_b,"/",tryings_mod," , Series of attempts = ",series_mod_i_b,"/",series_mod);
                                 tryings_mod_i_b++;
                                 if(tryings_mod_i_b>=tryings_mod)
                                   {
                                    timenew_mod_t_b=GetTickCount();
                                    series_mod_i_b++;
                                    tryings_mod_i_b=1;
                                    Print("Beginning new series of attempts № ",series_mod_i_b," of moving Buy stop");
                                   }
                                }

                              if(!(GetTickCount()>timenew_mod_t_b+timenew_mod*1000)) Print("Waiting for new series of attempts of moving Buy stop...");
                              if(!(series_mod_i_b<=series_mod)) Print("Attempts to moving Buy stop are completed by reaching a series of attempts № ",series_mod_i_b);

                             }


                          }
                       }

                     if(OT==OP_SELLSTOP)
                       {
                        if(Stoploss>=STOPLEVEL && Stoploss!=0) SL=NormalizeDouble(Bid-(Dist-Stoploss)*Point,Digits); else SL=0;
                        if(need_move_S)
                          {
                           otladka_start=GetTickCount();


                           if(GetTickCount()>timenew_mod_t_s+timenew_mod*1000 && series_mod_i_s<=series_mod)
                             {

                              if(OrderModify(OrderTicket(),NormalizeDouble(Bid-Dist*Point,Digits),SL,0,0,CLR_NONE))
                                {
                                 tryings_mod_i_s=1;
                                 series_mod_i_s=1;
                                 timenew_mod_t_s=0;
                                 Print("Sell stop moved on ",Bid-Dist*Point," in ",GetTickCount()-otladka_start," ms");
                                 lastOOP_S=NormalizeDouble(Bid-Dist*Point,Digits);
                                 need_move_S=false;
                                 MoveRect();
                                }
                              else
                                {
                                 Print("Fail moving Sell stop. Error=",GetLastError(),". Attemp number = ",tryings_mod_i_s,"/",tryings_mod," , Series of attempts = ",series_mod_i_s,"/",series_mod);
                                 tryings_mod_i_s++;
                                 if(tryings_mod_i_s>=tryings_mod)
                                   {
                                    timenew_mod_t_s=GetTickCount();
                                    series_mod_i_s++;
                                    tryings_mod_i_s=1;
                                    Print("Beginning new series of attempts № ",series_mod_i_s," of moving Sell stop");
                                   }
                                }
                              if(!(GetTickCount()>timenew_mod_t_s+timenew_mod*1000)) Print("Waiting for new series of attempts of moving Sell stop...");
                              if(!(series_mod_i_s<=series_mod)) Print("Attempts to moving Buy stop are completed by reaching a series of attempts № ",series_mod_i_b);
                             }




                          }
                       }

                    }

                 }

              }
           }
        }

      //+------------------------------------------------------------------+
      //|   ОТКРЫТИЕ ОРДЕРА БС/СС, ЕСЛИ ТАКИХ НЕТУ НА ДАННЫЙ МОМЕНТ        |
      //+------------------------------------------------------------------+


      if(!(pending_b_placed && pending_b_placed) && TimeCurrent()>=timeStart && TimeCurrent()<timeFinish) place_pendings("ТИК");

      count_maxspread();
     }

   if(!deal_opened)
     {

      if(TimeCurrent()<timeFinish)
        {

         if(TimeCurrent()-60>Minute_cur)
           {
            error=(ObjectMove(chart_ID,Rect1,0,TimeCurrent()+5*60,K1) && ObjectMove(chart_ID,Rect1,1,TimeCurrent()-5*60,K2));
            error=ObjectMove(chart_ID,time_curr,0,TimeCurrent(),0);
            Minute_cur=round(TimeCurrent()/60)*60;
           }

         if(Ask>K1 || Bid<K2)
           {
            if(!need_move_R)
              {
               need_move_R=true;
               TTouched=TimeCurrent();
              }
           }

         if((TimeCurrent()>TTouched+TimeModify) && (need_move_R))
           {

            if(TimeCurrent()<timeStart)
              {
               MoveRect();
               error=ObjectMove(chart_ID,hor_line_1,0,0,Ask+Dist*Point);
               error=ObjectMove(chart_ID,hor_line_2,0,0,Bid-Dist*Point);
              }

            need_move_R=false;

           }

        }

     }

   if(!local_time_corrected)
     {
      if(TimeLocal()>TimeCurrent()) otst=-1;
      time_otst=otst*(TimeCurrent()-TimeLocal());
      string speshat;
      if(otst==-1) speshat="rushes"; else speshat="is behind";
      Print("PC time ",speshat," for ",time_otst," sec");
      local_time_corrected=true;
     }

//if(print_stats && OrdersTotal()==0) if_ended_text_stats();

// if (deal_opened && tick_count<20) tick_count++;

   if(TimeCurrent()>=timeFinish)
     {
      //Print("if(TimeCurrent() ",TimeCurrent(), ">=timeFinish ",timeFinish,")");
      CloseSel(-1);
     }

   if(show_spread) ObjectSetString(chart_ID,currentspread_text,OBJPROP_TEXT,StringConcatenate(NormalizeDouble(round((Ask-Bid)/Point),0)));
  }
////////////////////////////+------------------------------------------------------------------+
////////////////////////////|                     КОНЕЦ ТИКА                                   |
////////////////////////////+------------------------------------------------------------------+




////////////////////////////+------------------------------------------------------------------+
////////////////////////////|                    НАЧАЛО ТАЙМЕРА                                |
////////////////////////////+------------------------------------------------------------------+


void OnTimer()
  {

   if(tttimer>0 && (TimeCurrent()>timeStart && TimeCurrent()<timeFinish))
     {
      STOPLEVEL=MarketInfo(symb,MODE_STOPLEVEL);
      OSL=0;
      OOP=0;
      SL=0;

      if(OrdersTotal()>0) ototal=OrdersTotal();

      for(i=0; i<OrdersTotal(); i++)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderSymbol()==symb)
              {

               TRAILING("Timer");

              }
           }
        }
      count_maxspread();
     }

   if(!(pending_b_placed && pending_b_placed) && TimeLocal()+otst*time_otst>=timeStart && TimeCurrent()<timeFinish) place_pendings("Timer");

   if(TimeLocal()>time5sec+5 && print_stats && !stats_printed)
     {
      Print("Print stats...");
      time5sec=TimeLocal();
      if_ended_text_stats();
     }

   if(TimeCurrent()>timeFinish && stats_empty && !stats_empty_written)
     {
      if(ototal>0) create_text("stats_empty1",StringConcatenate("Time passed, placed pendings did not open"),White);
      if(ototal==0) create_text("stats_empty1",StringConcatenate("Time passed, pendings did not place"),White);
      create_text("stats_empty2",StringConcatenate(timeStart," - ",timeFinish),White);
      stats_empty_written=true;
     }

   ObjectSetString(chart_ID,time_left_str_text,OBJPROP_TEXT,TimeLeftCount());
   ObjectSetInteger(chart_ID,time_left_str_text,OBJPROP_COLOR,TLclr);
   ObjectSetString(chart_ID,server_time,OBJPROP_TEXT,TimeToString(TimeLocal()+otst*time_otst,TIME_SECONDS));

   if(show_spread) ObjectSetString(chart_ID,currentspread_text,OBJPROP_TEXT,StringConcatenate(NormalizeDouble(round((Ask-Bid)/Point),0)));

   if((pending_b_placed || pending_s_placed) && ObjectFind(0,time_left_str_text)!=-1)
     {
      error=ObjectDelete(chart_ID,time_left_str_text);
     }

  }
////////////////////////////+------------------------------------------------------------------+
////////////////////////////|                    КОНЕЦ ТАЙМЕРА                                 |
////////////////////////////+------------------------------------------------------------------+




////////////////////////////+------------------------------------------------------------------+
////////////////////////////|                     ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (начало)             |
////////////////////////////+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                     CloseSel и CloseSeli                         |
//+------------------------------------------------------------------+


void CloseSel(int orderN) // <0 - значит закрыть все
  {
   for(i=0; i<OrdersTotal(); i++)
     {

      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && !(i==orderN))
        {
         if(OrderSymbol()==symb)
           {
            if(OrderType()==OP_BUY)  error=OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), slippage, CLR_NONE);
            if(OrderType()==OP_SELL) error=OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), slippage, CLR_NONE);
            if(OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP || OrderType()==OP_SELLLIMIT || OrderType()==OP_SELLSTOP)
              {
               otladka_start=GetTickCount();
               if(OrderDelete(OrderTicket()))
                 {
                  tryings_del_i=1;
                  series_del_i=1;
                  timenew_del_t=0;
                  Print("Pending № ",OrderTicket()," delete in ",GetTickCount()-otladka_start," мс");
                 }
               else
                 {
                  Print("Failure to close the pending. Error=",GetLastError(),". Attempt number = ",tryings_del_i,"/",tryings_del," , series = ",series_del_i,"/",series_del);
                  tryings_del_i++;
                  if(tryings_del_i>=tryings_del)
                    {
                     timenew_del_t=GetTickCount();
                     series_del_i++;
                     tryings_del_i=1;
                     Print("Beginning of new series of attempts № ",series_del_i," to close the order");
                    }
                 }

               if(!(GetTickCount()>timenew_del_t+timenew_del*1000)) Print("Waiting for new series of attempts to close the pending...");
               if(!(series_del_i<=series_del)) Print("Attempts to close the pending are completed by reaching a series of attempts № ",series_del_i);



              }
           }
        }
     }
   if(ObjectFind(0,Rect1)!=-1) error=ObjectDelete(chart_ID,Rect1);
   if(ObjectFind(0,time_left_str_text)!=-1 && orderN==-1) error=ObjectDelete(chart_ID,time_left_str_text);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseSeli()
  {
   if(!pending_closed)
     {
      Print("Closing the remaining pending...");
      CloseSel(i); // if (tick_count>2)  закрыть все кроме этого ордера
                   //Print("Отложка закрыта");
      pending_closed=true;
     }
  }
//+------------------------------------------------------------------+
//|                       TRAILING                                   |
//+------------------------------------------------------------------+
void TRAILING(string tick_or_timer_str)
  {

   OT=OrderType();
   OSL = OrderStopLoss();
   OOP = OrderOpenPrice();

   if(OT==OP_BUY) sign_order=1;
   if(OT==OP_SELL) sign_order=-1;

   ticketN=OrderTicket();
   SL=OSL;

   if(OT==OP_BUY || OT==OP_SELL)
     {
      deal_opened=true;
      if(OT==OP_BUY) SL=Bid-TrailingStop*Point; else SL=Ask+TrailingStop*Point;

      if(GetTickCount()>timenew_tral_t+timenew_tral*1000 && series_tral_i<=series_tral)
        {

         if(sign_order*(SL-OSL)>TSz*Point)
           {
            if(SL0==0) SL0=OSL;
            Print("Trailing...");
            tral_start=GetTickCount();

            if(OrderModify(ticketN,OOP,SL,0,0,0))
              {
               tryings_tral_i=1;
               series_tral_i=1;
               timenew_tral_t=0;
               TSsum=TSsum+sign_order*(SL-OSL);
               Print("SL moved by ",tick_or_timer_str," to ",(int)round(sign_order*(SL-OSL)/Point)," points , moving interval ",GetTickCount()-tral_start," ms");
              }
            else
              {
               Print("Trailing failure. Error=",GetLastError(),". Attempt number = ",tryings_tral_i,"/",tryings_tral," , series = ",series_tral_i,"/",series_tral);
               tryings_tral_i++;
               if(tryings_tral_i>=tryings_tral)
                 {
                  timenew_tral_t=GetTickCount();
                  series_tral_i++;
                  tryings_tral_i=1;
                  Print("Beginning of new series of attempts № ",series_tral_i," тралла ордера");
                 }
              }

            if(!(GetTickCount()>timenew_tral_t+timenew_tral*1000)) Print("Ждем новую серию попыток траллинга...");
            if(!(series_tral_i<=series_tral)) Print("Попытки траллинга закончены достижением серии попыток № ",series_tral_i);

           }

        }

      CloseSeli(); // возможно нужно перенести в момент открытия статистики
      if(!stats_printed) print_stats=true;
      time5sec=TimeLocal();
     }
  }
//+------------------------------------------------------------------+
//|                     MoveRect                                     |
//+------------------------------------------------------------------+



void MoveRect()
  {
   K1=Ask+Kor*Point;
   K2=Bid-Kor*Point;
   error=ObjectMove(chart_ID,Rect1,0,TimeCurrent()+5*60,K1) && ObjectMove(chart_ID,Rect1,1,TimeCurrent()-5*60,K2);
  }
//+------------------------------------------------------------------+
//|                     place_pendings                               |
///+------------------------------------------------------------------+


void place_pendings(string tick_or_timer_str)
  {
   STOPLEVEL=MarketInfo(symb,MODE_STOPLEVEL);
   SL=0;

   if(Stoploss>=STOPLEVEL && Stoploss!=0) SL=Ask+(Dist-Stoploss)*Point; else SL=0;

   otladka_start=GetTickCount();

   if(!pending_b_placed && GetTickCount()>timenew_place_t_b+timenew_place*1000 && series_place_i_b<=series_place)
     {

      if(OrderSend(symb,OP_BUYSTOP,Lot,Ask+Dist*Point,slippage,SL,0,"news",0,0,CLR_NONE))
        {
         tryings_place_i_b=1;
         series_place_i_b=1;
         timenew_place_t_b=0;
         Print("Buy stop выставлена по ",tick_or_timer_str,"У на уровень ",NormalizeDouble(Ask+Dist*Point,Digits)," за ",GetTickCount()-otladka_start," мс");
         lastOOP_B=Ask+Dist*Point;
         MoveRect();
         pending_b_placed=true;
        }
      else
        {
         Print("Ошибка выставления Buy stop. Код ошибки=",GetLastError(),". Номер попытки = ",tryings_place_i_b,"/",tryings_place," , серия = ",series_place_i_b,"/",series_place);
         tryings_place_i_b++;
         if(tryings_mod_i_b>=tryings_place)
           {
            timenew_place_t_b=GetTickCount();
            series_place_i_b++;
            tryings_place_i_b=1;
            Print("Начало новой серии попыток № ",series_place_i_b," выставления Buy stop");
           }
        }

      if(!(GetTickCount()>timenew_place_t_b+timenew_place*1000)) Print("Ждем новую серию попыток выставления Buy stop...");
      if(!(series_place_i_b<=series_place)) Print("Попытки выставления Buy stop закончены достижением серии попыток № ",series_place_i_b);

     }







   if(Stoploss>=STOPLEVEL && Stoploss!=0) SL=Bid-(Dist-Stoploss)*Point; else SL=0;
   otladka_start=GetTickCount();





   if(!pending_s_placed && GetTickCount()>timenew_place_t_s+timenew_place*1000 && series_place_i_s<=series_place)
     {
      if(OrderSend(symb,OP_SELLSTOP,Lot,Bid-Dist*Point,slippage,SL,0,"news",0,0,CLR_NONE))
        {
         tryings_place_i_s=1;
         series_place_i_s=1;
         timenew_place_t_s=0;
         Print("Sell stop выставлена ",tick_or_timer_str,"У на уровень ",NormalizeDouble(Bid-Dist*Point,Digits)," за ",GetTickCount()-otladka_start," мс");
         lastOOP_S=Bid-Dist*Point;
         MoveRect();
         pending_s_placed=true;
        }
      else
        {
         Print("Ошибка выставления Sell stop. Код ошибки=",GetLastError(),". Номер попытки = ",tryings_place_i_s,"/",tryings_place," , серия = ",series_place_i_s,"/",series_place);
         tryings_place_i_s++;
         if(tryings_mod_i_s>=tryings_place)
           {
            timenew_place_t_s=GetTickCount();
            series_place_i_s++;
            tryings_place_i_s++;
            Print("Начало новой серии попыток № ",series_place_i_s," выставления Sell stop");
           }
        }

      if(!(GetTickCount()>timenew_place_t_s+timenew_place*1000)) Print("Ждем новую серию попыток выставления Sell stop...");
      if(!(series_place_i_s<=series_place)) Print("Попытки выставления Sell stop закончены достижением серии попыток № ",series_place_i_s);


     }









   if(ObjectFind(0,hor_line_1)!=-1) error=ObjectDelete(chart_ID,hor_line_1);
   if(ObjectFind(0,hor_line_2)!=-1) error=ObjectDelete(chart_ID,hor_line_2);
//rivok0=(Ask+Bid)/2;

  }
//+------------------------------------------------------------------+
//|                     create_text (верхний)                        |
//+------------------------------------------------------------------+


void create_text(string name,string text,int clr)
  {
   otstup_level=otstup_up0+oi*otstup_up;

   ObjectCreate(chart_ID,name,OBJ_LABEL,0,0,0);

//--- установим способ привязки

   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);

//--- установим текст события

   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);

//--- установим цвет

   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);

//--- отобразим на переднем (false) или заднем (true) плане

   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);

//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов

   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);

//--- установим координаты метки

   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,otstup_right);

   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,otstup_level);

//--- установим угол графика, относительно которого будут определяться координаты точки

   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);

//--- установим шрифт текста

   ObjectSetString(chart_ID,name,OBJPROP_FONT,"Calibri");

//--- установим размер шрифта

   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   oi++;
  }
//+------------------------------------------------------------------+
//|                     create_text (нижний)                         |
//+------------------------------------------------------------------+


void create_text1(string name,string text,int clr)
  {
   otstup_level1=otstup_up01+oi1*otstup_up1;
   ObjectCreate(chart_ID,name,OBJ_LABEL,0,0,0);

//--- установим способ привязки

   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);

//--- установим текст события

   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);

//--- установим цвет

   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);

//--- отобразим на переднем (false) или заднем (true) плане

   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);

//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов

   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);

//--- установим координаты метки

   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,otstup_right);

   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,otstup_level1);

//--- установим угол графика, относительно которого будут определяться координаты точки

   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_RIGHT_LOWER);

//--- установим шрифт текста

   ObjectSetString(chart_ID,name,OBJPROP_FONT,"Calibri");

//--- установим размер шрифта

   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size1);
   oi1++;
  }
//+------------------------------------------------------------------+
//|                     create_text_error                            |
//+------------------------------------------------------------------+


void create_text_error(string name,string text,int clr)
  {
   otstup_level_error=otstup_level_error-60;
   ObjectCreate(chart_ID,name,OBJ_LABEL,0,0,0);

//--- установим способ привязки

   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);

//--- установим текст события

   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);

//--- установим цвет

   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);

//--- отобразим на переднем (false) или заднем (true) плане

   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);

//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов

   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);

//--- установим координаты метки

   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,50);

   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,otstup_level_error);

//--- установим угол графика, относительно которого будут определяться координаты точки

   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_RIGHT_LOWER);

//--- установим шрифт текста

   ObjectSetString(chart_ID,name,OBJPROP_FONT,"Calibri");

//--- установим размер шрифта

   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,28);
   oi1++;
  }
//+------------------------------------------------------------------+
//|     string TimeLeftCount (строка с оставшимся временем)          |
//+------------------------------------------------------------------+


string TimeLeftCount()
  {
   time_left=timeStart-(TimeLocal()+otst*time_otst);

   days_left=time_left/(24*60*60);
   hours_left=(time_left/(60*60))-days_left*24;
   mins_left=(time_left/60)-days_left*24*60-hours_left*60;
   secs_left=time_left-days_left*24*60*60-hours_left*60*60-mins_left*60;


   if(time_left<60) TLclr=Yellow; else TLclr=Lime;

   if(time_left/(24*60*60)>=1) time_left_str=StringConcatenate("Pendings ",days_left," days ",hours_left," h ",mins_left," min ",secs_left);
   if(time_left/(60*60)>=1 && time_left/(24*60*60)<1) time_left_str=StringConcatenate("Pendings ",hours_left," h ",mins_left," min ",secs_left);
   if(time_left/60>=1 && time_left/(60*60)<1) time_left_str=StringConcatenate("Pendings ",mins_left," min ",secs_left);
   if(time_left/60<1) time_left_str=StringConcatenate("Pendings ",secs_left);

//StringReplace(time_left_strstr,".0","");
   return time_left_str;
  }
//+------------------------------------------------------------------+
//|                        count_maxspread                           |
//+------------------------------------------------------------------+


void count_maxspread()
  {
   if(show_spread)
     {
      currentspread=(Ask-Bid)/Point;
      if(currentspread>maxspread) maxspread=currentspread;
     }
  }
//+------------------------------------------------------------------+
//|                    if_ended_text_stats                           |
//+------------------------------------------------------------------+


void if_ended_text_stats()
  {
   if(!stats_printed)
     {
      // CloseSeli();
      for(i=0; i<OrdersHistoryTotal(); i++)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
           {
            if(OrderOpenTime()>timeStart)
              {
               if(OrderType()==OP_BUY || OrderType()==OP_SELL)
                 {
                  if(OrderSymbol()==symb)
                    {
                     stats_empty=false;
                     create_text("order_history_ticket",StringConcatenate("Order ",OrderTicket()),DodgerBlue);

                     if(OrderType()==OP_BUY)
                       {
                        lastOOP=lastOOP_B;
                        sign_slip=1;
                        create_text("pokupka",StringConcatenate("Buy ",OrderLots()," lot"),DodgerBlue);
                       }

                     if(OrderType()==OP_SELL)
                       {
                        lastOOP=lastOOP_S;
                        sign_slip=-1;
                        create_text("prodazha",StringConcatenate("Sell ",OrderLots()," lot"),DodgerBlue);
                       }

                     datetime hOOT=OrderOpenTime(),hOCT=OrderCloseTime();

                     create_text("order_time_open",StringConcatenate("Open at ",TimeToStr(hOOT,TIME_SECONDS)),DodgerBlue);
                     create_text("order_time_close",StringConcatenate("Close at ",TimeToStr(hOCT,TIME_SECONDS)),DodgerBlue);

                     order_open_slippage_int=round(sign_slip*(OrderOpenPrice()-lastOOP)/Point);
                     create_text(order_open_slippage,StringConcatenate("Slippage on open ",order_open_slippage_int),Yellow);

                     order_close_slippage_int=round(sign_slip*(OrderStopLoss()-OrderClosePrice())/Point);
                     create_text(order_close_slippage,StringConcatenate("Slippage on close ",order_close_slippage_int),DarkOrange);

                     create_text("TSsum_points",StringConcatenate("Total movement SL ",round(TSsum/Point)),White);
                     if(show_spread) create_text("count_maxspread_str",StringConcatenate("Max spread ",round(maxspread)),White);

                     order_profit_p_int=round(sign_slip*(OrderClosePrice()-OrderOpenPrice())/Point);

                     if(order_profit_p_int>=0) color_profit=Lime; else color_profit=Red;

                     create_text(order_profit_p,StringConcatenate("Profit ",order_profit_p_int),color_profit);
                     create_text(order_profit,StringConcatenate("Profit ",NormalizeDouble(OrderProfit(),2)," value"),color_profit);

                     create_tria("Open_tria",hOOT,lastOOP,hOOT+2*60,lastOOP,hOOT,OrderOpenPrice(),Yellow,1);
                     create_tria("Close_tria",hOCT,OrderStopLoss(),hOCT+2*60,OrderStopLoss(),hOCT,OrderClosePrice(),DarkOrange,1);
                     create_tria("Profit_tria",hOOT,OrderOpenPrice(),hOOT+60,OrderOpenPrice(),hOCT,OrderClosePrice(),DodgerBlue,1);
                     //create_tria("moving_SL_tria",hOOT,SL0,hOOT+60,SL0,hOCT,OrderStopLoss(),DimGray,1);

                     //  create_rect("order_open_slippage_rect",OrderOpenTime(),lastOOP,OrderCloseTime()-5*60,OrderOpenPrice(),DarkOrange);
                     //  create_rect("order_profit_rect",OrderOpenTime(),OrderOpenPrice(),OrderCloseTime()-5*60,OrderClosePrice(),Blue);                
                     //  create_rect("order_close_slippage_rect",OrderOpenTime(),OrderStopLoss(),OrderCloseTime()-5*60,OrderClosePrice(),Yellow);

                     // create_arrow("order_rivok_arrow",OrderOpenTime()-5*60,lastOOP,White);
                     // create_rect("rivok_rect",OrderOpenTime()-6*60,NormalizeDouble(rivok0,Digits),OrderCloseTime()-5*60,rivok0+sign_slip*rivok*Point,color_rivok);
                     // create_tria("rivok_tria",OrderOpenTime()-6*60,rivok0+Point,OrderOpenTime()-6*60,rivok0+sign_slip*rivok*Point,OrderOpenTime()-8*60,rivok0+Point,color_rivok);

                     // create_text_("rivok_points",StringConcatenate(round(rivok)),OrderOpenTime()-6*60,rivok0+rivok*Point/2,White);
                     // create_text_("order_open_slippage_points",StringConcatenate("пр.откр. ",round(order_open_slippage_int)),OrderOpenTime()-3*60,(lastOOP+OrderOpenPrice())/2,White);
                     // create_text_("order_profit_p_int",StringConcatenate("профит ",round(order_profit_p_int)),OrderOpenTime()-3*60,(OrderOpenPrice()+OrderClosePrice())/2,White);
                     // create_text_("order_close_slippage_points",StringConcatenate("пр.закр. ",round(order_close_slippage_int)),OrderOpenTime()-3*60,(OrderClosePrice()+OrderStopLoss())/2,White);

                     ObjectSetInteger(chart_ID,currentspread_text,OBJPROP_COLOR,DodgerBlue);

                     Print(StringConcatenate("Dist=",Dist,", TS=",TrailingStop,"+",TSz,", SL=",Stoploss,", TM=",TimeModify,"s, Kor=",Kor,", Lot=",Lot));

                     print_stats=false;
                     stats_printed=true;

                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                           create_event                           |
//+------------------------------------------------------------------+


void create_event(string name,datetime time_ev,color color_ev)
  {
   error=ObjectCreate(chart_ID,name,OBJ_EVENT,0,time_ev,0);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,color_ev);
   ObjectMove(chart_ID,name,0,time_ev,0);
  }
//+------------------------------------------------------------------+
//|                           create_v_line                          |
//+------------------------------------------------------------------+

void create_v_line(string name,datetime time_l,color color_l,int style_l)
  {

   error=ObjectCreate(chart_ID,name,OBJ_VLINE,0,time_l,0);
//--- установим цвет линии
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,Blue);
//--- установим стиль отображения линии
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style_l);
//--- установим толщину линии
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,1);
//--- отобразим на переднем (false) или заднем (true) плане
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);
   ObjectMove(chart_ID,name,0,time_l,0);
  }
//+------------------------------------------------------------------+
//|                           create_h_line                          |
//+------------------------------------------------------------------+
void create_h_line(string name,double price_l,color color_l,int style_l)
  {
   error=ObjectCreate(chart_ID,name,OBJ_HLINE,0,0,price_l);
//--- установим цвет линии
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,color_l);
//--- установим стиль отображения линии
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style_l);
//--- установим толщину линии
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,1);
//--- отобразим на переднем (false) или заднем (true) плане
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);
   ObjectMove(chart_ID,name,0,0,price_l);
  }
//+------------------------------------------------------------------+
//|                           create_rect                            |
//+------------------------------------------------------------------+
void create_rect(string name,datetime time1,double price1,datetime time2,double price2,color color_r)
  {
   error=ObjectCreate(chart_ID,name,OBJ_RECTANGLE,0,time1,price1,time2,price2);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,color_r);
//--- отобразим на переднем (false) или заднем (true) плане
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,true);
  }
//+------------------------------------------------------------------+
//|                          create_tria                             |
//+------------------------------------------------------------------+
void create_tria(string name,datetime time1,double price1,datetime time2,double price2,datetime time3,double price3,color color_t,int width)
  {

   error=ObjectCreate(chart_ID,name,OBJ_TRIANGLE,0,time1,price1,time2,price2,time3,price3);

//--- установим цвет треугольника

   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,color_t);

//--- установим стиль линий треугольника

   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_SOLID);

//--- установим толщину линий треугольника

   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);

//--- отобразим на переднем (false) или заднем (true) плане

   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);

//--- включим (true) или отключим (false) режим выделения треугольник для перемещений

//--- при создании графического объекта функцией ObjectCreate, по умолчанию объект

//--- нельзя выделить и перемещать. Внутри же этого метода параметр selection

//--- по умолчанию равен true, что позволяет выделять и перемещать этот объект

   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,true);

   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false);

//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов

   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);

   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);

   ObjectSetInteger(chart_ID,name,OBJPROP_FILL,true);

  }
//+------------------------------------------------------------------+
//|                       create_arrow                               |
//+------------------------------------------------------------------+
void create_arrow(string name,datetime time,double price,color clr)
  {

   if(sign_slip==1) error=ObjectCreate(chart_ID,name,OBJ_ARROW_UP,0,time,price);
   if(sign_slip==-1) error=ObjectCreate(chart_ID,name,OBJ_ARROW_DOWN,0,time,price);

   if(!rivok==0)
     {

      //--- установим способ привязки

      if(sign_slip==1) ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
      if(sign_slip==-1) ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_TOP);

      //--- установим цвет знака

      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);

      //--- установим стиль окаймляющей линии

      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_SOLID);

      //--- установим размер знака

      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,10);

      //--- отобразим на переднем (false) или заднем (true) плане

      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);

      //--- включим (true) или отключим (false) режим перемещения знака мышью

      //--- при создании графического объекта функцией ObjectCreate, по умолчанию объект

      //--- нельзя выделить и перемещать. Внутри же этого метода параметр selection

      //--- по умолчанию равен true, что позволяет выделять и перемещать этот объект

      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,true);

      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false);

      //--- скроем (true) или отобразим (false) имя графического объекта в списке объектов

      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);

      //--- установим приоритет на получение события нажатия мыши на графике

      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,2);

     }
  }
//+------------------------------------------------------------------+
//|               create_text_  (по координатам)                     |
//+------------------------------------------------------------------+
bool create_text_(string name,string text,datetime time,double price,color clr)

  {

// ChangeTextEmptyPoint(time,price);

   error=ObjectCreate(chart_ID,name,OBJ_TEXT,0,time,price);

//--- установим текст

   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);

//--- установим шрифт текста

   ObjectSetString(chart_ID,name,OBJPROP_FONT,"Calibri");

//--- установим размер шрифта

   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size_text_);

//--- установим угол наклона текста

   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,0);

//--- установим способ привязки

   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_CENTER);

//--- установим цвет

   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);

//--- отобразим на переднем (false) или заднем (true) плане

   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);

//--- включим (true) или отключим (false) режим перемещения объекта мышью

   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,true);

   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false);

//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов

   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);

//--- установим приоритет на получение события нажатия мыши на графике

   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,0);

   return(true);

  }

//+------------------------------------------------------------------+
