#ifndef TOGGLED_EFFICIENCY_H
#define TOGGLED_EFFICIENCY_H

enum
{
	AM_TOGGLEDEFFICIENCY = 6,
	TIMER_PERIOD_MILLI_0 = 2048,
	TIMER_PERIOD_MILLI_1 = 5240
};

typedef nx_struct ToggledEfficiencyMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t counter;
	nx_uint16_t lostpackets;
	nx_uint16_t retransmissions;
	nx_uint16_t acknowledged;
	nx_uint16_t movingaverage;
}ToggledEfficiencyMsg;

#endif /* TOGGLED_EFFICIENCY_H */
