#include <Timer.h>
#include "Toggled.h"

configuration ToggledAppC{
}
implementation{
	
	components MainC;
	components ToggledC as App;
	components ActiveMessageC;
	components new AMSenderC(AM_TOGGLED);
	
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	
	components LedsC;
	components new AMReceiverC(AM_TOGGLED);
	
	

	
	
	App.Boot -> MainC;
	App.AMControl -> ActiveMessageC;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	
	App.Timer0 -> Timer0;
	App.Timer1 -> Timer1;
	
	App.PacketAcknowledgements -> AMSenderC;
	
	
	App.Leds -> LedsC;
	App.Receive -> AMReceiverC;

}
