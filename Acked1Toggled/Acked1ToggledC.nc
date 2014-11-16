#include <Timer.h>
#include "Acked1Toggled.h"


module Acked1ToggledC{
	
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface PacketAcknowledgements as PacketAck;
	
	uses interface Leds;
	uses interface Receive;
		
}

implementation{
	
	uint16_t counter;
	uint16_t new_counter;
	uint16_t LostPackets = 0;
	
	message_t pkt;
	
	bool busy = FALSE;
	bool COUNTER = TRUE;
	
	uint8_t node1 = 0x03;
	uint8_t node2 = 0x04;
	uint8_t node3 = 0x99;
	
	
	event void Boot.booted()
	{
		call AMControl.start();
		call Timer1.startPeriodic(TIMER_PERIOD_MILLI_NEW);
	}
	
	event void AMControl.startDone(error_t err)
	{
		if (err == SUCCESS)
		{
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
		
		dbg("Boot", " nodes switched\n");
	}
	
		
	task void DoNothing()
	{}
		
	task void SendMsg()
	{
		Acked1ToggledMsg* atpkt = (Acked1ToggledMsg*)(call Packet.getPayload(&pkt, sizeof(Acked1ToggledMsg)));
		
		if (atpkt == NULL)
		{
			return;
		}
		
		atpkt->nodeid = TOS_NODE_ID;
		atpkt->counter  = counter;
		atpkt->lostpackets = LostPackets;
		
		if (atpkt->counter % 0x02 == 0)
		{
			call PacketAck.requestAck(&pkt);
			if (node1 != TOS_NODE_ID)
			{
				if (call AMSend.send(node1, &pkt, sizeof (Acked1ToggledMsg)) == SUCCESS)
			    {
			    	busy = TRUE;
			    }
			}
			else
			{
				post DoNothing();
			}
		}
		
		else
		{
			call PacketAck.requestAck(&pkt);
			if (node2 != TOS_NODE_ID)
			{
				if (call AMSend.send(node2, &pkt, sizeof(Acked1ToggledMsg)) == SUCCESS)
			    {
			    	busy = TRUE;
			    }
			}			
			else 
			{
				post DoNothing();
			}
		}
	}
	
	event void Timer0.fired()
	{
		if (COUNTER == TRUE)
		{
			counter++;
		}
		
		if (!busy)
		{
			post SendMsg();
		}
	}
	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if (&pkt == msg)
		{
			busy = FALSE;
			dbg("Acked1ToggledC", "Message was sent @ %s, \n", sim_time_string());
		}
		
		if (call PacketAck.wasAcked(msg))
		{
			COUNTER = TRUE;
			call AMControl.start();
		}
		else
		{
			LostPackets++;
			COUNTER = FALSE;
			post SendMsg();
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
	 	dbg("Acked1ToggledC", "Received a packet of lenght %hhu @ %s with payload : %hhu \n", len, sim_time_string(), payload);
	 	
	 	if (len == sizeof(Acked1ToggledMsg))
	 	{
	 		Acked1ToggledMsg* atrpkt = (Acked1ToggledMsg*)payload;
	 		setLeds(atrpkt->counter);
	 	    dbg("Boot", "node : %hhu has a counter: %hhu with the number of lost packets: %hhu \n", atrpkt->nodeid, atrpkt->counter, atrpkt->lostpackets);
	 	}
	 	
	 	return rmsg;
	 }
	 
	 
}
