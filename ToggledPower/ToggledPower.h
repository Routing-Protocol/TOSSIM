#ifndef TOGGLED_POWER_H
#define TOGGLED_POWER_H

enum
{
	AM_TOGGLEDPOWER = 6,
	TIMER_PERIOD_MILLI_0 = 2048,
	TIMER_PERIOD_MILLI_1 = 5240
};

typedef nx_struct ToggledEfficiencyMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t counter;
	nx_uint16_t lostpackets;
	nx_uint16_t retransmission;
	nx_uint16_t acknowledged;
	nx_uint16_t movingaverage;
	nx_uint16_t battery;
	nx_uint32_t txtime;
	nx_uint32_t rxtime;
	nx_uint32_t processortime;
	nx_uint32_t energy;
}ToggledPowerMsg;

#endif /* TOGGLED_POWER_H */
