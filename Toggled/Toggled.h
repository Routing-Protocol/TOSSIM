#ifndef TOGGLED_H
#define TOGGLED_H


enum 
{
	AM_TOGGLED = 6,
	TIMER_PERIOD_MILLI = 250,
	TIMER_PERIOD_MILLI_NEW = 5240
};

typedef nx_struct ToggledMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t counter;	
} ToggledMsg;


#endif /* TOGGLED_H */
