#ifndef ACKED2_TOGGLED_H
#define ACKED2_TOGGLED_H


enum
{
	AM_ACKED2TOGGLED = 6,
	TIMER_PERIOD_MILLI = 2048,
	TIMER_PERIOD_MILLI_NEW = 5240
};

typedef nx_struct Acked2ToggledMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t counter;
	nx_uint16_t lostpackets;
}Acked2ToggledMsg;

#endif /* ACKED2_TOGGLED_H */
