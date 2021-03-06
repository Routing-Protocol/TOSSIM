#include <Timer.h>
#include "Acked2Toggled.h"


module Acked2ToggledC{
	
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
	uint16_t LostPackets = 0;
	uint8_t retx;
	
	message_t pkt;
	
	bool BUSY = FALSE;
	bool ACKed = TRUE;
	
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
		
		dbg("Boot", "nodes switched\n");
	}
	
	task void DoNothing()
	{}
	
	task void SendMsg()
	{
		Acked2ToggledMsg* atpkt = (Acked2ToggledMsg*)(call Packet.getPayload(&pkt, sizeof(Acked2ToggledMsg)));
		
		if (atpkt == NULL)
		{
			return;
		}
		
		atpkt->nodeid = TOS_NODE_ID;
		atpkt->counter = counter;
		atpkt->lostpackets = LostPackets;
		
		if (atpkt->counter % 0x02 == 0)
		{
			call PacketAck.requestAck(&pkt);
			if (node1 != TOS_NODE_ID)
			{
				if (call AMSend.send(node1, &pkt, sizeof (Acked2ToggledMsg)) == SUCCESS)
				{
					BUSY = TRUE;
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
				if (call AMSend.send(node2, &pkt, sizeof(Acked2ToggledMsg)) == SUCCESS)
				{
					BUSY = TRUE;
				}
				else
				{
					post DoNothing();
				}
			}			
		}
	}
	
	event void Timer0.fired()
	{
		if (ACKed == TRUE)
		{
			counter++;
		}
		
		if (!BUSY)
		{
			post SendMsg();
		}
	}
	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if (&pkt == msg)
		{
			BUSY = FALSE;
			dbg("Acked2ToggledC", "Message (%hhu)) was sent @ %s for the %hhu time, \n", counter, sim_time_string(), retx);
		}
		
		if (call PacketAck.wasAcked(msg))
		{
			retx = 0;
			ACKed = TRUE;
			call AMControl.start();
		}
		
		else
		{
			retx++;
			LostPackets++;
			ACKed = FALSE;
			
			if (retx < 8)
			{
				post SendMsg();
			}
			else
			{
				call AMControl.start();
			}
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
		dbg("Acked2ToggledC", "Received a packet of length %hhu @ %s with payload : %hhu \n", len, sim_time_string(), payload);
		
		if (len == sizeof(Acked2ToggledMsg))
		{
			Acked2ToggledMsg* atrpkt = (Acked2ToggledMsg*)payload;
			setLeds(atrpkt->counter);
			dbg("Boot", "node: %hhu has a counter: %hhu wiht the number of lost packets: %hhu \n", atrpkt->nodeid, atrpkt->counter, atrpkt->lostpackets);
		}
		
		return rmsg;
	}
	
	
	
		
}
