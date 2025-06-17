//这是师兄给我的跑的通的源文件

#include "udf.h"
#include "math.h"
//vertical motion initial condition
static real y_prev  = 0;
static real y_cur   = 0;
static real vy_prev = 0;
static real vy_cur  = 0;
static real ay_prev = 0;
static real ay_cur  = 0;
//other parameters
int zone_ID = 16;
static real pi = 3.141592653589793;
real x_cg[3],f_glob[3],m_glob[3];


DEFINE_EXECUTE_AT_END(execute_at_end)
{
    real time = RP_Get_Real("flow-time");
    if (!Data_Valid_P())
    	return;
    Domain *domain;
    Thread *thread;
    domain = Get_Domain(1);
    thread = Lookup_Thread(domain,zone_ID);

    x_cg[0] = 0;
    x_cg[1] = y_cur;
    Compute_Force_And_Moment (domain, thread , x_cg, f_glob, m_glob, TRUE);
    real force_y = f_glob[1];
   

    //vertical and torsional dynamic parameters
    real m  = 15.293;
    real yk = 5662.453;   
    real yc = 2*m*sqrt(yk/m)*0.0015;
    //newmark parameters
    real d_t = 0.0005;
    real beta = 0.25;
    real gamma = 0.5;

    real p1 = 1/(gamma*d_t*d_t);
    real p2 = beta/(gamma*d_t);
    real p3 = 1/(gamma*d_t);
    real p4 = 1/(2*gamma) - 1;
    real p5 = beta/gamma - 1;
    real p6 = d_t*(beta/gamma -2)/2;
    real p7 = d_t - beta*d_t;
    real p8 = beta*d_t;

    if(time>=3)
    {
   	y_prev = y_cur;
   	vy_prev = vy_cur;
    ay_prev = ay_cur;

    real K_y = yk + p1*m + p2*yc;
   	real F_y = force_y + m*(p1*y_prev + p3*vy_prev + p4*ay_prev) + yc*(p2*y_prev +p5*vy_prev +p6*ay_prev);

   	y_cur = F_y/K_y;
    ay_cur = p1*(y_cur - y_prev) - p3*vy_prev - p4*ay_prev;
   	vy_cur = vy_prev + p7*ay_prev +p8*ay_cur;
    }
}


DEFINE_REPORT_DEFINITION_FN(Y_CUR)
{
    return y_cur;
}
DEFINE_REPORT_DEFINITION_FN(VY_CUR)
{
    return vy_cur;
}
DEFINE_REPORT_DEFINITION_FN(AY_CUR)
{
    return ay_cur;
}
DEFINE_REPORT_DEFINITION_FN(Comp_F_x)
{
	return f_glob[0];
}
DEFINE_REPORT_DEFINITION_FN(Comp_F_y)
{
	return f_glob[1];
}
DEFINE_REPORT_DEFINITION_FN(Comp_M_z)
{
	return m_glob[2];
}


DEFINE_CG_MOTION(newmark,dt,vel,omega,time,dtime)
{
    if(time>=3)
    {
        NV_S(vel, =, 0.0);
        vel[1] = vy_cur;
       
    }
}
