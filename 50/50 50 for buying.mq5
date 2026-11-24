#include <Trade\Trade.mqh>
#property strict

input double lotSize         = 0.01;
input double targetProfitUSD = 1.50;   // updated profit target
input double maxLossUSD      = -3.00; // updated maximum loss allowed
input long   magicNumber     = 3005;   // updated unique ID for this EA

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   // ensure CTrade sends orders with this EA's magic number
   trade.SetExpertMagicNumber(magicNumber);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
{
   bool buyPositionExists = false;

   // Loop through all open positions (safely)
   for(int idx = PositionsTotal() - 1; idx >= 0; idx--)
   {
      // get ticket by index
      ulong ticket = PositionGetTicket(idx);
      if(ticket == 0) continue;

      // select that position by ticket so PositionGet* functions work
      if(!PositionSelectByTicket(ticket)) continue;

      // check if it's our symbol, our magic and a BUY position
      string sym = PositionGetString(POSITION_SYMBOL);
      long   type = (long)PositionGetInteger(POSITION_TYPE);
      long   mag  = (long)PositionGetInteger(POSITION_MAGIC);

      if(sym == _Symbol && type == POSITION_TYPE_BUY && mag == magicNumber)
      {
         buyPositionExists = true;

         double profit = PositionGetDouble(POSITION_PROFIT);

         // close if profit target reached or loss exceeded
         if(profit >= targetProfitUSD || profit <= maxLossUSD)
         {
            trade.PositionClose(ticket);
            buyPositionExists = false; // will open again later if needed
         }
      }
   }

   // If no buy position exists for this EA, open a new market buy
   if(!buyPositionExists)
   {
      bool ok = trade.Buy(lotSize, _Symbol);
      if(ok)
         PrintFormat("Buy opened (magic=%d, lots=%.2f)", magicNumber, lotSize);
      else
         Print("Buy open failed: ", GetLastError());
   }
}
