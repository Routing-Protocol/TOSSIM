#include <Timer.h>
#include "Acked2Toggled.h"


configuration Acked2ToggledAppC{
}
implementation{
	
	components MainC;
	components Acked2ToggledC as App;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components ActiveMessageC;
	components new AMSenderC (AM_ACKED2TOGGLED);
	
	components LedsC;
	components new AMReceiverC(AM_ACKED2TOGGLED);
	
	
	
	App.Boot -> MainC;
	App.Timer0 -> Timer0;
	App.Timer1 -> Timer1;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.PacketAck -> ActiveMessageC;
	
	App.Leds -> LedsC;
	App.Receive -> AMReceiverC;
	
	
}
