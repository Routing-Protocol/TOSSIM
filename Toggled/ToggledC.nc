#include <Timer.h>
#include "Toggled.h"


module ToggledC{
	
	uses interface Boot;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	
	uses interface PacketAcknowledgements;
	
	
	uses interface Leds;
	uses interface Receive;
	 
}
implementation{
	
	uint16_t counter;
	uint16_t new_counter;
	
	message_t pkt;
	
	bool busy = FALSE;
	bool acked = TRUE;
	
	uint8_t node1 = 0x03;
	uint8_t node2 = 0x04;
	uint8_t node3 = 0x99;
	
	
	event void Boot.booted()
	{
		call AMControl.start();
	}
	
	event void AMControl.startDone(error_t err)
	{
		if(err == SUCCESS)
		{
			call Timer1.startPeriodic(TIMER_PERIOD_MILLI_NEW);
			
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
			
		}
		
		else
		{
			call AMControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t err)
	{}
	
	event void Timer1.fired()
	{
		node3 = node2;
		node2 = node1;
		node1 = node3;
	}
	
	event void Timer0.fired()
	{
		if (acked)
		{
			counter++;
		}
		
		if (!busy)
		{
			ToggledMsg* tpkt = (ToggledMsg*) (call Packet.getPayload(&pkt, sizeof(ToggledMsg)));
			
			if (tpkt ==NULL)
			{
				return;
			}
			
			tpkt->nodeid = TOS_NODE_ID;
			tpkt->counter = counter;
			
			if (tpkt->counter % 0x02 == 0)
			{
				call PacketAcknowledgements.requestAck(&pkt);
				if (call AMSend.send(node1, &pkt, sizeof(ToggledMsg)) == SUCCESS)
				{
					busy = TRUE;
				}
			}
			
			else
			{
				call PacketAcknowledgements.requestAck(&pkt);
				if (call AMSend.send(node2, &pkt, sizeof(ToggledMsg)) == SUCCESS)
				{
					busy = TRUE;
				}
			}

		}
	}
	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if (&pkt == msg)
		{
			busy = FALSE;
			dbg("ToggledC", "Message was sent @ %s, \n", sim_time_string());
		}
		
		if (call PacketAcknowledgements.wasAcked(msg))
		{
                        acked = TRUE;
			call AMControl.start();
		}
	        else
	        {
	    	acked = FALSE;
	    	call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		}
	}	
	




	
	message_t rpkt;
	
	void setLeds(uint16_t val)
	{
		if (val & 0x01)
		     call Leds.led0On();
		else 
		     call Leds.led0Off();
		if (val & 0x02)
		     call Leds.led1On();
		else 
		     call Leds.led1Off();
		if (val & 0x04)
		     call Leds.led2On();
		else 
		     call Leds.led2Off();
	}
	
	event message_t* Receive.receive(message_t* rmsg, void* payload, uint8_t len)
	{
		dbg("ToggledC", "Received packet of lenght %hhu @ %s with payload : %hhu \n", len, sim_time_string(), payload);
		
		if (len == sizeof(ToggledMsg))
		{
			ToggledMsg* trpkt = (ToggledMsg*)payload;
			setLeds(trpkt->counter);
                        dbg("Boot", "node : %hhu has counter: %hhu  \n", trpkt->nodeid, trpkt->counter);
		}
		
		return rmsg;
	}	
	
}
