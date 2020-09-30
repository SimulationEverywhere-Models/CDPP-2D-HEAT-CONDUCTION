[top]
components : heatcond 

[heatcond]
type : cell
dim : (13,9)
%delay : transport
delay : inertial
defaultDelayTime  : 10
border : nowrapped 
neighbors : heatcond(-1,0) heatcond(0,0) 
neighbors : heatcond(0,1)  heatcond(1,0)  heatcond(0,-1)   
initialvalue : 20
initialCellsValue : 2dfem.val 
localtransition : conduction-rule
zone : Insulated-Boundary { (1,0)..(11,0) }
zone : Constant-Temp-Boundary { (0,0)..(0,8) }
zone : Constant-Temp-Boundary { (12,0)..(12,8) }
zone : Convective-Boundary { (1,8)..(11,8) }

% Rule used is: t0 = (t1+t2+t3+t4)/4
[conduction-rule]
rule : { ( (0,1)+(-1,0)+(0,-1)+(1,0) ) / 4  } 1 { t } 

%Rule use is: t0 = (t1+t3+ 2*t2)/4
[Insulated-Boundary]
rule : {((-1,0)+(1,0)+2*(0,1)) / 4} 1 {t}

[Constant-Temp-Boundary]
rule : {(0,0)} 1 {t}

%In the Convective-Boundary rule, fluid temperature is 25 degrees, and value of h.a/k is 1.666666666666665
% as per example 10.4 in "Introduction to Finite Elements in Engineering, Tirupathi Chandrupatla 
% and Ashok Belegundu
%Rule used is: t0 = (t1/2 + t3/2 + t2 + Tfluid * h*a/k) /(2 + h*a/k)
[Convective-Boundary]
rule : {( ((1,0)/2)+((-1,0)/2)+(0,-1)+ (25 * 1.666666666666665) )/(2 + 1.666666666666665) } 1 {t}
