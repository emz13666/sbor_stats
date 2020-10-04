FOR /L %%i IN (1,1,30) DO (ping 10.70.123.%%i -n 1 -w 1200)&&(plink -ssh -pw unrfce20 admin@10.70.123.%%i "iwconfig ath0 | grep level")
FOR /L %%i IN (60,1,81) DO (ping 10.70.123.%%i -n 1 -w 1200)&&(plink -ssh -pw unrfce20 admin@10.70.123.%%i "iwconfig ath0 | grep level")
