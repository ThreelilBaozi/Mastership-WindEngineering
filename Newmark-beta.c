//这是基于newmark-beta法的自由振动（竖向和扭转）涡振udf（使用前删除所有注释）

#include "udf.h"
#include "math.h"

//！！！使用前删掉所有注释


static real y_prev  = 0;
static real y_cur   = 0;
static real vy_prev = 0;
static real vy_cur  = 0;
static real ay_prev = 0;
static real ay_cur  = 0;


static real theta_prev  = 0;
static real theta_cur   = 0;
static real vtheta_prev = 0;
static real vtheta_cur  = 0;
static real atheta_prev = 0;
static real atheta_cur  = 0;


int zone_ID = 19;    //桥面板zone ID
real pi = 3.141592653589793;
real x_cg[3], f_glob[3], m_glob[3];

real m   = 7.6894;      //每延米质量
real I   = 0.3433;      //转动惯量
real yk  = 3495;        //y方向刚度，单位kg·m^2
real yxi = 0.00152;     //竖向阻尼比
real tk  = 810;         //扭转刚度，单位N·m/rad
real txi = 0.0045;      //扭转阻尼比
real dt  = 0.0005;      //时间步长
real t_start = 3.0;     //激活自由振动的起始时间


real beta = 0.25;
real gamma = 0.5;


DEFINE_EXECUTE_AT_END(execute_at_end)
{
    real time = RP_Get_Real("flow-time");
    if (!Data_Valid_P()) return;
    Domain *domain = Get_Domain(1);
    Thread *thread = Lookup_Thread(domain, zone_ID);


    x_cg[0] = 0;
    x_cg[1] = y_cur;
    x_cg[2] = 0;

    Compute_Force_And_Moment(domain, thread, x_cg, f_glob, m_glob, TRUE);
    real force_y = f_glob[1];
    real moment_z = m_glob[2];


    real yc = 2 * m * sqrt(yk / m) * yxi;


    real tc = 2 * I * sqrt(tk / I) * txi;


    if (time >= t_start)
    {

        y_prev     = y_cur;
        vy_prev    = vy_cur;
        ay_prev    = ay_cur;
        theta_prev = theta_cur;
        vtheta_prev = vtheta_cur;
        atheta_prev = atheta_cur;


        real p1 = 1 / (gamma * dt * dt);
        real p2 = beta / (gamma * dt);
        real p3 = 1 / (gamma * dt);
        real p4 = 1 / (2 * gamma) - 1;
        real p5 = beta / gamma - 1;
        real p6 = dt * (beta / gamma - 2) / 2;
        real p7 = dt - beta * dt;
        real p8 = beta * dt;


        real Ky = yk + p1 * m + p2 * yc;
        real Fy = force_y + m * (p1 * y_prev + p3 * vy_prev + p4 * ay_prev)
                  + yc * (p2 * y_prev + p5 * vy_prev + p6 * ay_prev);

        y_cur = Fy / Ky;
        ay_cur = p1 * (y_cur - y_prev) - p3 * vy_prev - p4 * ay_prev;
        vy_cur = vy_prev + p7 * ay_prev + p8 * ay_cur;


        real Kt = tk + p1 * I + p2 * tc;
        real Ft = moment_z + I * (p1 * theta_prev + p3 * vtheta_prev + p4 * atheta_prev)
                   + tc * (p2 * theta_prev + p5 * vtheta_prev + p6 * atheta_prev);

        theta_cur = Ft / Kt;
        atheta_cur = p1 * (theta_cur - theta_prev) - p3 * vtheta_prev - p4 * atheta_prev;
        vtheta_cur = vtheta_prev + p7 * atheta_prev + p8 * atheta_cur;
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
DEFINE_REPORT_DEFINITION_FN(THETA_CUR)  
{ 
return theta_cur; 
}
DEFINE_REPORT_DEFINITION_FN(VTHETA_CUR) 
{ 
return vtheta_cur; 
}
DEFINE_REPORT_DEFINITION_FN(ATHETA_CUR) 
{ 
return atheta_cur; 
}
DEFINE_REPORT_DEFINITION_FN(Comp_F_y)   
{ 
return f_glob[1]; 
}
DEFINE_REPORT_DEFINITION_FN(Comp_M_z)   
{ 
return m_glob[2]; 
}

DEFINE_CG_MOTION(newmark, dt, vel, omega, time, dtime)
{
    if (time >= t_start)
    {
        NV_S(vel, =, 0.0);
        NV_S(omega, =, 0.0);
        vel[1] = vy_cur;        
        omega[2] = vtheta_cur;  
    }
}
