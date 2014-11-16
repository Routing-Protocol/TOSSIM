#ifndef ACKED1_TOGGLED_H
#define ACKED1_TOGGLED_H

enum 
{
	AM_ACKED1TOGGLED = 6,
	TIMER_PERIOD_MILLI = 2048,
	TIMER_PERIOD_MILLI_NEW = 5240
};

typedef nx_struct Acked1ToggledMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t counter;
	nx_uint16_t lostpackets;
} Acked1ToggledMsg;

#endif /* ACKED1_TOGGLED_H */
