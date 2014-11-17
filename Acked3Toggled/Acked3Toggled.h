#ifndef ACKED3_TOGGLED_H
#define ACKED3_TOGGLED_H


enum
{
	AM_ACKED3TOGGLED = 6,
	TIMER_PERIOD_MILLI = 2048,
	TIMER_PERIOD_MILLI_NEW = 5240
};

typedef nx_struct Acked3ToggledMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t counter;
	nx_uint16_t lostpackets;
}Acked3ToggledMsg;

#endif /* ACKED3_TOGGLED_H */
