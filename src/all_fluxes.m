function [NE,AC,SMC,EC] = all_fluxes (t,state)
%% load the constants for the fluxes and pointers:
    all_indices();
    all_constants();

%% Calculate the fluxes for the Astrocyte (AC)

% Below all the additional equations are calculated and stores in AC, SMC
% and EC

AC(flu.R_s)    = R_tot - state(ind.R_k);                               % m

AC(flu.N_Cl_s) = state(ind.N_Na_s) + state(ind.N_K_s) - state(ind.N_HCO3_s);   % uMm

% AC(flu.Na_k  ) = negCheck(state(ind.N_Na_k)  ,6.1e-8);  % uM
% AC(flu.K_k   ) = negCheck(state(ind.N_K_k)   ,6.1e-8);  % uM
% AC(flu.HCO3_k) = negCheck(state(ind.N_HCO3_k),6.1e-8);  % uM
% AC(flu.Cl_k  ) = negCheck(state(ind.N_Cl_k)  ,6.1e-8);  % uM
% AC(flu.Na_s  ) = negCheck(state(ind.N_Na_s)  ,2.69e-8);     % uM
% AC(flu.K_s   ) = negCheck(state(ind.N_K_s)   ,2.69e-8);     % uM
% AC(flu.HCO3_s) = negCheck(state(ind.N_HCO3_s),2.69e-8);     % uM
% AC(flu.Cl_s  ) = negCheck(AC(flu.N_Cl_s)     ,2.69e-8);     % uM

AC(flu.Na_k  ) = negCheck(state(ind.N_Na_k)  ,state(ind.R_k));  % uM
AC(flu.K_k   ) = negCheck(state(ind.N_K_k)   ,state(ind.R_k));  % uM
AC(flu.HCO3_k) = negCheck(state(ind.N_HCO3_k),state(ind.R_k));  % uM
AC(flu.Cl_k  ) = negCheck(state(ind.N_Cl_k)  ,state(ind.R_k));  % uM
AC(flu.Na_s  ) = negCheck(state(ind.N_Na_s)  ,AC(flu.R_s));     % uM
AC(flu.K_s   ) = negCheck(state(ind.N_K_s)   ,AC(flu.R_s));     % uM
AC(flu.HCO3_s) = negCheck(state(ind.N_HCO3_s),AC(flu.R_s));     % uM
AC(flu.Cl_s  ) = negCheck(AC(flu.N_Cl_s)     ,AC(flu.R_s));     % uM

AC(flu.E_Na_k ) = (R_gas * Temp) / (z_Na * Farad) * log(AC(flu.Na_s)/AC(flu.Na_k)); % V
AC(flu.E_K_k )  = (R_gas * Temp) / (z_K  * Farad) * log(AC(flu.K_s )/AC(flu.K_k )); % V
AC(flu.E_Cl_k ) = (R_gas * Temp) / (z_Cl * Farad) * log(AC(flu.Cl_s)/AC(flu.Cl_k)); % V
AC(flu.E_NBC_k )= (R_gas * Temp) / (z_NBC* Farad) * ...
              log((AC(flu.Na_s)*AC(flu.HCO3_s)^2)/(AC(flu.Na_k)*AC(flu.HCO3_k)^2));     % V 
AC(flu.E_BK_k)  = (R_gas * Temp) / (z_K  * Farad) * log(state(ind.K_p)/AC(flu.K_k));% V


AC(flu.J_NaK_k  ) = J_NaK_max * Hill(AC(flu.Na_k), K_Na_k, 1.5) * ...
                Hill(AC(flu.K_s),K_K_s,1);              % uMm s-1 

AC(flu.v_k )   = ( g_Na_k  * AC(flu.E_Na_k )...
             + g_K_k   * AC(flu.E_K_k  )...
             + g_Cl_k  * AC(flu.E_Cl_k )...
             + g_NBC_k * AC(flu.E_NBC_k)...
             - AC(flu.J_NaK_k)*Farad/unitcon...
             + g_BK_k *state(ind.w_k) * AC(flu.E_BK_k)          )...
            /(g_Na_k + g_K_k + g_Cl_k + g_NBC_k + g_BK_k*state(ind.w_k));  % V

       
AC(flu.J_KCC1_k ) = getRef(t,'fluxft')*...
                (R_gas * Temp * g_KCC1_k) / (Farad^2) * log((AC(flu.K_s)...
                *AC(flu.Cl_s))/(AC(flu.K_k)*AC(flu.Cl_k)))*unitcon;                  %uMm s-1

AC(flu.J_NBC_k  ) = g_NBC_k / Farad * (AC(flu.v_k) - AC(flu.E_NBC_k))*unitcon;       %uMm s-1
AC(flu.J_NKCC1_k) = getRef(t,'fluxft')*...
                (g_NKCC1_k * R_gas * Temp) / (Farad^2) ...
                * log((AC(flu.K_s) * AC(flu.Na_s) * AC(flu.Cl_s)^2)...
                     /(AC(flu.K_k) * AC(flu.Na_k) * AC(flu.Cl_k)^2))*unitcon;        %uMm s-1            
AC(flu.J_Na_k  ) = g_Na_k / Farad * (AC(flu.v_k) - AC(flu.E_Na_k))*unitcon;          %uMm s-1
AC(flu.J_K_k   ) = g_K_k  / Farad * (AC(flu.v_k) - AC(flu.E_K_k ))*unitcon;          %uMm s-1
AC(flu.J_BK_k)   = g_BK_k / Farad * state(ind.w_k)*(AC(flu.v_k)-AC(flu.E_BK_k))*unitcon; %uMm s-1

AC(flu.w_inf)    = 0.5*(1+tanh((AC(flu.v_k)+v_6)/(v_4)));                        %[-]
AC(flu.phi_w)    = psi_w*cosh((AC(flu.v_k)+v_6)/(2*v_4));                        %s-1


%% SMC

SMC(flu.M)                   = 1 - state(ind.Mp) - state(ind.AM) - state(ind.AMp);                         
SMC(flu.E_K_i)              = (R_gas * Temp) / (z_K  * Farad)*unitcon*log(state(ind.K_p)/state(ind.K_i));
SMC(flu.h_r)                 =  -state(ind.R) + sqrt(state(ind.R)^2 + 2*rb_r*h0_r + h0_r^2);

SMC(flu.v_coup_i)            = - g_hat * ( state(ind.v_i) - state(ind.v_j) );   
SMC(flu.Ca_coup_i)           = - p_hat * ( state(ind.Ca_i) - state(ind.Ca_j) );
SMC(flu.IP3_coup_i)          = - p_hatIP3 * ( state(ind.I_i) - state(ind.I_j) );
SMC(flu.rho_i)              = 1;%( K_d + state(ind.Ca_i ))^2 / ( ( K_d + state(ind.Ca_i) )^2 + ( K_d * B_T ) );
SMC(flu.J_IP3_i)            = Fmax_i * ( state(ind.I_i)^2 ) / ( Kr_i^2 + state(ind.I_i)^2 );
SMC(flu.J_SRuptake_i)       = B_i * ( state(ind.Ca_i)^2 ) / ( state(ind.Ca_i)^2 + cb_i^2 );
SMC(flu.J_CICR_i)           = C_i *  ( state(ind.s_i)^2 ) / ( sc_i^2 + state(ind.s_i)^2 ) *  ( state(ind.Ca_i)^4 ) / ( cc_i^4 + state(ind.Ca_i)^4 );
SMC(flu.J_extrusion_i)      = D_i * state(ind.Ca_i) * ( 1 + ( state(ind.v_i) - vd_i ) / ( Rd_i ) );
SMC(flu.J_leak_i)           = L_i * state(ind.s_i);
SMC(flu.J_VOCC_i)           = G_Ca * ( state(ind.v_i) - v_Ca1) / ( 1 + exp( - ( state(ind.v_i) - v_Ca2 ) / ( R_Ca ) ) );
SMC(flu.J_NaCa_i)           = G_NaCa * state(ind.Ca_i)* ( state(ind.v_i) - v_NaCa ) / ( state(ind.Ca_i) + c_NaCa );
SMC(flu.J_NaK_i)            = F_NaK;
SMC(flu.J_Cl_i)             = G_Cl * ( state(ind.v_i) - v_Cl );
SMC(flu.J_K_i)              = G_K * state(ind.w_i) * ( state(ind.v_i) - vK_i );
SMC(flu.Kactivation_i)      = ( state(ind.Ca_i) + c_w )^2 / ( (state(ind.Ca_i) + c_w)^2 + bet*exp(-(state(ind.v_i) - SMC(flu.v_Ca3))/R_K) );
SMC(flu.J_degrad_i)         = k_i * state(ind.I_i);
SMC(flu.J_stretch_i)        = G_stretch/(1+exp(-alpha1*(P_str*state(ind.R)/SMC(flu.h_r) - sig0))) * (state(ind.v_i) - Esac);

SMC(flu.v_KIR_i)    = z_1 * state(ind.K_p)/unitcon + z_2;                                               % mV
SMC(flu.G_KIR_i)    = exp( z_5 * state(ind.v_i) + z_3 * state(ind.K_p)/unitcon + z_4 ); %exp( z_5 * state(ind.v_i) + z_3 * state(ind.K_p)/unitcon + z_4 );                     % pS pF-1 =s-1
SMC(flu.J_KIR_i)    = F_il/gam * SMC(flu.G_KIR_i)*(state(ind.v_i)-SMC(flu.v_KIR_i));                                % mV s-1

% Myosin crossbridge model
SMC(flu.K1_c) = gam_cross*state(ind.Ca_i)^3;
SMC(flu.K6_c) = SMC(flu.K1_c);

%% EC

EC(flu.v_coup_j)             = - g_hat * ( state(ind.v_j) - state(ind.v_i) );  
EC(flu.Ca_coup_j)            = - p_hat * ( state(ind.Ca_j) - state(ind.Ca_i) );
EC(flu.IP3_coup_j)           = - p_hatIP3 * ( state(ind.I_j) - state(ind.I_i) );
EC(flu.rho_j)               = 1;%( K_d + state(ind.Ca_j) )^2 / ( ( K_d + state(ind.Ca_j) )^2 + ( K_d * B_T ) );
EC(flu.J_0_j)               = J0_j;
EC(flu.J_IP3_j)             = Fmax_j * ( state(ind.I_j)^2 ) / ( Kr_j^2 + state(ind.I_j)^2 );
EC(flu.J_ERuptake_j)        = B_j * ( state(ind.Ca_j)^2 ) / ( state(ind.Ca_j)^2 + cb_j^2 );
EC(flu.J_CICR_j)            = C_j *  ( state(ind.s_j)^2 ) / ( sc_j^2 + state(ind.s_j)^2 ) *  ( state(ind.Ca_j)^4 ) / ( cc_j^4 + state(ind.Ca_j)^4 );
EC(flu.J_extrusion_j)       = D_j * state(ind.Ca_j); 
EC(flu.J_leak_j)            = L_j * state(ind.s_j);
EC(flu.J_cation_j)          = G_cat * ( E_Ca - state(ind.v_j) )* 0.5 * ( 1 + tanh(( log10( state(ind.Ca_j) ) - m3cat )/( m4cat)) );
EC(flu.J_BKCa_j) 			= 0.4/2 * ( 1 + tanh( ( (  log10(state(ind.Ca_j)) - c) * ( state(ind.v_j) - b ) - a1 ) / ( m3b*( state(ind.v_j) + a2 * ( log10( state(ind.Ca_j )) - c ) - b )^2 + m4b ) ) );
EC(flu.J_SKCa_j) 			= 0.6/2 * ( 1 + tanh( ( log10(state(ind.Ca_j)) - m3s ) / ( m4s ) ) );
EC(flu.J_K_j)               = G_tot * ( state(ind.v_j) - vK_j ) * ( EC(flu.J_BKCa_j) + EC(flu.J_SKCa_j) );
EC(flu.J_R_j)               = G_R * ( state(ind.v_j) - v_rest);
EC(flu.J_degrad_j)          = k_j * state(ind.I_j);
EC(flu.J_stretch_j)         = G_stretch/(1+exp(-alpha1*(P_str*state(ind.R)/SMC(flu.h_r) - sig0))) * (state(ind.v_j) - Esac);



%% NO pathway

Glu = getRef(t,'Glu');
tau_w = getRef(t,'wss');

% NE
NE(flu.P_NR2AO)         = Glu/(betA+Glu); 
NE(flu.P_NR2BO)         = Glu/(betB+Glu);
NE(flu.openProbTerm)    = 0.63 * NE(flu.P_NR2AO) + 11 * NE(flu.P_NR2BO);
NE(flu.I_Ca)            = (-4*v_n*G_M*P_Ca_P_M*(Ca_ex/M))/(1+exp(-0.08*(v_n+20)))...
                            *(exp(2*1e-3*v_n*F/(R*T)))/(1-exp(2*1e-3*v_n*F/(R*T)))...
                            *(0.63*NE(flu.P_NR2AO)+11*NE(flu.P_NR2BO));     % inward calcium current per open NMDA receptor ; (96)
NE(flu.phi_N)           = 1 + Q1*state(ind.Ca_n) + Q1*Q2*state(ind.Ca_n)^2 + Q1*Q2*Q3*state(ind.Ca_n)^3 + Q1*Q2*Q3*Q4*state(ind.Ca_n)^4;        % (102)
NE(flu.dphi_N)          = Q1 + 2*Q1*Q2*state(ind.Ca_n) + 3*Q1*Q2*Q3*state(ind.Ca_n)^2 + 4*Q1*Q2*Q3*Q4*state(ind.Ca_n)^3;            % == d(phi_N)/d(ind.Ca_n) ; (part of 101)
NE(flu.N)               = (state(ind.Ca_n)/NE(flu.phi_N))*NE(flu.dphi_N);                                                   % number of Ca2+ bound per calmodulin ; (101)
NE(flu.CaM)             = state(ind.Ca_n)/NE(flu.N);                                      % concentration of calmodulin / calcium complexes ; (100)            

            
% EC
EC(flu.W_tau_w)         = W_0*(tau_w + sqrt(16*delt_wss^2+tau_w^2)-4*delt_wss)^2/(tau_w+sqrt(16*delt_wss^2+tau_w^2)) ; 
EC(flu.F_tau_w)         = (1/(1+alp*exp(-EC(flu.W_tau_w))))-(1/(1+alp)); % -(1/(1+alp)) was added to get no NO at 0 wss (!)


% SMC 
SMC(flu.k4)             = C_4*state(ind.cGMP)^m;
SMC(flu.R_cGMP1)        = (state(ind.cGMP)^2)/(state(ind.cGMP)^2+K_m_cGMP^2);
SMC(flu.R_NO)           = (state(ind.NOi)/(state(ind.NOi)+K_m_NO)) ;
SMC(flu.v_Ca3)          = V_cGMP*SMC(flu.R_cGMP1) - V_NO*SMC(flu.R_NO) - V_b;
SMC(flu.P_O)            = (state(ind.Ca_i) + c_wi )^2/( (state(ind.Ca_i) + c_wi )^2 + bet_i*exp(-(state(ind.v_i) - SMC(flu.v_Ca3)) / (R_Kfit)) );
SMC(flu.R_cGMP2)        = (state(ind.cGMP)^2)/(state(ind.cGMP)^2+K_m_mlcp^2);
SMC(flu.K2_c)           = k_mlcp_b+k_mlcp_c*SMC(flu.R_cGMP2);
SMC(flu.K5_c)           = SMC(flu.K2);

% SMC(flu.test)           = (((K_dis*state(ind.Ca_j))/(K_eNOS+state(ind.Ca_j)))-mu2*state(ind.NOj)+g_max*EC(flu.F_tau_w)) - (state(ind.NOj)-state(ind.NOi))/tau_ji - k_O2*(state(ind.NOj))^2*Oj;







end


%    A function that corrects for negative concentrations and sets them to 1e-180
%    Note that, when the system is running correctly this function is not
%    used.


function out = negCheck(input,wx)
    if (input / wx) > 0
        out = input/wx;
    else
        out = 1e-180;
    end
end











