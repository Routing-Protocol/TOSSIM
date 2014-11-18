#include <Timer.h>
#include "ToggledPower.h"


module ToggledPowerC{
	
	uses interface Boot;
	
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	
	uses interface SplitControl as AMControl;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	
	uses interface LocalTime<TMilli>;
	
	uses interface PacketAcknowledgements as PacketAck;
	
	//uses interface Read<uint16_t> as BatteryVoltage;
	
	
	uses interface Leds;
	uses interface Receive;
	
}
implementation{
	
	uint16_t counter;
	uint16_t LostPackets = 0;
	uint16_t retransmissions = 0;
	uint16_t acknowledged = 0;
	uint8_t retx = 0;
	uint16_t microsecond = 1048;
	
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
	
	uint16_t batteryVoltage = 2.9;
	
	uint32_t startTime = 0x00;
	uint32_t stopTime = 0x00;
	
	uint32_t processorTime = 0x00;
	
	uint32_t radioTime = 0x00;
	uint32_t rstartTime = 0x00;
	
	uint32_t sendTime = 0x00;
	uint32_t sstartTime = 0x00;
	uint32_t sstopTime = 0x00;
	uint32_t sackTime = 0x00;
	
	uint32_t receiveTime = 0x00;
	
	uint32_t energyconsumed = 0x00;
	
	uint32_t processorCurrent;
	uint32_t sendCurrent;
	uint32_t receiveCurrent;
	
	
	event void Boot.booted()
	{
		startTime = call LocalTime.get();
		
		call AMControl.start();
		call Timer0.startPeriodic(TIMER_PERIOD_MILLI_0);
		call Timer1.startPeriodic(TIMER_PERIOD_MILLI_1);
	}
	
	event void AMControl.startDone(error_t err)
	{
		if (err == SUCCESS)
		{
			rstartTime = call LocalTime.get();
			RADIO = TRUE;			
		}
		
		else
		{
			call AMControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t err)
	{
		//stopTime = call LocalTime.get();
	}
	
	event void Timer1.fired()
	{
		node3 = node2;
		node2 = node1;
		node1 = node3;		
		
		dbg("Boot", "Switched\n");
	}
	
	task void DoNothing()
	{}
	
	task void SendMsg()
	{
		ToggledPowerMsg* TPMpkt = (ToggledPowerMsg*)(call Packet.getPayload(&pkt, sizeof(ToggledPowerMsg)));
		
		
		if (TPMpkt == NULL)
		{
			return;			
		}
		
		processorTime = call LocalTime.get() - startTime;
		receiveTime = processorTime - sendTime;
		
		//call BatteryVoltage.read();
		
		//batteryVoltage = ((uint16_t)1223 * (uint16_t)1024) / batteryVoltage;
		
		ftmavg = (float)(retransmissions + (counter * mavg)) / (float)(counter+1);
		mavg = ftmavg * 1000;
		//PRR = acknowledged / (acknowledged + LostPackets);
		
		sendTime = sackTime + (sstartTime - sstopTime);
		
		processorCurrent = 8;
		sendCurrent = 10;
		receiveCurrent = 16;
		
		energyconsumed = (processorCurrent * batteryVoltage) * processorTime + (receiveCurrent * batteryVoltage) * receiveTime + (sendCurrent * batteryVoltage) * sendTime;
		
		TPMpkt->nodeid = TOS_NODE_ID;
		TPMpkt->counter = counter;
		TPMpkt->lostpackets = LostPackets;
		TPMpkt->retransmission = retransmissions;
		TPMpkt->acknowledged = acknowledged;
		TPMpkt->movingaverage = mavg;
		TPMpkt->battery = batteryVoltage;
		TPMpkt->txtime = sendTime;
		TPMpkt->rxtime = receiveTime;
		TPMpkt->processortime = processorTime;
		TPMpkt->energy = energyconsumed;
		
		
		if (TPMpkt->counter%0x02 == 0)
		{
			call PacketAck.requestAck(&pkt);
			if (node1 != TOS_NODE_ID)
			{
				if (call AMSend.send(node1, &pkt, sizeof(ToggledPowerMsg)) == SUCCESS)
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
				if (call AMSend.send(node2, &pkt, sizeof(ToggledPowerMsg)) == SUCCESS)
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
	
	/*
	 * event void BatteryVoltage.readDone(error_t error, uint16_t battery)
	 * {
	 *     if (error != SUCCESS)
	 *     {
	 *         battery = 0x00;
	 *     }
	 * 
	 *     batteryVoltage = battery;
	 * } 
	 */
			
	event void Timer0.fired()
	{
		sstartTime = 0x00;
		sstopTime = 0x00;
		sackTime = 0x00;
		
		if (RADIO == TRUE)
		{
			retx = 0;
			counter ++;
			
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
	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if (&pkt == msg)
		{
			BUSY = FALSE;
			dbg("ToggledPowerC", "Message was sent @ %s, \n", sim_time_string());
		}
		
		if (call PacketAck.wasAcked(msg))
		{
			retransmissions = 0;
			acknowledged++;
			ACKed = TRUE;
			
			sstopTime = call LocalTime.get();
		}
		
		else
		{
			sackTime = sackTime + (sstartTime - call LocalTime.get());
			
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
		dbg("ToogledPowerC", "Received packet of lenght %hhu @ %s with Payload: %hhu \n", len, sim_time_string(), payload);
		
		if (call AMPacket.isForMe(rmsg) == TRUE)
		{
			if (len == sizeof(ToggledPowerMsg))
			{
				ToggledPowerMsg* TPpkt = (ToggledPowerMsg*)payload;
				setLeds(TPpkt->counter);
				dbg("Boot", "node: %hhu \n \t\t counter: %hhu \n \t\t\t\t\t lostpackets: %hhu \n \t\t\t\t\t retransmissions: %hhu \n \t\t\t\t\t acknowledgements: %hhu \n \t\t\t\t\t moving average: %hhu \n \t\t\t\t\t transmission time: %hhu \n \t\t\t\t\t Reveicer time: %hhu \n \t\t\t\t\t processing time: %hhu \n \t\t\t\t\t total energy consumed: %hhu \n ", TPpkt->nodeid, TPpkt->counter, TPpkt->lostpackets, TPpkt->retransmission, TPpkt->acknowledged, TPpkt->movingaverage, TPpkt->txtime, TPpkt->rxtime, TPpkt->processortime, TPpkt->energy);
			}			
		}
		
		return rmsg;
	}	
	
	
	
	
}
