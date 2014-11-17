#include <Timer.h>
#include "ToggledEfficiency.h"


module ToggledEfficiencyC{
	
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface LocalTime<TMilli>;
	uses interface SplitControl as AMControl;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface PacketAcknowledgements as PacketAck;
	//uses interface Read<uint16_t> as BatteryVoltage;
	
	uses interface Leds;
	uses interface Receive;
	
}
implementation{
	
	uint16_t counter = 0;
	uint16_t LostPackets = 0;
	uint16_t retransmissions = 0;
	uint16_t acknowledged = 0;
	uint16_t retx = 0;
	
	uint16_t PRR = 0;
	uint16_t mavg = 0;
	float ftmavg = 0.0;
	
	message_t pkt;
	
	bool RADIO = FALSE;
	bool BUSY = FALSE;
	bool ACKed = TRUE;
	
	uint8_t node1 = 0x03;
	uint8_t node2 = 0x04;
	uint8_t node3 = 0x99;
	
	
	event void Boot.booted()
	{
		call AMControl.start();
		call Timer0.startPeriodic(TIMER_PERIOD_MILLI_0);
		call Timer1.startPeriodic(TIMER_PERIOD_MILLI_1);
	}
	
	event void AMControl.startDone(error_t err)
	{
		if (err == SUCCESS)
		{
			RADIO = TRUE;
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
		ToggledEfficiencyMsg* TEpkt = (ToggledEfficiencyMsg*)(call Packet.getPayload(&pkt, sizeof(ToggledEfficiencyMsg)));
		if (TEpkt == NULL)
		{
			return;
		}
		
		ftmavg = (float)(retransmissions +(counter * mavg)) / (float)(counter+1);
		mavg = ftmavg*1000;
		//PRR = acknowledged / (acknowledged + LostPackets);
		
		TEpkt->nodeid = TOS_NODE_ID;
		TEpkt->counter = counter;
		TEpkt->lostpackets = LostPackets;
		TEpkt->retransmissions = retransmissions;
		TEpkt->acknowledged = acknowledged;
		TEpkt->movingaverage = mavg;
		
		if (TEpkt->counter%0x02 == 0)
		{
			call PacketAck.requestAck(&pkt);
			if (node1 != TOS_NODE_ID)
			{
				if (call AMSend.send(node1, &pkt, sizeof(ToggledEfficiencyMsg)) == SUCCESS)
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
				if (call AMSend.send(node2, &pkt, sizeof(ToggledEfficiencyMsg)) == SUCCESS)
				{
					BUSY = TRUE;
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
		if (RADIO == TRUE)
		{
			retx = 0;
			counter++;
			
			if (!BUSY)
			{
				post SendMsg();
			}
		}
		
		else
		{
			call AMControl.start();
		}
	}
	
	//event void BatteryVoltage.readDone(error_t error, uint16_t battery)
	//{}
	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if (&pkt == msg)
		{
			BUSY = FALSE;
			dbg("ToggledEfficiencyC", "Message was sent @ %s, \n", sim_time_string());
		}
		
		if (call PacketAck.wasAcked(msg))
		{
			retransmissions = 0;
			acknowledged++;
			ACKed = TRUE;
		}
		
		else
		{
			retx++;
			retransmissions = retx;
			LostPackets++;
			ACKed = FALSE;
			
			if (retx < 8)
			{
				post SendMsg();
			}
			else
			{
				post DoNothing();
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
		dbg("ToggledEfficiencyC", "Received packet of length %hhu @ %s with Payload: %hhu \n", len, sim_time_string(), payload);
		
		if (call AMPacket.isForMe(rmsg) == TRUE)
		{
			if (len == sizeof(ToggledEfficiencyMsg))
			{
				ToggledEfficiencyMsg* TEpkt = (ToggledEfficiencyMsg*)payload;
				setLeds(TEpkt->counter);
				dbg("Boot", "node: %hhu \n \t\t counter: %hhu \n \t\t\t\t lostpackets: %hhu \n \t\t\t\t retransmissions: %hhu \n \t\t\t\t acknowledgements: %hhu \n \t\t\t\t moving average: %hhu \n", TEpkt->nodeid, TEpkt->counter, TEpkt->lostpackets, TEpkt->retransmissions, TEpkt->acknowledged, TEpkt->movingaverage);
			}		
			
		}
	
	    return rmsg;	
	}


}
