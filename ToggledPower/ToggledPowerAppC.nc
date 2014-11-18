#include <Timer.h>
#include "ToggledPower.h"


configuration ToggledPowerAppC{
}
implementation{
	
	components MainC;
	components ToggledPowerC as app;
	
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	
	components LocalTimeMilliC;
	
	components ActiveMessageC;
	components new AMSenderC(AM_TOGGLEDPOWER);
	
	//components new VoltageC() as Battery;
	
	
	components LedsC;
	components new AMReceiverC(AM_TOGGLEDPOWER);
	
	
	
	
	app.Boot -> MainC;
	
	app.Timer0 -> Timer0;
	app.Timer1 -> Timer1;
	
	app.LocalTime -> LocalTimeMilliC;
	
	app.AMControl -> ActiveMessageC;
	app.AMSend -> AMSenderC;
	app.Packet -> AMSenderC;
	app.AMPacket -> AMSenderC;
	
	app.PacketAck -> ActiveMessageC;
	
	//app.BatteryVoltage -> Battery;
	
	app.Leds -> LedsC;
	app.Receive -> AMReceiverC;

}
